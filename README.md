# Home

Octagon is a fully fledged modular server sided anti exploit designed to detect many exploits reliably without interrupting user experience.

---

## Supported detections

Currently, Octagon supports the following physics / non physics detections. As newer versions come, Octagon will eventually support more detections.

**Physics**:

- High horizontal speed
- High vertical speed
- NoClip

**NonPhysics**:

- Multi tool equip
- Invalid primary part deletion

---

## Supported detections

Currently, Octagon supports the following physics / non physics detections. As newer versions come, Octagon will eventually support more detections.

**Physics**:

- High horizontal speed
- High vertical speed
- NoClip

**NonPhysics**:
- Multi tool equip
- Invalid primary part deletion

---

## How effective is it at stopping exploits and how performance friendly is it?

Firstly, Octagon already comes with preinstalled physics and non physics detections. 


If Octagon sees the player movement being invalid ( high vertical or horizontal speed or no clip (if enabled) ), then the player will be safely teleported to their last position and their network ownership temporarily taken away from them which temporarily results in a jerky movement but makes it near-impossible for the player to perform physics exploit. It is also safe to say that each exploit detection is **extremely battle tested** and are very reliable.

Note that Octagon *never* relies on any information from the client, it already performs physics checks rather than checking client sided computated values like [Humaniod.FloorMaterial](https://developer.roblox.com/en-us/api-reference/property/Humanoid/FloorMaterial) or [Humanoid StateTypes](https://developer.roblox.com/en-us/api-reference/enum/HumanoidStateType) which can be easily spoofed by the client.

### False positives

With every serversided anti exploit, false positives will sometimes appear due to replication latency of the player's position to the server. Octagon is designed in such a way that it safely computes the maximum vertical and horizontal speed of the player based on their jump power, jump height, walk speed and also accounting for gravity and changes in any of these properties. It is worth mentioning that these detections are extremely reliable based off of heavy testing and logic.

### Flexiblity and scalability

Octagon is extremely flexible, and you can easily adjust it to easily suit your own game's need without any headaches. Octagon already comes with group configuration support and manual player black listing from being monitored. Heck, it even allows you to toggle current detections and even create new ones (not currently documented yet).

As a bonus, one of the best features of Octagon is that it respects serverside changes. Meaning that changing walk speed, teleporting the player or any property that impacts physics / non physics on the server for a specific player, will cause **no issues** and Octagon will not falsely detect the player!

### Performance

By using a **single** [Heartbeat](https://developer.roblox.com/en-us/api-reference/event/RunService/Heartbeat) event to monitor all players in the game, it is performance friendly and uses something which I call physics cache (which caches physics computation value for later reuse).

Here are some concluded benchmarks against other anti exploits:

![image](https://user-images.githubusercontent.com/71311544/131211198-30fb0406-44fe-4341-b526-559b97d52af1.png)

---

## Why use Octagon over anti exploits?

- **Doesn't perform heavy computation and reserves resources** - Octagon is an extremely performant anti exploit as it doesn't perform heavy computation. Many other anti exploits perform very poorly which is **bad** for both developer experience and games. 

- **Easiness of usage** - Octagon is very easy to use and can be easily imported to your game without any headaches. It doesn't provide bloated methods and allows you to use it to it's fullest capability.

- **Handles nightmarish edge cases no developer would ever dare to fix** - Octagon is the most reliable anti exploit as of writing, and handles a **lot of nightmarish** edge cases which are guaranteed to arise when developing a reliable anti exploit.

- **Built for flexibility and massive scalability** - Octagon is extremely flexible, you can add your own checks alongside others without any headaches and is built to perform in large-player servers reliably. It spreads a **single** [Heartbeat](https://developer.roblox.com/en-us/api-reference/event/RunService/Heartbeat) event for all players in the game.

- **Future proof** - Octagon already provides group configuration support along side manual player blacklisting so you'll never be left in the dark and will **almost** never interrupt UX except very slightly in a **rare case**.

---

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