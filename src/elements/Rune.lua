-- -----------------------------------------------------------------------------
-- Rune.lua
-- -----------------------------------------------------------------------------

local AM                = ANIMATION_MANAGER
local CC                = CruxCounterR
local orbitRadius       = 32

--- @class CruxCounterR_Rune
--- @field New fun(self, control: any, index: number)
CruxCounterR_Rune  = ZO_InitializingObject:Subclass()

local function CanPlayFullFlashAnimation()
    local outDuration   = CC.Settings:getFlashOutDuration()
    local inDuration    = CC.Settings:getFlashInDuration()
    local inDelay       = CC.Settings:getFlashInDelay()
    local remainingTime = CC.State:GetRemainingCruxTime()
    local animationTime = outDuration + inDuration + inDelay 
    
    return remainingTime >= animationTime
end

--- Initialize the Rune
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
    else
        CC.Debug:Trace(2, "WARNING: Rune control not found for Crux: <<1>>", tostring(num))
    end

    -- Setup flash timeline
    self.flashTimeline      = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_Flash", self.control)
    self.flashTimelineOut   = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_FlashOut", self.control)
    self.flashTimelineIn    = ANIMATION_MANAGER:CreateTimelineFromVirtual("CruxCounterR_FlashIn", self.control)

    self.flashTimeline:SetHandler("OnPlay", function()
        d("FlashTimeline is playing for rune " .. self.number)
    end)
    self.flashTimeline:SetHandler("OnStop", function()
        d("FlashTimeline is stopped for rune " .. self.number)
    end)

    self.flashTimelineOut:SetHandler("OnPlay", function()
        d("flashTimelineOut is playing for rune " .. self.number)
    end)
    self.flashTimelineOut:SetHandler("OnStop", function()
        d("flashTimelineOut is stopped for rune " .. self.number)

        local inDelay       = CC.Settings:getFlashInDelay()
        local inDuration    = CC.Settings:getFlashInDuration()
        local remainingTime = CC.State:GetRemainingCruxTime()
        local requiredTime  = inDelay + inDuration

        if remainingTime >= requiredTime then
            self:PlayFlashIn("CruxCounterR_Rune:SetWarnState")
            self.flashEnabled = true
        else
            d(string.format("Skipping flashTimelineIn: remainingTime %.2f < requiredTime %.2f", remainingTime, requiredTime))
        end
    end)

    self.flashTimelineIn:SetHandler("OnPlay", function()
        d("flashTimelineIn is playing for rune " .. self.number)
    end)
    self.flashTimelineIn:SetHandler("OnStop", function()
        d("flashTimelineIn is stopped for rune " .. self.number)
    end)
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

-- function CruxCounterR_Rune:PlayFlash(source)
--     d("PlayFlash called" .. (source and (" from " .. source) or ""))

--     if not self.flashEnabled or not self:IsShowing() then
--         d(string.format("Skipping flash for rune %d — %s", self.number, not self.flashEnabled and "flash disabled" or "not visible"))
--         return
--     end

--     if self.flashTimeline then
--         if not CC.Global.isFlashing then
--             CC.Global.isFlashing = true
--             d("Flash: On")
--         end

--         self.rune:SetAlpha(1)
--         self.flashTimeline:PlayFromStart()
--     end
-- end

function CruxCounterR_Rune:PlayFlashOut(source)
    d("PlayFlashOut called" .. (source and (" from " .. source) or ""))

    -- if not self.flashEnabled or not self:IsShowing() then
    --     d(string.format("Skipping flash out for rune %d — %s", self.number, not self.flashEnabled and "flash disabled" or "not visible"))
    --     return
    -- end

    if self.flashTimelineOut then
        if not CC.Global.isFlashing then
            CC.Global.isFlashing = true
        end

        self.rune:SetAlpha(1)
        self.flashTimelineOut:PlayFromStart()
    end
end

function CruxCounterR_Rune:PlayFlashIn(source)
    d("PlayFlashIn called" .. (source and (" from " .. source) or ""))

    -- if not self.flashEnabled or not self:IsShowing() then
    --     d(string.format("Skipping flash in for rune %d — %s", self.number, not self.flashEnabled and "flash disabled" or "not visible"))
    --     return
    -- end

    if self.flashTimelineIn then
        if not CC.Global.isFlashing then
            CC.Global.isFlashing = true
        end

        -- self.rune:SetAlpha(1)
        self.flashTimelineIn:PlayFromStart()
    end
