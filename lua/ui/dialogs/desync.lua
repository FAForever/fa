--*****************************************************************************
--* File: lua/modules/ui/dialogs/desync.lua
--* Author: Chris Blackwell
--* Summary: handles multiplayer desyncs
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group

local dialog = false
local beforeFUCK = 0

function UpdateDialog(beatNumber, strings)
    if beforeFUCK != false then
		if not dialog then
			dialog = Group(GetFrame(0), "updateDialogGroup")
			LOG("Desynch at beat " .. beatNumber .. " tick " .. GetGameTimeSeconds())
			dialog.Width:Set(300)
			dialog.Height:Set(250)
			dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
			LayoutHelpers.AtCenterIn(dialog, GetFrame(0))
			local border, bg = UIUtil.CreateBorder(dialog, true)

			local title = UIUtil.CreateText(bg, "<LOC desync_0000>Desync Detected", 14, UIUtil.titleFont)
			LayoutHelpers.AtTopIn(title, dialog, 5)
			LayoutHelpers.AtHorizontalCenterIn(title, dialog)

			dialog.textControls = {}            
			local prev = false
			for i = 1,9 do
				dialog.textControls[i] = UIUtil.CreateText(bg, "", 12, UIUtil.bodyFont)
				if prev then
					LayoutHelpers.Below(dialog.textControls[i], prev, 5)
				else
					LayoutHelpers.AtLeftIn(dialog.textControls[i], bg, 5)
					dialog.textControls[i].Top:Set(function() return title.Bottom() + 5 end)
				end
				prev = dialog.textControls[i]
			end
			
			local okBtn = UIUtil.CreateButtonStd(bg, '/widgets/small', "<LOC _Ok>", 10)
			okBtn.Top:Set(dialog.textControls[9].Bottom)
			LayoutHelpers.AtLeftIn(okBtn, bg)
			okBtn.OnClick = function(self, modifiers)
				dialog:Destroy()
				dialog = false
				beforeFUCK = beforeFUCK + 1
			end
			
			local FUCKBtn = UIUtil.CreateButtonStd(bg, '/widgets/small', "FUCK this popup !", 10) -- Add rage button by Xinnony !, fucking popup.
			FUCKBtn.Top:Set(dialog.textControls[9].Bottom)
			LayoutHelpers.AtRightIn(FUCKBtn, bg)
			if beforeFUCK < 3 then
				FUCKBtn:Disable()
			else
				FUCKBtn:Enable()
			end
			FUCKBtn.OnClick = function(self, modifiers)
				dialog:Destroy()
				dialog = false
				beforeFUCK = false
			end
		end
		
		for i = 1,8 do
			if strings[i] then
				dialog.textControls[i]:SetText(strings[i])
			end
		end
		dialog.textControls[9]:SetText(LOC("<LOC desync_0001>Beat# ") .. tostring(beatNumber))
	else
		--PrintText(text, fontSize, fontColor, duration, location)
		PrintText('Desync !', 4, UIUtil.fontColor, 1, '')
	end
end