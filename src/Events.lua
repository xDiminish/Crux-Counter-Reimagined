-- -----------------------------------------------------------------------------
-- Events.lua
-- -----------------------------------------------------------------------------

local EM    = EVENT_MANAGER
local CC    = CruxCounterR
local M     = {}

local ARCANIST_CLASS_ID = 117
local knownArcanistLines = {
    ["Herald of the Tome"] = true,
    ["Soldier of Apocrypha"] = true,
    ["Curative Runeforms"] = true,
}

local wasArcanist = nil

-- local flashToggle = false
local flashPeriod = 0.5 -- seconds for full pulse cycle (fade in + fade out)

--- @type integer Crux ability ID
M.abilityId = 184220

--- UI element update logic based on Crux duration warning state.
--- Called by `UpdateWarnState()` to apply warn color changes to:
--- - Runes (crux)
--- - Background ring texture
--- - Number (aura stack count)
local elementHandlers = {
    --- Handles Crux rune coloring.
    --- @param elapsedSec number Seconds since last Crux gain
    --- @param baseSettings table The settings table containing color and threshold config
    runes = function(elapsedSec, baseSettings)
        for _, rune in ipairs(CC.Display.runes or {}) do
            if rune then
                CC.Utils.CheckWarnState(elapsedSec, baseSettings, "runes", function(color)
                    rune:SetColor(color)
                end)
            end
        end
    end,

    --- Handles ring (background) coloring.
    --- @param elapsedSec number Seconds since last Crux gain
    --- @param baseSettings table The settings table containing color and threshold config
    background = function(elapsedSec, baseSettings)
        local ring = CC.Display.ring
        if ring then
            CC.Utils.CheckWarnState(elapsedSec, baseSettings, "background", function(color)
                ring:SetColor(color)
            end)
        end
    end,

    --- Handles number (Crux count text) coloring.
    --- Resets to base color if Crux count is 0.
    --- @param elapsedSec number Seconds since last Crux gain
    --- @param baseSettings table The settings table containing color and threshold config
    number = function(elapsedSec, baseSettings)
        local stackCount = CC.State and CC.State.stacks or 0
        if stackCount == 0 then
            local baseColor = CC.UI:GetEnsuredColor(baseSettings.elements.number.color)
            CruxCounterR_Display:SetNumberColor(baseColor)
        else
            CC.Utils.CheckWarnState(elapsedSec, baseSettings, "number", function(color)
                CruxCounterR_Display:SetNumberColor(color)
            end)
        end
    end,
}

--- Build namespace for events
--- @param event string Name of the event
--- @return string namespace Addon-specific event namespace
local function getEventNamespace(event)
    return CC.Addon.name .. event
end

--- Handles effect changes for a specific ability and manages visual updates.
--- Tracks the remaining time of the buff, updates Crux stack state, and starts/stops a timer for UI warnings.
---
--- @see EVENT_EFFECT_CHANGED
--- @param eventCode integer Event identifier (unused)
--- @param changeType integer Type of effect change (e.g., EFFECT_RESULT_GAINED, EFFECT_RESULT_FADED)
--- @param effectSlot integer Slot ID for the effect (unused)
--- @param effectName string Localized name of the effect (unused)
--- @param unitTag string Unit the effect was applied to (e.g., "player", "reticleover")
--- @param beginTime number Game time in seconds when the effect began
--- @param endTime number Game time in seconds when the effect is expected to end
--- @param stackCount integer Number of Crux stacks (1 to 3 typically)
--- @param iconName string Icon path for the effect (unused)
--- @param buffType integer Type of buff (unused)
--- @param effectType integer Type of effect (unused)
--- @param abilityType integer Type of ability (unused)
--- @param statusEffectType integer Type of status effect (unused)
--- @param abilityId integer Unique identifier for the ability applied
--- @return nil
local function onEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, abilityId)
    -- Debug
    local args = { CC.Debug:PrintSafe(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime, stackCount, iconName, buffType, effectType, abilityType, statusEffectType, abilityId) }
    local output =
        "eventCode: "           .. args[1]  ..
        ", changeType: "        .. args[2]  ..
        ", effectSlot: "        .. args[3]  ..
        ", effectName: "        .. args[4]  ..
        ", unitTag: "           .. args[5]  ..
        ", beginTime: "         .. args[6]  ..
        ", endTime: "           .. args[7]  ..
        ", stackCount: "        .. args[8]  ..
        ", iconName: "          .. args[9]  ..
        ", buffType: "          .. args[10] ..
        ", effectType: "        .. args[11] ..
        ", abilityType: "       .. args[12] ..
        ", statusEffectType: "  .. args[13] ..
        ", abilityId: "         .. args[14]

    CC.Debug:Trace(2, output)

    -- Check if the crux buff has ended
    if changeType == EFFECT_RESULT_FADED then
        CC.State:ClearStacks()

        CC.Global.WarnState = false
        
        EVENT_MANAGER:UnregisterForUpdate("CruxTracker_Countdown")
        return
    end

    CC.State:SetStacks(stackCount)

    if endTime and endTime > 0 then
        local baseSettings        = CC.settings or {}
        local reimaginedSettings  = baseSettings.reimagined or {}
        local pollingInterval     = (reimaginedSettings.expireWarning and reimaginedSettings.expireWarning.pollingInterval) or 200

        EVENT_MANAGER:UnregisterForUpdate("CruxTracker_Countdown")
        EVENT_MANAGER:RegisterForUpdate("CruxTracker_Countdown", pollingInterval, function()
            local now = GetGameTimeMilliseconds()
            local endTimeMs = endTime * 1000
            local remainingMs = endTimeMs - now

            if remainingMs <= 0 then
                CC.State:ClearStacks()
                CC.Global.WarnState = false
                EVENT_MANAGER:UnregisterForUpdate("CruxTracker_Countdown")
                return
            end

            local lastGainMs = CC.State.lastCruxGainTime
            if not lastGainMs then return end

            local elapsedSec = (now - lastGainMs) / 1000
            local cruxCount = CC.State:GetCruxCount()

            if cruxCount == 0 then
                CC.Global.WarnState = false
                return
            end

            local baseSettings = CC.settings or {}

            -- Use the updated Utils function call here:
            CC.Utils.UpdateCruxVisuals(elapsedSec, baseSettings)
        end)
    end
