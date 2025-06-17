-- -----------------------------------------------------------------------------
-- Settings.lua
-- -----------------------------------------------------------------------------

local CC                    = CruxCounterR
local LAM                   = LibAddonMenu2
local M                     = {}
local gameSounds            = SOUNDS
local sounds                = {}
local rotationSpeedFactor   = 24000

-- Colors
local veryLightGreen  = ZO_ColorDef:New(0.7176, 1.0, 0.7765, 1)    -- B7FFC6
local lightGreen      = ZO_ColorDef:New(0.7176, 1.0, 0.4863, 1)    -- B7FF7C
local mediumGreen     = ZO_ColorDef:New(0.6784, 0.9608, 0.4510, 1) -- ADF573
local white           = ZO_ColorDef:New(1, 1, 1, 1)                -- FFFFFF
local red             = ZO_ColorDef:New(1, 0.2, 0.2, 1)            -- FF3333
local orange          = ZO_ColorDef:New(0.98, 0.58, 0.02, 1)       -- FA9405
local brightRed       = ZO_ColorDef:New(0.96, 0.04, 0.25, 1)       -- F50A41
local mintGreen       = ZO_ColorDef:New(0.0353, 0.7373, 0.5647, 1) -- 09BD90
local brightMagenta   = ZO_ColorDef:New(0.98, 0.02, 0.388, 1)      -- FA0563
local darkMagenta     = ZO_ColorDef:New(0.5, 0.0, 0.25, 1)         -- ~#800040
local darkRed         = ZO_ColorDef:New(0.4, 0.1, 0.1, 1)          -- ~#661A1A
local gray            = ZO_ColorDef:New(0.5, 0.5, 0.5, 1)          -- #808080

-- Defaults/Settings Storage
M.settings       = {}
M.dbVersion      = 0
M.savedVariables = "CruxCounterReimaginedData"
M.defaults = {
    -------------------------------------------------------------------
    -- Position of the UI element on screen
    -------------------------------------------------------------------
    top             = 0,                                                -- Vertical position (Y-axis)
    left            = 0,                                                -- Horizontal position (X-axis)

    -- General display settings
    hideOutOfCombat = false,                                            -- Whether to hide the display when not in combat
    locked          = false,                                            -- Whether the UI is locked in place
    lockToReticle   = false,                                            -- Whether to follow the reticle position
    size            = 128,                                              -- Size of the main display in pixels
    -------------------------------------------------------------------
    -- Appearance and behavior settings for UI elements
    -------------------------------------------------------------------
    elements = {
        number = {
            enabled = true,                                             -- Show the numeric counter
            color   = veryLightGreen,                                   -- Color of the numeric counter
        },
        runes = {
            enabled        = true,                                      -- Show the orbiting runes
            rotate         = true,                                      -- Animate rune rotation
            rotationSpeed  = 9600,                                      -- Rotation speed in units (degrees per second * 100)
            color          = lightGreen                                 -- Color of the runes
        },
        background = {
            enabled        = true,                                      -- Show the background ring
            rotate         = true,                                      -- Animate background rotation
            hideZeroStacks = false,                                     -- Hide when there are zero Crux stacks
            color          = mediumGreen                                -- Color of the background ring
        },
    },
    -------------------------------------------------------------------
    -- Sound effect settings for Crux state changes
    -------------------------------------------------------------------
    sounds = {
        cruxGained = {
            enabled = false,                                            -- Play a sound when gaining a Crux
            name    = "ENCHANTING_POTENCY_RUNE_PLACED",                 -- Sound name from ESO sound library
            volume  = 20,                                               -- Playback volume (0-100)
        },
        cruxLost = {
            enabled = false,                                            -- Play a sound when losing a Crux
            name    = "ENCHANTING_WEAPON_GLYPH_REMOVED",
            volume  = 20,
        },
        maxCrux = {
            enabled = true,                                             -- Play a sound when reaching max Crux
            name    = "DEATH_RECAP_KILLING_BLOW_SHOWN",
            volume  = 20,
        },
    },
    -------------------------------------------------------------------
    -- Settings specific to the reimagined style mode
    -------------------------------------------------------------------
    reimagined = {
        cruxDuration = 30,                                              -- Duration (in seconds) a Crux buff lasts
        runeSpinAnimation = true,                                       -- Whether runes spin when displayed

        -- Expiration warning feature
        expireWarning = {
            threshold       = 10,                                       -- Seconds remaining before triggering a visual warning
            pollingInterval = 200,                                      -- How often (in ms) to check for expiration
            enabled         = true,                                     -- Enable expiration warning effects

            elements = {
                number = {
                    color = brightRed,                                  -- Warning color for numeric counter
                },
                runes = {
                    color = brightMagenta,                              -- Warning color for runes
                },
                background = {
                    color = white,                                      -- Warning color for background ring
                }
            }
        },
        -------------------------------------------------------------------
        -- Flashing effect settings before expiration
        -------------------------------------------------------------------
        flash = {
            enabled   = false,                                          -- Global toggle for flash feature
            threshold = 5,                                              -- Seconds before expiration to start flashing (must be ≤ threshold in expireWarning)
            speed     = 2,                                              -- Flashing speed (Hz = flashes per second)

            elements = {
                runes = {
                    color1 = brightMagenta,                             -- First flash color for runes
                    color2 = darkMagenta,                               -- Second flash color for runes
                },
                background = {
                    color1 = white,                                     -- First flash color for background
                    color2 = gray,                                      -- Second flash color for background
                },
                number = {
                    color1 = brightRed,                                 -- First flash color for number
                    color2 = darkRed,                                   -- Second flash color for number
                },
            }
        }
    }
}


--- Save counter position
--- @param top number Top position
--- @param left number Left position
--- @return nil
function M:SavePosition(top, left)
    CC.Debug:Trace(2, "Saving position <<1>> x <<2>>", top, left)

    self.settings.top   = top
    self.settings.left  = left
end

--- Get the sound settings for a given condition type
--- @param type string Condition type
--- @return string sound The sound name
--- @return number volume The sound volume
function M:GetSoundForType(type)
    local sound     = self.settings.sounds[type].name
    local volume    = self.settings.sounds[type].volume

    return sound, volume
end

-- -----------------------------------------------------------------------------
-- Settings Panel Data
-- -----------------------------------------------------------------------------
--- @type table Options data
local optionsData               = {}
CruxCounterR_LockButton         = nil
CruxCounterR_MoveToCenterButton = nil

-- -----------------------------------------------------------------------------
-- Display
-- -----------------------------------------------------------------------------
--- Move the counter to the center of the screen
--- @return nil
local function moveToCenter()
    CruxCounterR_Display:Unhide()
    CruxCounterR_Display:MoveToCenter()
    M:SavePosition(0, 0)
end

--- Set the locked state of the counter
--- @param isLocked boolean True to lock the counter
--- @return nil
local function setLocked(isLocked)
    M.settings.locked = isLocked
    CruxCounterR_Display:SetMovable(not isLocked)
end

