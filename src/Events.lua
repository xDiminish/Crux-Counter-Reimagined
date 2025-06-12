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

--- @type integer Crux ability ID
M.abilityId = 184220

--- Build namespace for events
--- @param event string Name of the event
--- @return string namespace Addon-specific event namespace
local function getEventNamespace(event)
    return CC.Addon.name .. event
end

--- Respond to effect changes.
--- @see EVENT_EFFECT_CHANGED
--- @param changeType integer Type of effect change, see EffectResult enum for possible values
--- @param stackCount integer Number of stacks at the time of the event
--- @return nil
local function onEffectChanged(_, changeType, _, _, _, _, _, stackCount)
    if changeType == EFFECT_RESULT_FADED then
        CC.State:ClearStacks()
        return
    end

    CC.State:SetStacks(stackCount)
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

-- -----------------------------------------------------------------------------
-- Rune elapsed timer
-- -----------------------------------------------------------------------------
-- function M:PeriodicUpdate()
--     local currentTime = GetGameTimeMilliseconds()
--     local elapsed = currentTime - (CC.State.lastCruxGainTime or 0)
--     local warningThresholdMs = 25000
--     local isWarning = elapsed >= warningThresholdMs

--     d(string.format("CruxCounter PeriodicUpdate: elapsed=%d, isWarning=%s", elapsed, tostring(isWarning)))

--     if CC.Display and CC.Display.runes then
--         d("Rune count: " .. tostring(#CC.Display.runes))
--         for i, rune in ipairs(CC.Display.runes) do
--             if rune and rune.SetColor then
--                 d(string.format("Updating rune %d color to %s", i, isWarning and "red" or "green"))
--                 if isWarning then
--                     rune:SetColor(ZO_ColorDef:New(1, 0, 0, 1)) -- red
--                 else
--                     rune:SetColor(ZO_ColorDef:New(0.7176, 1, 0.4862, 1)) -- light green
--                 end
--             else
--                 d(string.format("Rune %d missing or has no SetColor!", i))
--             end
--         end
--     else
--         d("CC.Display.runes is nil or missing")
--     end

--     zo_callLater(function() self:PeriodicUpdate() end, 500)
-- end
-- function M:PeriodicUpdate()
--     local currentTime = GetGameTimeMilliseconds()
--     local lastGain = CC.State.lastCruxGainTime

--     if not lastGain then
--         -- Skip warning check if we haven't gained Crux yet
--         zo_callLater(function() self:PeriodicUpdate() end, 500)
--         return
--     end

--     local elapsed = currentTime - lastGain
--     local warningThresholdMs = 5000
--     local isWarning = elapsed >= warningThresholdMs

--     for i, rune in ipairs(CC.Display.runes or {}) do
--         if rune and rune.SetColor then
--             rune:SetColor(isWarning and ZO_ColorDef:New(1, 0, 0, 1) or ZO_ColorDef:New(0.7176, 1, 0.4862, 1)) -- default to light green
--         end
--     end

--     zo_callLater(function() self:PeriodicUpdate() end, 500)
-- end
function M:PeriodicUpdate()
    local currentTime = GetGameTimeMilliseconds()
    local lastGain = CC.State.lastCruxGainTime

    if not lastGain then
        zo_callLater(function() self:PeriodicUpdate() end, 500)
        return
    end

    local elapsedMs = currentTime - lastGain
    local elapsedSec = elapsedMs / 1000

    for _, rune in ipairs(CC.Display.runes or {}) do
        if rune and rune.UpdateColorBasedOnElapsed then
            rune:UpdateColorBasedOnElapsed(elapsedSec)
        end
    end

    zo_callLater(function() self:PeriodicUpdate() end, 500)
end



function M:StartPeriodicUpdate()
    self:PeriodicUpdate()
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
    local isArcanist = self:IsArcanist()
    local hideOutOfCombat = CC.Settings:Get("hideOutOfCombat")
    local inCombat = CC.State:IsInCombat()
    local shouldShow = isArcanist and (not hideOutOfCombat or inCombat)

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
    self:Listen("EffectChanged", EVENT_EFFECT_CHANGED, onEffectChanged)
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
    self:Listen("PlayerActivated", EVENT_PLAYER_ACTIVATED, onPlayerChanged)
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

    self:Listen("PlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        M.ReevaluateVisibility()
    end)

    -- Combat state
    if CC.Settings:Get("hideOutOfCombat") then
        self:RegisterForCombat()
    end
end

CC.Events = M