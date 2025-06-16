-- -----------------------------------------------------------------------------
-- Interface.lua
-- -----------------------------------------------------------------------------

local CC = CruxCounterR
local M  = {}

CC.Display = M

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
    fallback = fallback or ZO_ColorDef:New(0.7176, 1, 0.4862, 1) -- default green

    local safeColor = self:EnsureColorDef(color)

    return safeColor or fallback
end

--- Applies a repeating color pattern to each character of the given text.
--- @param text string The text to colorize.
--- @param palette string[] A list of 6-character hex color codes (e.g. {"FF0000", "00FF00"}).
--- @return string The colorized text.
function M:ColorizeTextWithPalette(text, palette)
    if not palette or #palette == 0 then
        return text -- fallback to uncolored text if no palette provided
    end

    local colored = ""
    local count = #palette

    for i = 1, #text do
        local char = text:sub(i, i)
        local color = palette[((i - 1) % count) + 1]
        colored = colored .. "|c" .. color .. char .. "|r"
    end

    return colored
end

--- Wraps a string in rainbow colors using ColorizedText, or returns a fallback ZO_ColorDef.
--- @param color string The text to colorize.
--- @param fallback ZO_ColorDef|nil A fallback ZO_ColorDef if the operation fails.
--- @return string|ZO_ColorDef Colored text string or fallback color object.
function M:GetColorizeTextWithPalette(text, palette, fallback)
    fallback = fallback or ZO_NORMAL_TEXT -- default menu color fallback

    local safeColor = self:ColorizeTextWithPalette(text, palette)

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
        CC.Debug:Trace(3, "INITIALIZATION ERROR: baseSettings is nil")
        return
    end

    self.runes = {}

    local runeControls = {
        CruxCounterR_AuraControlOrbitCrux1,
        CruxCounterR_AuraControlOrbitCrux2,
        CruxCounterR_AuraControlOrbitCrux3,
    }

    -- Resolve color defs once using fallback-safe wrapper
    local runeColor     = CC.UI:GetEnsuredColor(baseSettings.elements.runes.color)
    local ringColor     = CC.UI:GetEnsuredColor(baseSettings.elements.background.color)
    local numberColor   = CC.UI:GetEnsuredColor(baseSettings.elements.number.color)

    -- Initialize rune controls
    for i, control in ipairs(runeControls) do
        if control then
            local rune      = CruxCounterR_Rune:New(control, i)
            self.runes[i]   = rune

            if rune and rune.SetColor then
                rune:SetColor(runeColor)
            else
                CC.Debug:Trace(2, string.format("Rune %d missing SetColor!", i))
            end
        else
            CC.Debug:Trace(2, string.format("Rune control %d is missing!", i))
        end
    end

    -- Initialize ring control
    local ringControl = WINDOW_MANAGER:GetControlByName("CruxCounterR_AuraControlBG")

    if ringControl then
        self.ring = CruxCounterR_Ring:New(ringControl)

        if self.ring.SetColor then
            self.ring:SetColor(ringColor)
        else
            CC.Debug:Trace(2, "Ring is missing SetColor!")
        end
    else
        CC.Debug:Trace(2, "Ring control is missing!")
    end

    -- Initialize number color
    if self.SetNumberColor then
        self:SetNumberColor(numberColor)
    else
        CC.Debug:Trace(2, "Display missing SetNumberColor method!")
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
    local baseSettings = CC.settings or {}

    for i, rune in ipairs(self.runes or {}) do
        if rune and rune.SetColor then
            local runeColor = CruxCounterR.UI:GetEnsuredColor(
                baseSettings.elements 
                and baseSettings.elements.runes 
                and baseSettings.elements.runes.color,
                ZO_ColorDef:New(0.7176, 1, 0.4862, 1) -- light green (fallback)
            )

            rune:SetColor(runeColor)
        else
            CC.Debug:Trace(2, "ResetRingColor: rune or SetColor is nil")
        end
    end
end

--- Resets the ring color to the default medium green color.
--- Calls `SetColor` on the ring control if available.
--- @return nil
function CC.Display:ResetRingColor()
    if self.ring and self.ring.SetColor then
        local baseSettings = CC.settings or {}

        -- Use color from base settings or fallback medium green color
        local color = CruxCounterR.UI:GetEnsuredColor(
            baseSettings.elements 
            and baseSettings.elements.background 
            and baseSettings.elements.background.color,
            ZO_ColorDef:New(0.6784, 0.9607, 0.4509, 1) -- medium green (fallback)
        )

        self.ring:SetColor(color)
    else
        CC.Debug:Trace(2, "ResetRingColor: ring or SetColor is nil")
    end
end