--- Get the locked state of the counter
--- @return boolean isLocked True when the counter is locked
local function getLocked()
    return M.settings.locked
end

--- Get the lock to reticle state
--- @return boolean isLocked True when counter is locked to the reticle
local function getLockToReticle()
    return M.settings.lockToReticle
end

--- Get the translated locked/unlocked string
--- @return string buttonText Translated Lock/Unlock text
local function getLockUnlockButtonText()
    if getLocked() or getLockToReticle() then
        return CC.Language:GetString("SETTINGS_UNLOCK")
    else
        return CC.Language:GetString("SETTINGS_LOCK")
    end
end

--- Get the translated lock tooltip based on if lock to reticle is enabled
--- @return string tooltipText Translated lock button tooltip or lock to reticle warning
local function getLockUnlockTooltipText()
    if getLockToReticle() then
        return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE_WARNING")
    else
        return CC.Language:GetString("SETTINGS_LOCK_DESC")
    end
end

--- Get the translated move to center tooltip based on if lock to reticle is enabled
--- @return string tooltipText Translated move to center button tooltip or lock to reticle warning
local function getMoveToCenterTooltipText()
    if getLockToReticle() then
        return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE_WARNING")
    else
        return CC.Language:GetString("SETTINGS_MOVE_TO_CENTER_DESC")
    end
end

--- Toggle locked state of the counter
--- @param control any Lock/Unlock button control
--- @return nil
local function toggleLocked(control)
    setLocked(not getLocked())
    control:SetText(getLockUnlockButtonText())
end

--- Set if the counter is locked to the reticle
--- @param state boolean True to lock to reticle
--- @return nil
local function setLockToReticle(state)
    if state then
        moveToCenter()
    else
        CruxCounterR_Display:SetPosition(M.settings.top, M.settings.left)
    end

    setLocked(state)
    M.settings.lockToReticle = state

    CruxCounterR_LockButton.button.data = { tooltipText = LAM.util.GetStringFromValue(getLockUnlockTooltipText()) }
    CruxCounterR_MoveToCenterButton.button.data = { tooltipText = LAM.util.GetStringFromValue(getMoveToCenterTooltipText()) }
    CruxCounterR_LockButton.button:SetText(getLockUnlockButtonText())
end

--- Set the lock to reticle state
--- @param hide boolean Set true to lock the counter to the reticle
--- @return nil
local function setHideOutOfCombat(hide)
    M.settings.hideOutOfCombat = hide

    if hide then
        CC.Events:RegisterForCombat()
    else
        CC.Events:UnregisterForCombat()
    end
end

--- Get the option to hide out of combat
--- @return boolean
local function getHideOutOfCombat()
    return M.settings.hideOutOfCombat
end

--- Set the counter display size
--- @param value number
--- @return nil
local function setSize(value)
    M.settings.size = value
    CruxCounterR_Display:SetSize(value)
end

--- Get the counter display size
--- @return number size Counter display size
local function getSize()
    return M.settings.size
end

--- @type table Options for Display settings
local displayOptions = {
    {
        -------------------------------------------------------------------
        -- Display
        -------------------------------------------------------------------
        type = "header",
        name = function() 
            local colorPalette = {"72b007"}

            return CruxCounterR.UI:GetColorizeTextWithPalette(
                CC.Language:GetString("SETTINGS_DISPLAY_HEADER"),
                colorPalette
            )
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Lock/Unlock
        -------------------------------------------------------------------
        type = "button",
        name = getLockUnlockButtonText,
        tooltip = getLockUnlockTooltipText,
        disabled = getLockToReticle,
        func = toggleLocked,
        width = "half",
        reference = "CruxCounterR_LockButton"
    },
    {
        -------------------------------------------------------------------
        -- Move to Center
        -------------------------------------------------------------------
        type = "button",
        name = function() return CC.Language:GetString("SETTINGS_MOVE_TO_CENTER") end,
        tooltip = getMoveToCenterTooltipText,
        disabled = getLockToReticle,
        func = moveToCenter,
        width = "half",
        reference = "CruxCounterR_MoveToCenterButton",
    },
    {
        -------------------------------------------------------------------
        -- Lock to Reticle
        -------------------------------------------------------------------
        type = "checkbox",
        name = function() return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE") end,
        tooltip = function() return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE_DESC") end,
        getFunc = getLockToReticle,
        setFunc = setLockToReticle,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Hide out of Combat
        -------------------------------------------------------------------
        type = "checkbox",
        name = function() return CC.Language:GetString("SETTINGS_HIDE_OUT_OF_COMBAT") end,
        tooltip = function() return CC.Language:GetString("SETTINGS_HIDE_OUT_OF_COMBAT_DESC") end,
        getFunc = getHideOutOfCombat,
        setFunc = setHideOutOfCombat,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Size
        -------------------------------------------------------------------
        type = "slider",
        name = function() return CC.Language:GetString("SETTINGS_SIZE") end,
        tooltip = function() return CC.Language:GetString("SETTINGS_SIZE_DESC") end,
        min = 16,
        max = 512,
        step = 16,
        default = M.defaults.size,
        getFunc = getSize,
        setFunc = setSize,
        width = "full",
    },
}

-- -----------------------------------------------------------------------------
-- Style
-- -----------------------------------------------------------------------------
--- Set if a UI element is shown/enabled
--- @param element string Name of the element
--- @param enabled boolean True to enable the element
--- @return nil
local function setElementEnabled(element, enabled)
    if element == "background" then
        CruxCounterR_Display.ring:SetEnabled(enabled)
        CruxCounterR_Display.ring:SetRotationEnabled(M:GetElement("background").rotate)
    elseif element == "runes" then
        CruxCounterR_Display.orbit:SetEnabled(enabled)
        CruxCounterR_Display.orbit:SetRotationEnabled(M:GetElement("runes").rotate)
    elseif element == "number" then
        CruxCounterR_Display:SetNumberEnabled(enabled)
    else
        CC.Debug:Trace(0, "Invalid element '<<1>>' specified for element display setting", element)
        return
    end

    M.settings.elements[element].enabled = enabled
end

--- Get if a UI element is shown/enabled
--- @param element string Name of the element
--- @return boolean enabled True when the element is enabled
--- @return nil
local function getElementEnabled(element)
    return M.settings.elements[element].enabled
end

--- Set if an element plays a rotation animation
--- @param element string Name of the element
--- @param rotate boolean True to rotate the element
--- @return nil
local function setElementRotate(element, rotate)
    if element == "background" then
        CruxCounterR_Display.ring:SetRotationEnabled(rotate)
    elseif element == "runes" then
        CruxCounterR_Display.orbit:SetRotationEnabled(rotate)
    else
        CC.Debug:Trace(0, "Invalid element '<<1>>' specified for rotation setting", element)
        return
    end

    M.settings.elements[element].rotate = rotate
end

--- Get if an element plays a rotation animation
--- @param element string Name of the element
--- @return boolean rotate True if the element rotation is enabled
local function getElementRotate(element)
    return M.settings.elements[element].rotate
end