end

--- Update combat state
--- @param inCombat boolean Whether or not the player is in combat
--- @return nil
local function onCombatChanged(_, inCombat)
    CC.State:SetInCombat(inCombat)
    M:UpdateVisibility()  -- unified visibility update
end

--- Respond to player life/death/zone/load changes.
--- Note: Sound playback skipped for these stack transitions
--- @return nil
local function onPlayerChanged()
    pcall(function()
        M:ReevaluateVisibility()
        M:UpdateCombatState()

        local numBuffs = GetNumBuffs("player")
        for i = 1, numBuffs do
            local success, result = pcall(GetUnitBuffInfo, "player", i)
            if success and type(result) == "table" then
                local _, _, _, _, stackCount, _, _, _, _, _, abilityId = unpack(result)
                if abilityId == M.abilityId then
                    local safeStacks = tonumber(stackCount) or 0
                    CC.State:SetStacks(safeStacks --[[@as integer]], false)
                    return
                end
            end
        end

        -- No Crux buff found
        CC.State:SetStacks(0, false)
    end)
end

-- When stack count increases, save start time
function M:OnStackGained(index)
    CC.State.stackStartTimes[index] = GetGameTimeMilliseconds()
end

--- Check if the player is an Arcanist via class or skill lines
--- @return boolean
function M:IsArcanist()
    CC.Debug:Trace(1, "IsArcanist() called")

    if GetUnitClassId("player") == ARCANIST_CLASS_ID then
        CC.Debug:Trace(2, "Detected Arcanist class.")

        return true
    end

    for skillType = 1, GetNumSkillTypes() do
        for lineIndex = 1, GetNumSkillLines(skillType) do
            local success, name, _, discovered = pcall(GetSkillLineInfo, skillType, lineIndex)
            if success and discovered then
                CC.Debug:Trace(2, "Discovered skill line: <<1>>", name)

                if knownArcanistLines[name] then
                    CC.Debug:Trace(2, "Matched known Arcanist skill line: <<1>>", name)

                    return true
                end
            end
        end
    end

    CC.Debug:Trace(2, "Not an Arcanist class and no known Arcanist skill lines found.")

    return false
end

--- Update addon visibility
--- @return nil
function M:UpdateVisibility()
    local isArcanist        = self:IsArcanist()
    local hideOutOfCombat   = CC.Settings:Get("hideOutOfCombat")
    local inCombat          = CC.State:IsInCombat()
    local shouldShow        = isArcanist and (not hideOutOfCombat or inCombat)

    if CruxCounterR_Display and CruxCounterR_Display.SetVisible then
        CruxCounterR_Display:SetVisible(shouldShow)
    else
        CC.Debug:Trace(1, "ERROR: CruxCounterR_Display or SetVisible is nil")
    end
end

