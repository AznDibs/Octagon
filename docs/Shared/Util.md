# Util

The Util module is a simply module which provides a few basic instance methods associated to instances and players.

### `Util.GetPlayerEquippedTools()`

```lua
Util.GetPlayerEquippedTools(player : Player) --> table [equippedTools], number [equippedToolsCount]
```

Returns an array of the tools equipped by the player, along with the number of tools equipped.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `player : Player` | A Player object |

### `Util.HasBasePartFallenToVoid()`

```lua
Util.HasBasePartFallenToVoid(basePart : BasePart) --> boolean [HasBasePartFallenToVoid]
```

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `basePart : BasePart` | A BasePart object |

Returns a boolean indicating if `basePart` has fallen to void, i.e `basePart.Position.Y` equals or is lower than [Workspace.FallenPartsDestroyHeight](https://developer.roblox.com/en-us/api-reference/property/Workspace/FallenPartsDestroyHeight).

### `Util.IsBasePartFalling()`

```lua
Util.IsBasePartFalling(basePart : basePart, lastPosition : Vector3) --> boolean[IsBasePartFalling]
```

Returns a boolean indicating if `basePart` is falling, i.e `basePart.Position.Y` is lower than `lastPosition.Y`.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `basePart : BasePart` | A BasePart object |
| `lastPosition : Vector3` | A Vector3 object |

### `Util.IsInstanceDestroyed()`

```lua
 Util.IsInstanceDestroyed(instance : Instance, lastPosition : Vector3) --> boolean[IsInstanceDestroyed]
```

Returns a boolean indicating if `instance` is destroyed, i.e via [Instance:Destroy](https://developer.roblox.com/en-us/api-reference/function/Instance/Destroy).

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `instance : Instance` | An Instance |
| `lastPosition : Vector3` | A Vector3 object |

### `Util.SetBasePartNetworkOwner()`

```lua
Util.SetBasePartNetworkOwner(basePart : BasePart, networkOwner : player | nil) --> nil []
```

Sets the network owner of `basePart` to `networkOwner`. 

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `basePart : BasePart` | A BasePart object |
| `lastPosition : Vector3` | A Vector3 object |

!!!note
    This method will warn if the network ownership of `basePart` can't be set, along with the reason.

### `Util.GetBasePartNetworkOwner()`    

```lua
Util.GetBasePartNetworkOwner(basePart : BasePart) --> Player | nil [BasePartNetworkOwner]
```

Returns the network owner of `basePart`.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `basePart : BasePart` | A BasePart object |

!!!note
    This method will return `nil` if `basePart` is anchored.

### `Util.IsPlayerWalking()`

```lua
Util.IsPlayerWalking(player : Player, lastPosition : Vector3) --> boolean [IsPlayerWalking]
```

Returns a boolean indicating if `player` is falling by comparing if `player.Character.PrimaryPart.Position.Y` is lower than `lastPosition.Y`.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `player : Player` | A Player object |
| `lastPosition : Vector3` | A Vector3 object |

!!!note
    This method will return `false` if `player`'s character isn't loaded.

### `Util.DoValidPlayerBodyPartsExist()`

```lua
Util.DoValidPlayerBodyPartsExist(player : Player) --> boolean [DoValidPlayerBodyPartsExist]
```

Returns a boolean indicating if `player` has the primary part and a humanoid inside their character.

| Arguments      | Description                          |
| ----------- | ------------------------------------ |
| `player : Player` | A Player object |

!!!note
    This method will return `false` if `player`'s character isn't loaded.