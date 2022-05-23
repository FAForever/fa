local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Prefs = import('/lua/user/prefs.lua')

local panel

function Create(parent)
    panel = MassFabPanel(parent)
   
    return panel
end

function Update(data)
    if not IsDestroyed(panel) then
        panel:Update(data)
    end
end

MassFabPanel = Class(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self._panel = Bitmap(self)
        self._leftBrace = Bitmap(self)
        self._rightBrace = Bitmap(self)
        self._activeCountText = UIUtil.CreateText(self, "0", 18, UIUtil.bodyFont)
        self._inactiveCountText = UIUtil.CreateText(self, "0", 18, UIUtil.bodyFont)
        self._energyRequiredText = UIUtil.CreateText(self, "0", 12, UIUtil.bodyFont)
        self._energyConsumedText = UIUtil.CreateText(self, "0", 12, UIUtil.bodyFont)
        self._massProducedText = UIUtil.CreateText(self, "0", 12, UIUtil.bodyFont)
        self:_Layout()
        local pos = self:_LoadPosition()
        LayoutHelpers.AtLeftTopIn(self, parent, pos.left, 3)
    end,

    _Layout = function(self)
        self._panel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-mini-panel_bmp.dds"))
        self._leftBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-l_bmp.dds"))
        self._rightBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-r_bmp.dds"))

        self._panel:DisableHitTest()
        self._leftBrace:DisableHitTest()
        self._rightBrace:DisableHitTest()

        self.Height:Set(self._panel.Height)
        self.Width:Set(self._panel.Width)
        -- self._leftBrace.Width:Set(self._leftBrace.Width() / 2.5)
        -- self._rightBrace.Width:Set(self._rightBrace.Width() / 2.5)

        LayoutHelpers.FillParent(self._panel, self)

        LayoutHelpers.AnchorToLeft(self._leftBrace, self, -11)
        LayoutHelpers.AtTopIn(self._leftBrace, self)

        LayoutHelpers.AnchorToRight(self._rightBrace, self, -12)
        LayoutHelpers.AtTopIn(self._rightBrace, self)

        LayoutHelpers.AtLeftTopIn(self._activeCountText, self, 10, 5)
        LayoutHelpers.AtLeftBottomIn(self._inactiveCountText, self, 10, 5)

        LayoutHelpers.AtRightTopIn(self._energyConsumedText, self, 10, 5)
        LayoutHelpers.AtRightBottomIn(self._energyRequiredText, self, 10, 5)

        LayoutHelpers.AnchorToBottom(self._massProducedText, self._energyConsumedText)
        self._massProducedText.Right:Set(self._energyConsumedText.Right)

    end,

    Update = function(self, data)
        if data.on == 0 and data.off == 0 then
            self:Hide()
            return
        end
        self:Show()
        self._activeCountText:SetText(tostring(data.on))
        self._inactiveCountText:SetText(tostring(data.off))
        self._energyRequiredText:SetText(tostring(data.totalEnergyRequired))
        self._energyConsumedText:SetText(tostring(data.totalEnergyConsumed))
        self._massProducedText:SetText(tostring(data.totalMassProduced))
    end,

    HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' and event.Modifiers.Middle then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(x - offX)
                GetCursor():SetTexture(UIUtil.GetCursor('W_E'))
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
        return Prefs.GetFromCurrentProfile('MassFabsPanelPos') or {
            left = 500,
        }
    end,

    _SavePosition = function(self)
        Prefs.SetToCurrentProfile("MassFabsPanelPos", {
            left = self.Left(),
        })
    end

}

