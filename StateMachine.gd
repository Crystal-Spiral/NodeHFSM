@icon("StateMachine.svg")
class_name StateMachine
extends Node

##	Root node of a tree. Responcible for tracking and performing the active state
##	Data meant for states themselves is handled by StateContext

#	Shortcut to the node this machine acts on. Defaults to owner on _ready
@export var host : Node;
#	The starting state this machine should run
@export var inital_state : State;
#	A safety state if fetching a state fails during a change (optional)
@export var fallback_State : State;

#	The active state;
var current_state : State;
#	The shared memory pool between states;	
var context : StateContext;

#	Emitted on a successful state change
signal state_changed(new : State, old : State);
#	Emitted when the current state blocks a change attempt
signal state_change_blocked(blocked : State, by : State);


###################################################################################################
#	ENGINE CALLBACKS
###################################################################################################

func _ready() -> void:
	#	Setup machine and context
	current_state = inital_state;
	context = StateContext.new();
	context.host = host;
	context.change_state = change_state;

	# Wait for all nodes in tree to ready before starting JIC
	await owner.ready;
	if host == null:
		host = owner;
	current_state._enter(context);


func _physics_process(delta: float) -> void:
	#	Update the context and tick the current state
	context.delta = delta;
	current_state._tick(context);
	context.state_ticks += 1;
	context.state_time += delta;


###################################################################################################
#	STATE MANAGEMENT
###################################################################################################

#	Attempts to change the current state to a new one. Can be blocked by the current state, unless
#	force is flagged.
func change_state(new : Variant, force := false, use_fallback := true) -> bool:
	new = get_state_node(new) as State;
	if new == null:
		if use_fallback:
			return change_state(fallback_State, force);
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

	return true;


##	Get a state node from a variant value
func get_state_node(val : Variant) -> State:
	if val is String:
		val = get_node(val);	# Assume path
	
	if val is State:
		return val;

	return null;