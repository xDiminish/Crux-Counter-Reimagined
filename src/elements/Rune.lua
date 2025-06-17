-- -----------------------------------------------------------------------------
-- Rune.lua
-- -----------------------------------------------------------------------------

local AM                = ANIMATION_MANAGER
local CC                = CruxCounterR
local orbitRadius       = 32

--- @class CruxCounterR_Rune
--- @field New fun(self, control: any, index: number)
CruxCounterR_Rune  = ZO_InitializingObject:Subclass()

--- Initialize the Aura
--- @param control any Element control
--- @param num number Rune index
--- @return nil
function CruxCounterR_Rune:Initialize(control, num)
    self.control            = control
    self.number             = num
    self.startingRotation   = 360 - (360 / num)
    
    self.control:SetHidden(true)
    self.control:SetAlpha(0)

    self.smoke = {
        control     = self.control:GetNamedChild("Smoke"),
        timeline    = AM:CreateTimelineFromVirtual("CruxCounterR_CruxSmokeDontBreatheThis", 
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

    self.timelines.fadeIn:SetHandler("OnPlay", function()
        -- Show control immediately so it participates in fadeIn alpha animation
        self.control:SetHidden(false)

        self.smoke.timeline:PlayFromStart()
        self:PlaySpin()
    end)

    self.timelines.fadeOut:SetHandler("OnStop", function()
        self:SetRotation2D(self.startingRotation)
        self.smoke.timeline:Stop()
        self:StopSpin()

        CC.Display:ResetUI()

        -- Hide the control to fully remove from UI after fade out
        self.control:SetHidden(true)
    end)

    control.OnHidden = function()
        self.smoke.timeline:Stop()
    end

    control.OnShow = function()
        self.smoke.timeline:PlayFromStart()
    end

    self.spinTimeline = nil
    local runeControl = self.rune

    if runeControl then
        -- Assign spinTimeline based on rune number
        if num % 2 == 1 then
            -- Odd runes: clockwise
            self.spinTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_SpinCruxCW", self.rune)
        else
            -- Even runes: counterclockwise
            self.spinTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_SpinCruxCCW", self.rune)
        end
    else
        CC.Debug:Trace(2, "WARNING: Rune control not found for Crux: <<1>>", tostring(num))
    end
end

--- Starts the rune spin animation with a staggered delay based on the rune's index.
--- @return nil
function CruxCounterR_Rune:PlaySpin()
    if not CC.Settings:getRuneSpinAnimationEnabled() then return end

    if self.spinTimeline then
        self.spinTimeline:Stop() -- stop first in case it's mid-spin
        self.spinTimeline:PlayFromStart()
    end
end

--- Stops the rune spin animation immediately.
--- @return nil
function CruxCounterR_Rune:StopSpin()
    if self.spinTimeline then
        self.spinTimeline:PlayInstantlyToStart()
        self.spinTimeline:Stop()
    end
end

--- Set the color of the Rune elements
--- @param color ZO_ColorDef
--- @return nil
function CruxCounterR_Rune:SetColor(color)
    if not self.rune or not self.glow or not self.smoke or not self.smoke.control then
        CC.Debug:Trace(3, "[CruxCounterR_Rune] ERROR: one or more controls are nil in SetColor")

        return
    end

    CC.Debug:Trace(3, string.format("Rune SetColor called with RGBA = %.2f, %.2f, %.2f, %.2f", color:UnpackRGBA()))

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
    -- Make control visible immediately to allow fadeIn alpha animation to play
    self.control:SetHidden(false)
    self.timelines.fadeIn:PlayFromStart()
end

--- Hide the Rune via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:Hide()
    -- Play fadeOut animation, control will be hidden at animation end
    self.timelines.fadeOut:PlayFromStart()
end

--- Hide the Rune instantly via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:HideInstantly()
    self.timelines.fadeOut:Stop()
    self.control:SetHidden(true)
    self.control:SetAlpha(0)  -- reset alpha
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
    local x, y      = ZO_Rotate2D(math.rad(degrees), 0, orbitRadius)
    local parent    = self.control:GetParent()

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
    return not self.control:IsHidden()
end