## Example usage


### Server

Here's some serverside code which starts up Octagon and  listens to a player’s physics detection flags:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Octagon = require(ReplicatedStorage.Octagon)
local PlayerProfileService = require(Octagon.PlayerProfileService)

-- Start up Octagon:

Octagon.Start()

local function PlayerAdded(player)
    local profile = PlayerProfileService.GetPlayerProfile(player)  

    -- Safe check as the player's profile will not exist if the player
    -- isn't being monitored by the anti exploit:

    if not profile then
        return nil
    end

    -- Listen to new physics detection flags:
    profile.OnPhysicsDetectionFlag:Connect(function(flag)
        warn(("%s got flagged for %s"):format(player.Name, flag))
    end)

    return nil
end

-- Scripts are deferred when they run (in deferred signal behaviour), handle the edge case where players are already in the game by the time this script runs:
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
```

Okay, how about a very simple one?

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Octagon = require(ReplicatedStorage.Octagon)

Octagon.Start()
```

---

###  Client

Additionally, here is some basic client side code (parented to [StarterPlayerScripts](https://developer.roblox.com/en-us/api-reference/class/StarterPlayerScripts)) which starts up Octagon on the client side.Octagon on the client side will monitor the player's humanoid state and stops the player from bouncing high up when they fall to the ground (to prevent a false flag) and resets their velocity when flinged (to prevent a false flag).

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Octagon = require(ReplicatedStorage.Octagon)

-- Start up octagon:
Octagon.Start()
```