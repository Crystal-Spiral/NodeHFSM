@icon("stack_state_machine.svg")
class_name StackStateMachine
extends StateMachine

## Stacking variant of State Machine. Allows for layering state execution over eachother

##	The currently stored states, excluding the current state
var stack : Array[State] = [];

##	Emited when a state is pushed to the top of the stack, becoming the new active state
signal state_pushed(new : State, suspended : State);
##	Emited when a state is popped from the stack top, reverting to the state beneath it
signal state_popped(resumed : State, old : State);
##	Emited when the current state prevents stacking over it
signal stack_blocked(blocked : State, by : State);
##	Emitted when the current state has been replaced with a new one, maintaining the current depth
signal state_replaced(new : State, old : State);
##	Emited when anything changes. Useful for anything that wants to monitor but doesnt care what
signal changed()


###################################################################################################
#	ENGINE CALLBACKS
###################################################################################################

##	Start up the machine
func _ready() -> void:
	super._ready()
	context._replace_func = replace_state
	context._push_func = push_state
	context._pop_func = pop_state


###################################################################################################
#	STACK MANAGEMENT
###################################################################################################
 
##	Pauses the current state and pushes `new` on top of it as the active state. Can be blocked
##	by the current state's _can_interrupt, unless force is flagged.
func push_state(new : Variant, force := false) -> bool:
	new = get_state_node(new) as State;
	if new == null:
		return false;
 
	if not force and not current_state._can_interrupt(context):
		stack_blocked.emit(new, current_state);
		return false;
 
	var old := current_state;
	current_state._pause(context);
	stack.push_back(old);
 
	current_state = new;
	current_state._enter(context);
 
	context.previous_state_name = old.name;
	context.state_name = new.name;
	context.state_ticks = 0;
	context.state_time = 0.0;
 
	state_pushed.emit(new, old);
	return true;
 
 
##	Fully exits the current state and resumes whatever is beneath it on the stack. Returns false
##	if the stack is empty (nothing to pop back to) or the current state blocks the interrupt.
func pop_state(force := false) -> bool:
	if stack.is_empty():
		return false;
 
	if not force and not current_state._can_interrupt(context):
		stack_blocked.emit(stack.back(), current_state);
		return false;
 
	var old := current_state;
	current_state._exit(context);
 
	current_state = stack.pop_back();
	current_state._resume(context);
 
	context.previous_state_name = old.name;
	context.state_name = current_state.name;
	context.state_ticks = 0;
	context.state_time = 0.0;
 
	state_popped.emit(current_state, old);
	return true;


##	Exits the current state and sets new to the active state at the same level, leaving the stack
##	untouched
func replace_state(new : Variant, force := false) -> bool:
	new = get_state_node(new) as State;
	if new == null:
		return false;
 
	if not force and not current_state._can_interrupt(context):
		stack_blocked.emit(new, current_state);
		return false;
 
	var old := current_state;
	old._exit(context);
 
	current_state = new;
	current_state._enter(context);
 
	context.previous_state_name = old.name;
	context.state_name = new.name;
	context.state_ticks = 0;
	context.state_time = 0.0;
 
	state_replaced.emit(new, old);
	changed.emit();
	return true;

 
##	Pops repeatedly until `target` is the active state, or the stack empties out (whichever
##	comes first). Useful for unwinding several layers at once (e.g. closing a whole menu chain).
func pop_to(target : Variant, force := false) -> bool:
	target = get_state_node(target) as State;
	if target == null:
		return false;
	if not has_state_in_stack(target):
		return false;
 
	while current_state != target and not stack.is_empty():
		if not pop_state(force):
			return false;
 
	return current_state == target;
 

##	Pops repeatedly for a set number of states or the stack empties out
func pop_count(count : int, force := false) -> bool:
	for i in count:
		if not pop_state(force):
			return false;
	return true;


 
##	Discards the stack. Can be made to call exit on states 
func clear_stack(perform_exit := false) -> void:
	if perform_exit:
		for state in stack:
			state._exit(context);
	stack.clear();
 
 
###################################################################################################
#	OVERRIDES
###################################################################################################
 
##	A full change_state() is a hard reset: it exits current_state as normal (inherited behaviour)
##	but also drops the stack, since anything sitting on it no longer has a valid path back.
func change_state(new : Variant, force := false, fallback := fallback_State) -> bool:
	var result := super.change_state(new, force, fallback);
	if result:
		stack.clear();
	return result;
 
 
###################################################################################################
#	HELPERS
###################################################################################################
 
##	The state currently suspended directly beneath current_state, or null if the stack is empty.
func peek_state() -> State:
	if stack.is_empty():
		return null;
	return stack.back();
 
 
##	How many states are suspended beneath the current one.
func get_stack_depth() -> int:
	return stack.size();
 

## Check if the stack is empty. Reads nicer than comparing depth to zero
func is_stack_empty() -> bool:
	return stack.is_empty();

 
##	Whether `state` is currently sitting suspended somewhere in the stack.
func has_state_in_stack(state : Variant) -> bool:
	state = get_state_node(state) as State;
	if state == null:
		return false;
	return stack.has(state);
 

##	Check if there's something to pop back to and the current state allows the interrupt.
func can_pop() -> bool:
	if stack.is_empty():
		return false;
	return current_state._can_interrupt(context);


##	Return the stack bottom to top, with current added. Handy for debugging overlays and such
func get_full_stack() -> Array[State]:
	var full := stack.duplicate();
	full.push_back(current_state);
	return full;
