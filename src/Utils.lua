-- -----------------------------------------------------------------------------
-- Utils.lua
-- -----------------------------------------------------------------------------

local CC = CruxCounterR

CC.Utils = {}

--- Shared logic to update color based on elapsed time and warn threshold
--- @param elapsedSec number Time since crux gain
--- @param baseSettings table Saved settings (with .reimagined subtable)
--- @param elementType string One of: "runes", "background", "number"
--- @param setColorFunc function Function that takes a ZO_ColorDef and applies it to the UI
function CC.Utils.CheckWarnState(elapsedSec, baseSettings, elementType, setColorFunc)
    if elapsedSec < 0 then elapsedSec = 0 end

    if not baseSettings then
        CC.Debug:Trace(3, "[CruxCounterR.Utils] ERROR: baseSettings is nil")

        return
    end

    local reimaginedSettings = baseSettings.reimagined or {}
    if not reimaginedSettings then
        CC.Debug:Trace(3, "[CruxCounterR.Utils] ERROR: reimaginedSettings is nil")

        return
    end

    local baseColorPath = {
        runes       = baseSettings.elements.runes.color,
        background  = baseSettings.elements.background.color,
        number      = baseSettings.elements.number.color,
    }

    local warnColorPath = {
        runes       = reimaginedSettings.expireWarning.elements.runes.color,
        background  = reimaginedSettings.expireWarning.elements.background.color,
        number      = reimaginedSettings.expireWarning.elements.number.color,
    }

    -- Flash colors: 2 colors per element for flashing
    local flashColorsPath       = reimaginedSettings.flash and reimaginedSettings.flash.elements or {}
    local flashElementColors    = flashColorsPath[elementType] or {}

    -- Helper to ensure color or fallback to white
    local function GetColorOrDefault(c, default)
        if c and type(c) == "table" and c.r and c.g and c.b then
            return c
        else
            return default
        end
    end

    local baseColor = CC.UI:GetEnsuredColor(baseColorPath[elementType])
    local warnColor = CC.UI:GetEnsuredColor(warnColorPath[elementType], ZO_ColorDef:New(1, 0, 0, 1))

    -- Flash color1 and color2
    local flashColor1 = GetColorOrDefault(flashElementColors.color1, ZO_ColorDef:New(1,1,1,1))
    local flashColor2 = GetColorOrDefault(flashElementColors.color2, ZO_ColorDef:New(0.5,0.5,0.5,1))

    local totalDurationSec              = reimaginedSettings.cruxDuration or 30
    local warningThresholdRemainingSec  = reimaginedSettings.expireWarning.threshold or 25
    local warningElapsedSec             = totalDurationSec - warningThresholdRemainingSec
    local epsilon                       = 0.1
    local inWarn                        = elapsedSec + epsilon >= warningElapsedSec - 1

    CC.Global.WarnState = inWarn

    local flashSettings     = reimaginedSettings.flash or {}
    local flashEnabled      = flashSettings.enabled
    local flashThreshold    = flashSettings.threshold or 5
    local flashSpeed        = flashSettings.speed or 2.0

    -- Only allow flashing if flash threshold <= warning threshold
    if flashThreshold > warningThresholdRemainingSec then
        flashThreshold = warningThresholdRemainingSec
    end

    local flashStartTime    = totalDurationSec - flashThreshold
    local inFlash           = flashEnabled and (elapsedSec + 1 >= flashStartTime)
    local finalColor        = baseColor

    CC.Debug:Trace(2, "flashThreshold: <<1>>, warningThresholdRemainingSec: <<2>>, inWarn: <<3>>, inFlash: <<4>>", flashThreshold, warningThresholdRemainingSec, tostring(inWarn), tostring(inFlash))

    if inFlash then
        -- Calculate flash interpolation t (0..1) based on sine wave
        local timeIntoFlash = elapsedSec - flashStartTime

        -- Use duration (in seconds per full flash cycle)
        -- local sineInterval  = flashSpeed or 2.0
        -- local sineValue     = math.sin((math.pi * 2) * (timeIntoFlash / sineInterval))
        local sineValue     = math.sin(timeIntoFlash * flashSpeed * 2 * math.pi)
        -- local sineValue     = math.sin(timeIntoFlash * flashSpeed * 2 * math.pi)
        local t             = (sineValue + 1) / 2  -- normalize to 0..1

        -- Linear interpolate colors
        finalColor = ZO_ColorDef:New(
            flashColor1.r + (flashColor2.r - flashColor1.r) * t,
            flashColor1.g + (flashColor2.g - flashColor1.g) * t,
            flashColor1.b + (flashColor2.b - flashColor1.b) * t,
            flashColor1.a + (flashColor2.a - flashColor1.a) * t
        )
    elseif inWarn then
        finalColor = warnColor
    else
        finalColor = baseColor
    end

    if setColorFunc and type(setColorFunc) == "function" then
        setColorFunc(finalColor)
    end

    CC.Debug:Trace(2, "Current Warn State: <<1>>, Flashing: <<2>>", CC.Global.WarnState, tostring(inFlash))

    return inWarn
