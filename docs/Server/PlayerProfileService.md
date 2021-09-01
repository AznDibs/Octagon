# PlayerProfileService

The PlayerProfileService module provides methods to access player profiles easily.

!!!note
    This section does not include additional methods which are to be used by Octagon internally. It only includes the necessary information only.

### `PlayerProfileService.OnPlayerProfileLoaded`

```lua
PlayerProfileService.OnPlayerProfileLoaded : Signal  (playerProfile : PlayerProfile)
```

A signal which is fired whenever a new player profile is loaded.

```lua
PlayerProfileService.OnPlayerProfileLoaded:Connect(function(playerProfile)
    print(("%s's profile was loaded"):format(playerProfile.Player))
end
```

### `PlayerProfileService.OnPlayerProfileDestroyed`

```lua
PlayerProfileService.OnPlayerProfileDestroyed : Signal (player : Player)
```

A signal which is fired whenever a player profile is destroyed through [PlayerProfile:Destroy()](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofiledestroy).

```lua
PlayerProfileService.OnPlayerProfileDestroyed:Connect(function(player)
    print(("%s's profile was destroyed"):format(player))
end
```

### `PlayerProfileService.OnPlayerProfileInit`

```lua
PlayerProfileService.OnPlayerProfileInit : Signal (playerProfile : PlayerProfile)
```

A signal which is fired whenever a player's profile is init through [PlayerProfile:Init](https://silentsreplacement.github.io/Octagon/Server/PlayerProfile/#playerprofileinit).

### `PlayerProfileService.LoadedPlayerProfiles`

```lua
PlayerProfileService.LoadedPlayerProfiles : table
```

A dictionary of all loaded player profiles.

### `PlayerProfileService.GetPlayerProfile()`

```lua
PlayerProfileService.GetPlayerProfile(player : Player) --> PlayerProfile | nil []
```

Returns the player profile.

!!!note
    - This method may temporarily yield the thread if the profile isn't initialized yet or not loaded in time.

    - This method will return `nil` if `player` is black listed from being monitored by Octagon.

    - This method will return `nil` if all detections are disabled.

### `PlayerProfileService.ArePlayerProfilesLoaded()`

```lua
PlayerProfileService.ArePlayerProfilesLoaded() --> boolean [ArePlayerProfilesLoaded]
```

Returns a boolean indicating if player profiles have been loaded.