--- Sets the color of a UI element, optionally saving to the "reimagined" warning settings or normal settings.
--- @param element string The element name: "background", "runes", or "number"
--- @param color ZO_ColorDef The color object to apply
--- @param isReimagined boolean Optional, whether to save in reimagined expireWarning settings (default false)
local function setElementColor(element, color, isReimagined)
    if isReimagined == nil then isReimagined = false end

    local r, g, b, a = color:UnpackRGBA()

    -- Apply color visually
    if element == "background" then
        CruxCounterR_Display.ring:SetColor(color)
    elseif element == "runes" then
        CruxCounterR_Display.orbit:SetColor(color)
    elseif element == "number" then
        CruxCounterR_Display:SetNumberColor(color)
    else
        CC.Debug:Trace(0, "Invalid element '<<1>>' specified for color setting", element)
        return
    end

    -- Ensure settings subtables exist before assignment
    if isReimagined then
        M.settings.reimagined                                   = M.settings.reimagined or {}
        M.settings.reimagined.expireWarning                     = M.settings.reimagined.expireWarning or {}
        M.settings.reimagined.expireWarning.elements            = M.settings.reimagined.expireWarning.elements or {}
        M.settings.reimagined.expireWarning.elements[element]   = M.settings.reimagined.expireWarning.elements[element] or {}

        M.settings.reimagined.expireWarning.elements[element].color = { r = r, g = g, b = b, a = a }

        CC.Debug:Trace(2, string.format("Set reimagined color for '%s' to RGBA(%.2f, %.2f, %.2f, %.2f)", element, r, g, b, a))
    else
        M.settings.elements                 = M.settings.elements or {}
        M.settings.elements[element]        = M.settings.elements[element] or {}
        M.settings.elements[element].color  = { r = r, g = g, b = b, a = a }

        CC.Debug:Trace(2, string.format("Set normal color for '%s' to RGBA(%.2f, %.2f, %.2f, %.2f)", element, r, g, b, a))
    end
end

--- Retrieves the color setting for a specified UI element.
--- This function returns the color as a `ZO_ColorDef` object, either from the
--- standard settings or the reimagined style settings depending on the `isReimagined` flag.
--- @param element string The name of the UI element (e.g., "runes", "background", "number").
--- @param isReimagined boolean|nil If true, fetches from `reimagined.expireWarning` settings; otherwise from default style. Defaults to false.
--- @return ZO_ColorDef A `ZO_ColorDef` instance representing the configured color.
local function getElementColor(element, isReimagined)
    isReimagined = isReimagined or false

    if isReimagined then
        return ZO_ColorDef:New(M.settings.reimagined.expireWarning.elements[element].color)
    else 
        return ZO_ColorDef:New(M.settings.elements[element].color)
    end
end

--- Retrieves the default color for a specified UI element.
--- Optionally retrieves the reimagined expire warning color.
--- Logs color components for reimagined colors.
--- @param element string The key/name of the UI element (e.g., "runes", "background")
--- @param isReimagined boolean Whether to get the reimagined expire warning color (default: false)
--- @return ZO_ColorDef|nil The default color object or nil if not found
local function getDefaultColor(element, isReimagined)
    isReimagined = isReimagined or false

    local color

    if isReimagined then
        color = M.defaults.reimagined.expireWarning.elements[element].color

        if color then
            local r, g, b, a = color:UnpackRGBA()
            CC.Debug:Trace(3, string.format("Default warn color for '%s': r=%.2f, g=%.2f, b=%.2f, a=%.2f", element, r, g, b, a))
        else
            CC.Debug:Trace(2, string.format("No default warn color found for element '%s'", element))
        end
    else
        color = M.defaults.elements[element].color
    end

    return color
end

--- Get if the element is already set to the default color or disabled
--- @param element string Name of the element
--- @param isReimagined boolean Whether to use reimagined color checks (default: false)
--- @return boolean
local function isElementDefaultColorOrDisabled(element, isReimagined)
    isReimagined = isReimagined or false

    -- Disabled check applies only for non-reimagined colors? Or always?
    if not getElementEnabled(element) then
        if not isReimagined then
            return true
        end
    end

    local current = getElementColor(element, isReimagined)
    local default = getDefaultColor(element, isReimagined)

    return current:IsEqual(default)
end

--- Checks if the current warning color of a given UI element matches its default reimagined warning color.
--- Compares the current color to the default color using the color equality method.
--- @param element string The name/key of the UI element to check
--- @return boolean True if the current color equals the default color, false otherwise
local function isElementDefaultReimaginedColor(element)
    local current = getElementColor(element, true)
    local default = getDefaultColor(element, true)

    if (CruxCounterR.settings and CruxCounterR.settings.debugLevel or 0) >= 2 then
        CruxCounterR.PrintColor("Current Color", current)
        CruxCounterR.PrintColor("Default Color", default)
    end

    -- Safety check if either is nil
    if not current or not default then return false end

    return current:IsEqual(default)
end

--- Resets the color of a specified UI element to its default value.
--- This affects either the standard style or the reimagined style, depending on the `isReimagined` flag.
--- @param element string The name of the UI element (e.g., "runes", "background", "number").
--- @param isReimagined boolean|nil If true, applies the reimagined default color. Defaults to false.
local function setToDefaultColor(element, isReimagined)
    isReimagined = isReimagined or false

    setElementColor(element, getDefaultColor(element, isReimagined), isReimagined)
end

--- Get the Hide for No Crux setting
--- @return boolean hideZeroStacks True to hide when there are zero stacks
local function getBackgroundHideZeroStacks()
    return M.settings.elements.background.hideZeroStacks
end

--- Set the Hide for No Crux setting
--- @param hideZeroStacks boolean True to hide when there are no stacks
--- @return nil
local function setBackgroundHideZeroStacks(hideZeroStacks)
    M.settings.elements.background.hideZeroStacks = hideZeroStacks
    CruxCounterR_Display.ring:SetHideZeroStacks(hideZeroStacks)
end

--- Get the rotation speed representation for the settings slider
--- @return number
local function getRotationSpeed()
    local speed     = M.settings.elements.runes.rotationSpeed
    local inverted  = rotationSpeedFactor - speed
    local percent   = inverted / rotationSpeedFactor

    CC.Debug:Trace(3, "Speed: <<1>>, Inverted: <<2>>, Percent: <<3>>", speed, inverted, percent)

    return percent * 100
end

--- Set the rotation speed translated from the settings slider
--- @param value number Speed slider value
--- @return nil
local function setRotationSpeed(value)
    local percent                           = value / 100
    local speed                             = rotationSpeedFactor - (rotationSpeedFactor * percent)
    M.settings.elements.runes.rotationSpeed = speed

    CruxCounterR_Display.orbit:SetRotationDuration(speed)

    CC.Debug:Trace(3, "Value: <<1>>, Speed: <<2>>", value, speed)
end

--- Retrieve the total duration of the crux effect in seconds
--- @return number Duration in seconds
local function getCruxDuration()
    return CC.Utils:DeepGet(M.settings, "reimagined", "cruxDuration") or M.defaults.reimagined.cruxDuration
