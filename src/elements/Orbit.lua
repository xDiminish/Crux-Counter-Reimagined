-- -----------------------------------------------------------------------------
-- Orbit.lua
-- -----------------------------------------------------------------------------

local AM          = ANIMATION_MANAGER
local CC          = CruxCounterR
local Rune        = CruxCounterR_Rune

--- @class CruxCounterR_Orbit
--- @field New fun(self, control: any, index: number)
CruxCounterR_Orbit = ZO_InitializingObject:Subclass()

--- Initialize the Aura
--- @param control any Element control
--- @return nil
function CruxCounterR_Orbit:Initialize(control)
    self.control = control
    self.runes = {}

    local settings = CC.Settings:GetElement("runes")
    self.enabled = settings.enabled
    self.rotationEnabled = settings.rotate
    self.rotationSpeed = settings.rotationSpeed

    self:InitializeRunes()

    self.timeline = AM:CreateTimelineFromVirtual("CruxCounterR_RotateControlCCW", self.control)

    self.timeline:SetHandler("OnPlay", function()
        self:ForRunes(function(_, rune)
            rune:PlayRotation()
        end)
    end)

    self.timeline:SetHandler("OnStop", function()
        self:ForRunes(function(_, rune)
            rune:StopRotation()
        end)
    end)
end

--- Apply settings to the Orbit
--- @return nil
function CruxCounterR_Orbit:ApplySettings()
    local runes = CC.Settings:GetElement("runes")

    self:SetEnabled(runes.enabled)
    self:SetRotationEnabled(runes.rotate)
    self:SetRotationDuration(runes.rotationSpeed)
    self:SetColor(ZO_ColorDef:New(runes.color))
end

--- Set whether or not the Orbit is enabled
--- @param enabled boolean True to enable
--- @return nil
function CruxCounterR_Orbit:SetEnabled(enabled)
    self.enabled = enabled
    self:SetHidden(not enabled)
end

--- Set the Orbit color
--- @param color ZO_ColorDef
--- @return nil
function CruxCounterR_Orbit:SetColor(color)
    self:ForRunes(function(_, rune)
        rune:SetColor(color)
    end)
end

--- Set whether or not rotation is enabled
--- @param rotationEnabled boolean True to enable rotation
--- @return nil
function CruxCounterR_Orbit:SetRotationEnabled(rotationEnabled)
    self.rotationEnabled = rotationEnabled

    if self.enabled and rotationEnabled then
        self:PlayFromStart()
    else
        self:Stop()
    end
end

--- Set the hidden state of the element
--- @param hidden boolean True to hide the element
--- @return nil
function CruxCounterR_Orbit:SetHidden(hidden)
    self.control:SetHidden(hidden)

    if not hidden and self.enabled and self.rotationEnabled then
        self:PlayFromStart()
    else
        self:Stop()
    end
end

--- Run a callback on each of the Rune elements within the Orbit
--- @param callback fun(index: number, rune: CruxCounterR_Rune): nil Callback to execute for each Rune
--- @return nil
function CruxCounterR_Orbit:ForRunes(callback)
    for index, rune in ipairs(self.runes) do
        callback(index, rune)
    end
end

--- Update the Crux count
--- @param count number Number of Crux active
--- @return nil
function CruxCounterR_Orbit:UpdateCount(count)
    if count == 0 then
        -- Fade out all
        self:ForRunes(function(_, rune)
            if rune:IsShowing() then
                rune:Hide()
            else
                rune:HideInstantly()
            end
        end)

        return
    end

    -- Make sure to show as many as there are stacks
    for i = 1, count, 1 do
        local rune = self.runes[i]
        if not rune:IsShowing() then
            rune:Show()
        end
    end

    -- Move 2nd rune to make room for the third
    if count == 3 then
        local rune = self.runes[2]
        rune:PlayPositionShift()
    end
end

--- Set the Orbit rotation animation duration
--- @param duration number Milliseconds for a full rotation
--- @return nil
function CruxCounterR_Orbit:SetRotationDuration(duration)
    self.rotationSpeed = duration

    for _, rune in ipairs(self.runes) do
        rune:SetDuration(duration)
    end

    self.timeline:GetFirstAnimation():SetDuration(duration)
end

--- Play the Orbit rotation animation
--- The OnPlay handler plays the Rune animations
--- @return nil
function CruxCounterR_Orbit:PlayFromStart()
    self.timeline:PlayFromStart()
end

--- Stop the Orbit rotation animation
--- The OnStop handler stops the Rune animations
--- @return nil
function CruxCounterR_Orbit:Stop()
    self.timeline:PlayInstantlyToStart(false)
    self.timeline:Stop()
end

--- Initialize the Runes within the Orbit element.
--- Iterates through each child control named "Crux1", "Crux2", etc.,
--- creates a Rune instance for each, and stores them in self.runes.
--- @return nil
function CruxCounterR_Orbit:InitializeRunes()
    -- Loop through each child control of the main control
    for i = 1, self.control:GetNumChildren(), 1 do
        -- Retrieve the child control named "Crux" concatenated with the index (r.g. "Crux1", "Crux2", etcc)
        local child = self.control:GetNamedChild("Crux" .. i)

        -- Create a new Rune instance using the child control and the current index i
        -- Store the new Rune object in the runes table at position i
        self.runes[i] = Rune:New(child, i)
    end
end
