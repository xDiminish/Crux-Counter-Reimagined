-- -----------------------------------------------------------------------------
-- Debug.lua
-- -----------------------------------------------------------------------------

local CC = CruxCounterR
local M  = {}

--- @type integer Current debug level
---               0: Off    - No debug messages
--                1: Low    - Basic debug info, show core functionality
--                2: Medium - More information about skills and addon details
--                3: High   - Everything
M.level  = 0

--- Write a message to game chat
--- @param ... any Message to output
--- @return nil
function M:Say(...)
    local prefix = "[" .. CC.Addon.name .. "] "

    d(prefix .. zo_strformat(...))
end

--- Output a trace if the level is within the current debug level.
--- @param level integer Level to debug
--- @param ... any Information to trace
--- @return nil
function M:Trace(level, ...)
    if level <= self.level then
        self:Say(...)
    end
end

--- Write a message to game chat later
--- @param delayMs integer Milliseconds to delay output
--- @param ... any Message to output
--- @return nil
function M:SayLater(delayMs, ...)
    local args = ...

    zo_callLater(function()
        self:Say(args)
    end, delayMs)
end

--- Helper to print RGBA values of a color
--- @param label string - A descriptive label
--- @param color ZO_ColorDef or nil
function M:PrintColor(label, color)
    if not color then
        self:Trace(2, "%s: nil", label)
        
        return
    end

    -- Unpack the color into individual red, green, blue, and alpha components
    -- Each component is a number between 0 and 1
    local r, g, b, a = color:UnpackRGBA()

    self:Trace(2, "%s: r=%.2f g=%.2f b=%.2f a=%.2f", label, r, g, b, a)
end

--- Converts all arguments to strings, replacing any `nil` with the string "nil".
--- Useful for safely printing or passing values into formatted debug/log output
--- without causing errors due to unexpected `nil` values.
---
--- @vararg any The list of arguments to convert to strings
--- @return ... The converted arguments as strings, unpacked in order
function M:PrintSafe(...)
    local out = {}

    for i = 1, select("#", ...) do
        local val = select(i, ...)

        if val == nil or val == "" then
            out[i] = "nil"
        else
            out[i] = tostring(val)
        end
    end

    return unpack(out)
end

CC.Debug = M