end

--- Set the total duration of the crux effect in seconds
--- @param value number Duration in seconds
local function setCruxDuration(value)
    M.settings.reimagined               = M.settings.reimagined or {}
    M.settings.reimagined.cruxDuration  = value
end

--- Retrieve the warning threshold (seconds before expiration to warn)
--- @return number Threshold in seconds
local function getExpireWarnThreshold()
    return CC.Utils:DeepGet(M.settings, "reimagined", "expireWarning", "threshold") or M.defaults.reimagined.expireWarning.threshold
end

--- Set the warning threshold (seconds before expiration to warn)
--- @param value number Threshold in seconds
local function setExpireWarnThreshold(value)
    M.settings.reimagined                           = M.settings.reimagined or {}
    M.settings.reimagined.expireWarning             = M.settings.reimagined.expireWarning or {}
    M.settings.reimagined.expireWarning.threshold   = value
end

--- Retrieve the polling interval for expire warning updates (in ms)
--- @return number Polling interval in milliseconds
local function getExpireWarnPollingInterval()
    return CC.Utils:DeepGet(M.settings, "reimagined", "expireWarning", "pollingInterval") or M.defaults.reimagined.expireWarning.pollingInterval
end

--- Set the polling interval for expire warning updates (in ms)
--- @param value number Polling interval in milliseconds
local function setExpireWarnPollingInterval(value)
    M.settings.reimagined                               = M.settings.reimagined or {}
    M.settings.reimagined.expireWarning                 = M.settings.reimagined.expireWarning or {}
    M.settings.reimagined.expireWarning.pollingInterval = value
end

--- Get whether the rune spin animation is enabled
--- @return boolean Whether the spin animation is enabled
function M:getRuneSpinAnimationEnabled()
    local value = CC.Utils:DeepGet(M.settings, "reimagined", "runeSpinAnimation")

    if value == nil then
        return M.defaults.reimagined.runeSpinAnimation
    end

    return value
end

--- Set whether the rune spin animation is enabled
--- @param value boolean Enable or disable spin animation
function M:setRuneSpinAnimationEnabled(value)
    M.settings.reimagined                   = M.settings.reimagined or {}
    M.settings.reimagined.runeSpinAnimation = value

    if CruxCounterR_Display and CruxCounterR_Display.orbit then
        CruxCounterR_Display.orbit:UpdateSpinAnimations(value)
    else
        CC.Debug:Trace(2, "[setRuneSpinAnimationEnabled] orbit is nil")
    end
end

--- Get whether flash effect is enabled for expire warnings
--- @return boolean Flash enabled state
local function getFlashEnabled()
    return CC.Utils:DeepGet(M.settings, "reimagined", "flash", "enabled") or M.defaults.reimagined.flash.enabled
end

--- Set whether flash effect is enabled for expire warnings
--- @param value boolean Flash enabled state
local function setFlashEnabled(value)
    M.settings.reimagined               = M.settings.reimagined or {}
    M.settings.reimagined.flash         = M.settings.reimagined.flash or {}
    M.settings.reimagined.flash.enabled = value
end

--- Get flash threshold for expire warning flash start (in seconds)
--- @return number Threshold in seconds
local function getFlashThreshold()
    return CC.Utils:DeepGet(M.settings, "reimagined", "flash", "threshold") or M.defaults.reimagined.flash.threshold
end

--- Set flash threshold for expire warning flash start (in seconds)
--- @param value number Threshold in seconds
local function setFlashThreshold(value)
    M.settings.reimagined                   = M.settings.reimagined or {}
    M.settings.reimagined.flash             = M.settings.reimagined.flash or {}
    M.settings.reimagined.flash.threshold   = value
end

--- Get flash animation speed for expire warnings
--- @return number Speed multiplier
local function getFlashSpeed()
    return CC.Utils:DeepGet(M.settings, "reimagined", "flash", "speed") or M.defaults.reimagined.flash.speed
end

--- Set flash animation speed for expire warnings
--- @param value number Speed multiplier
local function setFlashSpeed(value)
    M.settings.reimagined               = M.settings.reimagined or {}
    M.settings.reimagined.flash         = M.settings.reimagined.flash or {}
    M.settings.reimagined.flash.speed   = value
end

--- Gets the current flash color for a given element and index.
--- Returns a ZO_ColorDef object representing the color.
--- If not found, returns white and logs a debug trace.
--- @param element string The element name (e.g., "runes", "background", "number").
--- @param idx number The color index (usually 1 or 2).
--- @return ZO_ColorDef The color object.
local function getFlashColor(element, idx)
    local colorKey = "color" .. tostring(idx)

    local color = M.settings.reimagined.flash.elements[element] and M.settings.reimagined.flash.elements[element][colorKey]

    if color then
        return ZO_ColorDef:New(color)
    else
        -- Fallback to white if not found
        CC.Debug:Trace(1, string.format("No flash color found for '%s' index %d", element, idx))

        return ZO_ColorDef:New(1, 1, 1, 1)
    end
end

--- Sets the flash color for a given element and index.
--- Updates the settings table with the RGBA components of the provided ZO_ColorDef color.
--- @param element string The element name (e.g., "runes", "background", "number").
--- @param idx number The color index (usually 1 or 2).
--- @param color ZO_ColorDef The color object to set.
local function setFlashColor(element, idx, color)
    local colorKey      = "color" .. tostring(idx)
    local r, g, b, a    = color:UnpackRGBA()

    -- Ensure settings path exists
    local flashSettings = M.settings.reimagined
        and M.settings.reimagined.flash
        and M.settings.reimagined.flash.elements
        and M.settings.reimagined.flash.elements[element]

    if not flashSettings then
        M.settings.reimagined                           = M.settings.reimagined or {}
        M.settings.reimagined.flash                     = M.settings.reimagined.flash or {}
        M.settings.reimagined.flash.elements            = M.settings.reimagined.flash.elements or {}
        M.settings.reimagined.flash.elements[element]   = {}
        flashSettings                                   = M.settings.reimagined.flash.elements[element]
    end

    flashSettings[colorKey] = { r = r, g = g, b = b, a = a }

    CC.Debug:Trace(2, string.format("Set flash color for '%s' (%s) to RGBA(%.2f, %.2f, %.2f, %.2f)", element, colorKey, r, g, b, a))
end

--- Gets the default flash color for a given element and index from the defaults table.
--- Returns a ZO_ColorDef object representing the default color.
--- If not found, returns white and logs a debug trace.
--- @param element string The element name (e.g., "runes", "background", "number").
--- @param idx number The color index (usually 1 or 2).
--- @return ZO_ColorDef The default color object.
local function getDefaultFlashColor(element, idx)
    local colorKey  = "color" .. tostring(idx)
    local color     = M.defaults.reimagined.flash
                        and M.defaults.reimagined.flash.elements
                        and M.defaults.reimagined.flash.elements[element]
                        and M.defaults.reimagined.flash.elements[element][colorKey]

    if color then
        local r, g, b, a = color.r or color[1], color.g or color[2], color.b or color[3], color.a or color[4]

        CC.Debug:Trace(3, string.format("Default flash color for '%s' (%s): r=%.2f, g=%.2f, b=%.2f, a=%.2f", element, colorKey, r, g, b, a))
        
        return ZO_ColorDef:New(r, g, b, a)
    else
        CC.Debug:Trace(2, string.format("No default flash color found for '%s' (%s)", element, colorKey))

        return ZO_ColorDef:New(1, 1, 1, 1) -- fallback white
    end
