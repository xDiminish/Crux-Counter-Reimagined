-- -----------------------------------------------------------------------------
-- Settings.lua
-- -----------------------------------------------------------------------------

local CC                  = CruxCounterR
local LAM                 = LibAddonMenu2
local M                   = {}

local gameSounds          = SOUNDS
local sounds              = {}

local rotationSpeedFactor = 24000

-- Colors
-- B7FFC6
local veryLightGreen      = ZO_ColorDef:New(0.7176470588, 1, 0.7764705882, 1)
-- B7FF7C
local lightGreen          = ZO_ColorDef:New(0.7176470588, 1, 0.4862745098, 1)
-- ADF573
local mediumGreen         = ZO_ColorDef:New(0.6784313725, 0.9607843137, 0.4509803921, 1)
-- FF3333
local brightRed           = ZO_ColorDef:New(1, 0.2, 0.2, 1)


-- Defaults/Settings Storage
M.settings       = {}
M.dbVersion      = 0
M.savedVariables = "CruxCounterReimaginedData"
M.defaults       = {
    top             = 0,
    left            = 0,
    hideOutOfCombat = false,
    locked          = false,
    lockToReticle   = false,
    size            = 128,
    elements        = {
        number     = {
            enabled = true,
            color   = veryLightGreen,
        },
        runes      = {
            enabled                     = true,
            rotate                      = true,
            rotationSpeed               = 9600,
            color                       = lightGreen,
        },
        background = {
            enabled        = true,
            rotate         = true,
            hideZeroStacks = false,
            color          = mediumGreen,
        },
    },
    sounds          = {
        cruxGained = {
            enabled = false,
            name    = "ENCHANTING_POTENCY_RUNE_PLACED",
            volume  = 20,
        },
        cruxLost   = {
            enabled = false,
            name    = "ENCHANTING_WEAPON_GLYPH_REMOVED",
            volume  = 20,
        },
        maxCrux    = {
            enabled = true,
            name    = "DEATH_RECAP_KILLING_BLOW_SHOWN",
            volume  = 20,
        },
    },
    reimagined = {
        cruxDuration = 30,
        expireWarning = {
            threshold = 10,
            pollingInterval = 200,
            enabled = true,
            elements = {
                number = {
                    color = brightRed,
                },
                runes = {
                    color = brightRed,
                },
                background = {
                    color = brightRed,
                }
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

    CruxCounterR_LockButton.button.data = {
        tooltipText = LAM.util.GetStringFromValue(getLockUnlockTooltipText())
    }
    CruxCounterR_MoveToCenterButton.button.data = {
        tooltipText = LAM.util.GetStringFromValue(getMoveToCenterTooltipText())
    }
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
        -- Display
        type = "header",
        name = function() return CC.Language:GetString("SETTINGS_DISPLAY_HEADER") end,
        width = "full",
    },
    {
        -- Lock/Unlock
        type = "button",
        name = getLockUnlockButtonText,
        tooltip = getLockUnlockTooltipText,
        disabled = getLockToReticle,
        func = toggleLocked,
        width = "half",
        reference = "CruxCounterR_LockButton"
    },
    {
        -- Move to Center
        type = "button",
        name = function() return CC.Language:GetString("SETTINGS_MOVE_TO_CENTER") end,
        tooltip = getMoveToCenterTooltipText,
        disabled = getLockToReticle,
        func = moveToCenter,
        width = "half",
        reference = "CruxCounterR_MoveToCenterButton",
    },
    {
        -- Lock to Reticle
        type = "checkbox",
        name = function() return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE") end,
        tooltip = function() return CC.Language:GetString("SETTINGS_LOCK_TO_RETICLE_DESC") end,
        getFunc = getLockToReticle,
        setFunc = setLockToReticle,
        width = "full",
    },
    {
        -- Hide out of Combat
        type = "checkbox",
        name = function() return CC.Language:GetString("SETTINGS_HIDE_OUT_OF_COMBAT") end,
        tooltip = function() return CC.Language:GetString("SETTINGS_HIDE_OUT_OF_COMBAT_DESC") end,
        getFunc = getHideOutOfCombat,
        setFunc = setHideOutOfCombat,
        width = "full",
    },
    {
        -- Size
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

--- Get the color of an element
--- @param element string Name of the element
--- @return ZO_ColorDef
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

--- Reset an element to its default color
--- @param element string Name of the element
--- @return nil
local function setToDefaultColor(element, isReimagined)
    isReimagined = isReimagined or false

    setElementColor(element, getDefaultColor(element, isReimagined), isReimagined)
end

--- Sets the warning color of a specified UI element to its default reimagined color.
--- Fetches the default color for the element and applies it using the setter function.
--- @param element string The name/key of the UI element whose warning color should be reset
local function setToDefaultReimaginedWarnColor(element)
    local defaultColor = getDefaultColor(element, true)

    setElementColor(element, defaultColor, true)
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

--- Retrieves the total duration of the crux effect in seconds.
--- Falls back to default if not explicitly set in current settings.
--- @return number duration in seconds
local function getCruxDuration()
    return M.settings.reimagined.cruxDuration or M.defaults.reimagined.cruxDuration
end

--- Sets the total duration of the crux effect in seconds.
--- @param value number The new crux duration in seconds
local function setCruxDuration(value)
    M.settings.reimagined.cruxDuration = value
end

--- Retrieves the warning threshold (time before crux expiration to start warning) in seconds.
--- Falls back to default if not set.
--- @return number threshold in seconds
local function getExpireWarnThreshold()
    return M.settings.reimagined.expireWarning.threshold or M.defaults.reimagined.expireWarning.threshold
end

--- Sets the warning threshold time (seconds before expiration to warn).
--- @param value number Warning threshold in seconds
local function setExpireWarnThreshold(value)
    M.settings.reimagined.expireWarning.threshold = value
end

--- Retrieves the color used for expire warning on runes.
--- Tries to return unpacked RGBA values for convenience.
--- Supports saved ZO_ColorDef objects or simple tables {r, g, b, a}.
--- Returns default red (1,0,0,1) if no color found.
--- @return number r, g, b, a Color channels as floats from 0 to 1
-- local function getExpireRuneWarnColor()
--     local color = M.settings.reimagined.elements.runes.expireWarning.color or M.defaults.reimagined.elements.runes.expireWarning.color

--     if type(color) == "table" and color.UnpackRGBA then
--         return color:UnpackRGBA()
--     elseif type(color) == "table" then
--         -- Fallback if saved as a simple table {r,g,b,a}
--         return color.r or 1, color.g or 0, color.b or 0, color.a or 1
--     else
--         return 1, 0, 0, 1 -- fallback red
--     end
-- end

--- Sets the expire warning color for runes.
--- Constructs a ZO_ColorDef object from RGBA floats.
--- @param r number Red channel (0-1)
--- @param g number Green channel (0-1)
--- @param b number Blue channel (0-1)
--- @param a number Alpha channel (0-1)
-- local function setExpireRuneWarnColor(r, g, b, a)
--     M.settings.reimagined.elements.runes.expireWarning.color = ZO_ColorDef:New(r, g, b, a)
-- end

--- Retrieves the color used for expire warning on the background.
--- Supports same formats and fallback as getExpireRuneWarnColor.
--- @return number r, g, b, a Color channels as floats from 0 to 1
-- local function getExpireBackgroundWarnColor()
--     local color = M.settings.reimagined.elements.background.expireWarning.color or M.defaults.reimagined.elements.background.expireWarning.color

--     if type(color) == "table" and color.UnpackRGBA then
--         return color:UnpackRGBA()
--     elseif type(color) == "table" then
--         -- Fallback if saved as a simple table {r,g,b,a}
--         return color.r or 1, color.g or 0, color.b or 0, color.a or 1
--     else
--         return 1, 0, 0, 1 -- fallback red
--     end
-- end

--- Sets the expire warning color for the background.
--- @param r number Red channel (0-1)
--- @param g number Green channel (0-1)
--- @param b number Blue channel (0-1)
--- @param a number Alpha channel (0-1)
-- local function setExpireBackgroundWarnColor(r, g, b, a)
--     M.settings.reimagined.elements.background.expireWarning.color = ZO_ColorDef:New(r, g, b, a)
-- end

--- Retrieves the polling interval (in milliseconds) for checking expire warnings.
--- Used to control how often color updates occur as expiration nears.
--- Falls back to default if unset.
--- @return number Polling interval in milliseconds
local function getExpireWarnPollingInterval()
    return M.settings.reimagined.expireWarning.pollingInterval or M.defaults.reimagined.expireWarning.pollingInterval
end

--- Sets the polling interval (milliseconds) for expire warning updates.
--- @param value number Polling interval in milliseconds
local function setExpireWarnPollingInterval(value)
    M.settings.reimagined.expireWarning.pollingInterval = value
end

--- Retrieves the rune-related settings table with defaults as fallback.
--- This function accesses the current saved settings and their defaults,
--- prints debug info listing the keys in each rune settings table,
--- and returns the rune settings table with a metatable to fall back
--- to default values for missing keys.
---
--- @return table Rune settings with fallback to default rune settings
local function GetRuneSettings()
    local settings          = M.settings or {}                      -- Get current saved settings or empty table if missing
    local elements          = settings.reimagined.elements or {}    -- Access the 'elements' subtable in the 'reimagined' settings or fallback to empty table
    local runes             = elements.runes or {}                  -- Attempt to get runes settings from 'elements', but this line has a bug (should be 'elements' not 'reimagined')
    -- local runes             = reimagined.elements.runes or {}       -- Attempt to get runes settings from 'elements', but this line has a bug (should be 'elements' not 'reimagined')
    local defaults          = M.defaults or {}                      -- Get defaults or empty table if missing
    local defaultElements   = defaults.reimagined.elements or {}    -- Access default 'elements' in 'reimagined' or fallback to empty table
    local defaultRunes      = defaultElements.runes or {}           -- Get default rune settings from defaultElements or empty table

    -- Debug print keys of current rune settings table
    CC.Debug:Trace(2, "[Crux Counter Reimagined] runes table keys:")
    for k, v in pairs(runes) do
        CC.Debug:Trace(2, "  " .. tostring(k) .. " = " .. tostring(v))
    end

    -- Debug print keys of default rune settings table
    CC.Debug:Trace(2, "[Crux Counter Reimagined] defaultRunes table keys:")
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
            return CC.Language:GetString("SETTINGS_STYLE_HEADER")
        end,
        width = "full",
    },
    {
        -- Number
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
        -- Number Color
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
            if newColor then
                setElementColor("number", newColor)
            end
        end,
        default = getDefaultColor("number"),
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
        -- Crux Runes
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
        -- Rotate
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
        -- Crux Color
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
            if newColor then
                setElementColor("runes", newColor)
            end
        end,
        default = getDefaultColor("runes"),
        disabled = function()
            return not getElementEnabled("runes")
        end,
        width = "half",
    },
    {
        -- Rotation Speed
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
        -- Background
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
        -- Rotate
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
        -- Background Color
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
            if newColor then
                setElementColor("background", newColor)
            end
        end,
        default = getDefaultColor("background"),
        disabled = function()
            return not getElementEnabled("background")
        end,
        width = "half",
    },
    {
        -- Hide on Zero Stacks
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
            return CC.Language:GetString("SETTINGS_STYLE_REIMAGINED_HEADER")
        end,
        width = "full",
    },
    {
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
        default = M.defaults.reimagined.cruxDuration,
        width = "full",
    },
    {
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
        default = M.defaults.reimagined.expireWarning.pollingInterval,
        width = "full",
    },
    {
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
        default = M.defaults.reimagined.expireWarning.threshold,
        width = "full",
        disabled = function() return not getElementEnabled("runes") end,
    },
    {
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_NUMBER_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("number", true)  -- reimagined color
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            if newColor then
                setElementColor("number", newColor, true)  -- update reimagined color
            end
        end,
        default = getDefaultColor("number", true),
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
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_CRUX_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("runes", true)  -- reimagined color
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)
            if newColor then
                setElementColor("runes", newColor, true)  -- update reimagined color
            end
        end,
        default = getDefaultColor("runes", true),
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
        type = "colorpicker",
        name = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR")
        end,
        tooltip = function()
            return CC.Language:GetString("SETTINGS_STYLE_BACKGROUND_WARN_COLOR_DESC")
        end,
        getFunc = function()
            local color = getElementColor("background", true)  -- reimagined color
            return color:UnpackRGBA()
        end,
        setFunc = function(r, g, b, a)
            local newColor = ZO_ColorDef:New(r, g, b, a)

            if newColor then
                setElementColor("background", newColor, true)  -- update reimagined color
            end
        end,
        default = getDefaultColor("background", true),
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
        -- Sounds
        type = "header",
        name = function()
            return CC.Language:GetString("SETTINGS_SOUNDS_HEADER")
        end,
        width = "full",
    },
    {
        -- Crux Gained
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
        -- Maximum Crux
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
        -- Crux Lost
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

--- Get setting by key
--- If no such key exists, get the default value
--- @param element string Element setting to get
--- @return table elementSetting Settings for the element
function M:GetReimaginedElement(element)
    local elements = self:Get("reimagined")
    local selection = reimagined[element] or nil

    -- Bad and weird
    assert(selection ~= nil,
        zo_strformat("No loaded settings for element '<<1>>' found and no default settings exist", element))

    return selection
end

--- Setup settings
--- @return nil
function M:Setup()
    local addon   = CC.Addon
    self.settings = ZO_SavedVars:NewAccountWide(self.savedVariables, self.dbVersion, nil, self.defaults)

    populateSounds()

    addToMenu(displayOptions)
    addToMenu(styleOptions)
    addToMenu(soundOptions)

    LAM:RegisterAddonPanel(addon.name, {
        type               = "panel",
        name               = "Crux Counter (Reimagined)",
        displayName        = "Crux Counter (Reimagined)",
        author             = "Dim (@xDiminish)",
        version            = addon.version,
        registerForRefresh = true,
        slashCommand       = "/ccr",
    })
    LAM:RegisterOptionControls(addon.name, optionsData)

    CC.Debug:Trace(2, "Finished InitSettings()")
end

CC.Settings = M