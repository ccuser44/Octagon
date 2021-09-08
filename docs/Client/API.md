# API

!!!warning
    Never edit the source of Octagon or any of it's modules. Octagon is a module not supposed to have it's source code interrupted.

## Octagon

### `Octagon.OnPlayerHardGroundLand`

```lua
Octagon.OnPlayerHardGroundLand : Signal ()
```

A signal which is fired whenever the player lands on a ground in a "hard way" such that they are likely to bounce back. 

!!!tip
    Octagon by default will stop the player from bouncing high up. It is recommended not to
    alter that behavoiur through this signal.

### `Octagon.Start()`

```lua 
Octagon.Start() --> nil []
```

Starts checking the humanoid state of the client for fling detections.

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

### `Octagon.Stop()`

```lua
Octagon.Stop() --> nil []
```

Cleans up all maids in use.

### `Octagon.AllowPlayerBouncing()`

```lua
Octagon.AllowPlayerBouncing() --> nil []
```

Allows the local player to bounce high up after falling. By default, Octagon will not allow the player to bounce high up in the air after jumping.

### `Octagon.PreventPlayerBouncing()`

```lua
Octagon.PreventPlayerBouncing() --> nil []
```

Stops the local player from bouncing high up after falling.