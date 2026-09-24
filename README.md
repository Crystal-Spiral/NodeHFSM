# NodeHFSM

Node Based Heirachical Finite State Machine implementation.

Provides just the starting building blocks.
Basic and unoptimised as all heck, but will get you started quickly.
Probably shouldn't use in anything beyond basic prototyping.


### Usage

- Drop a State Machine Node into your scene
- Build out your tree using scripts that extend state
- Pass the Host (the node the tree acts on) and inital state to the state machine

The State class provides enter, exit, and tick functions.
They also have an optional can interupt state for blocking transitions
When states have parent state nodes, their functions will be called unless overriten.

Also includes a stack based state machine


---
Maybe someday I'll brave GUI programming an editor for a proper resourced based version.
