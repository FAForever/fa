-- The replay's timeline, drawn from rectangles: a groove, what has played, thin lines at the keyframes, a playhead, and
-- while the replay is on its way to a chosen time, a mark at where it really is. The whole height takes the mouse, not
-- just the thin groove.

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local FlatPanel = import('/lua/ui/controls/flat_panel.lua')

local kGroove = 'ff26323a'
local kPending = '7036505c'
local kActual = 'ffffc040'
local kPlayhead = 'ffffffff'
local kHoverLine = 'a0ffffff'
local kKeyframeLine = '90a8c4cc'
local kKeyframeLineHeight = 12
local kKeyframeSnap = 3
local kGrooveHeight = 4
local kGrooveHeightOver = 6
local kPlayheadHeight = 18
local kBubbleLift = 10
-- What a click at the time under the mouse would do, by what `SeekKind` returns.
local kSeekLooks = {
    load = {text = "Jump", color = 'ff7fd4ff'},
    play = {text = "Fast forward", color = kActual},
}

Scrubber = ClassUI(Group) {
    --- `format` turns ticks into the text of the time bubble.
    __init = function(self, parent, totalTicks, format)
        Group.__init(self, parent, "ReplayScrubber")
        self.mTotal = math.max(totalTicks, 1)
        self.mFormat = format
        self.mEnabled = totalTicks > 0
        self.mOver = false
        self.mMouseX = 0
        self.mDragTick = false
        self.mShownLook = false

        -- Takes the events, and is the only part here that does.
        local catcher = Bitmap(self)
        catcher:SetSolidColor('00000000')
        LayoutHelpers.FillParent(catcher, self)
        catcher.Depth:Set(function() return self.Depth() + 8 end)
        catcher.HandleEvent = function(control, event)
            return self:OnMouse(event)
        end

        local function Line(color, depthAbove)
            local line = FlatPanel.Rectangle(self, color, depthAbove)
            line.Top:Set(function() return math.floor(self.Top() + (self.Height() - line.Height()) / 2) end)
            return line
        end

        self.mGroove = Line(kGroove, 1)
        self.mGroove.Left:Set(self.Left)
        self.mGroove.Right:Set(self.Right)

        self.mPending = Line(kPending, 2)
        self.mPlayed = Line(UIUtil.factionBackColor(), 3)
        self.mActual = Line(kActual, 4)
        self.mActual.Width:Set(function() return LayoutHelpers.ScaleNumber(2) end)
        self.mActual.Height:Set(function() return LayoutHelpers.ScaleNumber(kPlayheadHeight - 6) end)
        self.mHover = Line(kHoverLine, 5)
        self.mHover.Width:Set(1)
        self.mHover.Height:Set(function() return LayoutHelpers.ScaleNumber(kPlayheadHeight - 4) end)
        self.mPlayhead = Line(kPlayhead, 6)
        self.mPlayhead.Width:Set(function() return LayoutHelpers.ScaleNumber(3) end)
        self.mPlayhead.Height:Set(function() return LayoutHelpers.ScaleNumber(kPlayheadHeight) end)

        self.mKeyframeLines = {}
        self.mKeyframeTicks = {}

        self.mBubble = FlatPanel.FlatPanel(self, "ReplayScrubberBubble")
        self.mBubble.Depth:Set(function() return self.Depth() + 20 end)
        self.mBubble:DisableHitTest(true)
        self.mBubbleText = UIUtil.CreateText(self.mBubble, "", 12, UIUtil.bodyFont)
        self.mBubbleText:SetColor(UIUtil.fontColor())
        self.mBubbleText:DisableHitTest()
        LayoutHelpers.AtCenterIn(self.mBubbleText, self.mBubble)
        self.mBubbleText.Depth:Set(function() return self.mBubble.Depth() + 3 end)
        self.mBubble.Width:Set(function() return self.mBubbleText.Width() + LayoutHelpers.ScaleNumber(12) end)
        self.mBubble.Height:Set(function() return self.mBubbleText.Height() + LayoutHelpers.ScaleNumber(6) end)
        self.mBubble.Bottom:Set(function() return self.Top() - LayoutHelpers.ScaleNumber(kBubbleLift) end)
        self.mBubble.Left:Set(self.Left)
    end,

    XOf = function(self, tick)
        local share = math.min(math.max(tick / self.mTotal, 0), 1)
        return math.floor(self.Left() + share * self.Width())
    end,

    TickAt = function(self, x)
        local share = math.min(math.max((x - self.Left()) / math.max(self.Width(), 1), 0), 1)
        return math.floor(share * self.mTotal)
    end,

    --- The tick a click here would go to: a keyframe line this close, as nothing is quicker to reach.
    TargetAt = function(self, x)
        local reach = LayoutHelpers.ScaleNumber(kKeyframeSnap)
        local target = self:TickAt(x)
        for _, tick in self.mKeyframeTicks do
            local distance = math.abs(self:XOf(tick) - x)
            if distance <= reach then
                reach = distance
                target = tick
            end
        end
        return target
    end,

    IsDragging = function(self)
        return self.mDragTick != false
    end,

    OnMouse = function(self, event)
        if event.Type == 'MouseEnter' then
            self.mOver = true
            self.mMouseX = event.MouseX
        elseif event.Type == 'MouseExit' then
            self.mOver = false
        elseif event.Type == 'MouseMotion' then
            self.mMouseX = event.MouseX
        elseif event.Type == 'ButtonPress' and self.mEnabled and event.Modifiers.Left then
            self:BeginDrag(event)
            return true
        end
        return false
    end,

    BeginDrag = function(self, event)
        self.mDragTick = self:TargetAt(event.MouseX)
        self:OnScrub(self.mDragTick)
        local dragger = Dragger()
        dragger.OnMove = function(control, x, y)
            self.mMouseX = x
            self.mDragTick = self:TargetAt(x)
            self:OnScrub(self.mDragTick)
        end
        dragger.OnRelease = function(control, x, y)
            local tick = self:TargetAt(x)
            self.mDragTick = false
            dragger:Destroy()
            self:OnSeek(tick)
        end
        dragger.OnCancel = function(control)
            self.mDragTick = false
            dragger:Destroy()
        end
        PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
    end,

    --- Thin lines at these ticks, where a move back is quick.
    SetKeyframes = function(self, ticks)
        self.mKeyframeTicks = ticks
        local count = table.getn(ticks)
        for index = table.getn(self.mKeyframeLines) + 1, count do
            local line = FlatPanel.Rectangle(self, kKeyframeLine, 4)
            line.Width:Set(1)
            line.Height:Set(function() return LayoutHelpers.ScaleNumber(kKeyframeLineHeight) end)
            line.Top:Set(function() return math.floor(self.Top() + (self.Height() - line.Height()) / 2) end)
            self.mKeyframeLines[index] = line
        end
        for index, line in self.mKeyframeLines do
            local tick = ticks[index]
            FlatPanel.SetVisible(line, tick != nil)
            if tick then
                line.Left:Set(self:XOf(tick))
            end
        end
    end,

    --- The tick the playhead stands at; `actual` is where the replay is. Each frame.
    Update = function(self, playhead, actual)
        if self.mDragTick != false then
            playhead = self.mDragTick
        end
        local left = self.Left()
        local playheadX = self:XOf(playhead)
        local actualX = self:XOf(actual)
        local moving = actualX != playheadX

        local thick = LayoutHelpers.ScaleNumber((self.mOver or self.mDragTick != false) and kGrooveHeightOver or kGrooveHeight)
        for _, line in {self.mGroove, self.mPending, self.mPlayed} do
            line.Height:Set(thick)
        end

        local playedEnd = math.min(playheadX, actualX)
        self.mPlayed.Left:Set(left)
        self.mPlayed.Width:Set(playedEnd - left)

        FlatPanel.SetVisible(self.mPending, moving)
        FlatPanel.SetVisible(self.mActual, moving)
        if moving then
            self.mPending.Left:Set(playedEnd)
            self.mPending.Width:Set(math.max(playheadX, actualX) - playedEnd)
            self.mActual.Left:Set(actualX - math.floor(self.mActual.Width() / 2))
        end

        self.mPlayhead.Left:Set(playheadX - math.floor(self.mPlayhead.Width() / 2))

        -- The time under the mouse, or the one being dragged to.
        local showBubble = self.mEnabled and (self.mOver or self.mDragTick != false)
        FlatPanel.SetVisible(self.mHover, showBubble and self.mDragTick == false)
        FlatPanel.SetVisible(self.mBubble, showBubble)
        if showBubble then
            local tick = self.mDragTick != false and self.mDragTick or self:TargetAt(self.mMouseX)
            local x = self:XOf(tick)
            self.mHover.Left:Set(x)
            local look = kSeekLooks[self:SeekKind(tick) or '']
            self.mBubbleText:SetText(look and LOCF("%s  %s", self.mFormat(tick), look.text) or self.mFormat(tick))
            if look != self.mShownLook then
                self.mShownLook = look
                self.mBubbleText:SetColor(look and look.color or UIUtil.fontColor())
                self.mHover:SetSolidColor(look and look.color or kHoverLine)
            end
            self.mBubble.Left:Set(math.floor(x - self.mBubble.Width() / 2))
        end
    end,

    --- What a move to this tick would do: a key of `kSeekLooks`, or nil to say nothing.
    SeekKind = function(self, tick)
    end,

    --- While dragging: the tick under the mouse.
    OnScrub = function(self, tick)
    end,

    --- A click, or the end of a drag.
    OnSeek = function(self, tick)
    end,
}
