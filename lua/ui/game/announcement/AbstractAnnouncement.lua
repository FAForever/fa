local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local CreateLazyVar = import("/lua/lazyvar.lua").Create

---@class UIAbstractAnnouncement : Bitmap, Destroyable
---@field Trash TrashBag
---@field GoalControl Control
---@field OnFinishedCallback? fun()
---@field FadeThreadInstance? thread
AbstractAnnouncement = ClassUI(Bitmap) {

    ---@param self UIAbstractAnnouncement
    ---@param parent Control
    ---@param onFinishedCallback? fun()
    __init = function(self, parent, onFinishedCallback)
        Bitmap.__init(self, parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))

        self.Trash = TrashBag();
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

    --- Fades out the announcement. Starts the fade out at the current alpha value, scaling the duration accordingly.
    ---@param self UIAbstractAnnouncement
    ---@param duration number       # in seconds
    FadeOut = function(self, duration)
        if self.FadeThreadInstance then
            self.FadeThreadInstance:Destroy()
        end

        local from = self:GetAlpha()
        local scaledDuration = duration * from
        self.FadeThreadInstance = self.Trash:Add(ForkThread(self.FadeThread, self, scaledDuration, from, 0))
    end,

    --- Fades in the announcement. Starts the fade out at the current alpha value, scaling the duration accordingly.
    ---@param self UIAbstractAnnouncement
    ---@param duration number       # in seconds
    FadeIn = function(self, duration)
        if self.FadeThreadInstance then
            self.FadeThreadInstance:Destroy()
        end

        local from = self:GetAlpha()
        local scaledDuration = duration * (1 - from)
        self.FadeThreadInstance = self.Trash:Add(ForkThread(self.FadeThread, self, scaledDuration, from, 1))
    end,

    --- The thread for fading the announcement.
    ---@param self UIAbstractAnnouncement
    ---@param duration number       # in seconds
    FadeThread = function(self, duration, from, to)
        local startTime = GetSystemTimeSeconds()
        local endTime = startTime + duration
        while not IsDestroyed(self) do
            -- fade over time
            local currentTime = GetSystemTimeSeconds()
            local progress = (currentTime - startTime) / (endTime - startTime)
            local alpha = MATH_Lerp(progress, from, to)
            self:SetAlpha(alpha, true)

            if currentTime > endTime then
                break
            end

            WaitFrames(1)
        end
    end,


    ---@param self UIAbstractAnnouncement
    ---@param duration number
    ---@param originControl Control
    ---@param targetControl Control
    ExpandAnimation = function(self, duration, originControl, targetControl)
        -- animate alpha
        self:SetAlpha(0)
        self:FadeIn(duration)

        -- animate position and scale
        self.Trash:Add(self.ExpandAnimationThread, self, originControl, duration)
    end,



    ---@param self UIAbstractAnnouncement
    ---@param originControl Control
    ExpandAnimationThread = function(self, originControl, duration)

    end,

    -- ContractAnimation = function(self, duration, destinationControl)
    --     PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
    --     self.Trash:Add(self.ContractAnimationThread, self, destinationControl, duration)
    -- end,

    -- ---@param self UIAbstractAnnouncement
    -- ---@param destinationControl Control
    -- ContractAnimationThread = function(self, destinationControl, duration)

    -- end,

    ---@param self UIAbstractAnnouncement
    ---@param control Control       # the control where the announcement 'expands' from and 'contracts' to
    ---@param onFinishedCallback? fun()
    Animate = function(self, control, onFinishedCallback)
        local thread = ForkThread(self.AnimateThread, self, control, onFinishedCallback)
        self.Trash:Add(thread)
    end,

    ---@param self UIAbstractAnnouncement
    ---@param goalControl Control
    ---@param onFinishedCallback? fun()
    AnimateThread = function(self, goalControl, onFinishedCallback)

        local expandDuration = 2
        local contractDuration = 1.5
        local stationaryDuration = 3

        -- expand animation
        self:SetAlpha(0, true)
        self:FadeIn(expandDuration)
        self:ExpandAnimation(expandDuration, goalControl)

        -- wait for the expand animation to finish
        WaitSeconds(expandDuration)


        -- keep the message stationary for a while before contracting
        WaitSeconds(stationaryDuration)

        self:FadeOut(contractDuration)
        self:ContractAnimation(contractDuration, goalControl)
    end,

    --- Creates the border for the announcement control.
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

