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
var change_state : Callable

##	Arbitrary data storage
var _mem := {};


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