end

--- Resets all flash colors for all elements and indices to their default values.
--- Updates the settings and refreshes the LibAddonMenu panel if it exists.
local function resetAllFlashColorsToDefault()
    local elements      = { "runes", "background", "number" }
    local colorIndices  = { 1, 2 }

    for _, element in ipairs(elements) do
        for _, idx in ipairs(colorIndices) do
            local defaultColor = getDefaultFlashColor(element, idx)

            setFlashColor(element, idx, defaultColor)
        end
    end

    -- Refresh the menu to update all colorpickers (LAM-specific)
    if CC.LAMPanel then
        LibStub("LibAddonMenu-2.0"):RefreshPanel(CC.LAMPanel)
    end
end

--- Checks if all flash colors for all elements and indices are currently set to their default values.
--- Returns true if all match defaults, false otherwise.
--- Logs current and default colors if debug level >= 2.
--- @return boolean True if all flash colors are default, false otherwise.
local function areAllFlashColorsDefault()
    local elements      = { "runes", "background", "number" }
    local colorIndices  = { 1, 2 }

    for _, element in ipairs(elements) do
        for _, idx in ipairs(colorIndices) do
            local current = getFlashColor(element, idx)
            local default = getDefaultFlashColor(element, idx)

            if (CruxCounterR.settings and CruxCounterR.settings.debugLevel or 0) >= 2 then
                CruxCounterR.PrintColor(string.format("Current Flash [%s][%d]", element, idx), current)
                CruxCounterR.PrintColor(string.format("Default Flash [%s][%d]", element, idx), default)
            end

            -- If one is not default, return false
            if not current or not default or not current:IsEqual(default) then
                return false
            end
        end
    end

    return true
end

--- Retrieves the rune-related settings table with defaults as fallback.
--- This function accesses the current saved settings and their defaults,
--- prints debug info listing the keys in each rune settings table,
--- and returns the rune settings table with a metatable to fall back
--- to default values for missing keys.
--- @return table Rune settings with fallback to default rune settings
local function GetRuneSettings()
    local settings          = M.settings or {}                      -- Get current saved settings or empty table if missing
    local elements          = settings.reimagined.elements or {}    -- Access the 'elements' subtable in the 'reimagined' settings or fallback to empty table
    local runes             = elements.runes or {}                  -- Attempt to get runes settings from 'elements', but this line has a bug (should be 'elements' not 'reimagined')
    local defaults          = M.defaults or {}                      -- Get defaults or empty table if missing
    local defaultElements   = defaults.reimagined.elements or {}    -- Access default 'elements' in 'reimagined' or fallback to empty table
    local defaultRunes      = defaultElements.runes or {}           -- Get default rune settings from defaultElements or empty table

    -- Debug print keys of current rune settings table
    CC.Debug:Trace(2, "runes table keys:")

    for k, v in pairs(runes) do
        CC.Debug:Trace(2, "  " .. tostring(k) .. " = " .. tostring(v))
    end

    -- Debug print keys of default rune settings table
    CC.Debug:Trace(2, "defaultRunes table keys:")

    for k, v in pairs(defaultRunes) do
        CC.Debug:Trace(2, "  " .. tostring(k) .. " = " .. tostring(v))
    end

    -- Return the rune settings table with a metatable that falls back to the defaultRunes table for any missing keys
    return setmetatable(runes, { __index = defaultRunes })
end

--- Export the GetRuneSettings function to the module table M
M.GetRuneSettings = GetRuneSettings

