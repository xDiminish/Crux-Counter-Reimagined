-- -----------------------------------------------------------------------------
-- Aura.lua
-- -----------------------------------------------------------------------------

local WM         = WINDOW_MANAGER
local CC         = CruxCounterR
local Orbit      = CruxCounterR_Orbit
local Ring       = CruxCounterR_Ring

--- @class CruxCounterR_Aura
--- @field New fun(self, control: any)
CruxCounterR_Aura = ZO_InitializingObject:Subclass()

--- Initialize the Aura
--- @param control any Element control
--- @return nil
function CruxCounterR_Aura:Initialize(control)
    self.control = control
    self.fragment = nil
    self.hideOutOfCombat = CC.Settings:Get("hideOutOfCombat")
    self.locked = CC.Settings:Get("locked")

    self.ring = Ring:New(control:GetNamedChild("BG"))
    self.orbit = Orbit:New(control:GetNamedChild("Orbit"))
    self.count = control:GetNamedChild("Count")

    self:SetHandlers()

    local oldSetHidden = self.control.SetHidden
    self.control.SetHidden = function(ctrl, hidden)
        CC.Debug:Trace(2, "SetHidden(<<1>>) called", tostring(hidden))

        oldSetHidden(ctrl, hidden)
    end
end

--- Set whether or not the Number element disable is enabled
--- @param enabled boolean True to enable the element
--- @return nil
function CruxCounterR_Aura:SetNumberEnabled(enabled)
    self.count:SetHidden(not enabled)
end

--- Set the color of the Number element
--- @param color ZO_ColorDef
--- @return nil
function CruxCounterR_Aura:SetNumberColor(color)
    if not self.control then
        CC.Debug:Trace(3, "[CruxCounterR_Aura] ERROR: self.control is nil")
        return
    end

    CC.Debug:Trace(3, string.format("Aura SetNumberColor called with RGBA = %.2f, %.2f, %.2f, %.2f", color:UnpackRGBA()))

    self.count:SetColor(color:UnpackRGBA())
end

--- Apply settings to the Aura
--- @return nil
function CruxCounterR_Aura:ApplySettings()
    local settings = CC.Settings:Get()

    -- Aura settings
    self:SetPosition(settings.top, settings.left)
    self:SetMovable(not settings.locked)
    self:SetSize(settings.size)

    -- Combat settings
    CC.Events:UpdateCombatState()

    -- Other control settings
    local number = CC.Settings:GetElement("number")
    self:SetNumberEnabled(number.enabled)
    self:SetNumberColor(ZO_ColorDef:New(number.color))
    self.ring:ApplySettings()
    self.orbit:ApplySettings()
end

--- Hide the counter display
--- @return nil
function CruxCounterR_Aura:Hide()
    CC.Debug:Trace(1, "Hide() called")

    HUD_UI_SCENE:RemoveFragment(self.fragment)
    HUD_SCENE:RemoveFragment(self.fragment)
end

--- Show/unhide the counter display
--- @return nil
function CruxCounterR_Aura:Unhide()
    CC.Debug:Trace(1, "Unhide() called")

    HUD_UI_SCENE:AddFragment(self.fragment)
    HUD_SCENE:AddFragment(self.fragment)
end

--- Show or hide the aura based on visibility flag
--- @param isVisible boolean
--- @return nil
function CruxCounterR_Aura:SetVisible(isVisible)
    CC.Debug:Trace(2, "SetVisible called with: <<1>>", tostring(isVisible))

    if isVisible then
        if not self.fragment then
            self:AddSceneFragments()
        end

        self.control:SetHidden(false)
    else
        if self.fragment then
            self:RemoveSceneFragments()
        end
        
        self.control:SetHidden(true)
    end

    -- Debug
    zo_callLater(function()
        CC.Debug:Trace(3, "HUD_UI_SCENE state: <<1>>", tostring(HUD_UI_SCENE:IsShowing()))
        CC.Debug:Trace(3, "HUD_SCENE state: <<1>>", tostring(HUD_SCENE:IsShowing()))
        CC.Debug:Trace(3, "IsHidden after 500ms: <<1>>", tostring(self.control:IsHidden()))
    end, 500)
end

