@icon("state_context.svg")
class_name StateContext
extends RefCounted

##	Data storage for a State Machine. Passed to nodes during execution. Holds typical fields and an
##	arbitrary storage container. Does not bridge States to the machine beyond a reference to the
##	machine's change state function.


##	Shortcut reference for the Node this Machine acts on
var host : Node;

##	Current state's name
var state_name : String;
##	The last active state's name
var previous_state_name : String;

##	The time in seconds the current state has been active for
var state_time : float = 0.0;
##	The amount of ticks processed for the current state
var state_ticks : int = 1;

##	The physics process delta time. Updated by the machine each loop
var delta : float;


##	Reference to the machines change state function, giving states indirect access
var _change_func : Callable
##	Reference to a stacked state machines replace function
var _replace_func : Callable
##	Reference to a stacked state machines push function
var _push_func : Callable
##	Reference to a stacked state machines pop function
var _pop_func : Callable


##	Arbitrary data storage
var _mem := {};
##	Flag for a stacked state machine
var _is_stack


###################################################################################################
#	MEMORY MANAGEMENT
###################################################################################################

##	Store a value in the context memory
func set_val(key : Variant, data : Variant) -> void:
	_mem.set(key, data);


##	Retrieve a value from the context memory (or a default if it fails)
func get_val(key : Variant, default : Variant = null) -> Variant:
	return _mem.get(key, default);


##	Erase a value from the context memory
func erase_val(key : Variant) -> void:
	_mem.erase(key);


##	Completely whipe the context memory
func clear() -> void:
	_mem.clear();


###################################################################################################
#	STATE MANAGEMENT
###################################################################################################

##	Allows states to request a state change
func change_state(new : Variant, force := false) -> bool:
	return _change_func.call(new, force);


##	Allows states to request a state replace in stacked fsms
func replace_state(new : Variant, force := false) -> bool:
	if not _is_stack or not _replace_func:
		return false
	return _replace_func.call(new, force);


##	Allows states to request a push in stacked fsms
func push_state(new : Variant, force := false) -> bool:
	if not _is_stack or not _push_func:
		return false;
	return _push_func.call(new, force);


##	Allows states to request a pop in stacked fsms
func pop_state(force := false) -> bool:
	if not _is_stack or not _pop_func:
		return false;
	return _pop_func.call(force);


##	Check if the running machine is  a stack state machine in case branching is needed
func is_stack_machine() -> bool:
	return _is_stack;