--- @type table Options for Style settings
local styleOptions = {
    {
        type = "header",
        name = function()
            local colorPalette = {"72b007"}

            return CruxCounterR.UI:GetColorizeTextWithPalette(
                CC.Language:GetString("SETTINGS_STYLE_HEADER"),
                colorPalette
            )
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Number
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_DESC")
        end,
        getFunc = function()
            return getElementEnabled("number")
        end,
        setFunc = function(enabled)
            setElementEnabled("number", enabled)
        end,
        width = "half",
    },
    {
        type = "custom",
        width = "half",
    },
    {
        -------------------------------------------------------------------
        -- Number Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("number")
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("number", newColor)
        end,
        default = function()
            local color = getDefaultColor("number")
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("number")
        end,
        width = "half",
    },
    {
        type = "custom",
        width = "half",
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_COLOR_RESET_DESC")
        end,
        func = function()
            setToDefaultColor("number")
        end,
        width = "half",
        disabled = function() return isElementDefaultColorOrDisabled("number") end,
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Crux Runes
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_RUNES")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_RUNES_DESC")
        end,
        getFunc = function()
            return getElementEnabled("runes")
        end,
        setFunc = function(enabled)
            setElementEnabled("runes", enabled)
        end,
        width = "half",
    },
    {
        -------------------------------------------------------------------
        -- Rotate
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_ROTATE")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_RUNES_ROTATE_DESC")
        end,
        getFunc = function()
            return getElementRotate("runes")
        end,
        setFunc = function(enabled)
            setElementRotate("runes", enabled)
        end,
        width = "half",
        disabled = function()
            return not getElementEnabled("runes")
        end,
    },
    {
        -------------------------------------------------------------------
        -- Runes (Crux) Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("runes")
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("runes", newColor)
        end,
        default = function()
            local color = getDefaultColor("runes")
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("runes")
        end,
        width = "half",
    },
    {
        -------------------------------------------------------------------
        -- Runes (Crux) Rotation Speed
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_RUNES_ROTATION_SPEED")
        end,
        min = 5,
        max = 95,
        step = 5,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_RUNES_ROTATION_SPEED_DESC")
        end,
        getFunc = getRotationSpeed,
        setFunc = setRotationSpeed,
        width = "half",
        default = M.defaults.elements.runes.rotationSpeed,
        disabled = function()
            return not getElementEnabled("runes") or not getElementRotate("runes")
        end,
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_COLOR_RESET_DESC")
        end,
        func = function()
            setToDefaultColor("runes")
        end,
        width = "half",
        disabled = function() return isElementDefaultColorOrDisabled("runes") end,
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Background
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_DESC")
        end,
        getFunc = function()
            return getElementEnabled("background")
        end,
        setFunc = function(enabled)
            setElementEnabled("background", enabled)
        end,
        width = "half",
    },
    {
        -------------------------------------------------------------------
        -- Background Rotate
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_ROTATE")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_ROTATE")
        end,
        getFunc = function()
            return getElementRotate("background")
        end,
        setFunc = function(enabled)
            setElementRotate("background", enabled)
        end,
        width = "half",
        disabled = function()
            return not getElementEnabled("background")
        end,
    },
    {
        -------------------------------------------------------------------
        -- Background Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("background")
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("background", newColor)
        end,
        default = function()
            local color = getDefaultColor("background")
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("background")
        end,
        width = "half",
    },
    {
        -------------------------------------------------------------------
        -- Hide on Zero Stacks
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_HIDE_ZERO_CRUX")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_HIDE_ZERO_CRUX_DESC")
        end,
        getFunc = getBackgroundHideZeroStacks,
        setFunc = setBackgroundHideZeroStacks,
        width = "half",
        disabled = function()
            return not getElementEnabled("background")
        end,
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_COLOR_RESET_DESC")
        end,
        func = function()
            setToDefaultColor("background")
        end,
        width = "half",
        disabled = function() return isElementDefaultColorOrDisabled("background") end,
    },
    {
        type = "divider",
    },
    {
        type = "header",
        name = function()
            local colorPalette = {"ffffff", "ffffff", "59b8a9", "4da99a", "3c9588", "2f877b", "26776c", "1f6c61", "188074", "0e7362"}

            return CruxCounterR.UI:GetColorizeTextWithPalette(
                CC.Language:GetString("SETTINGS_STYLE_REIMAGINED_HEADER"),
                colorPalette
            )
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Max Crux Buff Duration
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_DURATION")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_DURATION_DESC")
        end,
        min = 1,
        max = 30,
        step = 1,
        getFunc = getCruxDuration,
        setFunc = setCruxDuration,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.cruxDuration) or 30
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Warn Threshold Polling Interval
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_POLLING_INTERVAL")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_POLLING_INTERVAL_DESC")
        end,
        min = 100,
        max = 1000,
        step = 100,
        getFunc = getExpireWarnPollingInterval,
        setFunc = setExpireWarnPollingInterval,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.expireWarning and M.defaults.reimagined.expireWarning.pollingInterval) or 200
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Warn Threshold
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_THRESHOLD")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_THRESHOLD_DESC")
        end,
        min = 1,
        max = 30,
        step = 1,
        getFunc = getExpireWarnThreshold,
        setFunc = setExpireWarnThreshold,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.expireWarning and M.defaults.reimagined.expireWarning.threshold) or 10
        end,
        width = "full",
        disabled = function() return not getElementEnabled("runes") end,
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Number (Aura) Warn Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("number", true)
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("number", newColor, true)
        end,
        default = function()
            local color = getDefaultColor("number", true)
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("number")
        end,
        width = "full",
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR_RESET_DESC")
        end,
        func = function()
            local ok, err = pcall(function()
                setToDefaultColor("number", true)
            end)

            if not ok then d("Button func error: " .. tostring(err)) end
        end,
        disabled = function()
            local status = isElementDefaultReimaginedColor("number")

            if type(status) ~= "boolean" then
                CC.Debug:Trace(2, "WARNING: disabled callback returned non-boolean: <<1>>", tostring(status))

                return false
            end

            return status
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Rune (Crux) Warn Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("runes", true)
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("runes", newColor, true)
        end,
        default = function()
            local color = getDefaultColor("runes", true)
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("runes")
        end,
        width = "full",
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR_RESET_DESC")
        end,
        func = function()
            local ok, err = pcall(function()
                setToDefaultColor("runes", true)
            end)

            if not ok then d("Button func error: " .. tostring(err)) end
        end,
        disabled = function()
            local status = isElementDefaultReimaginedColor("runes")

            if type(status) ~= "boolean" then
                CC.Debug:Trace(2, "WARNING: disabled callback returned non-boolean: <<1>>", tostring(status))

                return false
            end

            return status
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Backround Warn Color
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("background", true)
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            setElementColor("background", newColor, true)
        end,
        default = function()
            local color = getDefaultColor("background", true)
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getElementEnabled("background")
        end,
        width = "full",
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR_RESET")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR_RESET_DESC")
        end,
        func = function()
            local ok, err = pcall(function()
                setToDefaultColor("background", true)
            end)

            if not ok then d("Button func error: " .. tostring(err)) end
        end,
        disabled = function()
            local status = isElementDefaultReimaginedColor("background")

            if type(status) ~= "boolean" then
                CC.Debug:Trace(2, "WARNING: disabled callback returned non-boolean: <<1>>", tostring(status))
                return false
            end

            return status
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Enable/Disable spin animation on runes (crux)
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_SPIN_ANIMATION")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_SPIN_ANIMATION_DESC")
        end,
        getFunc = function() return CC.Settings:getRuneSpinAnimationEnabled() end,
        setFunc = function(value) 
            CC.Settings:setRuneSpinAnimationEnabled(value) 
        end,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.runeSpinAnimation) or true
        end,
        width = "full",
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Enable/Disable flash within warn threshold
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_ENABLE")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_ENABLE_DESC")
        end,
        getFunc = getFlashEnabled,
        setFunc = setFlashEnabled,
        width = "full",
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.flash and M.defaults.reimagined.flash.enabled) or false
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash start threshold
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_START_THRESHOLD")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_START_THRESHOLD_DESC")
        end,
        min = 0,
        max = 30,
        step = 1,
        getFunc = function()
            local flashVal  = getFlashThreshold()
            local maxVal    = getExpireWarnThreshold()
            
            if flashVal > maxVal then
                return maxVal
            end
            
            return flashVal
        end,
        setFunc = function(value)
            local maxVal = getExpireWarnThreshold()
            
            if value > maxVal then
                value = maxVal
            end
            
            setFlashThreshold(value)
        end,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.flash and M.defaults.reimagined.flash.threshold) or 0
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("runes")
                and not getElementEnabled("background")
                and not getElementEnabled("number")
            )
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash speed
        -------------------------------------------------------------------
        type = "slider",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_SPEED")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_SPEED_DESC")
        end,
        min = 0.5,  -- Half a flash per second (slower)
        max = 5.0,  -- 5 flashes per second (very fast)
        step = 0.5,
        getFunc = getFlashSpeed,
        setFunc = setFlashSpeed,
        default = function()
            return (M.defaults.reimagined and M.defaults.reimagined.flash and M.defaults.reimagined.flash.speed) or 2.0
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("runes")
                and not getElementEnabled("background")
                and not getElementEnabled("number")
            )
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Rune (Crux) Color 1
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RUNE_COLOR_1")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RUNE_COLOR_1_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("runes", 1)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            
            setFlashColor("runes", 1, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("runes", 1)
            
            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("runes")
            ) 
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Runes (Crux) Color 2
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RUNE_COLOR_2")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RUNE_COLOR_2_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("runes", 2)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            setFlashColor("runes", 2, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("runes", 2)

            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("runes")
            ) 
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Background Color 1
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_BACKGROUND_COLOR_1")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_BACKGROUND_COLOR_1_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("background", 1)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            setFlashColor("background", 1, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("background", 1)

            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("background")
            ) 
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Background Color 2
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_BACKGROUND_COLOR_2")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_BACKGROUND_COLOR_2_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("background", 2)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            setFlashColor("background", 2, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("background", 2)

            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("background")
            ) 
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Aura Color 1
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_NUMBER_COLOR_1")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_NUMBER_COLOR_1_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("number", 1)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            setFlashColor("number", 1, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("number", 1)

            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("number")
            )
        end,
        width = "full"
    },
    {
        -------------------------------------------------------------------
        -- Flash Aura Color 2 
        -------------------------------------------------------------------
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_NUMBER_COLOR_2")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_NUMBER_COLOR_2_DESC")
        end,
        getFunc = function()
            local color = getFlashColor("number", 2)

            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            setFlashColor("number", 2, newColor)
        end,
        default = function()
            local color = getDefaultFlashColor("number", 2)

            return color:UnpackRGBA()
        end,
        disabled = function()
            return not getFlashEnabled() or (
                not getElementEnabled("number")
            )
        end,
        width = "full"
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Reset all flash colors
        -------------------------------------------------------------------
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RESET_COLORS")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_WARN_FLASH_RESET_COLORS_DESC")
        end,
        func = resetAllFlashColorsToDefault,
        disabled = function()
            return not getFlashEnabled() or not getElementEnabled("runes")
        end,
        width = "full",
    },
}

