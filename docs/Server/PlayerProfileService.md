# PlayerProfileService

The PlayerProfileService module provides methods to access player profiles easily.

!!!note
    This section does not include additional methods / members which are used by Octagon internally. It only includes the necessary information only.

### `PlayerProfileService.LoadedPlayerProfiles`

```lua
PlayerProfileService.LoadedPlayerProfiles : table
```

A dictionary of all loaded player profiles.

### `PlayerProfileService.GetPlayerProfile()`

```lua
PlayerProfileService.GetPlayerProfile(player : Player) --> PlayerProfile | nil []
```

Returns the player profile of `player`.

!!!note
    - This method may temporarily yield the thread if the profile isn't initialized yet or not loaded in time.

    - This method will return `nil` if `player` is black listed from being monitored by Octagon.

    - This method will return `nil` if all detections are disabled.

### `PlayerProfileService.ArePlayerProfilesLoaded()`

```lua
PlayerProfileService.ArePlayerProfilesLoaded() --> boolean [ArePlayerProfilesLoaded]
```

Returns a boolean indicating if player profiles have been loaded.