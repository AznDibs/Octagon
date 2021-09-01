# Detections

Octagon already comes with preinstalled physics and non physics detections of course. They can be extremely easily be configured for your own game's needs and you can even create your own custom physics detections.

## Physics

By default, Octagon comes with the following physics detections:

- NoClip
- HorizontalSpeed
- VerticalSpeed

## How do they work?

#### **NoClip**

This detection by default, checks if the player (who is being monitored) has no clipped through an instance reliably. If these conditions are true, then the player is flagged for no clip, teleported to their last CFrame (just before they no clipped) and their network ownership temporarily taken away from them.

!!!tip
    This detection does account for physics collision groups and the property `CanCollide` of an instance. If the can collide 

#### **HorizontalSpeed**

This detection by default, checks if the player (who is being monitored) is walking / teleported / has teleported **significantly higher** than their walk speed is capable of.  If these conditions are true, then the player is flagged for high horizontal speed, teleported to their last CFrame (just before these conditions were true) and their network ownership temporarily taken away from them.

!!!tip
    The server can safely increase the velocity of the player's character's primary part, or
    simply teleport the player without this detection flagging the player.

#### **VerticalSpeed**

This detection works exactly like the above one, but for high vertical speed.

---

**Sneak peak** of a physics detection:
```lua
-- SilentsReplacement
-- HorizontalSpeed
-- July 18, 2021

--[[
    HorizontalSpeed.Leeway : number
    HorizontalSpeed.StartInterval : number
    HorizontalSpeed.PlayerDetectionFlagExpireInterval : number
    HorizontalSpeed.LeewayMultiplier : number
    HorizontalSpeed.Enabled : boolean

	HorizontalSpeed.Cleanup() --> nil []
	HorizontalSpeed.Init() --> nil []
    HorizontalSpeed.Start(
        detectionData : table
        playerProfile : PlayerProfile
        dt : number
    ) --> nil []
]]

local HorizontalSpeed = {
	Leeway = 8,
	StartInterval = 0.3,
	PlayerDetectionFlagExpireInterval = 4,
	LeewayMultiplier = 1.3,
	Enabled = true,
}

...
```

!!!tip
    The server can safely increase the velocity of the player's character's primary part, or
    simply teleport the player without this detection flagging the player.

Each physics detection, comes with a predefined set of members which you can toggle for your own game's need:

### `PhysicsDetection.Leeway`

```lua
PhysicsDetection.Leeway : number
```

For each physics threshold, an additional amount of value is considered which is referred to as "Leeway".

!!!note
    It is recommended to have this value set to a number greater than or equal to `8` to reduce the chance of false positives.

### `PhysicsDetection.StartInterval`

```lua
PhysicsDetection.StartInterval : number
```

The interval (in seconds) at which the physics detection runs.

### `PhysicsDetection.PlayerDetectionFlagExpireInterval`

```lua
PhysicsDetection.PlayerDetectionFlagExpireInterval : number
```

The interval (in seconds) at which the player(who is currently flagged by the physics detection)'s flag expires.

!!!note
    It is recommended to have this value set to a number lower than or equal to `4` to reduce the chance of false positives.

### `PhysicsDetection.LeewayMultiplier`

```lua
PhysicsDetection.LeewayMultiplier : number
```

The multiplier for the leeway, used internally by Octagon when calculating the max physics threshold.

!!!note
    It is recommended to have this value set to a number greater than or equal to `2.5` to reduce the chance of false positives.

### `PhysicsDetection.Enabled`

```lua
PhysicsDetection.Enabled : boolean
```

A boolean indicating if this detection should run or not.

---

## NonPhysics

By default, Octagon comes with the following non physics detections:

- MultiToolEquip
- PrimaryPartDeletion

## How do they work?

!!!note
    Non physics detections do not flag the player as non physics detections are mostly caused by glitches / bugs by the engine. 

#### **MultiToolEquip**

This detection by default, tracks the equipped tools for the player, and if the number of equipped tools exceed higher than the limit `MaxEquippedToolCount` (which is `1` as a constant), then the **extra equipped tools** will be parented back to the player's backpack.

#### **PrimaryPartDeletion**

This detection by default, tracks the primary part (HumanoidRootPart) of the player's character, and if the primary part  is deleted (by the client or through some other method), then the player's character will be loadd again and the player will flagged for primary part deletion.

!!!tip
    The server can safely delete the primary part of the player **only** through [Instance:Destroy](https://developer.roblox.com/en-us/api-reference/function/Instance/Destroy) and the detection will not reload the player's character.


**Sneak peak** of a non physics detection:
```lua
-- SilentsReplacement
-- MultiToolEquip
-- July 26, 2021

--[[
    MultiToolEquip.Enabled : boolean
    
	MultiToolEquip.Init() --> nil []
    MultiToolEquip.Start(playerProfile : PlayerProfile) --> nil []
    MultiToolEquip.Cleanup() --> nil []
]]

local MultiToolEquip = {
	Enabled = true,
}
...
```

Each non physics detection by default, comes with a predefined set of members which you can toggle for your own game's need:

### `NonPhysicsDetection.Enabled`
```lua
NonPhysicsDetection.Enabled : boolean
```

A boolean indicating if the non physics detection should run or not.