-- -----------------------------------------------------------------------------
-- Sound
-- -----------------------------------------------------------------------------
--- Set if a sound playback condition should play
--- @param type string Name of the playback condition
--- @param enabled boolean True if the condition should play a sound
--- @return nil
local function setSoundEnabled(type, enabled)
    M.settings.sounds[type].enabled = enabled
end

--- Get if a sound playback condition should play
--- @param type string Name of the playback condition
--- @return boolean enabled True when the condition should play a sound
function M:GetSoundEnabled(type)
    return self.settings.sounds[type].enabled
end

--- Set the sound for a playback condition
--- @param type string Name of the playback condition
--- @param soundName string Name of the sound to play
--- @return nil
local function setSound(type, soundName)
    M.settings.sounds[type].name = soundName
end

--- Get the sound for a playback condition
--- @param type string Name of the playback condition
--- @return string soundName Name of the sound to play
local function getSound(type)
    return M.settings.sounds[type].name
end

--- Set the sound volume for a playback condition
--- @param type string Name of the playback condition
--- @param volume number Playback volume
--- @return nil
local function setVolume(type, volume)
    M.settings.sounds[type].volume = volume
end

--- Get the sound volume for a playback condition
--- @param type string Name of the playback condition
--- @return number volume Playback volume
local function getVolume(type)
    return M.settings.sounds[type].volume
end

--- @type table Options for Sound settings
local soundOptions = {
    {
        -------------------------------------------------------------------
        -- Sounds
        -------------------------------------------------------------------
        type = "header",
        name = function()
            local colorPalette = {"72b007"}

            return CruxCounterR.UI:GetColorizeTextWithPalette(
                CC.Language:GetString("SETTINGS_SOUNDS_HEADER"),
                colorPalette
            )
        end,
        width = "full",
    },
    {
        -------------------------------------------------------------------
        -- Crux Gained
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_CRUX_GAINED")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_CRUX_GAINED_DESC")
        end,
        getFunc = function()
            return M:GetSoundEnabled("cruxGained")
        end,
        setFunc = function(state)
            setSoundEnabled("cruxGained", state)
        end,
        width = "full",
    },
    {
        type = "dropdown",
        name = "",
        choices = sounds,
        getFunc = function()
            return getSound("cruxGained")
        end,
        setFunc = function(soundName)
            setSound("cruxGained", soundName)
        end,
        width = "half",
        -- sort = "name-up",
        scrollable = true,
        disabled = function()
            return not M:GetSoundEnabled("cruxGained")
        end,
    },
    {
        type = "slider",
        name = "",
        min = 0,
        max = 100,
        step = 10,
        getFunc = function()
            return getVolume("cruxGained")
        end,
        setFunc = function(volume)
            setVolume("cruxGained", volume)
        end,
        width = "half",
        default = M.defaults.sounds.cruxGained.volume,
        disabled = function()
            return not M:GetSoundEnabled("cruxGained")
        end,
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_PLAY")
        end,
        func = function()
            CC.UI:PlaySoundForType("cruxGained")
        end,
        width = "full",
        disabled = function()
            return not M:GetSoundEnabled("cruxGained")
        end,
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Maximum Crux
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_MAXIMUM_CRUX")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_MAXIMUM_CRUX_DESC")
        end,
        getFunc = function()
            return M:GetSoundEnabled("maxCrux")
        end,
        setFunc = function(state)
            setSoundEnabled("maxCrux", state)
        end,
        width = "full",
    },
    {
        type = "dropdown",
        name = "",
        choices = sounds,
        getFunc = function()
            return getSound("maxCrux")
        end,
        setFunc = function(soundName)
            setSound("maxCrux", soundName)
        end,
        width = "half",
        -- sort = "name-up",
        scrollable = true,
        disabled = function()
            return not M:GetSoundEnabled("maxCrux")
        end,
    },
    {
        type = "slider",
        name = "",
        min = 0,
        max = 100,
        step = 10,
        getFunc = function()
            return getVolume("maxCrux")
        end,
        setFunc = function(volume)
            setVolume("maxCrux", volume)
        end,
        width = "half",
        default = M.defaults.sounds.maxCrux.volume,
        disabled = function()
            return not M:GetSoundEnabled("maxCrux")
        end,
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_PLAY")
        end,
        func = function()
            CC.UI:PlaySoundForType("maxCrux")
        end,
        width = "full",
        disabled = function()
            return not M:GetSoundEnabled("maxCrux")
        end,
    },
    {
        type = "divider",
    },
    {
        -------------------------------------------------------------------
        -- Crux Lost
        -------------------------------------------------------------------
        type = "checkbox",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_CRUX_LOST")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_CRUX_LOST_DESC")
        end,
        getFunc = function()
            return M:GetSoundEnabled("cruxLost")
        end,
        setFunc = function(state)
            setSoundEnabled("cruxLost", state)
        end,
        width = "full",
    },
    {
        type = "dropdown",
        name = "",
        choices = sounds,
        getFunc = function()
            return getSound("cruxLost")
        end,
        setFunc = function(soundName)
            setSound("cruxLost", soundName)
        end,
        width = "half",
        -- sort = "name-up",
        scrollable = true,
        disabled = function()
            return not M:GetSoundEnabled("cruxLost")
        end,
    },
    {
        type = "slider",
        name = "",
        min = 0,
        max = 100,
        step = 10,
        getFunc = function()
            return getVolume("cruxLost")
        end,
        setFunc = function(volume)
            setVolume("cruxLost", volume)
        end,
        width = "half",
        default = M.defaults.sounds.cruxLost.volume,
        disabled = function()
            return not M:GetSoundEnabled("cruxLost")
        end,
    },
    {
        type = "button",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_PLAY")
        end,
        func = function()
            CC.UI:PlaySoundForType("cruxLost")
        end,
        width = "full",
        disabled = function()
            return not M:GetSoundEnabled("cruxLost")
        end,
    },
}

