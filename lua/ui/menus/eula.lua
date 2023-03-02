--*****************************************************************************
--* File: lua/modules/ui/menus/eula.lua
--* Author: Ted Snook
--* Summary: Front end display of the EULA
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local WrapText = import("/lua/maui/text.lua").WrapText
local ItemList = import("/lua/maui/itemlist.lua").ItemList

function CreateEULA(inParent, callback)
    local parent = Group(inParent)
    LayoutHelpers.FillParent(parent, inParent)
    parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

    local worldCover = UIUtil.CreateWorldCover(parent, '00000000')

    local bg = Bitmap(parent, UIUtil.UIFile('/scx_menu/eula/eula.dds'))
    LayoutHelpers.AtCenterIn(bg, parent)

    bg.brackets = UIUtil.CreateDialogBrackets(bg, 40, 25, 40, 24)

    local exitButton = UIUtil.CreateButtonStd(bg, '/scx_menu/small-btn/small', "<LOC _Close>", 16, 2)
    exitButton.OnClick = function(self)
        parent:Destroy()
        if callback then
            callback()
        end
    end

    UIUtil.MakeInputModal(parent, function() exitButton.OnClick(exitButton) end, function() exitButton.OnClick(exitButton) end)

    local title = UIUtil.CreateText(bg, "<LOC EULA_TITLE>End User License Agreement", 20)
    LayoutHelpers.AtHorizontalCenterIn(title, bg)
    LayoutHelpers.AtTopIn(title, bg, 35)

    LayoutHelpers.AtBottomIn(exitButton, bg, 25)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, bg)

    local eulaBody = ItemList(bg)
    LayoutHelpers.AtLeftTopIn(eulaBody, bg, 30, 84)
    LayoutHelpers.SetDimensions(eulaBody, 630, 402)
    eulaBody:SetColors(UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor(), UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor()) -- we don't really want selection here so don't differentiate colors
    eulaBody:SetFont(UIUtil.bodyFont, 12)
    UIUtil.CreateVertScrollbarFor(eulaBody)

    local eulaText = import("/lua/ui/help/eula.lua").EULA
    local textBoxWidth = eulaBody.Width()

    local tempTable = WrapText(LOC(eulaText), textBoxWidth,
    function(text)
        return eulaBody:GetStringAdvance(text)
    end)

    for i, v in tempTable do
        eulaBody:AddItem(v)
    end
end