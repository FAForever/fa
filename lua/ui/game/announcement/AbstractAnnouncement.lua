local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

---@class UIAbstractAnnouncement : Bitmap, Destroyable
---@field Trash TrashBag
---@field GoalControl Control
---@field OnFinishedCallback? fun()
AbstractAnnouncement = ClassUI(Bitmap) {

    ---@param self UIAbstractAnnouncement
    ---@param parent Control
    ---@param goalControl Control
    ---@param onFinishedCallback? fun()
    __init = function(self, parent, goalControl, onFinishedCallback)
        Bitmap.__init(self, parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))

        self.Trash = TrashBag();
        self.GoalControl = goalControl
        self.OnFinishedCallback = onFinishedCallback
    end,

    ---@param self UIAbstractAnnouncement
    ---@param parent Control
    ---@param goalControl Control
    ---@param onFinishedCallback fun()
    __post_init = function(self, parent, goalControl, onFinishedCallback)
        -- initial layout
        LayoutHelpers.LayoutFor(self)
            :Height(0)
            :Width(0)
            :Over(parent, 1)
            :AtCenterIn(self.GoalControl)
            :NeedsFrameUpdate(true)
            :End()

        self:CreateBorder()
    end,

    ---@param self UIAbstractAnnouncement
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)

        if self.OnFinishedCallback then
            self.OnFinishedCallback()
        end
    end,

    --- Fades out the announcement, destroying it when it's done.
    ---@param self UIAbstractAnnouncement
    ---@param duration number       # in seconds
    FadeOut = function(self, duration)
        self.Trash:Add(ForkThread(self.FadeOutThread, self, duration))
    end,

    --- The thread for fading out the announcement, destroying it when it's done.
    ---@param self UIAbstractAnnouncement
    ---@param duration number       # in seconds
    FadeOutThread = function(self, duration)

        local startTime = GetSystemTimeSeconds()
        local endTime = startTime + 1000 * duration
        while not IsDestroyed(self) do
            WaitFrames(1)

            -- fade out over time
            local currentTime = GetSystemTimeSeconds()
            local alpha = 1 - (currentTime - startTime) / (endTime - startTime)
            self:SetAlpha(alpha)

            if CurrentTime > endTime then
                break
            end
        end

        self:Destroy()
    end,

    ---@param self UIAbstractAnnouncement
    CreateBorder = function(self)
        local tl = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
        local tm = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
        local tr = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
        local ml = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
        local mr = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
        local bl = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
        local bm = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
        local br = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))
    
        Layouter(tl):TopLeftOf(self):End()
        Layouter(tm):CenteredAbove(self):FillHorizontally(self):End()
        Layouter(tr):TopRightOf(self):End()
        Layouter(ml):CenteredLeftOf(self):FillVertically(self):End()
        Layouter(mr):CenteredRightOf(self):FillVertically(self):End()
        Layouter(bl):BottomLeftOf(self):End()
        Layouter(bm):CenteredBelow(self):FillHorizontally(self):End()
        Layouter(br):BottomRightOf(self):End()
    end,
}

