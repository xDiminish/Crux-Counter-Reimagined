-- -----------------------------------------------------------------------------
-- Init.lua
-- -----------------------------------------------------------------------------

local CC     = CruxCounterV2
local EM     = EVENT_MANAGER

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
    CruxCounterV2_Display:ApplySettings()

    -- Defer RegisterEvents until after player is in-world
    EM:RegisterForEvent("CruxCounterV2_InitPlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        EM:UnregisterForEvent("CruxCounterV2_InitPlayerActivated", EVENT_PLAYER_ACTIVATED)
        CC.Events:RegisterEvents()
    end)
end

-- Make the magic happen
EM:RegisterForEvent(initNs, EVENT_ADD_ON_LOADED, init)