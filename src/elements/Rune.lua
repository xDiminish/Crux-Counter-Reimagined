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

local function EnsureColorDef(color)
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

--- Update a rune color based on elapsed time
--- @return nil
-- function CruxCounterR_Rune:UpdateColorBasedOnElapsed(elapsedSec, settings)
--     if not settings then
--         d("[CruxCounter] ERROR: settings is nil")
--         return
--     end

--     local runeSettings = settings.elements and settings.elements.runes
--     if not runeSettings then
--         d("[CruxCounter] ERROR: settings.elements.runes is nil")
--         return
--     end

--     local baseColor = EnsureColorDef(runeSettings.color) or ZO_ColorDef:New(0.7176, 1, 0.4862, 1)
--     local warnColor = EnsureColorDef(runeSettings.expireWarnColor) or ZO_ColorDef:New(1, 0, 0, 1)

--     local totalDurationSec = settings.cruxDuration or 30
--     local warningThresholdRemainingSec = runeSettings.expireWarnThreshold or 25
--     local warningElapsedSec = totalDurationSec - warningThresholdRemainingSec

--     local epsilon = 0.1 -- 100 ms margin
--     if elapsedSec + epsilon >= warningElapsedSec - 1 then
--         self:SetColor(warnColor)
--     else
--         self:SetColor(baseColor)
--     end
-- end
function CruxCounterR_Rune:UpdateColorBasedOnElapsed(elapsedSec, settings)
    if not settings then
        d("[CruxCounter] ERROR: settings is nil")
        return
    end

    local runeSettings = settings.elements and settings.elements.runes
    if not runeSettings then
        d("[CruxCounter] ERROR: settings.elements.runes is nil")
        return
    end

    local baseColor = EnsureColorDef(runeSettings.color) or ZO_ColorDef:New(0.7176, 1, 0.4862, 1)
    local warnColor = EnsureColorDef(runeSettings.reimagined.expireWarnColor) or ZO_ColorDef:New(1, 0, 0, 1)

    local totalDurationSec = settings.cruxDuration or 30
    local warningThresholdRemainingSec = runeSettings.reimagined.expireWarnThreshold or 25
    local warningElapsedSec = totalDurationSec - warningThresholdRemainingSec

    local epsilon = 0.1 -- 100 ms margin
    if elapsedSec + epsilon >= warningElapsedSec - 1 then
        self:SetColor(warnColor)
    else
        self:SetColor(baseColor)
    end
end