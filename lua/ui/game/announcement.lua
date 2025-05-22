--*****************************************************************************
--* File: lua/modules/ui/game/announcement.lua
--* Author: Ted Snook
--* Summary: Announcement UI for sending general messages to the user
--*
--* Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local SmallAnnouncement = import("/lua/ui/game/announcement/SmallAnnouncement.lua").SmallAnnouncement

local MATH_Lerp = MATH_Lerp

local bg = false

--- Create an announcement UI for sending general messages to the user
---@param text UnlocalizedString # title text
---@param goalControl? Control The control where the announcement appears out of.
---@param secondaryText? UnlocalizedString # body text
---@param onFinished? function
function CreateAnnouncement(text, goalControl, secondaryText, onFinished)
    local frame = GetFrame(0)

    do
        -- just do nothing
        LOG(text, goalControl, secondaryText, onFinished)

        ForkThread(
            function()
                local announcement = SmallAnnouncement(frame, goalControl, onFinished, text)
                WaitSeconds(3)
                announcement:FadeOut(3)
            end
        )

        return
    end

    if not goalControl then
        -- make it originate from the top
        goalControl = Group(frame)
        goalControl.Left:Set(function() return frame.Left() + 0.49 * frame.Right() end)
        goalControl.Right:Set(function() return frame.Left() + 0.51 * frame.Right() end)
        goalControl.Top:Set(function() return frame.Top() end);
        goalControl.Height:Set(0)
    end

    local scoreDlg = import("/lua/ui/dialogs/score.lua")
    if scoreDlg.dialog then
        if onFinished then
            onFinished()
        end
        return
    end

    if bg then
        if bg.OnFinished then
            bg.OnFinished()
        end
        bg.OnFrame = function(self, delta)
            local newAlpha = self:GetAlpha() - (delta*2)
            if newAlpha < 0 then
                newAlpha = 0
                self:Destroy()
                bg.OnFinished = nil
                bg = false
                CreateAnnouncement(text, goalControl, secondaryText, onFinished)
            end
            self:SetAlpha(newAlpha, true)
            if bg.secText then
                bg.secText:SetAlphaOfColors(newAlpha)
            end
        end
        return
    end

    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Open'}))

    bg = Layouter(Bitmap(frame, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_m.dds')))
        :Height(0):Width(0):Over(frame, 1):AtCenterIn(goalControl):End()
    bg.border = CreateBorder(bg)

    local textGroup = Group(bg)

    local title = Layouter(UIUtil.CreateText(textGroup, text, 22, UIUtil.titleFont))
        :AtCenterIn(frame, -250)
        :DropShadow(true):Color(UIUtil.fontColor)
        :NeedsFrameUpdate(true):End()

    local secText
    if secondaryText then
        secText = TextArea(textGroup, 600, 60)
        secText:SetFont(UIUtil.bodyFont, 18)
        secText:SetText(secondaryText)
        secText:FitToText()
        secText:SetTextAlignment(0.5)
        secText:SetColors(UIUtil.fontColor)
        secText:SetAlphaOfColors(0)
        Layouter(secText):CenteredBelow(title, 10):End()
        bg.secText = secText

        Layouter(textGroup):Top(title.Top)
            :Left(function() return math.min(secText.Left(), title.Left()) end)
            :Right(function() return math.max(secText.Right(), title.Right()) end)
            :Bottom(secText.Bottom):End()
    else
        LayoutHelpers.FillParent(textGroup, title)
    end
    bg:DisableHitTest(true)

    textGroup:SetAlpha(0, true)

    bg:SetNeedsFrameUpdate(true)

    bg.OnFinished = onFinished
    bg.time = 0
    local tGTop, tGLeft, tGRight, tGBottom, tGHeight, tGWidth = textGroup.Top(), textGroup.Left(), textGroup.Right(), textGroup.Bottom(), textGroup.Height(), textGroup.Width()
    local gCTop, gCLeft, gCRight, gCBottom, gCHeight, gCWidth = goalControl.Top(), goalControl.Left(), goalControl.Right(), goalControl.Bottom(), goalControl.Height(), goalControl.Width()

    bg.OnFrame = function(self, delta)
        local time = self.time + delta
        self.time = time

        -- expansion animation
        if time < .2 then
            local lerpMult = MATH_Lerp(time, 0, 0.2, 0, 1)
            self.Top:Set(MATH_Lerp(lerpMult, gCTop, tGTop))
            self.Left:Set(MATH_Lerp(lerpMult, gCLeft, tGLeft))
            self.Right:Set(MATH_Lerp(lerpMult, gCRight, tGRight))
            self.Bottom:Set(MATH_Lerp(lerpMult, gCBottom, tGBottom))
            self.Height:Set(MATH_Lerp(lerpMult, gCHeight, tGHeight))
            self.Width:Set(MATH_Lerp(lerpMult, gCWidth, tGWidth))
        -- stationary
        elseif time > .2 and time < 3.5 and not self.TextGroupReached then
            Layouter(self):Fill(textGroup):End()
            self.TextGroupReached = true
        -- contraction animation
        elseif time >= 3.5 and time < 3.7 then
            if not self.CloseSoundPlayed then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Announcement_Close'}))
                self.CloseSoundPlayed = true
            end
            local lerpMult = MATH_Lerp(time, 3.5, 3.7, 0, 1)
            self.Top:Set(MATH_Lerp(lerpMult, tGTop, gCTop))
            self.Left:Set(MATH_Lerp(lerpMult, tGLeft, gCLeft))
            self.Right:Set(MATH_Lerp(lerpMult, tGRight, gCRight))
            self.Bottom:Set(MATH_Lerp(lerpMult, tGBottom, gCBottom))
            self.Height:Set(MATH_Lerp(lerpMult, tGHeight, gCHeight))
            self.Width:Set(MATH_Lerp(lerpMult, tGWidth, gCWidth))
        end

        local textGroupAlpha = textGroup:GetAlpha()
        local titleAlpha = title:GetAlpha()
        -- fade out the text at the end of the announcement
        if time > 3 and textGroupAlpha ~= 0 then
            local newAlpha = math.max(textGroupAlpha - (delta * 2), 0)
            textGroup:SetAlpha(newAlpha, true)
            if secText then
                secText:SetAlphaOfColors(newAlpha)
            end
        -- fade in the text when the announcement appears
        elseif time > .2 and time < 3 and titleAlpha ~= 1 then
            local newAlpha = math.min(titleAlpha + (delta * 2), 1)
            textGroup:SetAlpha(newAlpha, true)
            if secText then
                secText:SetAlphaOfColors(newAlpha)
            end
        end

        if time > 3.7 then
            if bg.OnFinished then
                bg.OnFinished()
            end
            bg:Destroy()
            bg.OnFinished = nil
            bg = false
        end
    end

    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        bg:Hide()
    end
end

--- Instantly hides the current announcement
function Contract()
    if bg then
        bg:Hide()
    end
end

--- Instantly shows the current announcement
function Expand()
    if bg then
        bg:Show()
    end
end

--- Create a border around the `parent` with the `filter-ping-list-panel` files
---@param parent Control
---@return { tl: Bitmap, tm: Bitmap, tr: Bitmap, ml: Bitmap, mr: Bitmap, bl: Bitmap, bm: Bitmap, br: Bitmap } border
function CreateBorder(parent)
    -- t, m, b = top, middle, bottm
    -- l, m, r = left, middle, right
    local tl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
    local tm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
    local tr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
    local ml = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
    local mr = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
    local bl = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
    local bm = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
    local br = Bitmap(parent, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))

    Layouter(tl):TopLeftOf(parent):End()
    Layouter(tm):CenteredAbove(parent):FillHorizontally(parent):End()
    Layouter(tr):TopRightOf(parent):End()
    Layouter(ml):CenteredLeftOf(parent):FillVertically(parent):End()
    Layouter(mr):CenteredRightOf(parent):FillVertically(parent):End()
    Layouter(bl):BottomLeftOf(parent):End()
    Layouter(bm):CenteredBelow(parent):FillHorizontally(parent):End()
    Layouter(br):BottomRightOf(parent):End()

    return { ["tl"] = tl, ["tm"] = tm, ["tr"] = tr, ["ml"] = ml, ["mr"] = mr, ["bl"] = bl, ["bm"] = bm, ["br"] = br }
end
