# API

!!!warning
    Never edit the source of Octagon or any of it's modules. Octagon is a module not supposed to have it's source code interrupted.

## Octagon

### `Octagon.OnPlayerFling`
```lua
Octagon.OnPlayerFling : Signal ()
```

A signal which is fired whenever the player is flinged (when hit by a fast moving object). 

### `Octagon.OnPlayerHardGroundLand`
```lua
Octagon.OnPlayerHardGroundLand : Signal ()
```

A signal which is fired whenever the player lands on a ground in a "hard way" such that they are likely to bounce back. 

### `Octagon.Start()`
```lua 
Octagon.Start() --> nil []
```

Starts checking the humanoid state of the client for fling detections.

### `Octagon.IsStarted()`

```lua
Octagon.IsStarted() --> boolean [IsStarted]
```

Returns a boolean indicating if Octagon is started through [Octagon.Start()](https://silentsreplacement.github.io/Octagon/Client/API/#octagonstart).

### `Octagon.IsStopped()`

```lua
Octagon.IsStopped() --> boolean [IsStopped]
```

Returns a boolean indicating if Octagon is stopped through [Octagon.Stop()](https://silentsreplacement.github.io/Octagon/Client/API/#octagonstop).

### `Octagon.Stop()`

```lua
Octagon.Stop() --> nil []
```

Cleans up all maids in use.