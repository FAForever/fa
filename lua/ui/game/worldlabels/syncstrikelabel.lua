local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local WorldLabel = import('/lua/ui/game/worldlabel.lua')
local Checkbox = import('/lua/ui/controls/checkbox.lua').Checkbox

local SessionIsPaused = SessionIsPaused

SyncStrikeWorldLabel = ClassUI(WorldLabel.WorldLabel) {

    __init = function(self, position, syncStrike)
        self.syncStrike = syncStrike
        WorldLabel.WorldLabel.__init(self, position, 'syncStrike')
    end,

    SetLayout = function(self, position)

        LOG('SyncStrikeWorldLabel.SetLayout: ', position[1], position[2], position[3])
        self.Left:Set(position[1] or 0)
        self.Bottom:Set(position[3] or 0)
        LayoutHelpers.SetDimensions(self, 24, 24)

        local prefix = '/game/orders/launch-'..self.syncStrike.commandType..'_btn'

        self.button = Checkbox(self,
            UIUtil.SkinnableFile(prefix..'_up.dds', true),
            UIUtil.SkinnableFile(prefix..'up_sel.dds', true),
            UIUtil.SkinnableFile(prefix..'_over.dds', true),
            UIUtil.SkinnableFile(prefix..'_down.dds', true),
            UIUtil.SkinnableFile(prefix..'dis.dds', true),
            UIUtil.SkinnableFile(prefix..'dis_sel.dds', true)
        )

        LOG('Button height: ', self.button.Height())
        LOG('Button width: ', self.button.Width())

        LayoutHelpers.AtCenterIn(self.button, self, -self.button.Height() / 2, self.button.Width() / 2)

        self.button.OnCheck = function(button, checked)
            self.syncStrike:Launch()
            self:StartCountdown()
        end

        
        self:DisableHitTest(false)

    end,

    StartCountdown = function(self)
        self.countingDown = true
        self.button:Hide()
        self.timeLeft = self.syncStrike.maxTicksToTarget / 10
        self.timerText = UIUtil.CreateText(self, string.format('%.2f', self.timeLeft), 12, UIUtil.bodyFont, true)
        LayoutHelpers.AtCenterIn(self.timerText, self)
    end,

    OnFrame = function(self, delta)
        WorldLabel.WorldLabel.OnFrame(self, delta)
        if self.countingDown and not SessionIsPaused() then
            self.timeLeft = self.timeLeft - delta
            if self.timeLeft <= 0 then
                self:Destroy()
            else
                self.timerText:SetText(string.format('%.2f', self.timeLeft))
            end
        end
    end,
}