--- Resets the number color to the default base color from settings.
--- Calls `SetNumberColor` on the display if available.
--- @return nil
function CC.Display:ResetNumberColor()
    if CruxCounterR_Display and CruxCounterR_Display.SetNumberColor then
        local baseSettings      = CC.settings or {}
       
        local color = CruxCounterR.UI:GetEnsuredColor(
            baseSettings.elements 
            and baseSettings.elements.number 
            and baseSettings.elements.number.color, 
            ZO_ColorDef:New(0.7176, 1, 0.7764, 1)
        )

        CruxCounterR.PrintColor("Current Color", color)        
        CruxCounterR_Display:SetNumberColor(color)
    else
        CC.Debug:Trace(2, "[CC.Display:ResetNumberColor] ERROR: aura or SetNumberColor is nil")
    end
end

--- Updates a control's color based on time elapsed and threshold
--- @param elapsedSec number Elapsed time in seconds
--- @param baseSettings table The settings table
--- @param currentStacks number Current crux stack count
--- @param colorKey string Key inside `elements` (e.g., "runes", "number", "background")
--- @param setColorFunc function Function to apply the color (e.g., control:SetColor or aura:SetNumberColor)
function CC.Display:UpdateElementColor(elapsedSec, baseSettings, currentStacks, colorKey, setColorFunc)
    if elapsedSec < 0 then elapsedSec = 0 end
    if not baseSettings then return end

    local reimagined        = baseSettings.reimagined or {}
    local totalDurationSec  = reimagined.cruxDuration or 30
    local thresholdSec      = reimagined.expireWarning and reimagined.expireWarning.threshold or 25
    local warnElapsedSec    = totalDurationSec - thresholdSec
    local epsilon           = 0.1

    local baseColor = CruxCounterR.UI:GetEnsuredColor(baseSettings.elements[colorKey].color)
    local warnColor = CruxCounterR.UI:GetEnsuredColor(
        (reimagined.expireWarning.elements[colorKey] and reimagined.expireWarning.elements[colorKey].color),
        ZO_ColorDef:New(1, 0, 0, 1) -- default to red
    )

    if currentStacks == 0 then
        setColorFunc(baseColor)
        return
    end

    if elapsedSec + epsilon >= warnElapsedSec - 1 then
        setColorFunc(warnColor)
    else
        setColorFunc(baseColor)
    end
end

function CC.Display:StartFlashForAllRunes()
    local flashOutDuration = CC.Settings:getFlashOutDuration() * 1000
    local flashInDelay     = CC.Settings:getFlashInDelay() * 1000

    for _, rune in pairs(self.runes) do
        if rune:IsShowing() and rune.flashOutTimeline and rune.flashInTimeline then
            rune.flashOutTimeline:Stop()
            rune.flashInTimeline:Stop()

            -- Play flash-out immediately
            rune.flashOutTimeline:PlayFromStart()
            d("Playing flash-out for rune " .. rune.number)
        else
            d("Rune " .. tostring(rune.number) .. " not flashing (not visible or missing timeline)")
        end
    end

    CC.Global.isFlashing = true
    d("Flash: On (all runes)")

    zo_callLater(function()
        CC.Global.isFlashing = false
        d("Flash: Reset")
    end, flashOutDuration + flashInDelay + CC.Settings:getFlashInDuration() * 1000)
end

-- function CC.Display:ApplyFlashTimingToRunes()
--     local timing = CC.Settings:GetFlashTiming()
--     for _, rune in pairs(self.runes) do
--         rune:SetFlashTiming(timing.outDuration, timing.inDelay, timing.inDuration)
--     end
-- end

--- Reset all UI elements to their base color and stop any flashing animations.
--- This is called, for example, after a rune fades out or the Crux count is reset.
--- It waits briefly before applying rune color resets to allow other animations to settle.
--- @return nil
function M:ResetUI()
    local baseSettings = CC.settings
    if not baseSettings then return end

    -- Wait 500ms before applying color reset (gives other effects time to finish)
    zo_callLater(function()
        for _, rune in ipairs(CC.Display.runes or {}) do
            -- Reset the rune color to base color
            if rune and rune.SetColor then
                local baseColor = CruxCounterR.UI:GetEnsuredColor(baseSettings.elements.runes.color)
                rune:SetColor(baseColor)
            end
        end
    end, 500)

    -- Reset ring (background) color
    if CC.Display.ring and CC.Display.ring.SetColor then
        local baseColor = CruxCounterR.UI:GetEnsuredColor(baseSettings.elements.background.color)
        CC.Display.ring:SetColor(baseColor)
    end

    -- Reset number (aura) color
    if CruxCounterR_Display and CruxCounterR_Display.SetNumberColor then
        local baseColor = CruxCounterR.UI:GetEnsuredColor(baseSettings.elements.number.color)
        CruxCounterR_Display:SetNumberColor(baseColor)
    end
end

function CC.Display:ResetRunes()
    for _, rune in ipairs(self.runes or {}) do
        if rune and rune.Reset then
            rune:Reset()
        end
    end

    if self.ring and self.ring.Reset then
        self.ring:Reset()
    end

    -- If your aura/number also needs resetting:
    if self.aura and self.aura.Reset then
        self.aura:Reset()
    end
end



CC.UI = M