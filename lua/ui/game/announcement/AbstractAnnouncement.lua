--******************************************************************************************************
--** Copyright (c) 2025  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local CreateLazyVar = import("/lua/lazyvar.lua").Create

--- An abstract announcement that has all the functionality that you would expect from an announcement. Do not create an instance of this class.
---@class UIAbstractAnnouncement : Destroyable, Group
---@field Trash TrashBag
---@field AnimateBackgroundThreadInstance? thread
---@field AnimateThreadInstance? thread
---@field AnimateContentThreadInstance? thread
---@field AbortAnimationThreadInstance? thread
---@field Background Bitmap                     # Background that we animate
---@field BackgroundBorderTopLeft Bitmap        # Border element of the background
---@field BackgroundBorderTop Bitmap            # Border element of the background
---@field BackgroundBorderTopRight Bitmap       # Border element of the background
---@field BackgroundBorderLeft Bitmap           # Border element of the background
---@field BackgroundBorderRight Bitmap          # Border element of the background
---@field BackgroundBorderBottomLeft Bitmap     # Border element of the background
---@field BackgroundBorderBottom Bitmap         # Border element of the background
---@field BackgroundBorderBottomRight Bitmap    # Border element of the background
---@field ContentArea Group                     # Content area that we animate to/from
AbstractAnnouncement = ClassUI(Group) {

    -- Announcements works by morphing the background from a control, to the content area, and then back. By doing so,
    -- we give the player an idea what the announcement is connected to. The content of the announcement is never 
    -- moved, only the background is. The alpha of the content is adjusted when the announcement arrives and 
    -- leaves again.

    -- To make it more concrete:
    -- - The 'ContentArea' is the area that we animate towards when displaying the announcement, and away from when hiding it
    -- - The 'Background' is the background that we animate

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
        Layouter(self)
            :Height(0)
            :Width(0)
            :AtCenterIn(frame, -250)
            :Over(parent, 1)
            :End()

        -- by default, fill the parent
        Layouter(self.ContentArea)
            :Fill(self)
            :End()

        -- by default, just fill the parent
        Layouter(self.Background)
            :Fill(self)
            :Alpha(0, true)
            :End()

        -- put border around the background
        Layouter(self.BackgroundBorderTopLeft)
            :TopLeftOf(self.Background)
            :End()

        Layouter(self.BackgroundBorderTop)
            :CenteredAbove(self.Background)
            :FillHorizontally(self.Background)
            :End()

        Layouter(self.BackgroundBorderTopRight)
            :TopRightOf(self.Background)
            :End()

        Layouter(self.BackgroundBorderLeft)
            :CenteredLeftOf(self.Background)
            :FillVertically(self.Background)
            :End()

        Layouter(self.BackgroundBorderRight)
            :CenteredRightOf(self.Background)
            :FillVertically(self.Background)
            :End()

        Layouter(self.BackgroundBorderBottomLeft)
            :BottomLeftOf(self.Background)
            :End()

        Layouter(self.BackgroundBorderBottom)
            :CenteredBelow(self.Background)
            :FillHorizontally(self.Background)
            :End()

        Layouter(self.BackgroundBorderBottomRight)
            :BottomRightOf(self.Background)
            :End()
    end,

    ---@param self UIAbstractAnnouncement
    OnDestroy = function(self)
        Bitmap.OnDestroy(self)

        self.Trash:Destroy()
    end,

    --- A utility function to set the alpha of the content. Concrete implementations 
    --- can hook this function to set the alpha value of UI elements that do propagate 
    --- properly when the alpha of a parent is set (looking at you, TextArea).
    ---@param self UIAbstractAnnouncement
    ---@param value number
    SetAlphaOfContent = function(self, value)
        self.ContentArea:SetAlpha(value, true)
    end,

    ---------------------------------------------------------------------------
    --#region Interface to animate

    --- The default animation sequence for an announcement. The announcement is destroyed at the end of the animation.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param durationForContent number
    Animate = function(self, control, durationForContent)
        -- do not allow other animations
        if self.AnimateThreadInstance then
            self.AnimateThreadInstance:Destroy()
        end

        self.AnimateThreadInstance = self.Trash:Add(ForkThread(self.AnimateThread, self, control, durationForContent))
    end,

    --- The default animation sequence for an announcement. The announcement is destroyed at the end of the animation.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param durationForContent number
    AnimateThread = function(self, control, durationForContent)
        -- early exist for edge case
        if IsDestroyed(self) then
            return
        end

        -- internal configuration of the animation
        local expandDuration = 0.4
        local contractDuration = 0.4
        local contentShowDuration = 0.2
        local contentHideDuration = 0.4

        -- expand animation
        self:ExpandBackground(control, expandDuration)
        WaitSeconds(expandDuration)
        if IsDestroyed(self) then
            return
        end

        -- show content and hide it
        self:AnimateContent(contentShowDuration, 1.0)
        WaitSeconds(contentShowDuration + durationForContent)
        if IsDestroyed(self) then
            return
        end

        self:AnimateContent(contentHideDuration, 0.0)
        WaitSeconds(contentHideDuration)
        if IsDestroyed(self) then
            return
        end

        -- contract animation
        self:ContractBackground(control, contractDuration)
        WaitSeconds(contractDuration)
        if IsDestroyed(self) then
            return
        end

        self:Destroy()
    end,

    --- Animates the alpha value of the content area.
    ---@param self UIAbstractAnnouncement
    ---@param duration number
    ---@param targetTransparency number
    AnimateContent = function(self, duration, targetTransparency)
        -- do not allow other animations
        if self.AnimateContentThreadInstance then
            self.AnimateContentThreadInstance:Destroy()
        end

        local from = self.ContentArea:GetAlpha()
        self.AnimateContentThreadInstance = self.Trash:Add(ForkThread(self.AnimateContentThread, self, duration, from, targetTransparency))
    end,

    --- Animates the alpha value of the content area.
    ---@param self UIAbstractAnnouncement
    ---@param duration number
    ---@param target number
    AnimateContentThread = function(self, duration, from, target)
        -- early exit for edge case
        if IsDestroyed(self) then
            return
        end

        local startTime = GetSystemTimeSeconds()
        local endTime = startTime + duration
        while not IsDestroyed(self) do
            local currentTime = GetSystemTimeSeconds()
            if currentTime > endTime then
                break
            end

            local progress = (currentTime - startTime) / duration
            local alpha = math.clamp(MATH_Lerp(progress, from, target), 0, 1)
            self:SetAlphaOfContent(alpha)

            WaitFrames(1)
        end

        -- always make sure the target is reached
        self:SetAlphaOfContent(target)
    end,

    --- Expands the background of the announcement, starting at the provided control towards the content area.
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

    --- Animates the background. Use the utility functions `ExpandBackground` and `ContractBackground` to
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ---@param state 'Expand' | 'Contract'
    AnimateBackground = function(self, control, duration, state)
        -- do not allow other animations
        if self.AnimateBackgroundThreadInstance then
            self.AnimateBackgroundThreadInstance:Destroy()
        end

        -- animate position and scale
        self.AnimateBackgroundThreadInstance = self.Trash:Add(ForkThread(self.AnimateBackgroundThread, self, control, duration, state))
    end,

    --- Expands the background of the announcement, starting at the provided control towards the center of the screen.
    ---@param self UIAbstractAnnouncement
    ---@param control Control
    ---@param duration number
    ---@param state 'Expand' | 'Contract'
    AnimateBackgroundThread = function(self, control, duration, state)
        -- early exit for edge case
        if IsDestroyed(self) then
            return
        end

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
        Layouter(background)
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

        -- make sure animation completes properly even when there are frame drops
        if state == 'Expand' then
            progress:Set(1)
        else
            progress:Set(0)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Interface to abort 

    --- Aborts the announcement. All animations are stopped. The announcement is turned transparent and then destroyed.
    ---@param self UIAbstractAnnouncement
    AbortAnnouncement = function(self)
        -- make the function idempotent
        if self.AbortAnimationThreadInstance then
            return
        end

        self:CancelAnimation()
        self:CancelContentAnimation()

        self.AbortAnimationThreadInstance = self.Trash:Add(ForkThread(self.AbortAnimationThread, self))
    end,

    --- Aborts the announcement by turning it completely transparent. The announcement is destroyed at the end of it.
    ---@param self UIAbstractAnnouncement
    AbortAnimationThread = function(self)
        -- early exit for edge case
        if IsDestroyed(self) then
            return
        end

        local alphaContent = self.ContentArea:GetAlpha()
        local alphaBackground = self.Background:GetAlpha()

        local lastTime = GetSystemTimeSeconds()
        while not IsDestroyed(self) do
            local currentTime = GetSystemTimeSeconds()
            local diff = 2 * (currentTime - lastTime) -- 100% alpha change in 0.5 seconds
            lastTime = currentTime

            alphaContent = math.clamp(alphaContent - diff, 0, 1)
            alphaBackground = math.clamp(alphaBackground - diff, 0, 1)

            self:SetAlphaOfContent(alphaContent)
            self.Background:SetAlpha(alphaBackground, true)

            if alphaContent == 0 and alphaBackground == 0 then
                break
            end

            WaitFrames(1)
        end

        self:Destroy()
    end,

    --- Cancels the main animation thread.
    ---@param self UIAbstractAnnouncement
    CancelAnimation = function(self)
        if self.AnimateThreadInstance then
            self.AnimateThreadInstance:Destroy()
        end
    end,

    --- Cancels the animation of the background, stopping it in its tracks.
    ---@param self UIAbstractAnnouncement
    CancelBackgroundAnimation = function(self)
        if self.AnimateBackgroundThreadInstance then
            self.AnimateBackgroundThreadInstance:Destroy()
        end
    end,

    --- Cancels the animation of the content.
    ---@param self UIAbstractAnnouncement
    CancelContentAnimation = function(self)
        if self.AnimateContentThreadInstance then
            self.AnimateContentThreadInstance:Destroy()
        end
    end,

    --#endregion
}