--- Set the Aura position
--- @param top number Top position
--- @param left number Left position
--- @return nil
function CruxCounterR_Aura:SetPosition(top, left)
    self.control:ClearAnchors()
    self.control:SetAnchor(CENTER, GuiRoot, CENTER, left, top)
end

--- Move the Aura to center
--- @return nil
function CruxCounterR_Aura:MoveToCenter()
    self:SetPosition(0, 0)
end

--- Setup handlers for the Aura
--- @return nil
function CruxCounterR_Aura:SetHandlers()
    self.control.OnMoveStop = function()
        CC.Debug:Trace(3, "Aura OnMoveStop")

        local centerX, centerY              = self.control:GetCenter()
        local parentCenterX, parentCenterY  = self.control:GetParent():GetCenter()
        local top, left                     = centerY - parentCenterY, centerX - parentCenterX

        CC.Debug:Trace(3, "Top: <<1>> Left: <<2>>", top, left)

        CC.Settings:SavePosition(top, left)
    end

    self.control:SetHandler("OnMouseEnter", function()
        if CC.Settings:Get("locked") then return end

        WM:SetMouseCursor(MOUSE_CURSOR_PAN)
    end)

    self.control:SetHandler("OnMouseExit", function()
        if CC.Settings:Get("locked") then return end

        WM:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    end)
end

--- Set the counter display size
--- @param size number Counter size in (roughly) pixels, is divided by the default size to set the float scale amount
--- @return nil
function CruxCounterR_Aura:SetSize(size)
    self:SetScale(size / CC.Settings:GetDefault("size"))
end

--- Set the scale of the counter display
--- @param scale number Float scaling value
--- @return nil
function CruxCounterR_Aura:SetScale(scale)
    self.control:SetScale(scale)
end

--- Setup scenes the addon should appear
--- @return nil
function CruxCounterR_Aura:AddSceneFragments()
    CC.Debug:Trace(2, "Adding scene fragments")

    local fragment = ZO_SimpleSceneFragment:New(self.control)
    
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    
    self.fragment = fragment
end

-- --- Remove fragments from scenes
-- --- @return nil
function CruxCounterR_Aura:RemoveSceneFragments()
    if self.fragment then
        CC.Debug:Trace(2, "Removing scene fragments")

        HUD_UI_SCENE:RemoveFragment(self.fragment)
        HUD_SCENE:RemoveFragment(self.fragment)
        
        self.fragment = nil
    end
end

--- Update the elements with a new count
--- @return nil
function CruxCounterR_Aura:UpdateCount(count)
    CC.Debug:Trace(1, "Updating Aura count to <<1>>", count)

    self.count:SetText(count)
    self.orbit:UpdateCount(count)
    self.ring:UpdateCount(count)
end

--- Set whether or not the Aura can be moved
--- @param movable boolean True enable moving
--- @return nil
function CruxCounterR_Aura:SetMovable(movable)
    CC.Debug:Trace(2, "Setting movable <<1>>", movable)

    self.locked = not movable
    self.control:SetMovable(movable)
end

--- Initialization of the Aura display
--- @return nil
function CruxCounterR_Aura_OnInitialized(control)
    CruxCounterR_Display = CruxCounterR_Aura:New(control)

    -- Now safe to call ReevaluateVisibility
    CC.Events:ReevaluateVisibility()
end

--- When the Aura has stopped moving, handle the move
--- @return nil
function CruxCounterR_Aura_OnMoveStop(self)
    self.OnMoveStop()
end

--- Update aura number color based on elapsed time
--- @param self any
--- @param elapsedSec number
--- @param baseSettings table
function CruxCounterR_Aura:UpdateColorBasedOnElapsed(elapsedSec, baseSettings)
    local currentStacks = CruxCounterR.State and CruxCounterR.State.stacks or 0
    if currentStacks == 0 then
        local baseColor = CruxCounterR.UI:GetEnsuredColor(baseSettings.elements.number.color)
        CruxCounterR_Display:SetNumberColor(baseColor)
        return
    end

    CruxCounterR.Utils.UpdateColorBasedOnElapsed(elapsedSec, baseSettings, "number", function(color)
        CruxCounterR_Display:SetNumberColor(color)
    end)
end