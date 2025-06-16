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
    self.isShown = false

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
        self.isShown = false
        self.forceHidden = false
        self:SetRotation2D(self.startingRotation)
        self.smoke.timeline:Stop()
        
        -- Stop spin animatation
        self:StopSpin()

        -- Reset colors after fading out
        CC.Display:ResetUI()

        self.forceFadeOut = false
    end)

    self.timelines.fadeIn:SetHandler("OnPlay", function()
        self.isShown = true
        self.smoke.timeline:PlayFromStart()
        self:PlaySpin()

        if self.pendingFlash then
            self:PlayFlash("fadeIn handler")
            self.pendingFlash = false
        end
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

    ------------------------------------------------------------------
    -- flashTimeline Handlers
    ------------------------------------------------------------------
    self.flashTimeline:SetHandler("OnPlay", function()
        d("FlashTimeline is playing for rune " .. self.number)

        if self.forceHidden then
            self.flashTimeline:Stop()
            self:SetAlpha(0)
            d("flashTimeline cancelled because rune was forcibly hidden")
        end
    end)

      self.flashTimeline:SetHandler("OnStop", function()
        d("FlashTimeline is stopped for rune " .. self.number)

        if self.flashSuppressed then
            d("FlashTimeline ended but was suppressed — skipping visibility restore")
            self.flashSuppressed = false
            return
        end

        if self.forceFlashHide or self.forceHidden then
            d("FlashTimeline ended while rune was force-hidden (flash or forced)")
            self.control:SetHidden(true)
            return
        end

        local cruxCount = CC.State:GetCruxCount()
        if self.number <= cruxCount then
            d("FlashTimeline ended — rune should be visible")
            self.control:SetHidden(false)
        else
            d("FlashTimeline ended — rune should be hidden")
            self.control:SetHidden(true)
        end
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

function CruxCounterR_Rune:PlayFlash(source)
    d("PlayFlash called" .. (source and (" from " .. source) or ""))

    if self.forceHidden then
        d("PlayFlash blocked: rune is force-hidden")
        return
    end

    local remainingTime = CC.State:GetRemainingCruxTime()
    if not remainingTime or remainingTime <= 0.15 then
        d("PlayFlash blocked: Crux already expired or expiring soon")
        return
    end

    if self.flashTimeline:IsPlaying() then
        self.flashTimeline:Stop()
    end

    self.flashTimeline:PlayFromStart()
end

------------------------------------------------------------
-- StopFlash
------------------------------------------------------------
function CruxCounterR_Rune:StopFlash(source)
    d("StopFlash called" .. (source and (" from " .. source) or ""))
end

------------------------------------------------------------
-- StopFlashOut
------------------------------------------------------------
function CruxCounterR_Rune:StopFlashOut(source)
    d("StopFlashOut called" .. (source and (" from " .. source) or ""))
end

------------------------------------------------------------
-- StopFlashIn
------------------------------------------------------------
function CruxCounterR_Rune:StopFlashIn(source)
    d("StopFlashIn called" .. (source and (" from " .. source) or ""))
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

    if self.pendingFlash and self:IsShowing() then
        self:PlayFlash("Show() fallback")
        self.pendingFlash = false
    end
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
    self.flashSuppressed = true

    if self.flashTimeline and self.flashTimeline:IsPlaying() then
        self.flashTimeline:Stop()
    end

    self.forceFlashHide = true
    self.forceHidden = true
    self.pendingFlash = false

    self.control:SetHidden(true)  -- << Use this instead of SetAlpha(0)
    d("HideInstantly called" .. (source and (" from " .. source) or ""))
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
    -- return self.control:GetAlpha() == 1
    -- d("Rune " .. self.number .. " IsShowing = " .. tostring(self.isShown))
    local alpha = self.control:GetAlpha()
    local shown = self.isShown or (alpha == 1)
    d("Rune " .. self.number .. " IsShowing = " .. tostring(shown) .. " (self.isShown=" .. tostring(self.isShown) .. ", alpha=" .. alpha .. ")")
    return shown
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
    local cruxCount = CC.State:GetCruxCount() or 0

    if self.forceHidden then
        d("SetWarnState aborted: rune is force-hidden")
        return
    end

    if state then
        -- 💥 New: skip flash if Crux already expired or about to
        local remainingTime = CC.State:GetRemainingCruxTime()
        if not remainingTime or remainingTime <= 0.15 then
            d("Flash skipped: crux expired or about to expire")
            return
        end

        -- Only flash if this rune number is <= crux count (active)
        if self.number <= cruxCount then
            if self.flashTimeline and not self.flashTimeline:IsPlaying() then
                if self:IsShowing() then
                    self:PlayFlash("SetWarnState")
                else
                    self.pendingFlash = true
                    d("Queued flash animation — rune not yet shown")

                    if not self.timelines.fadeIn:IsPlaying() and not self.timelines.fadeOut:IsPlaying() then
                        self:Show()
                    end
                end
            end
        else
            d(string.format("Rune %d is beyond crux count %d — not flashing", self.number, cruxCount))
        end
    else
        self.pendingFlash = false
        if self.flashTimeline and self.flashTimeline:IsPlaying() then
            d("Stopping flash animation because state is false")
            self.flashTimeline:Stop()
        end
    end
end

function CruxCounterR_Rune:SetAlphaAll(alpha)
    self.control:SetAlpha(alpha)
    local glow = self.control:GetNamedChild("Glow")
    if glow then glow:SetAlpha(alpha) end
    local smoke = self.control:GetNamedChild("Smoke")
    if smoke then smoke:SetAlpha(alpha) end
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

--- Refresh rune visibility based on current Crux count
function CruxCounterR_Rune:RefreshVisibility()
    if self.shouldBeVisible then
        if not self:IsShowing() then
            self:Show()
        end
    else
        if self:IsShowing() then
            self:HideInstantly()
        end
    end
end
