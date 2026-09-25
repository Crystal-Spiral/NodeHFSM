@icon("state_machine.svg")
class_name StateMachine
extends Node

##	Root node of a tree. Responcible for tracking and performing the active state
##	Data meant for states themselves is handled by StateContext

##	Shortcut to the node this machine acts on. Defaults to owner on _ready
@export var host : Node;
##	The starting state this machine should run
@export var inital_state : State;
##	A safety state if fetching a state fails during a change (optional)
@export var fallback_State : State;

##	The active state;
var current_state : State;
##	The shared memory pool between states;	
var context : StateContext;

##	Emitted on a successful state change
signal state_changed(new : State, old : State);
##	Emitted when the current state blocks a change attempt
signal state_change_blocked(blocked : State, by : State);


###################################################################################################
#	ENGINE CALLBACKS
###################################################################################################

##	Start up the machine
func _ready() -> void:
	#	Setup machine and context
	current_state = inital_state;
	context = StateContext.new();
	context.host = host;
	context.change_func = change_state;

	# Wait for all nodes in tree to ready before starting JIC
	await owner.ready;
	if host == null:
		host = owner;
	current_state._enter(context);


## Update the machine for each tick
func _physics_process(delta: float) -> void:
	#	Update the context and tick the current state
	context.delta = delta;
	current_state._tick(context);
	context.state_ticks += 1;
	context.state_time += delta;


###################################################################################################
#	STATE MANAGEMENT
###################################################################################################

##	Attempts to change the current state to a new one. Can be blocked by the current state, unless
##	force is flagged. If it fails to find the state, it'll change to fallback if not null
func change_state(new : Variant, force := false, fallback := fallback_State) -> bool:
	new = get_state_node(new) as State;
	if new == null:
		if fallback:
			return change_state(fallback, force);
		return false;

	if not force and not current_state._can_interrupt(context):
		state_change_blocked.emit(new, current_state);
		return false;
	
	var old := current_state;
	current_state._exit(context);

	current_state = new;
	current_state._enter(context);

	context.state_name = new.name;
	context.previous_state_name = old.name;
	context.state_ticks = 0;
	context.state_time = 0.0;

	state_changed.emit(current_state, old);
	return true;


##	Dynamically add a state to the machine tree
func add_state(new : State, location : String) -> bool:
	var par = get_node(location);
	if not par:
		return false;
	if new.get_parent():
		new.reparent(par)
	else:
		par.add_child(new);
	return true;


##	Dynamically remove a state from the tree. If its the current state, go to the fallback
func remove_state(state : Variant, fallback := fallback_State, force := false) -> bool:
	state = get_state_node(state) as State;
	if not state:
		return false;
	
	if not force and not state._can_remove(context):
		return false;

	if state == current_state:
		change_state(fallback);
	state.queue_free();
	return true;




###################################################################################################
#	HELPERS
###################################################################################################

##	Get a state node from a variant value
func get_state_node(val : Variant) -> State:
	if val is String:
		val = get_node(val);	# Assume path
	
	if val is State:
		return val;

	return null;