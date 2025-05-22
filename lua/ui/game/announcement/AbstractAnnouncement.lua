local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local CreateLazyVar = import("/lua/lazyvar.lua").Create



---@class UIAbstractAnnouncement : Destroyable, Group
---@field Trash TrashBag
---@field AnimateThreadInstance? thread
---@field FadeThreadInstance? thread
---@field Background Bitmap
---@field BackgroundBorderTopLeft Bitmap
---@field BackgroundBorderTop Bitmap
---@field BackgroundBorderTopRight Bitmap
---@field BackgroundBorderLeft Bitmap
---@field BackgroundBorderRight Bitmap
---@field BackgroundBorderBottomLeft Bitmap
---@field BackgroundBorderBottom Bitmap
---@field BackgroundBorderBottomRight Bitmap
---@field ContentArea Group
AbstractAnnouncement = ClassUI(Group) {

    -- Announcements works by morphing the background to/from a control. By doing so you give the player an idea
    -- what the announcement is connected to. The content of the announcement is never moved, only the background
    -- is. The alpha of the content is adjusted when the announcement arrives and leaves again.

    -- To make it more concrete:
    -- - The announcement class itself is the content.
    -- - The background is what we animate.

    ---@param self UIAbstractAnnouncement
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "Announcement")

        self.Trash = TrashBag();

        self.ContentArea = Group(self)

        -- background that we animate
        self.Background = Bitmap(self, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds'))
        self.BackgroundBorderTopLeft = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
        self.BackgroundBorderTop = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
        self.BackgroundBorderTopRight = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
        self.BackgroundBorderLeft = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
        self.BackgroundBorderRight = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
        self.BackgroundBorderBottomLeft = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
        self.BackgroundBorderBottom = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
        self.BackgroundBorderBottomRight = Bitmap(self.Background, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))
    end,

    ---@param self UIAbstractAnnouncement
    ---@param parent Control
    __post_init = function(self, parent)
        local frame = GetFrame(0)

        -- where we expect announcements to be
        LayoutHelpers.LayoutFor(self)
            :Height(0)
            :Width(0)
            :AtCenterIn(frame, -250)
            :Over(parent, 1)
            :End()

        -- by default, fill the parent
        LayoutHelpers.LayoutFor(self.ContentArea)
            :Fill(self)
            :End()

        -- by default, just fill the parent
        LayoutHelpers.LayoutFor(self.Background)
            :Fill(self)
            :End()

        -- put border around the background
        LayoutHelpers.Layouter(self.BackgroundBorderTopLeft)
            :TopLeftOf(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderTop)
            :CenteredAbove(self.Background)
            :FillHorizontally(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderTopRight)
            :TopRightOf(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderLeft)
            :CenteredLeftOf(self.Background)
            :FillVertically(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderRight)
            :CenteredRightOf(self.Background)
            :FillVertically(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderBottomLeft)
            :BottomLeftOf(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderBottom)
            :CenteredBelow(self.Background)
            :FillHorizontally(self.Background)
            :End()

        LayoutHelpers.Layouter(self.BackgroundBorderBottomRight)
            :BottomRightOf(self.Background)
            :End()
    end,

    ---@param self UIAbstractAnnouncement
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)

        self.Trash:Destroy()
    end,

    ---@param self UIAbstractAnnouncement
    ---@param duration number
    ---@param targetTransparency number
    AnimateContent = function(self, duration, targetTransparency)
        local from = self.ContentArea:GetAlpha()
        self.Trash:Add(ForkThread(self.AnimateContentThread, self, duration, from, targetTransparency))
    end,

    ---@param self UIAbstractAnnouncement
    ---@param duration number
    ---@param target number
    AnimateContentThread = function(self, duration, from, target)
        -- animate it
        local startTime = GetSystemTimeSeconds()
        local endTime = startTime + duration
        while not IsDestroyed(self) do
            local currentTime = GetSystemTimeSeconds()
            if currentTime > endTime then
                break
            end

            local progress = (currentTime - startTime) / duration
            local alpha = math.clamp(MATH_Lerp(progress, from, target), 0, 1)
            self.ContentArea:SetAlpha(alpha, true)

            WaitFrames(1)
        end
    end,

    --- Expands the background of the announcement, starting at the provided control towards the center of the screen.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ExpandBackground = function(self, control, duration)
        self:AnimateBackground(control, duration, 'Expand')
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Open'}))
    end,

    --- Contracts the background of the announcement, the provided control is the destination to contract to.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ContractBackground = function(self, control, duration)
        self:AnimateBackground(control, duration, 'Contract')
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
    end,

    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ---@param state 'Expand' | 'Contract'
    AnimateBackground = function(self, control, duration, state)
        -- do not allow other animations
        if self.AnimateThreadInstance then
            self.AnimateThreadInstance:Destroy()
        end

        -- animate position and scale
        self.AnimateThreadInstance = self.Trash:Add(ForkThread(self.BackgroundAnimationThread, self, control, duration, state))
    end,

    --- Expands the background of the announcement, starting at the provided control towards the center of the screen.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ---@param state 'Expand' | 'Contract'
    BackgroundAnimationThread = function(self, control, duration, state)
        -- local scope for performance
        local background = self.Background
        local content = self.ContentArea

        ---@type LazyVar
        local progress = CreateLazyVar(0)

        background.Top:Set(
            function() 
                local percentage = progress()
                return percentage * content.Top() + (1 - percentage) * control.Top()
            end
        )

        background.Bottom:Set(
            function() 
                local percentage = progress()
                return percentage * content.Bottom() + (1 - percentage) * control.Bottom()
            end
        )

        background.Left:Set(
            function() 
                local percentage = progress()
                return percentage * content.Left() + (1 - percentage) * control.Left()
            end
        )

        background.Right:Set(
            function() 
                local percentage = progress()
                return percentage * content.Right() + (1 - percentage) * control.Right()
            end
        )

        -- define width and height by top/bottom and left/right values
        LayoutHelpers.LayoutFor(background)
            :ResetWidth()
            :ResetHeight()
            :End()

        -- animate it
        local startTime = GetSystemTimeSeconds()
        local endTime = startTime + duration
        while not IsDestroyed(self) do
            local currentTime = GetSystemTimeSeconds()
            if currentTime > endTime then
                break
            end

            -- compute where we are in the animation
            local percentage = math.clamp((currentTime - startTime) / (endTime - startTime), 0, 1)
            if state == 'Contract' then
                percentage = 1 - percentage
            end

            -- triggers the translation and scaling changes
            progress:Set(percentage)

            -- update alpha separately
            background:SetAlpha(percentage, true)

            WaitFrames(1)
        end
    end
}
