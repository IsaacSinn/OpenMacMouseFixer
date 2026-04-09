# CLAUDE.md

Notes for Claude Code when working in this repo.

## What this project is

A tiny Hammerspoon-based tool that remaps macOS mouse buttons to system actions. The headline feature is middle-click → Mission Control, but the `bindings` table in `hammerspoon/init.lua` makes any button → any action trivial to configure.

It is intentionally small: **one Lua config + two shell scripts**. Resist the urge to add a build system, package manager, tests, or abstractions. If a change can't be explained in one sentence in the README, it's probably too much.

## Layout

```
hammerspoon/init.lua   ← source of truth for the mapping logic
scripts/on.sh          ← enable + persist across reboots
scripts/off.sh         ← disable + persist across reboots
README.md              ← user-facing docs
```

The *live* config that Hammerspoon actually runs lives at `~/.hammerspoon/init.lua`. The copy in `hammerspoon/init.lua` is the version-controlled source. When editing, keep them in sync — simplest flow is edit the repo copy, then `cp hammerspoon/init.lua ~/.hammerspoon/init.lua` and click Hammerspoon menu-bar → Reload Config (or run `scripts/on.sh` again).

## How the on/off persistence works

There are two layers of "on":

1. **Hammerspoon itself auto-launches** at login via `hs.autoLaunch(true)` in `init.lua`.
2. **The event tap** is started only if a flag file exists at `~/.hammerspoon/.mmtmc_enabled`.

`on.sh` creates the flag file and tells the running Hammerspoon to start the tap (`hs -c "mmtmc.start()"`). `off.sh` deletes the flag file and calls `mmtmc.stop()`. Because the flag file lives on disk, the state survives reboots: after login, `init.lua` reads it and either starts or doesn't start the tap.

The `hs` CLI is the bridge between shell scripts and the running Hammerspoon process. It's installed by `hs.ipc.cliInstall()` in `init.lua`, which runs the first time Hammerspoon launches with our config.

## The event tap

`init.lua` listens on `otherMouseDown` (middle + side buttons — **not** left or right click, those are their own event types). It reads `mouseEventButtonNumber` and looks the button up in the `bindings` table. If a binding exists, it runs the action and returns `true` to swallow the click so the app underneath doesn't see it. If no binding exists, it returns `false` and the click passes through normally.

Important: **never bind button 0 (left click)**. The event tap would swallow every left click and the machine becomes unusable. Button 0 wouldn't even hit this code path today (it's a `leftMouseDown`, not `otherMouseDown`), but if anyone widens the event types watched, add a guard.

## Gotchas

- **Accessibility permission** is required. Without it, `hs.eventtap.new` returns an object that silently does nothing. If debugging "my click does nothing", this is almost always the cause.
- **`hs.spaces.toggleMissionControl()`** is the clean API call. Don't replace it with `hs.eventtap.keyStroke({}, "f3")` unless there's a specific reason — the keystroke approach breaks when the user has rebound F3.
- **Reloading config** via `hs.reload()` re-runs `init.lua` from scratch. That's safe here; the old event tap gets garbage collected.
- **The `hs` CLI** only works while Hammerspoon is running. The scripts handle this by `open -g -a Hammerspoon` then polling briefly.

## Editing bindings

The `bindings` table at the top of `init.lua` is the only thing most users should ever touch. Values can be either a string (name of an entry in the `actions` table) or a raw Lua function. When adding a new built-in action, add it to the `actions` table *and* list it in the README's "Built-in actions" table — those two need to stay in sync.

## What not to do

- Don't add a LaunchAgent / launchd plist. Hammerspoon's own auto-launch covers it and is one less moving part.
- Don't rewrite in Swift "for performance". A single event tap on mouse-down has no measurable overhead and Lua is why this config is 100 lines instead of 1000.
- Don't hard-code paths with `/Users/isaac`. Everything should use `$HOME` or `os.getenv("HOME")`.
- Don't silently widen the event-type list beyond `otherMouseDown` without reviewing the left-click safety note above.
