--*****************************************************************************
--* File: lua/modules/ui/game/commandgraph.lua
--* Summary: Command graph display funcs
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Text = import("/lua/maui/text.lua").Text
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local trashBtn = nil
local dragging = false

function OnCommandGraphShow(show)

    import("/lua/ui/game/reclaim.lua").OnCommandGraphShow(show)

    --Table of all map views to display pings in
    local views = import("/lua/ui/game/worldview.lua").GetWorldViews()
    for i, v in views do
        if v and not v.DisableMarkers then
            v:ShowPings(show)
        end
    end
--    if not show then
--        if trashBtn then
--            trashBtn:Destroy()
--            trashBtn = nil
--        end
--    else
--        if not trashBtn then
--            local worldView = import("/lua/ui/game/borders.lua").GetMapGroup()
--            trashBtn = Button(worldView,
--                              UIUtil.UIFile('/game/icons/icon-trash-lg_btn_up.dds'),
--                              UIUtil.UIFile('/game/icons/icon-trash-lg_btn_down.dds'),
--                              UIUtil.UIFile('/game/icons/icon-trash-lg_btn_over.dds'),
--                              UIUtil.UIFile('/game/icons/icon-trash-lg_btn_dis.dds'))
--            trashBtn.Width:Set(64)
--            trashBtn.Height:Set(64)
--            LayoutHelpers.AtBottomIn(trashBtn, worldView, 16)
--            LayoutHelpers.AtRightIn(trashBtn, worldView, 16)
--            trashBtn.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
--
--            trashBtn.HandleEvent = function(self, event)
--                if dragging then
--                    Button.HandleEvent(self,event)
--                end
--            end
--
--        end
--    end
end

function OnCommandDragBegin()
--    local worldView = import("/lua/ui/game/worldview.lua").view
--    worldView:OnCommandDragBegin()
--
--    dragging = true
end

function OnCommandDragEnd(event,cmdId)
--    local worldView = import("/lua/ui/game/worldview.lua").view
--    worldView:OnCommandDragEnd()
--
--    if trashBtn then
--        if (event.MouseX > trashBtn.Left() and event.MouseX < trashBtn.Right() and
--            event.MouseY > trashBtn.Top() and event.MouseY < trashBtn.Bottom()) then
--            DeleteCommand(cmdId)
--            trashBtn:SetTexture(trashBtn.mNormal)
--        end
--    end
--    dragging = false
end
