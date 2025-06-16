-- -----------------------------------------------------------------------------
-- Utils.lua
-- -----------------------------------------------------------------------------

local CC = CruxCounterR

CC.Utils = {}

CC.Global.PreviousWarnState = CC.Global.PreviousWarnState or {
    runes       = false,
    background  = false,
    number      = false,
}

--- Shared logic to update color based on elapsed time and warn threshold
--- @param elapsedSec number Time since crux gain
--- @param baseSettings table Saved settings (with .reimagined subtable)
--- @param elementType string One of: "runes", "background", "number"
--- @param setColorFunc function Function that takes a ZO_ColorDef and applies it to the UI
function CC.Utils.CheckWarnState(elapsedSec, baseSettings, elementType, setColorFunc, controlObj)
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
        runes      = baseSettings.elements.runes.color,
        background = baseSettings.elements.background.color,
        number     = baseSettings.elements.number.color,
    }

    local warnColorPath = {
        runes      = reimaginedSettings.expireWarning.elements.runes.color,
        background = reimaginedSettings.expireWarning.elements.background.color,
        number     = reimaginedSettings.expireWarning.elements.number.color,
    }

    local baseColor = CC.UI:GetEnsuredColor(baseColorPath[elementType])
    local warnColor = CC.UI:GetEnsuredColor(warnColorPath[elementType], ZO_ColorDef:New(1, 0, 0, 1))

    local totalDurationSec             = reimaginedSettings.cruxDuration or 30
    local warningThresholdRemainingSec = reimaginedSettings.expireWarning.threshold or 25
    local warningElapsedSec            = totalDurationSec - warningThresholdRemainingSec
    local epsilon                      = 0.1

    local inWarn = elapsedSec + epsilon >= warningElapsedSec - 1
    CC.Global.WarnState = inWarn

    if setColorFunc and type(setColorFunc) == "function" then
        setColorFunc(inWarn and warnColor or baseColor)

        -- Only trigger play/stop when the warn state *changes*
        local prevState = CC.Global.PreviousWarnState[elementType]
        
        if prevState ~= inWarn and controlObj and controlObj.PlayFlash then
            CC.Global.PreviousWarnState[elementType] = inWarn
        end
    end

    CC.Debug:Trace(2, "Current Warn State: <<1>>", CC.Global.WarnState)

    return inWarn
end


