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

### `Octagon.BlacklistNoClipMonitoringPartsForPlayer()`
```lua
Octagon.BlacklistNoClipMonitoringPartsForPlayer(player : Player, parts : table) --> nil []
```

Iterates through `parts` and adds a noclip black listed tag for `player` to each instance found which will allow only `player` to pass
through those parts even if their property `CanCollide` isn't set to `false` on the server. This method is useful when you want to allow specific players to pass through collideable parts.

### `Octagon.UnBlacklistNoClipMonitoringPartsForPlayer()`
```lua
Server.UnBlacklistNoClipMonitoringPartsForPlayer(player : Player, parts : table) --> nil []
```

Iterates through `parts` and removes the noclip black listed tag for `player` from each instance found.

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
