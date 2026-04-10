-- OpenMacMouseFix
-- Hammerspoon config that maps mouse buttons to macOS actions.
--
-- Repo: ~/Documents/GitHub/OpenMacMouseFix
-- Enable/disable at runtime with the on.sh / off.sh scripts.
--
-- =============================================================
-- CONFIG — edit this table to remap mouse buttons
-- =============================================================
-- Button numbers (macOS convention):
--   0 = left click      (DO NOT remap — you'll lose your Mac)
--   1 = right click
--   2 = middle click
--   3 = back button (mouse 4)
--   4 = forward button (mouse 5)
--   5+ = extra buttons on fancy mice
--
-- Available actions (see the `actions` table below for the full list):
--   "mission_control", "app_expose", "show_desktop", "launchpad",
--   "notification_center", "spotlight", "next_space", "prev_space",
--   "cmd_tab", "quick_note", "lock_screen"
--
-- You can also write a Lua function inline, e.g.:
--   [2] = function() hs.application.launchOrFocus("Safari") end,
local bindings = {
  [2] = "mission_control",   -- middle click -> Mission Control
  -- [3] = "app_expose",     -- back button  -> App Exposé
  -- [4] = "show_desktop",   -- forward btn  -> Show Desktop
}

-- =============================================================
-- Action implementations
-- =============================================================
local actions = {
  mission_control     = function() hs.spaces.toggleMissionControl() end,
  app_expose          = function() hs.spaces.toggleAppExpose() end,
  show_desktop        = function() hs.spaces.toggleShowDesktop() end,
  launchpad           = function() hs.spaces.toggleLaunchPad() end,
  notification_center = function() hs.eventtap.keyStroke({"fn"}, "n") end,
  spotlight           = function() hs.eventtap.keyStroke({"cmd"}, "space") end,
  next_space          = function() hs.eventtap.keyStroke({"ctrl"}, "right") end,
  prev_space          = function() hs.eventtap.keyStroke({"ctrl"}, "left") end,
  cmd_tab             = function() hs.eventtap.keyStroke({"cmd"}, "tab") end,
  quick_note          = function() hs.eventtap.keyStroke({"fn", "cmd"}, "q") end,
  lock_screen         = function() hs.caffeinate.lockScreen() end,
}

-- =============================================================
-- Event tap — intercepts mouse-down for any bound button
-- =============================================================
local function resolve(binding)
  if type(binding) == "function" then return binding end
  return actions[binding]
end

local tap = hs.eventtap.new(
  { hs.eventtap.event.types.otherMouseDown },
  function(e)
    local btn = e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
    local b = bindings[btn]
    if not b then return false end
    local fn = resolve(b)
    if not fn then
      hs.alert.show("mmtmc: unknown action for button " .. btn)
      return false
    end
    fn()
    return true  -- swallow the click so apps don't see it
  end
)

-- =============================================================
-- Persistent on/off state (controlled by scripts/on.sh, off.sh)
-- =============================================================
local flagFile = os.getenv("HOME") .. "/.hammerspoon/.mmtmc_enabled"

local function isEnabled()
  local f = io.open(flagFile, "r")
  if f then f:close(); return true end
  return false
end

-- =============================================================
-- Menu bar toggle
-- =============================================================
local menuIcon = hs.menubar.new()

local function updateMenu()
  if tap:isEnabled() then
    menuIcon:setTitle("🖱 ON")
  else
    menuIcon:setTitle("🖱 OFF")
  end
end

local function setFlagFile(enabled)
  if enabled then
    local f = io.open(flagFile, "w")
    if f then f:close() end
  else
    os.remove(flagFile)
  end
end

-- Expose a tiny module so the CLI can flip state without a full reload
mmtmc = {
  tap = tap,
  start = function()
    tap:start()
    setFlagFile(true)
    updateMenu()
    hs.alert.show("Mouse mapping: ON")
  end,
  stop = function()
    tap:stop()
    setFlagFile(false)
    updateMenu()
    hs.alert.show("Mouse mapping: OFF")
  end,
  toggle = function()
    if tap:isEnabled() then mmtmc.stop() else mmtmc.start() end
  end,
}

menuIcon:setClickCallback(function() mmtmc.toggle() end)

-- Launch at login + expose `hs` CLI so on.sh / off.sh can reach us
hs.autoLaunch(true)
require("hs.ipc")
hs.ipc.cliInstall()

if isEnabled() then
  tap:start()
  print("mmtmc: enabled at startup")
else
  print("mmtmc: disabled at startup")
end
updateMenu()