end

--- Updates the visual appearance of Crux elements (runes, ring, number)
--- based on the current elapsed time and provided base settings.
--- Applies color transitions for each element if a warning state is active.
--- @param elapsedSec number Elapsed time in seconds since Crux buff started
--- @param baseSettings table The visual settings including warning color thresholds and base colors
function CC.Utils.UpdateCruxVisuals(elapsedSec, baseSettings)
    local function setRuneColor(color)
        for _, rune in ipairs(CC.Display.runes or {}) do
            if rune then rune:SetColor(color) end
        end
    end

    local function setBackgroundColor(color)
        if CC.Display.ring then CC.Display.ring:SetColor(color) end
    end

    local function setNumberColor(color)
        CruxCounterR_Display:SetNumberColor(color)
    end

    CC.Utils.CheckWarnState(elapsedSec, baseSettings, "runes", setRuneColor)
    CC.Utils.CheckWarnState(elapsedSec, baseSettings, "background", setBackgroundColor)
    CC.Utils.CheckWarnState(elapsedSec, baseSettings, "number", setNumberColor)
end

--- Linearly interpolates between two colors.
--- @param colorA ZO_ColorDef Starting color
--- @param colorB ZO_ColorDef Ending color
--- @param t number Interpolation factor (0.0 to 1.0)
--- @return ZO_ColorDef Interpolated color
function CC.Utils.LerpColor(colorA, colorB, t)
    local r = colorA.r + (colorB.r - colorA.r) * t
    local g = colorA.g + (colorB.g - colorA.g) * t
    local b = colorA.b + (colorB.b - colorA.b) * t
    local a = colorA.a + (colorB.a - colorA.a) * t

    return ZO_ColorDef:New(r, g, b, a)
end

--- Calculates a pulsing factor between 0 and 1 using a sine wave.
--- Useful for animating visual effects like flashing.
--- @param timeSec number Elapsed time in seconds
--- @param periodSec number Full period of the sine wave cycle in seconds
--- @return number Pulse factor between 0 and 1
function CC.Utils.GetPulseFactor(timeSec, periodSec)
    -- Sinusoidal pulse oscillates between 0 and 1
    -- (sin wave goes -1 to 1, so map to 0-1 by (sin+1)/2)
    local omega = (2 * math.pi) / periodSec
    local val   = (math.sin(omega * timeSec) + 1) / 2

    return val
end

--- Safely retrieves a nested value from a table using a variable number of keys.
--- Returns `nil` if any key along the path is missing or if a non-table is encountered.
---
--- Example:
--- local value = CC.Utils:DeepGet(settings, "reimagined", "flash", "threshold")
---
--- @param tbl table The root table to search within
--- @param ... any A sequence of keys representing the nested path
--- @return any The value found at the nested path, or nil if not found
function CC.Utils:DeepGet(tbl, ...)
    for _, key in ipairs({...}) do
        if type(tbl) ~= "table" then return nil end

        tbl = tbl[key]
    end

    return tbl
end

--- Deeply sets a value into a nested table structure.
--- @param tbl table Root table to write to
--- @param value any Value to set
--- @param ... string Keys to walk through (e.g., "flash", "elements", "runes")
function CC.Utils:DeepSet(tbl, value, ...)
    local keys      = {...}
    local lastKey   = table.remove(keys)

    for _, key in ipairs(keys) do
        if type(tbl[key]) ~= "table" then
            tbl[key] = {}
        end

        tbl = tbl[key]
    end

    tbl[lastKey] = value
end

--- Converts an {r,g,b,a} table to a ZO_ColorDef object.
--- @param tbl table Color as {r,g,b,a}
--- @return ZO_ColorDef
function CC.Utils:WrapColor(tbl)
    if type(tbl) == "table" and #tbl >= 3 then
        return ZO_ColorDef:New(tbl[1], tbl[2], tbl[3], tbl[4] or 1)
    end

    -- fallback to white if invalid
    return ZO_ColorDef:New(1, 1, 1, 1)
end

--- Converts an RGBA table (e.g., {1,1,1,1}) to a ZO_ColorDef object if needed.
--- If already a ZO_ColorDef, returns it as-is.
--- @param color table|ZO_ColorDef
--- @return ZO_ColorDef
function CC.Utils:ColorTableToZO(color)
    if type(color) == "table" and type(color.UnpackRGBA) ~= "function" then
        -- Assume plain RGBA table
        return ZO_ColorDef:New(unpack(color))
    end

    return color
end
