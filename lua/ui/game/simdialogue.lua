----*****************************************************************************
----* File: lua/ui/game/simdialogue.lua
----* Summary: UI controls for sim control
----*
----* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
----*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText

local dialogues = {}

function CreateSimDialogue(newDialogues)
    local function CreateBackground(parent)
        local bg = Bitmap(parent, UIUtil.UIFile('/game/ability_brd/chat_brd_m.dds'))
        LayoutHelpers.FillParent(bg, parent)
        bg.Depth:Set(function() return parent.Depth() - 5 end)

        bg.tl = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'))
        bg.t = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'))
        bg.tr = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'))
        bg.ml = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'))
        bg.mr = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'))
        bg.bl = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'))
        bg.bm = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'))
        bg.br = Bitmap(bg, UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'))

        bg.tlWidget = Bitmap(bg, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        bg.trWidget = Bitmap(bg, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        bg.blWidget = Bitmap(bg, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        bg.brWidget = Bitmap(bg, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

        LayoutHelpers.AtLeftTopIn(bg.tlWidget, bg.tl, -25, -10)
        LayoutHelpers.AtRightTopIn(bg.trWidget, bg.tr, -25, -10)
        LayoutHelpers.AtRightBottomIn(bg.brWidget, bg.br, -25, -10)
        LayoutHelpers.AtLeftBottomIn(bg.blWidget, bg.bl, -25, -10)

        bg.tl.Depth:Set(bg.Depth)
        bg.t.Depth:Set(bg.Depth)
        bg.tr.Depth:Set(bg.Depth)
        bg.ml.Depth:Set(bg.Depth)
        bg.mr.Depth:Set(bg.Depth)
        bg.bl.Depth:Set(bg.Depth)
        bg.bm.Depth:Set(bg.Depth)
        bg.br.Depth:Set(bg.Depth)

        bg.tl.Bottom:Set(parent.Top)
        bg.tl.Right:Set(parent.Left)

        bg.tr.Bottom:Set(parent.Top)
        bg.tr.Left:Set(parent.Right)

        bg.bl.Top:Set(parent.Bottom)
        bg.bl.Right:Set(parent.Left)

        bg.br.Top:Set(parent.Bottom)
        bg.br.Left:Set(parent.Right)

        bg.t.Bottom:Set(parent.Top)
        bg.t.Left:Set(parent.Left)
        bg.t.Right:Set(parent.Right)

        bg.bm.Top:Set(parent.Bottom)
        bg.bm.Left:Set(parent.Left)
        bg.bm.Right:Set(parent.Right)

        bg.ml.Top:Set(parent.Top)
        bg.ml.Bottom:Set(parent.Bottom)
        bg.ml.Right:Set(parent.Left)

        bg.mr.Top:Set(parent.Top)
        bg.mr.Bottom:Set(parent.Bottom)
        bg.mr.Left:Set(parent.Right)

        bg:DisableHitTest(true)
        return bg
    end
    local function CreateButton(dlg, text)
        local btn = Button(dlg,
            UIUtil.SkinnableFile('/widgets02/small_btn_up.dds'),
            UIUtil.SkinnableFile('/widgets02/small_btn_down.dds'),
            UIUtil.SkinnableFile('/widgets02/small_btn_over.dds'),
            UIUtil.SkinnableFile('/widgets02/small_btn_dis.dds'))
        btn.label = UIUtil.CreateText(btn, text, 12, UIUtil.bodyFont)
        btn.label:DisableHitTest()
        LayoutHelpers.AtCenterIn(btn.label, btn)
        return btn
    end
    local function CreateDialogue(info)
        local dlg = Group(GetFrame(0))
        dlg.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
        dlg.ID = info.ID
        dlg.background = CreateBackground(dlg)
        dlg.text = MultiLineText(dlg, UIUtil.bodyFont, 18, 'ffffffff')
        LayoutHelpers.SetWidth(dlg.text, 300)
        LayoutHelpers.AtTopIn(dlg.text, dlg)
        LayoutHelpers.AtHorizontalCenterIn(dlg.text, dlg)
        dlg.text:SetText(LOC(info.text) or '')
        dlg.text:SetColor(UIUtil.fontColor)
        dlg.btns = {}
        for index, text in info.buttonText do
            local i = index
            dlg.btns[i] = CreateButton(dlg, text)
            dlg.btns[i].ID = i
            dlg.btns[i].OnClick = function(self)
                SimCallback({Func = 'SimDialogueButtonPress', Args = {ID = dlg.ID, buttonID = self.ID, presser = GetFocusArmy()}})
            end
            if i == 1 and info.buttonText[2] then
                if dlg.text._text[1] then
                    LayoutHelpers.Below(dlg.btns[i], dlg.text._text[table.getsize(dlg.text._text)], 5)
                else
                    LayoutHelpers.AtLeftTopIn(dlg.btns[i], dlg, 5, 5)
                end
            elseif i == 1 then
                if dlg.text._text[1] then
                    LayoutHelpers.Below(dlg.btns[i], dlg.text._text[table.getsize(dlg.text._text)], 5)
                else
                    LayoutHelpers.AtTopIn(dlg.btns[i], dlg, 5)
                end
                LayoutHelpers.AtHorizontalCenterIn(dlg.btns[i], dlg)
            elseif math.mod(i, 2) == 1 and info.buttonText[i+1] then
                LayoutHelpers.Below(dlg.btns[i], dlg.btns[i-2], 5)
            elseif math.mod(i, 2) == 1 then
                LayoutHelpers.Below(dlg.btns[i], dlg.btns[i-2], 5)
                LayoutHelpers.AtHorizontalCenterIn(dlg.btns[i], dlg)
            else
                LayoutHelpers.RightOf(dlg.btns[i], dlg.btns[i-1], 5)
            end
        end
        dlg.buttonHeight = 0
        if dlg.btns[1] then
            dlg.buttonHeight = math.ceil(table.getsize(dlg.btns) / 2) * (dlg.btns[1].Height() + 5)
        end
        dlg.CalcHeight = function(self)
            if dlg.text._text[1] then
                self.Height:Set(function() return math.max(dlg.buttonHeight + (dlg.text:GetLineHeight() * table.getsize(dlg.text._text)), 90) end)
            else
                self.Height:Set(function() return math.max(dlg.buttonHeight, 90) end)
            end
        end
        dlg:CalcHeight()
        dlg.Width:Set(dlg.text.Width)
        dlg.SetPosition = function(self, position)
            if position == 'left' then
                LayoutHelpers.AtLeftTopIn(self, import("/lua/ui/game/borders.lua").GetMapGroup(), 40, 170)
                LayoutHelpers.ResetRight(self)
                LayoutHelpers.ResetBottom(self)
            elseif position == 'right' then
                LayoutHelpers.AtRightIn(self, import("/lua/ui/game/borders.lua").GetMapGroup(), 40)
                LayoutHelpers.AtBottomIn(self, import("/lua/ui/game/borders.lua").GetMapGroup(), 160)
                LayoutHelpers.ResetLeft(self)
                LayoutHelpers.ResetTop(self)
            else
                LayoutHelpers.AtCenterIn(self, import("/lua/ui/game/borders.lua").GetMapGroup())
                LayoutHelpers.ResetRight(self)
                LayoutHelpers.ResetBottom(self)
            end
        end
        dlg:SetPosition(info.position)
        return dlg
    end
    for _, info in newDialogues do
        dialogues[info.ID] = CreateDialogue(info)
    end
end

function SetButtonDisabled(buttonDisabledInfo)
    for _, info in buttonDisabledInfo do
        if dialogues[info.ID] and dialogues[info.ID].btns[info.buttonID] then
            if info.disabled then
                dialogues[info.ID].btns[info.buttonID]:Disable()
            else
                dialogues[info.ID].btns[info.buttonID]:Enable()
            end
        end
    end
end

function UpdatePosition(positionInfo)
    for _, info in positionInfo do
        if dialogues[info.ID] then
            dialogues[info.ID]:SetPosition(info.position)
        end
    end
end

function UpdateButtonText(updatedButtonText)
    for _, info in updatedButtonText do
        if dialogues[info.ID] and dialogues[info.ID].btns[info.buttonID] then
            dialogues[info.ID].btns[info.buttonID].label:SetText(info.text)
        end
    end
end

function SetDialogueText(updatedDialogueText)
    for _, info in updatedDialogueText do
        if dialogues[info.ID] then
            dialogues[info.ID].text:SetText(info.text)
            dialogues[info.ID].text:SetColor(UIUtil.fontColor)
            if dialogues[info.ID].btns[1] then
                if dialogues[info.ID].text._text[1] then
                    LayoutHelpers.Below(dialogues[info.ID].btns[1], dialogues[info.ID].text._text[table.getsize(dialogues[info.ID].text._text)], 5)
                else
                    LayoutHelpers.AtLeftTopIn(dialogues[info.ID].btns[1], dialogues[info.ID], 5, 5)
                end
            end
            dialogues[info.ID]:CalcHeight()
        end
    end
end

function DestroyDialogue(destroyedDialogues)
    for _, dlgID in destroyedDialogues do
        if dialogues[dlgID] then
            for _, line in dialogues[dlgID].text._text do
                line:Destroy()
            end
            dialogues[dlgID]:Destroy()
            dialogues[dlgID] = nil
        end
    end
end