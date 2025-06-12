-- -----------------------------------------------------------------------------
-- Interface.lua
-- -----------------------------------------------------------------------------

local CC = CruxCounterR
local M  = {}

CC.Display = {}

--- Play a sound at a specific volume
--- @param sound string Name of the sound
--- @param volume number Playback volume from 0-100%
--- @return nil
function M:PlaySound(sound, volume)
    CC.Debug:Trace(3, "Playing sound <<1>> at volume <<2>>", sound, volume)

    --- Use variable for loop purposes only
    --- @diagnostic disable:unused-local
    for i = 0, volume, 10 do
        PlaySound(SOUNDS[sound])
    end
end

--- Play the sound for the given playback condition
--- @param type string Playback event type
--- @return nil
function M:PlaySoundForType(type)
    if CC.Settings:GetSoundEnabled(type) then
        local sound, volume = CC.Settings:GetSoundForType(type)
        self:PlaySound(sound, volume)
    end
end

function CC.Display:Initialize()
    self.runes = {}

    local runeControls = {
        CruxCounterR_AuraControlOrbitCrux1,
        CruxCounterR_AuraControlOrbitCrux2,
        CruxCounterR_AuraControlOrbitCrux3,
    }

    for i, control in ipairs(runeControls) do
        if control then
            local rune = CruxCounterR_Rune:New(control, i)
            rune:SetColor(ZO_ColorDef:New(0.7176, 1, 0.4862, 1)) -- set default to light green
            self.runes[i] = rune
        else
            d(string.format("CruxCounterR: Rune control %d is missing!", i))
        end
    end
end

function CC.Display:GetRune(index)
    return self.runes[index]
end

function CC.Display:ResetRuneColors()
    for i, rune in ipairs(self.runes or {}) do
        if rune and rune.SetColor then
            rune:SetColor(ZO_ColorDef:New(0.7176, 1, 0.4862, 1)) -- light green
        end
    end
end

CC.UI = M
