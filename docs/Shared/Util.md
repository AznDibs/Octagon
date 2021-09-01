# Util

The Util module is a simple module which provides methods associated to instances and players.

### `Util.GetPlayerEquippedTools()`

```lua
Util.GetPlayerEquippedTools(player : Player) --> table [equippedTools], number [equippedToolCount]
```

Returns an array of the tools equipped by the player, along with the number of tools equipped.

### `Util.HasBasePartFallenToVoid()`

```lua
Util.HasBasePartFallenToVoid(basePart : BasePart) --> boolean [HasBasePartFallenToVoid]
```

Returns a boolean indicating if `basePart` has fallen to void, i.e `basePart.Position.Y` equals or is lower than [Workspace.FallenPartsDestroyHeight](https://developer.roblox.com/en-us/api-reference/property/Workspace/FallenPartsDestroyHeight).

### `Util.IsBasePartFalling()`

```lua
Util.IsBasePartFalling(basePart : basePart, lastPosition : Vector3) --> boolean[IsBasePartFalling]
```

Returns a boolean indicating if `basePart` is falling, i.e `basePart.Position.Y` is lower than `lastPosition.Y`.

### `Util.IsInstanceDestroyed()`

```lua
 Util.IsInstanceDestroyed(instance : Instance) --> boolean[IsInstanceDestroyed]
```

Returns a boolean indicating if `instance` is destroyed, i.e via [Instance:Destroy()](https://developer.roblox.com/en-us/api-reference/function/Instance/Destroy).

### `Util.SetBasePartNetworkOwner()`

```lua
Util.SetBasePartNetworkOwner(basePart : BasePart, networkOwner : player | nil) --> nil []
```

Sets the network owner of `basePart` to `networkOwner`. 

!!!note
    This method will warn if the network ownership of `basePart` can't be set, along with the reason.

### `Util.GetBasePartNetworkOwner()`    

```lua
Util.GetBasePartNetworkOwner(basePart : BasePart) --> Player | nil [BasePartNetworkOwner]
```

Returns the network owner of `basePart`.

!!!note
    This method will return `nil` if `basePart` is anchored.

### `Util.IsPlayerWalking()`

```lua
Util.IsPlayerWalking(player : Player, lastPosition : Vector3) --> boolean [IsPlayerWalking]
```

Returns a boolean indicating if `player` is falling by comparing if `player.Character.PrimaryPart.Position.Y` is lower than `lastPosition.Y`.

!!!note
    This method will return `false` if `player`'s character isn't loaded.

### `Util.DoValidPlayerBodyPartsExist()`

```lua
Util.DoValidPlayerBodyPartsExist(player : Player) --> boolean [DoValidPlayerBodyPartsExist]
```

Returns a boolean indicating if `player` has the primary part and a humanoid inside their character.

!!!note
    This method will return `false` if `player`'s character isn't loaded.

### `Util.IsPlayerGameOwner()`

```lua
Util.IsPlayerGameOwner(player : Player) --> boolean [IsPlayerGameOwner]
```

Returns a boolean indicating if the player is the owner of the game or the owner of the group the game is in.

!!!note
    This method may temporarily yield the thread if the game is under a group as it will send an GET HTTP request to retrieve `player`'s rank in order to determine if `player` is the owner of that group.

### `Util.IsPlayerSubjectToBeMonitored()`
```lua
Util.IsPlayerSubjectToBeMonitored(player : Player) --> boolean [IsPlayerSubjectToBeMonitored]
```

Returns a boolean indicating if `player` is going to be monitored by Octagon.

!!!note
    This method may temporarily yield the thread as it checks to see if the player is black listed through the [Config](https://github.com/SilentsReplacement/Octagon/blob/main/src/Octagon/Server/Config.lua) module which may send an GET HTTP request to retrieve the player's rank.