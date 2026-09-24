@icon("state.svg")
class_name State
extends Node

##	The actual state behaviour. Inherit this and lob it into a machine. The node heirachy controls
##	parental relations. If a function is not specified it will pass execution down the chain until
##	reaching a parent which does. Parent methods can still be called within overriden functions
##	via the parent reference.
##	All between-state data is held by the context, passed to the state node on each execution.
##	States have no concept of the overall State Machine


##	Reference to this state's parent node (if applicable). Searched for during _ready();
var parent : State = null;


###################################################################################################
#	ENGINE CALLBACKS
###################################################################################################

## Get the parent State
func _ready() -> void:
	# Fetch the state's parent (if applicable)
	var par = get_parent()
	if not par is State:
		if not par is StateMachine:
			push_error(name + " Should be parented to State or State Machine")
		return
	parent = par;


###################################################################################################
#	STATE CALLBACKS
###################################################################################################

##	Called every physics frame while this is the active state.
func _tick(context : StateContext) -> void:
	if parent:
		parent._tick(context);


##	Called when the state is made into the current state.
func _enter(context : StateContext ) -> void:
	if parent:
		parent._enter(context);


##	Called when the state is being booted from being the current state.
func _exit(context : StateContext ) -> void:
	if parent:
		parent._exit(context);


##	Called when attempting to change from this state. Allows for custom checks per state.
func _can_interrupt(context : StateContext) -> bool:
	if parent:
		parent._can_interrupt(context);
	return true;


##	Used for realtime removing of tree states. We dont want to propogate this down. Use carefully.
func _can_remove(context : StateContext) -> bool:
	return true;


## Called when this state is pushed underneath a new stacked state
func _pause(context : StateContext) -> void:
	_exit(context);


## Called when this state is popped back to the top of a state stack
func _resume(context : StateContext) -> void:
	_enter(context);