--*****************************************************************************
--* File: lua/modules/ui/game/connectivity.lua
--* Author: Ted Snook
--* Summary: Connectivity Dialog
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GameMain = import('/lua/ui/game/gamemain.lua')

local GUI = {
    slots = {},
    bgTop = false,
    bgBottom = false,
    group = false,
}
function PingUpdate()
    local clients = GetSessionClients()
	local armiesInfo = GetArmiesTable().armiesTable
    
	for i, clientInfo in clients do
        local index = i
        if GUI.slots[index] then
            GUI.slots[index].name:SetText(clientInfo.name)
            
            if clientInfo.connected then
                GUI.slots[index].ping:SetText(LOCF("<LOC connectivity_0000>Ping (ms): %d", clientInfo.ping))
                
                if clientInfo.ping < 200 then
                    GUI.slots[index].ping:SetColor('ff00ff00') -- Ping green color
                elseif clientInfo.ping < 400 then
                    GUI.slots[index].ping:SetColor('ffffff00') -- Ping yellow color
                else
                    GUI.slots[index].ping:SetColor('ffff0000') -- Ping red color
                end
            
                if clientInfo.quiet > 3000 then
                    local min = clientInfo.quiet / (1000 * 60)
                    local sec = math.mod(clientInfo.quiet / 1000, 60)
                    GUI.slots[index].quiet:Show()
                    GUI.slots[index].quiet:SetText(LOCF("<LOC connectivity_0001>Quiet (m:s): %d:%02d", min, sec))
                else
                    GUI.slots[index].quiet:Hide()
                end
            
				if armiesInfo[index].outOfGame then -- Player dead
					GUI.slots[index].conn:SetColor('ff00ff00') -- Green
					--GUI.slots[index].conn:SetColor('ffffff00') -- Yellow
					GUI.slots[index].conn:SetText(LOC("<LOC connectivity_0002>Connected"))
					GUI.slots[index].state:Show()
				else -- Player not dead
					GUI.slots[index].conn:SetColor('ff00ff00') -- Green
					GUI.slots[index].conn:SetText(LOC("<LOC connectivity_0002>Connected"))
					GUI.slots[index].state:Hide()
				end
                
				GUI.slots[index].ping:Show()
            else
                GUI.slots[index].ping:Hide()
                GUI.slots[index].quiet:Hide()
                GUI.slots[index].conn:SetColor('ffff0000')
                GUI.slots[index].conn:SetText(LOC("<LOC connectivity_0003>Not Connected"))
				GUI.slots[index].state:Show()
            end
            
            if not clientInfo.connected or clientInfo.quiet > 3000 then
                GUI.slots[index].name:SetColor('ffff0000')
            else
                GUI.slots[index].name:SetColor('ffffffff')
            end
        end
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
    
    local _,isSession = UIUtil.GetNetworkBool()
    if not isSession then return end
    
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
        local index = i
        GUI.slots[index] = {}
        
        GUI.slots[index].bg = Bitmap(GUI.group, UIUtil.UIFile('/scx_menu/panel-brd/conn-bg.dds'))
        if prevControl then
            LayoutHelpers.Below(GUI.slots[index].bg, prevControl)
        else
            LayoutHelpers.AtTopIn(GUI.slots[index].bg, GUI.group)
            LayoutHelpers.AtHorizontalCenterIn(GUI.slots[index].bg, GUI.group)
        end
        
        GUI.slots[index].name = UIUtil.CreateText(GUI.slots[index].bg, '', 18, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(GUI.slots[index].name, GUI.slots[index].bg, 10, 2)
		
		GUI.slots[index].state = Bitmap(GUI.group)
		GUI.slots[index].state:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds')) -- Skull bitmap
        GUI.slots[index].state:DisableHitTest()
		GUI.slots[index].state:Hide()
        LayoutHelpers.AtRightTopIn(GUI.slots[index].state, GUI.slots[index].bg, 2, 2)
        
        GUI.slots[index].ping = UIUtil.CreateText(GUI.slots[index].bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(GUI.slots[index].ping, GUI.slots[index].bg, 10, 30)
        
        GUI.slots[index].quiet = UIUtil.CreateText(GUI.slots[index].bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(GUI.slots[index].quiet, GUI.slots[index].bg, 150, 30)
        
        GUI.slots[index].conn = UIUtil.CreateText(GUI.slots[index].bg, '', 16, UIUtil.bodyFont)
        LayoutHelpers.AtRightTopIn(GUI.slots[index].conn, GUI.slots[index].bg, 10, 30)
        
        height = height + GUI.slots[index].bg.Height()
        prevControl = GUI.slots[index].bg
    end
    
    GUI.group.Height:Set(height+12)
    GUI.group.Width:Set(function() return GUI.slots[1].bg.Width() - 80 end)
    
    LayoutHelpers.AtCenterIn(GUI.group, GetFrame(0))
    
    GameMain.AddBeatFunction(PingUpdate)
end

function CloseWindow()
    GameMain.RemoveBeatFunction(PingUpdate)
    GUI.group:Destroy()
    GUI.group = false
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