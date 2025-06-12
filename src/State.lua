-- -----------------------------------------------------------------------------
-- State.lua
-- -----------------------------------------------------------------------------

local M     = {}
local CC    = CruxCounterR

--- @type integer Current number of Crux stacks
M.stacks    = 0

--- @type integer Maximum number of stacks
M.maxStacks = 3

--- @type boolean True when the player is in combat
M.inCombat  = false

--- @type integer Time when the last Crux was gained
M.lastCruxGainTime = 0

-- -----------------------------------------------------------------------------
-- Stacks State
-- -----------------------------------------------------------------------------

--- Set the number of stacks to the given value
--- @param count integer Number of stacks
--- @param playSound boolean? Optional: True to evaluate sound playback logic, false to force not playing a sound
--- @return nil
function M:SetStacks(count, playSound)
    if playSound == nil then playSound = true end

    local previousStacks = self.stacks
    self.stacks = count

    -- Always check if a Crux was gained or refreshed
    local cruxGainedOrRefreshed = false

    if count > previousStacks then
        cruxGainedOrRefreshed = true
        CC.Debug:Trace(1, "Crux Gained: <<1>> -> <<2>>", previousStacks, count)
    elseif count == previousStacks and count == self.maxStacks then
        -- Special case: Already at 3, but a new Crux was generated and replaced the oldest
        cruxGainedOrRefreshed = true
        CC.Debug:Trace(1, "Crux Refreshed at Max Stack: <<1>>", count)
    elseif count < previousStacks then
        CC.Debug:Trace(1, "Crux Lost: <<1>> -> <<2>>", previousStacks, count)
    end

    if cruxGainedOrRefreshed then
        self.lastCruxGainTime = GetGameTimeMilliseconds()

        if CC.Display and CC.Display.ResetRuneColors then
            CC.Display:ResetRuneColors()
        end
    end

    -- Only update UI and play sounds if stack count actually changed
    if count ~= previousStacks then
        CC.Debug:Trace(2, "Updating Crux: <<1>> -> <<2>>", previousStacks, count)
        CruxCounterR_Display:UpdateCount(count)

        if playSound then
            local soundToPlay = nil
            if count < previousStacks then
                soundToPlay = "cruxLost"
            elseif count > previousStacks then
                soundToPlay = (count < self.maxStacks) and "cruxGained" or "maxCrux"
            end

            if soundToPlay then
                CC.UI:PlaySoundForType(soundToPlay)
            end
        end
    end
end
-- function M:SetStacks(count, playSound)
--     if playSound == nil then playSound = true end

--     local previousStacks = self.stacks
--     self.stacks = count

--     if count == previousStacks then
--         CC.Debug:Trace(2, "Crux Unchanged: <<1>> -> <<2>>", previousStacks, count)
--         return
--     end

--     CC.Debug:Trace(2, "Updating Crux: <<1>> -> <<2>>", previousStacks, count)
--     CruxCounterR_Display:UpdateCount(count)

--     local soundToPlay
--     if count < previousStacks then
--         CC.Debug:Trace(1, "Crux Lost: <<1>> -> <<2>>", previousStacks, count)
--         soundToPlay = "cruxLost"
--     elseif count >= previousStacks then
--         CC.Debug:Trace(1, "Crux Gained: <<1>> -> <<2>>", previousStacks, count)

--         -- Track last crux gained time
--         self.lastCruxGainTime = GetGameTimeMilliseconds()

--         -- Reset all rune colors to green on any Crux gain
--         if CC.Display and CC.Display.ResetRuneColors then
--             CC.Display:ResetRuneColors()
--         end

--         if count < self.maxStacks then
--             soundToPlay = "cruxGained"
--         else
--             soundToPlay = "maxCrux"
--         end
--     end

--     if playSound then
--         CC.UI:PlaySoundForType(soundToPlay)
--     end
-- end


--- Reset stack count to zero
--- @return nil
function M:ClearStacks()
    self:SetStacks(0)

    -- Reset last crux gained timer
    self.lastCruxGainTime = 0
end

-- -----------------------------------------------------------------------------
-- Combat State
-- -----------------------------------------------------------------------------

--- Set the combat state
--- @param inCombat boolean
--- @return nil
function M:SetInCombat(inCombat)
    self.inCombat = inCombat
end

--- Check if the player is currently in combat
--- @return boolean
function M:IsInCombat()
    return self.inCombat or false
end

CC.State = M
