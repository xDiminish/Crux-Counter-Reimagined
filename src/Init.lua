-- -----------------------------------------------------------------------------
-- Init.lua
-- -----------------------------------------------------------------------------

local CC     = CruxCounterR
local EM     = EVENT_MANAGER

-- Initialize  global state container
CC.Global = CC.Global or {}

--- @type string Namespace for addon init event
local initNs = CC.Addon.name .. "_Init"

--- Unregister the addon
local function unregister()
    EM:UnregisterForEvent(initNs, EVENT_ADD_ON_LOADED)
end

--- Initialize the addon
local function init(_, addonName)
    CC.Debug:Trace(2, "EVENT_ADD_ON_LOADED fired for: <<1>>", tostring(addonName))

    if addonName ~= CC.Addon.name then return end

    unregister()

    CC.Language:Setup()
    CC.Settings:Setup()

    CC.settings = CC.Settings.settings

    CC.Debug:Trace(1, "CC.settings initialized: " .. tostring(CC.settings))

    -- Initialize the warn state flag
    CC.Global.WarnState = false
    
    CruxCounterR_Display:ApplySettings()

    -- Initialize rune display
    CC.Display:Initialize()

    -- Defer RegisterEvents until after player is in-world
    EM:RegisterForEvent("CruxCounterR_InitPlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        EM:UnregisterForEvent("CruxCounterR_InitPlayerActivated", EVENT_PLAYER_ACTIVATED)
        CC.Events:RegisterEvents()
    end)
end

-- Make the magic happen
EM:RegisterForEvent(initNs, EVENT_ADD_ON_LOADED, init)