local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local WorldViewGame = import('/lua/ui/game/worldview.lua')
local WorldLabel = import('/lua/ui/game/worldlabel.lua').WorldLabel
local WorldLabelGroup = import('/lua/ui/game/worldlabel.lua').WorldLabelGroup
local Checkbox = import('/lua/ui/controls/checkbox.lua').Checkbox
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local CommandMode = import('/lua/ui/game/commandmode.lua')

local SessionIsPaused = SessionIsPaused

local fadeStart = 150
local fadeRange = 650
local fadeEnd  = fadeStart + fadeRange
local fadeLimit = 0.5

local baseButtonWidth
local baseButtonHeight
local baseMarkerWidth
local baseMarkerHeight
local plusWidth
local plusHeight

local syncLabelGroup = {}

local launchOrdersTable = {
    RULEUCC_Tactical = 'tactical',
    RULEUCC_Nuke = 'nuke',
}

local function GetOrderBitmaps(order)
    if order == 'tactical' or order == 'nuke' then
        order = 'launch-'..order
    end
    local prefix = '/game/orders/'..order..'_btn'
    return UIUtil.SkinnableFile(prefix..'_up.dds', true),
    UIUtil.SkinnableFile(prefix..'_up_sel.dds', true),
    UIUtil.SkinnableFile(prefix..'_over.dds', true),
    UIUtil.SkinnableFile(prefix..'_down.dds', true),
    UIUtil.SkinnableFile(prefix..'_dis.dds', true),
    UIUtil.SkinnableFile(prefix..'_dis_sel.dds', true)
end

SyncStrikeLabelGroup = ClassUI(WorldLabelGroup) {

    __init = function(self, mapGroup)
        WorldLabelGroup.__init(self, mapGroup)
        self:SetNeedsFrameUpdate(true)
        self.labels = {}
        syncLabelGroup = self
        import('/lua/ui/game/syncstrike.lua').RegisterSyncStrikeLabelGroup(self)
        self._state = {
            inCommandMode = false,
            buttonDown = false,
            launchType = false,
            targetLabel = false,
        }
    end,

    OnCommandMode = function(self, inMode, commandMode, modeData)
        LOG('OnCommandMode')
        LOG('inMode: '..repr(inMode))
        LOG('commandMode: '..repr(commandMode))
        self:SetState({
            inCommandMode = inMode,
            launchType = inMode and launchOrdersTable[modeData.name] or false,
            targetLabel = false,
        })
    end,

    OnSyncButton = function(self, down)
        self:SetState({
            buttonDown = down,
        })
    end,

    SetLabelForAdd = function(self, label)
        self:SetState({
            targetLabel = label
        })
    end,

    SetState = function(self, state)
        for label in self.labels do
            label:SetState(state)
        end
    end,

    OnFrame = function(self, delta)
        if self.manager.changed then
            if self.manager._prevZoom > fadeEnd then
                if self.fade > fadeLimit then
                    self.fade = fadeLimit
                else
                    self.fade = false
                end
            elseif self.manager._prevZoom > fadeStart then
                self.fade = fadeLimit + math.max(0, (1 - fadeLimit) * (1 - (self.manager._prevZoom - fadeStart)/fadeRange))
            elseif self.fade < 1 then
                self.fade = 1
            else
                self.fade = false
            end
        end
    end,

    ---@param self WorldLabelGroup
    ---@param hidden boolean
    OnHide = function(self, hidden)
        self:SetNeedsFrameUpdate(not hidden)
    end,

    AddLabel = function(self, label)
        self.labels[label] = true
    end,

    RemoveLabel = function(self, label)
        self.labels[label] = nil
        if table.empty(self.labels) then
            self.manager:DeregisterLabelGroup(self.type)
        end
    end,

}

