-- A thin progress line: a known share, or a block that sweeps back and forth while the length of the work isn't known.

local Group = import('/lua/maui/group.lua').Group
local FlatPanel = import('/lua/ui/controls/flat_panel.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local kGroove = 'ff26323a'
local kBusyShare = 0.25
local kBusyCycleSeconds = 1.4

FlatProgress = ClassUI(Group) {
    __init = function(self, parent)
        Group.__init(self, parent, "FlatProgress")

        local groove = FlatPanel.Rectangle(self, kGroove, 0)
        groove.Left:Set(self.Left)
        groove.Right:Set(self.Right)
        groove.Top:Set(self.Top)
        groove.Bottom:Set(self.Bottom)

        self.mFill = FlatPanel.Rectangle(self, UIUtil.factionBackColor(), 1)
        self.mFill.Top:Set(self.Top)
        self.mFill.Bottom:Set(self.Bottom)
        self.mFill.Left:Set(self.Left)
        self.mFill.Width:Set(0)

        self.mBusy = false
        self.mBusyTime = 0
    end,

    --- A share from 0 to 1.
    SetProgress = function(self, share)
        self.mBusy = false
        self.mFill.Left:Set(self.Left())
        self.mFill.Width:Set(math.floor(self.Width() * math.min(math.max(share, 0), 1)))
    end,

    --- Sweeps until the next SetProgress. Each frame while it lasts.
    Sweep = function(self, delta)
        self.mBusy = true
        self.mBusyTime = math.mod(self.mBusyTime + delta, kBusyCycleSeconds)
        local phase = self.mBusyTime / kBusyCycleSeconds
        local there = phase < 0.5 and phase * 2 or (1 - phase) * 2
        local block = self.Width() * kBusyShare
        self.mFill.Left:Set(math.floor(self.Left() + there * (self.Width() - block)))
        self.mFill.Width:Set(math.floor(block))
    end,
}
