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
    playSound               = (playSound ~= false) -- default true
    local previousStacks    = self.stacks
    self.stacks             = count

    local function isGainedOrRefreshed()
        if count > previousStacks then
            CC.Debug:Trace(1, "Crux Gained: <<1>> -> <<2>>", previousStacks, count)
            return true
        elseif count == previousStacks and count == self.maxStacks then
            CC.Debug:Trace(1, "Crux Refreshed at Max Stack: <<1>>", count)
            return true
        elseif count < previousStacks then
            CC.Debug:Trace(1, "Crux Lost: <<1>> -> <<2>>", previousStacks, count)
        end

        return false
    end

    local cruxGainedOrRefreshed = isGainedOrRefreshed()

    if cruxGainedOrRefreshed or (count == previousStacks and count > 0) then
        CC.State.lastCruxGainTime = GetGameTimeMilliseconds()
    end

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

function M:GetCruxCount()
    return self.stacks or 0
end

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
