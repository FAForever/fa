--*****************************************************************************
--* File: lua/modules/ui/game/gamemain.lua
--* Author: Chris Blackwell
--* Summary: Entry point for the in game UI
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

view = false

function ShowLogoInHead1()
    if GetNumRootFrames() < 2 then return end

    local rootFrame = GetFrame(1)
    local bg = Bitmap(rootFrame, UIUtil.UIFile('/marketing/splash.dds'))
    LayoutHelpers.FillParentPreserveAspectRatio(bg, rootFrame)
end

function CreateSecondView()
    if GetNumRootFrames() < 2 then return end
    
    ClearFrame(1)
    secondHeadGroup = Group(GetFrame(1), "secondHeadGroup")
    LayoutHelpers.FillParent(secondHeadGroup, GetFrame(1))

    view = import("/lua/ui/controls/worldview.lua").WorldView(secondHeadGroup, 'CameraHead2', 1, false) -- depth value should be below minimap
    view:Register('CameraHead2', nil, '<LOC map_view_0003>Secondary View', 3)
    view:SetRenderPass(UIUtil.UIRP_UnderWorld | UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
    LayoutHelpers.FillParent(view, secondHeadGroup)

end