--- Evaluate whether the addon should be visible based on Arcanist status
--- @return nil
function M:ReevaluateVisibility()
    CC.Debug:Trace(1, "ReevaluateVisibility() called")
    CC.Debug:Trace(2, "CruxCounterR_Display = <<1>>", tostring(CruxCounterR_Display))

    if CruxCounterR_Display then
        CC.Debug:Trace(2, "CruxCounterR_Display.SetVisible = <<1>>", tostring(CruxCounterR_Display.SetVisible))
    else
        CC.Debug:Trace(2, "CruxCounterR_Display is nil")
    end

    local isNowArcanist = self:IsArcanist()

    CC.Debug:Trace(2, "wasArcanist: <<1>>, isNowArcanist: <<2>>", tostring(wasArcanist), tostring(isNowArcanist))
    CC.Debug:Trace(2, "IsArcanist? <<1>>", tostring(isNowArcanist))

    if CruxCounterR_Display and CruxCounterR_Display.SetVisible then
        CruxCounterR_Display:SetVisible(isNowArcanist)
    else
        CC.Debug:Trace(1, "CruxCounterR_Display or SetVisible method is nil, skipping SetVisible call")
    end

    if wasArcanist == nil then
        wasArcanist = isNowArcanist
        return
    end

    if isNowArcanist and not wasArcanist then
        self:RegisterForCombat()
        onPlayerChanged()
    elseif not isNowArcanist and wasArcanist then
        self:UnregisterForCombat()
        CC.State:ClearStacks()
    end

    wasArcanist = isNowArcanist
end

--- Update combat state with current value
--- @return nil
function M:UpdateCombatState()
    onCombatChanged(nil, IsUnitInCombat("player") --[[@as boolean]])
end

--- Wrap EVENT_MANAGER:RegisterForEvent function
--- @param namespace string Unique event namespace
--- @param event any Event to filter
--- @param callbackFunc function Execute function on event trigger
--- @return nil
function M:Listen(namespace, event, callbackFunc)
    EM:RegisterForEvent(getEventNamespace(namespace), event, callbackFunc)
end

--- Wrap EVENT_MANAGER:UnregisterForEvent function
--- @param namespace string Unique event namespace
--- @param event any Event to filter
--- @return nil
function M:Unlisten(namespace, event)
    EM:UnregisterForEvent(getEventNamespace(namespace), event)
end

--- Wrap EVENT_MANAGER:AddFilterForEvent function
--- @param namespace string Unique event namespace
--- @param event any Event to filter
--- @param filterType integer Type of filter
--- @param filterValue any Value to filter
--- @param ... any Additional filters
--- @return nil
function M:AddFilter(namespace, event, filterType, filterValue, ...)
    EM:AddFilterForEvent(getEventNamespace(namespace), event, filterType, filterValue, ...)
end

--- Register to receive combat state transitions
--- @return nil
function M:RegisterForCombat()
    self:UpdateCombatState()
    self:Listen("CombatState", EVENT_PLAYER_COMBAT_STATE, onCombatChanged)
end

--- Unregister listening for combat state transitions
--- @return nil
function M:UnregisterForCombat()
    self:Unlisten("CombatState", EVENT_PLAYER_COMBAT_STATE)
    self:UpdateCombatState()
end

--- Registers event manager events.
--- @return nil
function M:RegisterEvents()
    CC.Debug:Trace(2, "Registering events...")

    -- Ability updates
    self:Listen("EffectChanged", EVENT_EFFECT_CHANGED, function(eventCode, ...)
        return onEffectChanged(eventCode, ...)
    end)

    self:AddFilter(
        "EffectChanged",
        EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_ABILITY_ID, self.abilityId,
        REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER
    )
 
    -- Life or death
    self:Listen("PlayerDead", EVENT_PLAYER_DEAD, onPlayerChanged)
    self:Listen("PlayerAlive", EVENT_PLAYER_ALIVE, onPlayerChanged)

    -- Zone change or load
    self:Listen("PlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        onPlayerChanged()
        M:ReevaluateVisibility()
    end)

    self:Listen("ZoneUpdated", EVENT_ZONE_UPDATE, onPlayerChanged)

    -- Skill line and subclass changes to reevaluate visibility
    self:Listen("SkillLineUpdated", EVENT_SKILL_LINE_UPDATED, function()
        zo_callLater(function()
            M:ReevaluateVisibility()
        end, 500)
    end)

    self:Listen("SubclassChanged", EVENT_SUBCLASS_CHANGED, function()
        zo_callLater(function()
            M:ReevaluateVisibility()
        end, 500)
    end)

    self:Listen("SkillLineAdded", EVENT_SKILL_LINE_ADDED, function(_, skillType, lineIndex, isNew)
        local name = GetSkillLineInfo(skillType, lineIndex)

        CC.Debug:Trace(2, "Skill line added: <<1>>", name)

        zo_callLater(function()
            M:ReevaluateVisibility()
        end, 500)
    end)

    -- Combat state
    if CC.Settings:Get("hideOutOfCombat") then
        self:RegisterForCombat()
    end
end

CC.Events = M