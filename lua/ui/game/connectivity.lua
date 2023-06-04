--*****************************************************************************
--* File: lua/modules/ui/game/connectivity.lua
--* Author: Ted Snook
--* Summary: Connectivity Dialog
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameMain = import("/lua/ui/game/gamemain.lua")

local SessionClients = import("/lua/ui/override/sessionclients.lua")

local GUI = {
    slots = {},
    bgTop = false,
    bgBottom = false,
    group = false,
}

local updateThread = nil

function PingUpdate()
    while true do
        local clients = GetSessionClients()
        local armiesInfo = GetArmiesTable().armiesTable

        for i, clientInfo in clients do
            local index = i
            local slot = GUI.slots[index]
            if slot then
                slot.name:SetText(clientInfo.name)

                if clientInfo.connected then
                    slot.ping:SetText(LOCF("<LOC connectivity_0000>Ping (ms): %d", clientInfo.ping))
                    if clientInfo.ping < 200 then
                        slot.ping:SetColor('ff00ff00') -- Ping green color
                    elseif clientInfo.ping < 400 then
                        slot.ping:SetColor('ffffff00') -- Ping yellow color
                    else
                        slot.ping:SetColor('ffff0000') -- Ping red color
                    end

                    if clientInfo.quiet > 3000 then
                        local min = clientInfo.quiet / (1000 * 60)
                        local sec = math.mod(clientInfo.quiet / 1000, 60)
                        slot.quiet:SetText(LOCF("<LOC connectivity_0001>Quiet (m:s): %d:%02d", min, sec))
                        slot.quiet:Show()
                    else
                        slot.quiet:Hide()
                    end

                    if armiesInfo[index].outOfGame then
                        slot.conn:SetColor('ff00ff00')
                        slot.conn:SetText(LOC("<LOC connectivity_0002>Connected"))
                        slot.state:Show()
                    else
                        slot.conn:SetColor('ff00ff00')
                        slot.conn:SetText(LOC("<LOC connectivity_0002>Connected"))
                        slot.state:Hide()
                    end
                    slot.ping:Show()
                else
                    slot.ping:Hide()
                    slot.quiet:Hide()
                    slot.conn:SetColor('ffff0000')
                    slot.conn:SetText(LOC("<LOC connectivity_0003>Not Connected"))
                    slot.state:Show()
                end

                if not clientInfo.connected or clientInfo.quiet > 3000 then
                    slot.name:SetColor('ffff0000')
                else
                    slot.name:SetColor('ffffffff')
                end
            end
        end

        WaitSeconds(.1)
    end
end

function CreateUI()
    if not SessionIsMultiplayer() then
        return
    end
    if GUI.group then
        CloseWindow()
        return
    end

    ConExecute('ren_shownetworkstats true')

    local _,isSession = UIUtil.GetNetworkBool()
    if not isSession then return end

    SessionClients.FastInterval()

    GUI.group = Bitmap(GetFrame(0), UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'))
    GUI.group.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

    GUI.group.wc = UIUtil.CreateWorldCover(GUI.group)

    GUI.border = CreateBorder(GUI.group)
    GUI.brackets = UIUtil.CreateDialogBrackets(GUI.group, 106, 110, 110, 108, true)

    GUI.title = UIUtil.CreateText(GUI.border.tm, '<LOC _Connectivity>', 20)
    LayoutHelpers.AtTopIn(GUI.title, GUI.border.tm, 12)
    LayoutHelpers.AtHorizontalCenterIn(GUI.title, GUI.group)

    GUI.closeBtn = UIUtil.CreateButtonStd(GUI.group, '/scx_menu/small-btn/small', '<LOC _Close>', 16, 2)
    LayoutHelpers.AtTopIn(GUI.closeBtn, GUI.border.bm, -20)
    LayoutHelpers.AtHorizontalCenterIn(GUI.closeBtn, GUI.group)
    GUI.closeBtn.OnClick = function(self)
        RemoveInputCapture(GUI.group)
        CloseWindow()
    end

    AddInputCapture(GUI.group)
    GUI.group.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 352 then
                GUI.closeBtn:OnClick()
            end
        end
    end

    local clients = GetSessionClients()

    GUI.slots = {}
    local prevControl = false
    local height = 0

    for i, clientInfo in clients do
        local slot = {}

        slot.bg = Bitmap(GUI.group, UIUtil.UIFile('/scx_menu/panel-brd/conn-bg.dds'))
        if prevControl then
            LayoutHelpers.Below(slot.bg, prevControl)
        else
            LayoutHelpers.AtTopIn(slot.bg, GUI.group)
            LayoutHelpers.AtHorizontalCenterIn(slot.bg, GUI.group)
        end

        slot.name = UIUtil.CreateText(slot.bg, '', 18, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(slot.name, slot.bg, 10, 2)

        slot.state = Bitmap(GUI.group)
        slot.state:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds')) -- Skull bitmap
        slot.state:DisableHitTest()
        slot.state:Hide()
        LayoutHelpers.AtRightTopIn(slot.state, slot.bg, 2, 2)

        slot.ping = UIUtil.CreateText(slot.bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(slot.ping, slot.bg, 10, 30)

        slot.quiet = UIUtil.CreateText(slot.bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(slot.quiet, slot.bg, 150, 30)

        slot.conn = UIUtil.CreateText(slot.bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtRightTopIn(slot.conn, slot.bg, 10, 30)

        height = height + slot.bg.Height()
        prevControl = slot.bg

        GUI.slots[i] = slot
    end

    GUI.group.Height:Set(height+12)
    GUI.group.Width:Set(function() return GUI.slots[1].bg.Width() - 80 end)

    LayoutHelpers.AtCenterIn(GUI.group, GetFrame(0))

    if not updateThread then
        updateThread = ForkThread(PingUpdate)
    end
end

function CloseWindow()

    SessionClients.ResetInterval()

    if updateThread then
        KillThread(updateThread)
        updateThread = nil
    end
    GUI.group:Destroy()
    GUI.group = false
    ConExecute('ren_shownetworkstats false')
end

function CreateBorder(parent)
    local tbl = {}
    tbl.tl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ul.dds'))
    tbl.tm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_horz_um.dds'))
    tbl.tr = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ur.dds'))
    tbl.l = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_l.dds'))
    tbl.r = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_r.dds'))
    tbl.bl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ll.dds'))
    tbl.bm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lm.dds'))
    tbl.br = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lr.dds'))

    tbl.tl.Bottom:Set(parent.Top)
    tbl.tl.Right:Set(parent.Left)

    tbl.tr.Bottom:Set(parent.Top)
    tbl.tr.Left:Set(parent.Right)

    tbl.tm.Bottom:Set(parent.Top)
    tbl.tm.Right:Set(parent.Right)
    tbl.tm.Left:Set(parent.Left)

    tbl.l.Bottom:Set(parent.Bottom)
    tbl.l.Top:Set(parent.Top)
    tbl.l.Right:Set(parent.Left)

    tbl.r.Bottom:Set(parent.Bottom)
    tbl.r.Top:Set(parent.Top)
    tbl.r.Left:Set(parent.Right)

    tbl.bl.Top:Set(parent.Bottom)
    tbl.bl.Right:Set(parent.Left)

    tbl.br.Top:Set(parent.Bottom)
    tbl.br.Left:Set(parent.Right)

    tbl.bm.Top:Set(parent.Bottom)
    tbl.bm.Right:Set(parent.Right)
    tbl.bm.Left:Set(parent.Left)

    tbl.tl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tr.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.l.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.r.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.br.Depth:Set(function() return parent.Depth() - 1 end)

    return tbl
end
