--*****************************************************************************
--* File: lua/modules/ui/dialogs/disconnect.lua
--* Author: Chris Blackwell
--* Summary: handles multiplayer disconnects
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local LazyVar = import('/lua/lazyvar.lua').Create

local parent = false
local Your_index = ''

function DestroyDialog()
    if parent then 
        parent:Destroy()
        parent = false
    end
end


local function CreateDialog(clients)
    import('/lua/ui/game/worldview.lua').UnlockInput()
    import('/lua/ui/game/gamemain.lua').KillWaitingDialog()
	
	GetCursor():Show()
    DestroyDialog()
    
    parent = Group(GetFrame(0), "diconnectDialogParentGroup")
    parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    parent:SetNeedsFrameUpdate(true)
    parent.time = 0
        
    bg = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'))
    LayoutHelpers.FillParent(bg, parent)
            
    bg.border = CreateBorder(bg)
            
    local dlgTitle = UIUtil.CreateText(bg, "<LOC UI_Disco0000>Connectivity", 18)
    LayoutHelpers.AtTopIn(dlgTitle, bg, -52)
    LayoutHelpers.AtHorizontalCenterIn(dlgTitle, parent)

    local slots = {}
    local previous = false

    for i,client in clients do
        local slot = Bitmap(bg, UIUtil.UIFile('/scx_menu/panel-brd/conn-bg.dds'),"clientSlotGroup " .. tostring(i))
        slots[i] = slot

        slot.index = i
        
        if client['local'] then -- GET your index local
			Your_index = i
			--LOG('>>> Local index:'..Your_index)
		end
		
		if previous then
            LayoutHelpers.Below(slot, previous)
        else
            LayoutHelpers.AtTopIn(slot, parent)
            LayoutHelpers.AtHorizontalCenterIn(slot, parent)
        end
        previous = slot
        
        slot.id = UIUtil.CreateText(slot, slot.index, 20, UIUtil.fixedFont)
        slot.id:SetColor('ffffffff')
        LayoutHelpers.AtLeftTopIn(slot.id, slot, 5, 1)
        
        slot.name = UIUtil.CreateText(slot, client.name, 16, UIUtil.fixedFont)
        slot.name:SetColor('FFbadbdb')
        LayoutHelpers.AtLeftTopIn(slot.name, slot, 20, 4)
        
        slot.state = Bitmap(slot) 																		-- Skull if the player is Dead
		slot.state:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds')) 	-- Skull bitmap
        slot.state:DisableHitTest()
		slot.state:Hide()
        LayoutHelpers.AtRightTopIn(slot.state, slot, 2, 2)
		
		slot.ping = UIUtil.CreateText(slot, "", 14, UIUtil.fixedFont)
        LayoutHelpers.AtLeftTopIn(slot.ping, slot, 5, 32)
        
        slot.quiet = UIUtil.CreateText(slot, "", 14, UIUtil.fixedFont)
        LayoutHelpers.AtLeftTopIn(slot.quiet, slot, 120, 32)
        
        slot.ejectedBy = UIUtil.CreateText(slot, '', 16, UIUtil.fixedFont)
        slot.ejectedBy:SetColor('FFbadbdb')
        LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)

        slot.eject = UIUtil.CreateButtonStd(slot, '/widgets02/small', "<LOC UI_Disco0005>Eject From Game", 12, 0)
        slot.eject.label:SetFont(UIUtil.bodyFont, 12)
        LayoutHelpers.AtLeftTopIn(slot.eject, slot, 248, 24)
        slot.eject.OnClick = function(self, modifiers) EjectSessionClient(slot.index) end
        slot.eject:Disable()    -- disable all temporarily so they can't be misclicked, then unlock a few seconds later
    end
	
	local canEject = false
	local ForceEject = false

    parent.OnFrame = function(self, delta)
        self.time = self.time + delta
        if self.time > 180 then
			ForceEject = true
		elseif self.time > 45 then
			canEject = true
        end
    end

    parent.Width:Set(function() return slots[1].Width() - 100 end)
    parent.Height:Set(function() return slots[1].Height() * table.getsize(slots) - 34 end)
    
    LayoutHelpers.AtCenterIn(parent, GetFrame(0))

    function parent.Update(self, clients)
		--local all_connected = nil
		--for index, client in clients do
			--if client.quiet > 1 and all_connected != false then
				--all_connected = true
				--LOG('>>> Connected ('..index..' - '..client.name..')')
			--else
				--all_connected = false
				--LOG('>>> Unconnected ('..index..' - '..client.name..')')
				--break
			--end
		--end
		--if all_connected then
			--LOG('>>> All_Connected : YES')
		--else
			--LOG('>>> All_Connected : NO')
		--end
		
		for index, client in clients do
            local slot = slots[index]
			local armiesInfo = GetArmiesTable().armiesTable
			
            if client.connected then
                if client.quiet < 5000 then--and armiesInfo[index].outOfGame == false then	-- IF client no lag and playing ...
					if canEject then
						slot.eject:Disable()
					end
                    slot.ping:SetText(LOCF("%s: %d", "<LOC UI_Disco0003>Ping (ms)", client.ping))
                    slot.quiet:SetText('')
                    slot.ping:SetColor('FFbadbdb')
                    slot.quiet:SetColor('FFbadbdb')					
                else																										-- IF client Lag --or Observer ...
					if ForceEject then																				-- IF client lag timeout (+3 minute), kick !
						EjectSessionClient(index)
						slot.eject:Disable()
						slot.eject:Hide()
					elseif armiesInfo[Your_index].outOfGame and canEject then				-- IF ME is Observer
						--LOG('>>> CanEject and outOfGame')
						EjectSessionClient(index)																-- Autokick the player lag
						slot.eject:Disable()																			-- and Hide + Disable the Eject button
						slot.eject:Hide()
					elseif canEject then--or armiesInfo[index].outOfGame then 				-- IF client Lag --or Observer ...
						--LOG('>>> CanEject')
						slot.eject:Enable()
					end
                    slot.ping:SetText(LOCF("%s: ---", "<LOC UI_Disco0003>Ping (ms)"))
                    slot.ping:SetColor('FFe24f2d')
                    slot.quiet:SetColor('FFe24f2d')
                    local min = client.quiet / (1000 * 60)
                    local sec = math.mod(client.quiet / 1000, 60)
                    slot.quiet:SetText(LOCF("%s: %d:%02d", "<LOC UI_Disco0004>Quiet (m:s)",min,sec))					
                end
            else
                slot.ping:SetText(LOC("<LOC connectivity_0003>Not Connected"))
				slot.ping:SetColor('FFff0000')
				--slot.ping:SetText('')
                --slot.quiet:SetText('')
            end
			
			if armiesInfo[index].outOfGame then -- Show the Skull if the player is Dead
				slot.state:Show()
				LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 34, 4)
			else
				LayoutHelpers.AtRightTopIn(slot.ejectedBy, slot, 5, 4)
				slot.state:Hide()
			end
			
            local ejectedBy = ''
            for k, v in client.ejectedBy do
                if ejectedBy != '' then
                    ejectedBy = ejectedBy .. ', ' .. tostring(v)
                else
                    ejectedBy = LOC('<LOC UI_Disco0006>Ejected by')..': '..tostring(v)
                end
            end
            slot.ejectedBy:SetText(ejectedBy)

            if client.connected and not client['local'] then
                if slot.eject:IsHidden() then slot.eject:Show() end
            else
                if not slot.eject:IsHidden() then slot.eject:Hide() end
            end
        end
    end
end



function Update()

    local needDialog = false

    local clients = GetSessionClients()

    local stillin = {}
    for index,client in clients do
        if client.connected then
            table.insert(stillin,index)
        end
    end

    for index,client in clients do
        if client.quiet > 5000 then
            needDialog = true
        end
        if client.connected then
            if not table.equal(client.ejectedBy, {}) then
                needDialog = true
            end
        else
            if not table.equal(table.sorted(client.ejectedBy), stillin) then
                needDialog = true
            end
        end
    end

    if needDialog then
        if not parent then
            CreateDialog(clients)
        end
        parent:Update(clients)
    else
        if parent then DestroyDialog() end
    end

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