-- -----------------------------------------------------------------------------
-- Setup
-- -----------------------------------------------------------------------------
--- Add an option to the LibAddonMenu settings menu
--- @param options table Menu options
--- @return nil
local function addToMenu(options)
    for _, option in pairs(options) do
        table.insert(optionsData, option)
    end
end

--- Populate sound options list and sort it
--- @return nil
local function populateSounds()
    for sound, _ in pairs(gameSounds) do
        if sound ~= nil and sound ~= "" then
            table.insert(sounds, sound)
        end
    end

    table.sort(sounds)
end

--- Get the default value for a key
--- @param key string Default setting key
--- @return any value Default setting value
function M:GetDefault(key)
    -- No key provided, return full defaults table
    if key == nil then return self.defaults end

    local value = self.defaults[key]

    -- Error when invalid option requested
    assert(value ~= nil, zo_strformat("Invalid setting '<<1>>' provided", key))

    return value;
end

--- Get setting by key
--- If no such key exists, get the default value
--- @param key string|nil Setting key to lookup
--- @return any|nil value Setting value or nil if the key doesn't exist
function M:Get(key)
    -- No key provided, return full settings table
    if key == nil then return self.settings end

    if self.settings[key] then
        return self.settings[key]
    end

    -- Fall back to defaults if loaded setting is not found
    return self:GetDefault(key)
end

--- Get setting by key
--- If no such key exists, get the default value
--- @param element string Element setting to get
--- @return table elementSetting Settings for the element or
function M:GetElement(element)
    local elements = self:Get("elements")
    local selection = elements[element] or nil

    -- Bad and weird
    assert(selection ~= nil,
        zo_strformat("No loaded settings for element '<<1>>' found and no default settings exist", element))

    return selection
end

--- Migrates old settings to the new 'reimagined' settings structure.
--- Copies legacy threshold, polling interval, and warning colors into
--- the new format if they are not already set.
--- Marks migration as done to prevent repeated execution.
--- @param settings table The settings table to migrate. If nil or not a table, migration is skipped.
local function MigrateOldSettings(settings)
    if not settings or type(settings) ~= "table" then return end

    -- Skip if migration already done
    if settings.reimagined and settings.reimagined._migrationDone then return end

    -- Ensure structure exists
    settings.reimagined = settings.reimagined or {}
    local r = settings.reimagined

    r.expireWarning                     = r.expireWarning or {}
    r.expireWarning.elements            = r.expireWarning.elements or {}
    r.expireWarning.elements.runes      = r.expireWarning.elements.runes or {}
    r.expireWarning.elements.number     = r.expireWarning.elements.number or {}
    r.expireWarning.elements.background = r.expireWarning.elements.background or {}

    -- Migrate threshold
    if not r.expireWarning.threshold then
        local legacy = settings.elements and settings.elements.runes and settings.elements.runes.reimagined

        if legacy and legacy.expireWarnThreshold then
            r.expireWarning.threshold = legacy.expireWarnThreshold
        elseif settings.reimagined and settings.reimagined.runes and settings.reimagined.runes.expireWarn then
            r.expireWarning.threshold = settings.reimagined.runes.expireWarn.threshold
        else
            r.expireWarning.threshold = M.defaults.reimagined.expireWarning.threshold
        end
    end

    -- Migrate polling interval
    if not r.expireWarning.pollingInterval then
        local legacy = settings.elements and settings.elements.runes and settings.elements.runes.reimagined
        
        if legacy and legacy.expireWarnPollingInterval then
            r.expireWarning.pollingInterval = legacy.expireWarnPollingInterval
        elseif settings.reimagined and settings.reimagined.runes and settings.reimagined.runes.expireWarn then
            r.expireWarning.pollingInterval = settings.reimagined.runes.expireWarn.pollingInterval
        else
            r.expireWarning.pollingInterval = M.defaults.reimagined.expireWarning.pollingInterval
        end
    end

    -- Migrate warn colors
    local function migrateColorElement(elementName)
        local target = r.expireWarning.elements[elementName]

        if not target.color then
            local legacyColor = settings.elements
                and settings.elements[elementName]
                and settings.elements[elementName].reimagined
                and settings.elements[elementName].reimagined.expireWarnColor
            if legacyColor then
                target.color = legacyColor
                return
            end

            local flatColor = settings.elements
                and settings.elements[elementName]
                and settings.elements[elementName].expireWarnColor
            if flatColor then
                target.color = flatColor
                return
            end

            target.color = M.defaults.reimagined.expireWarning.elements[elementName].color
        end
    end

    migrateColorElement("runes")
    migrateColorElement("number")
    migrateColorElement("background")

    -- Mark migration as complete
    r._migrationDone = true
end

--- Setup settings
--- @return nil
function M:Setup()
    local addon = CC.Addon

    -- Load raw saved variables (no defaults applied yet)
    local rawSaved = ZO_SavedVars:NewAccountWide(self.savedVariables, self.dbVersion, nil, nil)

    -- Run migration BEFORE loading final settings (important!)
    MigrateOldSettings(rawSaved)

    -- Now apply defaults after migration
    self.settings = ZO_SavedVars:NewAccountWide(self.savedVariables, self.dbVersion, nil, self.defaults)

    populateSounds()

    addToMenu(displayOptions)
    addToMenu(styleOptions)
    addToMenu(soundOptions)

    CC.panel = LAM:RegisterAddonPanel(addon.name, {
        type                = "panel",
        name                = "Crux Counter (reIMAGINED)",
        displayName         = "Crux Counter (reIMAGINED)",
        author              = "Dim (@xDiminish)",
        version             = addon.version,
        registerForRefresh  = true,
        slashCommand        = "/ccr",
    })

    -- Register debug/help slash commands
    SLASH_COMMANDS["/ccr"] = function(text)
        local args = {}

        for word in text:gmatch("%S+") do
            table.insert(args, word)
        end

        if args[1] == "debug" then
            local level = tonumber(args[2])

            if level and level >= 0 and level <= 3 then
                CruxCounterR.Debug.level = level
                CruxCounterR.Debug:Say("Debug level set to <<1>>", level)
            else
                CruxCounterR.Debug:Say("Usage: /ccr debug [0-3]")
            end
        elseif args[1] == "help" then
            CruxCounterR.Debug:Say("Slash commands:")
            CruxCounterR.Debug:Say("/ccr - Open settings panel")
            CruxCounterR.Debug:Say("/ccr debug [0-3] - Set debug level")
            CruxCounterR.Debug:Say("/ccr help - Show this message")
        else
            if CC.panel then
                LibAddonMenu2:OpenToPanel(CC.panel)
            else
                CruxCounterR.Debug:Say("Settings panel not found.")
            end
        end
    end

    LAM:RegisterOptionControls(addon.name, optionsData)

    CC.Debug:Trace(2, "Finished InitSettings()")
end

CC.Settings = M