# PlayerProfile

A player profile in layman's terms, is simply a table which contains necessary data for Octagon and the developer to work with. 

!!!warning
    When a player's profile is destroyed internally, i.e whenever they leave the game, most of the members will be not accessible and only some methods will be calleable on the profile.

    Here is the list of the methods / members safe to access even if the profile is destroyed:

    - [PlayerProfile.PhysicsDetectionFlagCount](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofilephysicsdetectionflagcount)
    - [PlayerProfile:IsDestroyed()](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofileisdestroyed)

!!!note
    To retrieve a player profile, only use [PlayerProfileService.GetPlayerProfile()](https://silentsreplacement.github.io/Octagon/Server/PlayerProfileService/#playerprofileservicegetplayerprofile).

### `PlayerProfile.IsPlayerProfile()`

```lua
PlayerProfile.IsPlayerProfile(self : any) --> boolean [IsPlayerProfile]
```

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `self : any` | Any value |

Returns a boolean indicating if `self` is a player profile or not.

---

### **`Only accessible from an object created by the PlayerProfile.new:`**

!!!warning
    Never cleanup any maids or signals, this is done by Octagon automatically whenever the profile associated to a player leaves. Doing so will cause a lot of errors and break a lot of functionality!

### `PlayerProfile.Player`

```lua
PlayerProfile.Player : Player
```

A reference to the player who owns the profile.

### `PlayerProfile.Maid`

```lua
PlayerProfile.Maid : Maid
```

A reference to a maid object, used for cleaning up signals.

### `PlayerProfile.DetectionMaid`

```lua
PlayerProfile.DetectionMaid : Maid
```

A reference to a maid object, used for cleaning up signals regarding non physics detections.

### `PlayerProfile.PhysicsDetectionFlagsHistory`

```lua
PlayerProfile.PhysicsDetectionFlagsHistory : table
```

An array of physics detection flags accumulated by the player who owns this profile.

### `PlayerProfile.PhysicsDetectionFlagCount`

```lua
PlayerProfile.PhysicsDetectionFlagCount : number
```

The number of physics detection flags accumulated by the player who owns this profile.

### `PlayerProfile.OnPhysicsDetectionFlag`

```lua
PlayerProfile.OnPhysicsDetectionFlag : Signal (detectionFlag : string)
```

A signal which is fired whenever the player is flagged by a detection through [PlayerProfile:RegisterPhysicsDetectionFlag](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofileregisterphysicsdetectionflag). 

```lua
PlayerProfile.OnPhysicsDetectionFlag:Connect(function(flag) 
    warn(("%s was flagged for %s"):format(PlayerProfile.Player, flag)) 
end) 
```

| Parameters      | Description                          |
| ----------- | ------------------------------------ |
| `flag : string` | The flag by the detection (for e.g `HighHorizontalSpeed`, `HighVerticalSpeed`) |

### `PlayerProfile.OnPhysicsDetectionFlagExpire`

```lua
PlayerProfile.OnPhysicsDetectionFlagExpire : Signal (expiredFlag : string)
```

A signal which is fired whenever the player's flag by a physics detection is expired periodically. When this signal is fired, the physics detections by default, will give back the network ownership from the server to the player and return the player to a normal state.

```lua
PlayerProfile.OnPhysicsDetectionFlagExpire:Connect(function(expiredFlag) 
    warn(("%s's %s flag has been expired"):format(PlayerProfile.Player, expiredFlag)) 
end) 
```

| Parameters      | Description                          |
| ----------- | ------------------------------------ |
| `expiredFlag : string` | The now expired flag by the detection (for e.g `HighHorizontalSpeed`, `HighVerticalSpeed`) |

### `PlayerProfile:RegisterPhysicsDetectionFlag()`

```lua 
PlayerProfile:RegisterPhysicsDetectionFlag(detectionName : string, flag : string) --> nil []
```

Register a new flag, incrementing [PlayerProfile.PhysicsDetectionFlagCount](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofilephysicsdetectionflagcount) by 1 and adds `flag` to the player profile's physics detection history and fires [PlayerProfile.OnPhysicsDetectionFlag](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofileonphysicsdetectionflag) passing in `flag` as the argument.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `detectionName : string` | The exact name of the physics detection |
| `flag : string` | The flag by the detection, for e.g `HighHorizontalSpeed`, `HighVerticalSpeed`. |

### `PlayerProfile:IsDestroyed()`

```lua
PlayerProfile:IsDestroyed() --> boolean [IsDestroyed]
```

Returns a boolean indicating if the profile has been destroyed

### `PlayerProfile:IncrementPhysicsThreshold()`

```lua
PlayerProfile:IncrementPhysicsThreshold(physicsThreshold : string, thresholdIncrement : number) --> nil []
```

Increments the threshold for `physicsThreshold` by `thresholdIncrement`. Useful for managing player specific thresholds in different scenarios and can greatly reduce false positives if implemented correctly.

```lua
-- Assuming HorizontalSpeed detection is enabled:

humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	profile:DecrementPhysicsThreshold("HorizontalSpeed", profile:GetPhysicsThresholdIncrement("HorizontalSpeed"))
	profile:IncrementPhysicsThreshold("HorizontalSpeed", math.sqrt(humanoid.WalkSpeed ) * 2)
end)
```

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `physicsThreshold : string` | A value which can be either `VerticalSpeed` or `HorizontalSpeed`  |
| `thresholdIncrement : number` | The value to increment the threshold by |

!!!warning
    This method will throw an error if the detection it self for `physicsThreshold` doesn't exist or isn't enabled.

### `PlayerProfile:DecrementPhysicsThreshold()`

```lua
PlayerProfile:DecrementPhysicsThreshold(physicsThreshold : string, thresholdDecrement : number) --> nil []
```

Decrements the threshold for `physicsThreshold` by `thresholdDecrement`. 

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `physicsThreshold : string` | A value which can be either `VerticalSpeed` or `HorizontalSpeed` (if the detections for them are enabled) |
| `thresholdIncrement : number` | The value to decrement the threshold by |

!!!warning
    This method will throw an error if the detection it self for `physicsThreshold` doesn't exist or isn't enabled.

!!!note
    If decrementing physics threshold values such that they are to be a value <= `0`, they will be clamped to `0`.

    ```lua
    PlayerProfile:IncrementPhysicsThreshold("VerticalSpeed", 500)
    print(PlayerProfile:GetPhysicsThresholdIncrement("VerticalSpeed")) --> 500
    PlayerProfile:DecrementPhysicsThreshold("VerticalSpeed", 500)
    print(PlayerProfile:GetPhysicsThresholdIncrement("VerticalSpeed")) --> 0
    PlayerProfile:DecrementPhysicsThreshold("VerticalSpeed", 500)
    print(PlayerProfile:GetPhysicsThresholdIncrement("VerticalSpeed")) --> 0
    ```

### `PlayerProfile:GetPhysicsThresholdIncrement()`

```lua
PlayerProfile:GetPhysicsThresholdIncrement(physicsThreshold : string) --> number [thresholdIncrement]
```

Returns the threshold increment for `physicsThreshold`.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `physicsThreshold : string` | A value which can be either `VerticalSpeed` or `HorizontalSpeed` (if the detections for them are enabled) |

!!!note
    This method will return `nil` if the detection for `physicsThreshold` doesn't exist or isn't enabled.

### `PlayerProfile:GetCurrentActivePhysicsDetectionFlag()`

```lua
PlayerProfile:GetCurrentActivePhysicsDetectionFlag() --> string | nil [physicsDetectionFlag]
```

Returns the name of the physics detection whose flag has still not expired.