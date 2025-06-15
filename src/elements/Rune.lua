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
    self.control = control
    self.number = num
    self.startingRotation = 360 - (360 / num)

    --local cruxCount = CC.State:GetCruxCount()
    --self.startingRotation = (360 / 2) * (num - 1)

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
        fadeIn      = AM:CreateTimelineFromVirtual("CruxCounterR_CruxFadeIn", self.control),
        fadeOut     = AM:CreateTimelineFromVirtual("CruxCounterR_CruxFadeOut", self.control),
        rotation    = AM:CreateTimelineFromVirtual("CruxCounterR_RotateControlCW", self.control),
        swoop    = swoopTimeline,
    }

    self.timelines.fadeOut:SetHandler("OnStop", function()
        self:SetRotation2D(self.startingRotation)
        self.smoke.timeline:Stop()
        
        -- Stop spin animatation
        self:StopSpin()

        -- Reset colors after fading out
        CC.Display:ResetUI()
    end)

    self.timelines.fadeIn:SetHandler("OnPlay", function()
        self.smoke.timeline:PlayFromStart()
        self:PlaySpin()
    end)

    control.OnHidden = function()
        self.smoke.timeline:Stop()
    end

    control.OnShow = function()
        self.smoke.timeline:PlayFromStart()
    end

    self.spinTimeline   = nil
    self.flashTimeline  = nil
    local runeControl   = self.rune

    if runeControl then
        -- Assign spinTimeline based on rune number
        if num % 2 == 1 then
            -- Odd runes: clockwise
            self.spinTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_SpinCruxCW", self.rune)
        else
            -- Even runes: counterclockwise
            self.spinTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_SpinCruxCCW", self.rune)
        end

        self.flashTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_Flash", self.rune)
        --d("Flash animation timeline created!")
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

function CruxCounterR_Rune:PlayFlash()
    if self.flashTimeline then
        if not CC.Global.isFlashing then
            CC.Global.isFlashing = true
            d("Flash: On")
        end

        self.rune:SetAlpha(1)
        self.flashTimeline:PlayFromStart()
    end
end

function CruxCounterR_Rune:StopFlash()
    if self.flashTimeline then
        if CC.Global.isFlashing then
            CC.Global.isFlashing = false
            d("Flash: Off")
        end

        self.flashTimeline:Stop()
        --self.control:SetAlpha(1) -- ensure full visibility when stopped
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
    self.timelines.fadeIn:PlayFromStart()
end

--- Hide the Rune via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:Hide()
    self.timelines.fadeOut:PlayFromStart()
end

--- Hide the Rune instantly via the fadeOut animation
--- @return nil
-- function CruxCounterR_Rune:HideInstantly()
--     self.timelines.fadeOut:PlayInstantlyToEnd()
-- end
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
    d("alpha: " .. self.control:GetAlpha())
    return self.control:GetAlpha() == 1
end

--- Update rune color based on elapsed time
--- @param self any
--- @param elapsedSec number
--- @param baseSettings table
function CruxCounterR_Rune:UpdateColorBasedOnElapsed(elapsedSec, baseSettings)
    CruxCounterR.Utils.UpdateColorBasedOnElapsed(elapsedSec, baseSettings, "runes", function(color)
        self:SetColor(color)
    end)
end

--- Enable or disable warning flash effect
--- @param state boolean True to start flashing, false to stop
function CruxCounterR_Rune:SetWarnState(state)
    if state then
        d("Setting state to true")
        if self.flashTimeline and not self.flashTimeline:IsPlaying() then
            self:PlayFlash()
        end
    else
        d("Setting state to false")
        if self.flashTimeline and self.flashTimeline:IsPlaying() then
            self:StopFlash()
        end
    end
end