-- -----------------------------------------------------------------------------
-- Rune.lua
-- -----------------------------------------------------------------------------

local AM          = ANIMATION_MANAGER
local orbitRadius = 32

--- @class CruxCounterR_Rune
--- @field New fun(self, control: any, index: number)
CruxCounterR_Rune  = ZO_InitializingObject:Subclass()

--- Initialize the Aura
--- @param control any Element control
--- @param num number Rune index
--- @return nil
function CruxCounterR_Rune:Initialize(control, num)
    self.control = control
    self.number = num
    self.startingRotation = 360 - (360 / num)

    self.smoke = {
        control = self.control:GetNamedChild("Smoke"),
        timeline = AM:CreateTimelineFromVirtual("CruxCounterR_CruxSmokeDontBreatheThis",
            self.control:GetNamedChild("Smoke")),
    }
    self.glow = self.control:GetNamedChild("Glow")
    self.rune = self.control:GetNamedChild("Rune")

    self:SetRotation2D(self.startingRotation)

    local swoopAnimation, swoopTimeline = CreateSimpleAnimation(ANIMATION_CUSTOM, self.control)
    if swoopAnimation and swoopTimeline then
        swoopAnimation:SetEasingFunction(ZO_EaseOutQuadratic)
        swoopAnimation:SetUpdateFunction(function(_, progress)
            local rotation = self.startingRotation - 60 * progress
            self:SetRotation2D(rotation)
        end)
        swoopAnimation:SetDuration(250)
    end

    self.timelines = {
        fadeIn   = AM:CreateTimelineFromVirtual("CruxCounterR_CruxFadeIn", self.control),
        fadeOut  = AM:CreateTimelineFromVirtual("CruxCounterR_CruxFadeOut", self.control),
        rotation = AM:CreateTimelineFromVirtual("CruxCounterR_RotateControlCW", self.control),
        swoop    = swoopTimeline,
    }

    self.timelines.fadeOut:SetHandler("OnStop", function()
        self:SetRotation2D(self.startingRotation)
        self.smoke.timeline:Stop()
    end)

    self.timelines.fadeIn:SetHandler("OnPlay", function()
        self.smoke.timeline:PlayFromStart()
    end)

    control.OnHidden = function()
        self.smoke.timeline:Stop()
    end

    control.OnShow = function()
        self.smoke.timeline:PlayFromStart()
    end
end

--- Set the color of the Rune elements
--- @param color ZO_ColorDef
--- @return nil
function CruxCounterR_Rune:SetColor(color)
    self.rune:SetColor(color:UnpackRGBA())
    self.glow:SetColor(color:UnpackRGBA())
    self.smoke.control:SetColor(color:UnpackRGBA())
end

--- Play the Rune rotation animation
--- @return nil
function CruxCounterR_Rune:PlayRotation()
    self.timelines.rotation:PlayFromStart()
end

--- Stop the Rune rotation animation
--- @return nil
function CruxCounterR_Rune:StopRotation()
    self.timelines.rotation:PlayInstantlyToStart(false)
    self.timelines.rotation:Stop()
end

--- Show the Rune via the fadeIn animation
--- @return nil
function CruxCounterR_Rune:Show()
    self.timelines.fadeIn:PlayFromStart()
end

--- Hide the Rune via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:Hide()
    self.timelines.fadeOut:PlayFromStart()
end

--- Hide the Rune instantly via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:HideInstantly()
    self.timelines.fadeOut:PlayInstantlyToEnd()
end

--- Play the position shift swoop animation
--- @return nil
function CruxCounterR_Rune:PlayPositionShift()
    self.timelines.swoop:PlayFromStart()
end

--- Set the position of the Rune
--- @param degrees number Amount to rotate the Rune in degrees
--- @return nil
function CruxCounterR_Rune:SetRotation2D(degrees)
    local x, y = ZO_Rotate2D(math.rad(degrees), 0, orbitRadius)
    local parent = self.control:GetParent()
    self.control:SetAnchor(CENTER, parent, CENTER, x, y)
end

--- Set the Rune rotation animation duration
--- @return nil
function CruxCounterR_Rune:SetDuration(duration)
    self.timelines.rotation:GetFirstAnimation():SetDuration(duration)
end

--- Is the Rune element showing?
--- @return boolean showing True when the Rune is showing
function CruxCounterR_Rune:IsShowing()
    return self.control:GetAlpha() == 1
end

--- Update a rune color based on elapsed time
--- @return nil
-- function CruxCounterR_Rune:UpdateColorBasedOnElapsed(elapsedMs)
--     local totalDurationMs = 30000 -- assumed Crux duration is 30s
--     local warningThresholdRemainingMs = 25000
--     local warningElapsedMs = totalDurationMs - warningThresholdRemainingMs -- = 5000ms
--     local lightGreen = ZO_ColorDef:New(0.7176470588, 1, 0.4862745098, 1)
--     local red = ZO_ColorDef:New(1, 0, 0, 1)

--     if elapsedMs >= warningElapsedMs then
--         self:SetColor(red)
--     else
--         self:SetColor(lightGreen)
--     end
-- end
function CruxCounterR_Rune:UpdateColorBasedOnElapsed(elapsedSec)
    local rune = GetRuneSettings()
    if not rune then
        d("[CruxCounter] Rune settings missing!")
        return
    end

    -- Duration of crux before it expires
    local totalDurationSec = M.settings.cruxDuration or M.defaults.cruxDuration or 30

    -- How long before expiration to start warning
    local warnThresholdSec = rune.expireWarnThreshold or 5
    local warnStartTimeSec = totalDurationSec - warnThresholdSec

    -- Normal color fallback (greenish)
    local normalColor = rune.color or ZO_ColorDef:New(0.7176, 1, 0.4862, 1)

    -- Warning color fallback (red)
    local warnColorTable = rune.expireWarnColor or { r = 1, g = 0, b = 0, a = 1 }
    local warnColor = ZO_ColorDef:New(warnColorTable.r, warnColorTable.g, warnColorTable.b, warnColorTable.a)

    if elapsedSec >= warnStartTimeSec then
        self:SetColor(warnColor)
    else
        self:SetColor(normalColor)
    end
end



