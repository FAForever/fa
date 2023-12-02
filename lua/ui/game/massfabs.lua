local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Prefs = import("/lua/user/prefs.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local panel

function Create(parent)
    panel = MassFabPanel(parent)
    return panel
end

function SetLayout()
    Layouter(panel)
        :Hide()
        :End()
end

function Update(data)
    if not IsDestroyed(panel) then
        panel:Update(data)
    end
end

function ToggleControl()
    if panel and not panel._collapseArrow:IsDisabled() then
        panel._collapseArrow:ToggleCheck()
    end
end

function FocusArmyChanged()
    local focusArmy = GetFocusArmy()
    if focusArmy == -1 then
        if panel then
            panel:Hide()
        end
    end
end

---@class MassFabPanel : Group
MassFabPanel = ClassUI(Group) {

    DefaultHeight = 72,
    DefaultWidth = 104,

    __init = function(self, parent)
        Group.__init(self, parent)
        self._parent = parent
        self._collapseArrow = UIUtil.CreateCollapseArrow(parent, "t")
        self._leftPanel = Bitmap(self)
        self._rightPanel = Bitmap(self)
        self._centerPanel = Bitmap(self)
        self._leftBrace = Bitmap(self)
        self._rightBrace = Bitmap(self)
        self._activeCountText = UIUtil.CreateText(self, "0", 18, UIUtil.bodyFont, true)
        self._inactiveCountText = UIUtil.CreateText(self, "0", 18, UIUtil.bodyFont, true)
        self._energyRequiredText = UIUtil.CreateText(self, "0", 10, UIUtil.bodyFont, true)
        self._energyConsumedText = UIUtil.CreateText(self, "0", 10, UIUtil.bodyFont, true)
        self._massProducedText = UIUtil.CreateText(self, "0", 10, UIUtil.bodyFont, true)
        self:_Logic()
        local pos = self:_LoadPosition()
        LayoutHelpers.AtLeftTopIn(self, parent, pos.left, 4)
    end,

    Layout = function(self)
        LayoutHelpers.AtTopIn(self._collapseArrow, self._parent, -3)
        LayoutHelpers.AtHorizontalCenterIn(self._collapseArrow, self)
        LayoutHelpers.DepthOverParent(self._collapseArrow, self, 10)
        self._collapseArrow:Disable()
        self._collapseArrow:Hide()

        self._leftPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_l_bmp.dds"))
        self._rightPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_r_bmp.dds"))
        self._centerPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_c_bmp.dds"))
        self._leftBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-r_bmp.dds"))
        self._rightBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-r_bmp.dds"))

        self._centerPanel:DisableHitTest()
        self._leftPanel:DisableHitTest()
        self._rightPanel:DisableHitTest()

        self._leftBrace:DisableHitTest()
        self._rightBrace:DisableHitTest()

        self.Height:Set(LayoutHelpers.ScaleNumber(self.DefaultHeight))
        self.Width:Set(LayoutHelpers.ScaleNumber(self.DefaultWidth))

        self._leftPanel.Top:Set(self.Top)
        self._rightPanel.Top:Set(self.Top)
        self._centerPanel.Top:Set(self.Top)

        self._leftPanel.Left:Set(self.Left)
        self._rightPanel.Right:Set(self.Right)
        self._centerPanel.Left:Set(self._leftPanel.Right)
        self._centerPanel.Right:Set(self._rightPanel.Left)

        LayoutHelpers.AtLeftIn(self._leftBrace, self, 11)
        LayoutHelpers.AtTopIn(self._leftBrace, self)

        self._leftBrace.Right:Set(function()
            return self._leftBrace.Left() - self._leftBrace.Width()
        end)

        LayoutHelpers.AnchorToRight(self._rightBrace, self, -11)
        LayoutHelpers.AtTopIn(self._rightBrace, self)

        LayoutHelpers.AtLeftTopIn(self._activeCountText, self, 12, 10)
        LayoutHelpers.AtLeftTopIn(self._inactiveCountText, self, 12, 39)

        LayoutHelpers.AtRightTopIn(self._massProducedText, self, 12, 8)
        LayoutHelpers.AtRightTopIn(self._energyRequiredText, self, 12, 49)

        LayoutHelpers.AnchorToBottom(self._energyConsumedText, self._massProducedText, -1)
        self._energyConsumedText.Right:Set(self._massProducedText.Right)


        Tooltip.AddControlTooltip(self._energyRequiredText, "mf_energy_required")
        Tooltip.AddControlTooltip(self._energyConsumedText, "mf_energy_expense_display")
        Tooltip.AddControlTooltip(self._massProducedText, "mf_mass_income_display")
        Tooltip.AddControlTooltip(self._activeCountText, "mf_active_amount")
        Tooltip.AddControlTooltip(self._inactiveCountText, "mf_inactive_amount")
        Tooltip.AddCheckboxTooltip(self._collapseArrow, "fabricator_collapse")
    
        self._energyRequiredText:SetColor("fff8c000")
        self._energyConsumedText:SetColor("fff8c000")
        self._massProducedText:SetColor("ffb7e75f")

        self._activeCountText:SetColor("ffffffff")
        self._inactiveCountText:SetColor("ffffffff")
    end,

    _Logic = function(self)
        self._collapseArrow.OnCheck = function(_, checked)
            if UIUtil.GetAnimationPrefs() then
                if not checked or self:IsHidden() then
                    PlaySound(Sound({
                        Cue = "UI_Score_Window_Open",
                        Bank = "Interface"
                    }))
                    self:Show()
                    self:SetNeedsFrameUpdate(true)
                    self.OnFrame = function(control, delta)
                        local newTop = control.Top() + (500 * delta)
                        if newTop > control._parent.Top() then
                            newTop = control._parent.Top()
                            control:SetNeedsFrameUpdate(false)
                        end
                        control.Top:Set(newTop + 4)
                    end
                else
                    PlaySound(Sound({
                        Cue = "UI_Score_Window_Close",
                        Bank = "Interface"
                    }))

                    self:SetNeedsFrameUpdate(true)
                    self.OnFrame = function(control, delta)
                        local newTop = control.Top() - (500 * delta)
                        if newTop < control._parent.Top() - control.Height() then
                            newTop = control._parent.Top() - control.Height()
                            control:Hide()
                            control:SetNeedsFrameUpdate(false)
                        end
                        control.Top:Set(newTop)
                    end
                end
            else
                if not checked or self:IsHidden() then
                    self:Show()
                    self._collapseArrow:SetCheck(false, true)
                else
                    self:Hide()
                    self._collapseArrow:SetCheck(true, true)
                end
            end
        end
        self._collapseArrow.OnHide = function(collapse, hide)
            if collapse:IsDisabled() and not hide then
                return true
            end
        end
    end,

    Update = function(self, data)
        if data.on == 0 and data.off == 0 then
            if not self:IsHidden() then
                self._collapseArrow:Disable()
                self:Hide()
            end
            return
        end
        if self:IsHidden() then
            self._collapseArrow:Enable()
            self:Show()
        end
        self._activeCountText:SetText(tostring(data.on))
        self._inactiveCountText:SetText(tostring(data.off))
        self._energyRequiredText:SetText(tostring(data.totalEnergyRequired))
        self._energyConsumedText:SetText(tostring(-data.totalEnergyConsumed))
        self._massProducedText:SetText("+" .. tostring(data.totalMassProduced))
    end,

    HandleEvent = function(self, event)
        if event.Type == "ButtonPress" and event.Modifiers.Middle then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(math.min(math.max(x - offX, self._parent.Left()), self._parent.Right() - self.Width()))
                GetCursor():SetTexture(UIUtil.GetCursor("W_E"))
            end
            drag.OnRelease = function(dragself)
                self:_SavePosition()
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
            return true
        end
        return false
    end,

    _LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile("MassFabsPanelPos") or {
            left = 500
        }
    end,

    _SavePosition = function(self)
        Prefs.SetToCurrentProfile("MassFabsPanelPos", {
            left = LayoutHelpers.InvScaleNumber(self.Left())
        })
    end,

    OnHide = function(self, hide)
        local supress = import("/lua/ui/game/gamecommon.lua").SupressShowingWhenRestoringUI(self, hide)
        local collapse = self._collapseArrow
        if collapse then
            if supress or collapse:IsDisabled() then
                collapse:Hide()
                if not hide then
                    supress = true
                end
            else
                collapse:Show()
            end
        end
        return supress
    end,

}

