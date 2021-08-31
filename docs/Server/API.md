# API

!!!warning
    Never edit the source of Octagon or any of it's modules. Octagon is a module not supposed to have it's source code interrupted.

!!!note
    Octagon will not monitor players whose profiles were cleaned up / not loaded.

## Octagon

### `Octagon.MonitoringPlayerProfiles` 

```lua
Octagon.MonitoringPlayerProfiles : table  
```

An dictionary of all player profiles being monitored by Octagon.

### `Octagon.BlacklistedPlayers` 

```lua
Octagon.BlacklistedPlayers : table  
```

An array of all players blacklisted from being monitored by Octagon.

### `Octagon.Start()`
```lua
Octagon.Start() --> nil []
```

Starts up Octagon and starts monitoring players who aren't black listed from being monitored.

### `Octagon.Stop()`

```lua
Octagon.Stop() --> nil []
```

Cleans up all maids in use, destroys all loaded player profiles and stops monitoring players.

### `Octagon.IsStarted()`

```lua
Octagon.IsStarted() --> boolean [IsStarted]
```

Returns a boolean indicating if Octagon is started.

### `Octagon.IsStopped()`

```lua
Octagon.IsStopped() --> boolean [IsStopped]
```

Returns a boolean indicating if Octagon is stopped.

### `Octagon.IsPlayerGameOwner()`

```lua
Octagon.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
```

Returns a boolean indicating if the player is the owner of the game or the owner of the group the game is in.

!!!note
    This method may temporarily yield the thread if the game is under a group as it will send an GET HTTP request to retrieve `player`'s rank in order to determine if `player` is the owner of that group.

### `Octagon.BlacklistNoClipMonitoringParts()`
```lua
Octagon.BlacklistNoClipMonitoringParts(parts : table) --> nil []
```

Iterates through `parts` and adds a noclip black listed tag which will allow players to pass
through those parts even if they aren't `CanCollide` `true` on the server.

!!!note
    This method ignores parts that aren't BaseParts.

### `Octagon.UnBlacklistNoClipMonitoringParts()`
```lua
Octagon.UnBlacklistNoClipMonitoringParts(parts : table) --> nil []
```

Iterates through `parts` and removes the noclip black listed tag.

!!!note
    This method ignores parts that aren't BaseParts.

### `Octagon.TemporarilyBlacklistPlayerFromBeingMonitored()`

```lua
Octagon.TemporarilyBlacklistPlayerFromBeingMonitored(
    player : Player,
    value : number | RBXScriptSignal | function
) --> nil []
```

Temporarily black lists the player from being monitored by Octagon.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `player : Player` | The player to temporarily black list from being monitored |
| `value : number`       | The number of seconds before the player will be monitored again by Octagon |
| `value : function`       | The function to be called and done executed before the player will be monitored again by Octagon. |
| `value : RBXScriptSignal | Signal`    | A signal (which contains a `Wait` method) or a RBXScriptSignal, whose `Wait` method will be called and done completing before the player will be monitored again by Octagon |


### `Octagon.IsPlayerSubjectToBeMonitored()`
```lua
Server.IsPlayerSubjectToBeMonitored(player : Player) --> boolean [IsPlayerSubjectToBeMonitored]
```

Returns a boolean indicating if `player` is going to be monitored by Octagon.

!!!note
    This method may temporarily yield the thread as it checks to see if the player is black listed through the [Config](https://github.com/SilentsReplacement/Octagon/blob/v0.1/src/Octagon/Server/Config.lua) module which may send an GET HTTP request to retrieve the player's rank.