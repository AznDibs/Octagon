Here's some basic serverside code (should be parented to [ServerScriptService](https://developer.roblox.com/en-us/api-reference/class/ServerScriptService)) which starts up Octagon and listens to player's exploit detection flags:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Octagon = require(ReplicatedStorage.Octagon)
local PlayerProfileService = require(Octagon.PlayerProfileService)
 
-- Start up Octagon:
Octagon.Start()

local function PlayerAdded(player)
	local profile = PlayerProfileService.GetPlayerProfile(player)  
	
	-- Safe check as the player's profile will not exist if the player
	-- isn't being monitored by the anti exploit:
	if not profile then
		return nil
	end

	-- Listen to new physics detection flags:
	profile.OnPhysicsDetectionFlag:Connect(function(detectionFlag)
		warn(("%s got flagged for %s"):format(player.Name, detectionFlag))
	end)

	return nil
end

-- Scripts are deferred when they run, handle the edge case where players are already
-- in the game by the time this script runs:
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
```

Okay, let's do it the more simpler way:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Octagon = require(ReplicatedStorage.Octagon)
 
Octagon.Start()
```

Additionally, here is a very basic client side code (should be parented to [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts)) which starts up Octagon on the client side. For clarification, it will monitor the player's humanoid state and stops them from bouncing high up when they fall to the ground (to prevent false positive) and resets their velocity when flinged (to prevent false positive).

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Octagon = require(ReplicatedStorage.Octagon)

-- Start up octagon:
Octagon.Start()
```
