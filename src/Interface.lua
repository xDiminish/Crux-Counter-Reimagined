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

--- Ensures the given color is a ZO_ColorDef instance.
--- If `color` is already a ZO_ColorDef, it is returned as-is.
--- If `color` is a table with color components, creates a new ZO_ColorDef.
--- Returns nil if `color` is nil or not a recognized format.
---
--- @param color table|ZO_ColorDef|nil Color as a ZO_ColorDef or table with r,g,b,a or indexed components
--- @return ZO_ColorDef|nil The resulting ZO_ColorDef object or nil if input invalid
function M:EnsureColorDef(color)
    if not color then return nil end
    if color.UnpackRGBA then
        return color  -- already ZO_ColorDef
    elseif type(color) == "table" then
        -- Create a ZO_ColorDef from table fields, defaulting missing channels to 1 or 0
        return ZO_ColorDef:New(
            color.r or color[1] or 1,
            color.g or color[2] or 1,
            color.b or color[3] or 1,
            color.a or color[4] or 1
        )
    else
        return nil
    end
end

--- Returns a valid ZO_ColorDef, falling back to a default if needed.
--- @param color table|ZO_ColorDef|nil
--- @param fallback ZO_ColorDef|nil Optional fallback color if color is invalid or nil
--- @return ZO_ColorDef
function M:GetEnsuredColor(color, fallback)
    fallback = fallback or ZO_ColorDef:New(0.7176, 1, 0.4862, 1) -- your default green
    local safeColor = self:EnsureColorDef(color)
    return safeColor or fallback
end

--- Initializes the display elements for CruxCounter, including runes and the ring, 
--- setting their colors based on current settings. Loads rune controls from global UI 
--- elements, creates CruxCounterR_Rune instances, and initializes the ring control as 
--- CruxCounterR_Ring. Logs errors if base settings or controls are missing.
--- @return nil
function CC.Display:Initialize()
    local baseSettings = CC.settings
    if not baseSettings then
        CC.Debug:Trace(3, "[Crux Counter Reimagined] INITIALIZATION ERROR: baseSettings is nil")
        return
    end

    self.runes = {}

    local runeControls = {
        CruxCounterR_AuraControlOrbitCrux1,
        CruxCounterR_AuraControlOrbitCrux2,
        CruxCounterR_AuraControlOrbitCrux3,
    }

    -- Resolve color defs once using fallback-safe wrapper
    local runeColor = CC.UI:GetEnsuredColor(baseSettings.elements.runes.color)
    local ringColor = CC.UI:GetEnsuredColor(baseSettings.elements.background.color)

    -- Initialize rune controls
    for i, control in ipairs(runeControls) do
        if control then
            local rune = CruxCounterR_Rune:New(control, i)
            self.runes[i] = rune

            if rune and rune.SetColor then
                rune:SetColor(runeColor)
            else
                CC.Debug:Trace(2, string.format("[Crux Counter Reimagined] Rune %d missing SetColor!", i))
            end
        else
            CC.Debug:Trace(2, string.format("[Crux Counter Reimagined] Rune control %d is missing!", i))
        end
    end

    -- Initialize ring control
    local ringControl = WINDOW_MANAGER:GetControlByName("CruxCounterR_AuraControlBG")
    if ringControl then
        self.ring = CruxCounterR_Ring:New(ringControl)
        if self.ring.SetColor then
            self.ring:SetColor(ringColor)
        else
            CC.Debug:Trace(2, "[Crux Counter Reimagined] Ring is missing SetColor!")
        end
    else
        CC.Debug:Trace(2, "[Crux Counter Reimagined] Ring control is missing!")
    end
end

--- Returns the rune object at the specified index.
--- @param index number The 1-based index of the rune to retrieve.
--- @return CruxCounterR_Rune|nil The rune object at the given index, or nil if none exists.
function CC.Display:GetRune(index)
    return self.runes[index]
end

--- Resets the color of all runes to the default light green color.
--- Calls `SetColor` on each rune if available.
--- @return nil
function CC.Display:ResetRuneColors()
    for i, rune in ipairs(self.runes or {}) do
        if rune and rune.SetColor then
            rune:SetColor(ZO_ColorDef:New(0.7176, 1, 0.4862, 1)) -- light green
        end
    end
end

--- Resets the ring color to the default medium green color.
--- Calls `SetColor` on the ring control if available.
--- @return nil
function CC.Display:ResetRingColor()
    if self.ring and self.ring.SetColor then
        self.ring:SetColor(ZO_ColorDef:New(0.6784, 0.9607,0.4509, 1)) -- medium green
    end
end

CC.UI = M