end

function CruxCounterR_Rune:StopFlash(source)
    d("StopFlash called" .. (source and (" from " .. source) or ""))
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
function CruxCounterR_Rune:Hide(source)
    self.timelines.fadeOut:PlayFromStart()
    d("hide called" .. (source and (" from " .. source) or ""))
end

--- Hide the Rune instantly via the fadeOut animation
--- @return nil
function CruxCounterR_Rune:HideInstantly(source)
    self.timelines.fadeOut:PlayInstantlyToEnd()
    d("hide instantly called" .. (source and (" from " .. source) or ""))
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
-- function CruxCounterR_Rune:SetWarnState(state)
-- function CruxCounterR_Rune:SetWarnState(state)
--     if state then
--         if self.flashTimeline and not self.flashTimeline:IsPlaying() and self:IsShowing() then
--             local remaining = CC.State:GetRemainingCruxTime()
--             d("Remaining Crux Time: " .. string.format("%.2f", remaining) .. " seconds")

--             -- Only play flash if there's enough time left for the full animation
--             if CanPlayFullFlashAnimation() then
--                 self:PlayFlash("CruxCounterR_Rune:SetWarnState")
--                 self.flashEnabled = true
--             else
--                 d("Not enough buff time remaining to play full flash animation.")
--             end
--         end
--     else
--         if self.flashTimeline and self.flashTimeline:IsPlaying() then
--             d("Stopping flash animation because state is false")
--             -- You can also stop or reset the animation here if needed
--         end
--     end
-- end
function CruxCounterR_Rune:SetWarnState(state)
    if state then
        local outInactive = self.flashTimelineOut and not self.flashTimelineOut:IsPlaying()
        local inInactive  = self.flashTimelineIn and not self.flashTimelineIn:IsPlaying()

        if (outInactive or inInactive) and self:IsShowing() then
            local remaining = CC.State:GetRemainingCruxTime()

            d(string.format("Remaining Crux Time: %.2f seconds", remaining))

            if CanPlayFullFlashAnimation() then
                self:PlayFlashOut("CruxCounterR_Rune:SetWarnState")
                self.flashEnabled = true
            else
                d("Not enough buff time remaining to play full flash animation.")
            end
        end
    else
        local outPlaying = self.flashTimelineOut and self.flashTimelineOut:IsPlaying()
        local inPlaying  = self.flashTimelineIn and self.flashTimelineIn:IsPlaying()

        if outPlaying or inPlaying then
            d("Stopping flash animation because state is false")
            -- Optional: Stop the timelines
            -- self.flashTimelineOut:Stop()
            -- self.flashTimelineIn:Stop()
            --self.flashEnabled = false
        end
    end
end

--- Set delay and duration for all animations in a timeline
--- @param timeline AnimationTimeline
--- @param delay number
--- @param duration number
function CruxCounterR_Rune:SetTimelineAnimationTiming(timeline, duration, delay)
    if not timeline then
        d("[SetTimelineAnimationTiming] timeline is nil!")
        return
    end
    local numAnimations = timeline:GetNumAnimations()
    if numAnimations == 0 then
        d("[SetTimelineAnimationTiming] timeline has zero animations")
        return
    end

    for i = 1, numAnimations do
        local anim = timeline:GetAnimation(i)
        if anim then
            if type(anim.SetDelay) == "function" and type(anim.SetDuration) == "function" then
                anim:SetDelay(delay)
                anim:SetDuration(duration)
            else
                d(string.format("[SetTimelineAnimationTiming] Animation %d missing SetDelay or SetDuration method", i))
            end
        else
            d(string.format("[SetTimelineAnimationTiming] Animation %d is nil", i))
        end
    end
end

function CruxCounterR_Rune:SetFlashTiming(outDuration, inDuration, inDelay)
    self:SetTimelineAnimationTiming(self.flashOutTimeline, 0, outDuration)
    self:SetTimelineAnimationTiming(self.flashInTimeline, inDelay, inDuration)

    -- Store for later use in zo_callLater
    self.currentFlashInDelay = inDelay
end
