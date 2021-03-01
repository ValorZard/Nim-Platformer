Nico Platform Fighter (name pending)

an example 2D platform fighter built with the nico framework.

to be put on itch.io soon.

Moves: Jump, Punch, Kick, Special (Shoots Fireball)

Only 3 possible moves.

TODO:

Add Floating Points but make sure to only round to three decimal places for determinism

Investigate Netty, get peer to peer networking working

Add Gamestates, and a replay feature.

Add a diagram of the current state machine

Figure out how to do states for a set amount of frames (hitlag)

Figure out fixed update, 60 frames a second.

Seperate out code into multiple files

Make hitboxes/collision better, more feature rich. (Add godot style collision normals, lines of overlap)

Add Floors, Walls, Ceilings. (Floors has ground jumps, walls have wall jumps)

Have more complex collision for the player (change from boxes to circles)

Use Zinac's algorithm to make rollback netcode: https://gist.github.com/rcmagic/f8d76bca32b5609e85ab156db38387e9

ADD DOCUMENTATION (Total beginner should understand)

Reference material for the project:

https://springrollgames.itch.io/platform-fighter-engine

https://ki.infil.net/w02-netcode.html