SyncStrikeWorldLabel = ClassUI(WorldLabel) {

    __init = function(self, position, syncStrike, view)
        self.syncStrike = syncStrike
        WorldLabel.__init(self, position, 'syncStrike', view)
        syncLabelGroup:AddLabel(self)
    end,

    CreateLabelGroup = function(self, type, view)
        return SyncStrikeLabelGroup(type, view)
    end,

    SetLayout = function(self, position)

        self.Left:Set(position[1] or 0)
        self.Bottom:Set(position[3] or 0)
        LayoutHelpers.SetDimensions(self, 24, 24)

        self.button = Checkbox(self, GetOrderBitmaps(self.syncStrike.commandType))

        if not (baseButtonWidth and baseButtonHeight) then
            baseButtonWidth = self.button.checkBmp.Width()
            baseButtonHeight = self.button.checkBmp.Height()
        end

        LayoutHelpers.AtCenterIn(self.button, self, -self.button.Height() / 2, self.button.Width() / 2)

        self.button.HandleEvent = function(control, event)
            if event.Type == 'MouseEnter' then
                self:AlphaOverride(1)
            elseif event.Type == 'MouseExit' then
                self:AlphaOverride(false)
            elseif event.Type == 'WheelMotion' then
                WorldViewGame.ForwardMouseWheelInput(event)
            end
            return Checkbox.HandleEvent(control, event)
        end

        self.button.OnCheck = function(button, checked)
            if not self.plusSign:IsHidden() then
                syncLabelGroup:SetLabelForAdd(self)
                CommandMode.GetCommandMode()[2].syncStrike = self.syncStrike
            else
                self.syncStrike:Launch()
                self:StartCountdown()
            end
        end

        self.button:EnableHitTest(true)

        self.marker = Bitmap(self, UIUtil.UIFile('/game/marker/point_launch.dds'))
        if not (baseMarkerWidth and baseMarkerHeight) then
            baseMarkerWidth = self.marker.Width()
            baseMarkerHeight = self.marker.Height()
        end

        self.marker:DisableHitTest()
        LayoutHelpers.AtCenterIn(self.marker, self)
        LayoutHelpers.DepthUnderParent(self.marker, self.button)

        self.plusSign = Bitmap(self, UIUtil.UIFile('/game/marker/plus_sign.dds'))
        self.plusSign:DisableHitTest()
        self.plusSign:Hide()
        LayoutHelpers.AtRightTopIn(self.plusSign, self.button.checkBmp)
        LayoutHelpers.DepthOverParent(self.plusSign, self.button)

        if not (plusWidth and plusHeight) then
            plusWidth = self.plusSign.Width()
            plusHeight = self.plusSign.Height()
        end

    end,

    StartCountdown = function(self)
        self.countingDown = true
        self.button:Hide()
        self.timeLeft = self.syncStrike.maxTicksToTarget / 10
        self.timerText = UIUtil.CreateText(self, string.format('%.2fs', self.timeLeft), 12, UIUtil.bodyFont, true)
        LayoutHelpers.AtCenterIn(self.timerText, self, -12, self.timerText.Width()/2 + 12)
    end,

    OnFrame = function(self, delta)
        WorldLabel.OnFrame(self, delta)
        if self.countingDown and not SessionIsPaused() then
            self.timeLeft = self.timeLeft - delta
            if self.timeLeft <= 0 then
                self:Destroy()
            else
                self.timerText:SetText(string.format('%.2fs', self.timeLeft))
            end
        end
    end,

    ProjectToScreen = function(self)
        WorldLabel.ProjectToScreen(self)
        self:Fade()
    end,

    Fade = function(self)
        if syncLabelGroup.fade then
            if not self._alphaOverride then
                self.button.checkBmp:SetAlpha(syncLabelGroup.fade)
            end
            local markerWidth, markerHeight = baseMarkerWidth * syncLabelGroup.fade, baseMarkerHeight * syncLabelGroup.fade
            local buttonWidth, buttonHeight = baseButtonWidth * syncLabelGroup.fade, baseButtonHeight * syncLabelGroup.fade
            local plusWidth, plusHeight = plusWidth * syncLabelGroup.fade, plusHeight * syncLabelGroup.fade
            LayoutHelpers.SetDimensions(self.marker, markerWidth, markerHeight)
            LayoutHelpers.SetDimensions(self.button.checkBmp, buttonWidth, buttonHeight)
            LayoutHelpers.AtCenterIn(self.button, self, -self.button.Height() / 2, self.button.Width() / 2)
            LayoutHelpers.SetDimensions(self.plusSign, plusWidth, plusHeight)
            LayoutHelpers.AtRightTopIn(self.plusSign, self.button.checkBmp)
        end
    end,

    AlphaOverride = function(self, override)
        if override == false then
            self._alphaOverride = nil
            self.button.checkBmp:SetAlpha(syncLabelGroup.fade or 1)
        else
            self._alphaOverride = override
            self.button.checkBmp:SetAlpha(self._alphaOverride)
        end
    end,

    Disable = function(self)
        LOG('SyncLabel disabled')
        self:Reset()
        self:AlphaOverride(fadeLimit)
        self.button:DisableHitTest(true)
    end,

    Enable = function(self)
        LOG('SyncLabel enabled')
        self:Reset()
        self:AlphaOverride(false)
        self.button:EnableHitTest(true)
    end,

    Reset = function(self)
        if self.markerHighlight then
            self.markerHighlight = false
            self.marker:SetTexture(UIUtil.UIFile('/game/marker/point_launch.dds'))
        end
        self:AlphaOverride(false)
        if self.button:IsHidden() then
            self.button:Show()
        end
        if not self.plusSign:IsHidden() then
            self.plusSign:Hide()
        end
    end,

    SetState = function(self, state)
        if self.countingDown then
            return
        end
        if state.targetLabel then
            if state.targetLabel == self then
                self.markerHighlight = true
                self.marker:SetTexture(UIUtil.UIFile('/game/marker/point_launch_highlighted.dds'))
                self.button:Hide()
                self.plusSign:Hide()
            else
                self:Disable()
            end
        elseif state.launchType == self.syncStrike.type then
            if state.buttonDown then
                self.plusSign:Show()
                self.button:EnableHitTest(true)
                self:AlphaOverride(1)
            elseif not state.targetLabel == self then
                self:Disable()
            end
        elseif state.inCommandMode then
            self:Disable()
        else
            self:Enable()
        end
    end,

    OnDestroy = function(self)
        syncLabelGroup:RemoveLabel(self)
    end,
}