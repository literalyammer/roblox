--------------------------------------------------------
---------- Version 2.0 ---------------------------------
---------- Released 8/17/2017 --------------------------
---------- Written by orange451 ------------------------
--------------------------------------------------------

--[[
	
To use this script, place it in: (( Game --> StarterPlayer --> StarterCharacterScripts ))


To activate it, set the scripts Activate boolean value to TRUE.

SETTINGS:
	- Activate
		- This flag, when set to true, will activate the ragdoll effect (alive or dead)
		
	- Weld Head
		- If set to true, a stuff joint will be used on the neck to prevent the head from moving while ragdolled.
		
	- GivePlayerPhysics
		- When the ragdoll effect is active, this flag will force the player who is being ragdolled to control the physics of the ragdoll. 
		- If it is set to false, the roblox server decides who has the physics.
		
			- ForceClosestPlayer
				- For this to work, GivePlayerPhysics must be set to true
				- This will search for the nearest Player object to thie ragdoll, and set him as the physics holder.
				- This is useful for NPC's, who are not owned by a player, and you want accurate Ragdolls.
		
	- ApplyRandomVelocity
		- This will set every part in the player to have a random amount of velocity applied.
		- Helps to keep ragdolls unique every time

	- ActiveOnDeath
		- This flag, when set to true, will force the ragdoll to activate when your character dies.	
			
			- CloneAndDestroy
				- For this to work, ActiveOnDeath must be set to true.
				- This will, when your character dies, clone your body into a new model named "RagDoll". (Parent is workspace)
				- Can be useful to set the collision group of ragdolls, as you can listen for models named "RagDoll" to be added to the workspace.
				- This will also place an ObjectValue named "RagDoll" inside your Character, so it is easy to find the newly created RagDoll.
					
					- Delay
						- For this to work, CloneAndDestroy must be set to true.
						- This is the amount of time before the ragdoll is removed from the workspace. 
	

EXAMPLE PROGRAM:
	local Character = game.Workspace.Player1;
	local Ragdoll = Character.RagdollR15;
	Ragdoll.Activate.Value = true;
	wait(5);
	Ragdoll.Activate.Value = false;
--]]

