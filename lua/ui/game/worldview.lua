#*****************************************************************************
#* File: lua/modules/ui/game/wolrdview.lua
#* Author: Chris Blackwell
#* Summary: UI to manage the games main world view
#*
#* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group

MapControls = {}

view = false
viewLeft = false
viewRight = false
secondaryView = false
tertiaryView = false
local parentForFrame = false

function CreateMainWorldView(parent, mapGroup, mapGroupRight)    
    if viewLeft then    
        viewLeft:Destroy()
        viewLeft = false  
    end
    if viewRight then
        viewRight:Destroy()
        viewRight = false
    end
    if view then
        view:Destroy()
        view = false
    end
    if mapGroupRight then
        parentForFrame = parent
        viewLeft = import('/lua/ui/controls/worldview.lua').WorldView(mapGroup, 'WorldCamera', 1, false) -- depth value should be below minimap
        viewLeft:Register('WorldCamera', nil, '<LOC map_view_0004>Split View Left', 2)
        viewLeft:SetRenderPass(UIUtil.UIRP_UnderWorld | UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
        LayoutHelpers.FillParent(viewLeft, mapGroup)
        viewLeft:GetsGlobalCameraCommands(true)
        
        viewRight = import('/lua/ui/controls/worldview.lua').WorldView(mapGroupRight, 'WorldCamera2', 1, false) -- depth value should be below minimap
        viewRight:Register('WorldCamera2', nil, '<LOC map_view_0005>Split View Right', 2)
        viewRight:SetRenderPass(UIUtil.UIRP_UnderWorld | UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
        LayoutHelpers.FillParent(viewRight, mapGroupRight)
        
        view = Group(viewLeft)
        view.Left:Set(viewLeft.Left)
        view.Top:Set(viewLeft.Top)
        view.Bottom:Set(viewLeft.Bottom)
        view.Right:Set(viewRight.Right)
        view:DisableHitTest()
    else
        parentForFrame = parent
        viewLeft = import('/lua/ui/controls/worldview.lua').WorldView(mapGroup, 'WorldCamera', 1, false) -- depth value should be below minimap
        viewLeft:Register('WorldCamera', nil, '<LOC map_view_0006>Main View', 2)
        viewLeft:SetRenderPass(UIUtil.UIRP_UnderWorld | UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
        LayoutHelpers.FillParent(viewLeft, mapGroup)
        viewLeft:GetsGlobalCameraCommands(true)
        
        view = Group(viewLeft)
        view:DisableHitTest()
        LayoutHelpers.FillParent(view, viewLeft)
    end
    import('/lua/ui/game/multifunction.lua').RefreshMapDialog()
end

-- these two functions will cause the world view to fill the screen or go back to its original settings
local origLeft = false
local origRight = false
local origTop = false
local origBottom = false

function Expand()
    if viewRight then
        origRightLeft = viewRight.Left.compute
        origRightRight = viewRight.Right.compute
        origRightTop = viewRight.Top.compute
        origRightBottom = viewRight.Bottom.compute
        origLeft = viewLeft.Left.compute
        origRight = viewLeft.Right.compute
        origTop = viewLeft.Top.compute
        origBottom = viewLeft.Bottom.compute
        
        local gameViewTemp = GetFrame(parentForFrame:GetRootFrame():GetTargetHead())
        
        viewLeft.Top:Set(gameViewTemp.Top)
        viewLeft.Left:Set(gameViewTemp.Left)
        viewLeft.Right:Set(function() return (gameViewTemp.Left() - 2) + ((gameViewTemp.Right() - gameViewTemp.Left()) / 2) end)
        viewLeft.Bottom:Set(gameViewTemp.Bottom)
        
        viewRight.Top:Set(gameViewTemp.Top)
        viewRight.Left:Set(function() return (gameViewTemp.Left() + 2) + ((gameViewTemp.Right() - gameViewTemp.Left()) / 2) end)
        viewRight.Right:Set(gameViewTemp.Right)
        viewRight.Bottom:Set(gameViewTemp.Bottom)
    else
        origLeft = viewLeft.Left.compute
        origRight = viewLeft.Right.compute
        origTop = viewLeft.Top.compute
        origBottom = viewLeft.Bottom.compute
        LayoutHelpers.FillParent(viewLeft, GetFrame(parentForFrame:GetRootFrame():GetTargetHead()))
    end
end

function Contract()
    if viewRight then        
        viewRight.Left:Set(origRightLeft)
        viewRight.Right:Set(origRightRight)
        viewRight.Top:Set(origRightTop)
        viewRight.Bottom:Set(origRightBottom)
    end
    
    viewLeft.Left:Set(origLeft)
    viewLeft.Right:Set(origRight)
    viewLeft.Top:Set(origTop)
    viewLeft.Bottom:Set(origBottom)
end

function Destroy()
    if viewLeft then
        viewLeft:Destroy()
        viewLeft = false
    end
    if viewRight then
        viewRight:Destroy()
        viewRight = false
    end
end

local worldBlock = false

function LockInput()
    if not worldBlock then
        worldBlock = Group(GetFrame(0))
        LayoutHelpers.FillParent(worldBlock, GetFrame(0))
        UIUtil.MakeInputModal(worldBlock)
    end
    
    if viewLeft then
        viewLeft:LockInput()
    end
    
    if viewRight then
        viewRight:LockInput()
    end
    GetCursor():Hide()
    SessionResume()
end

function UnlockInput()
    GetCursor():Show()
    if viewLeft then
        viewLeft:UnlockInput()
    end
    
    if viewRight then
        viewRight:UnlockInput()
    end
    
    if not IsInputLocked() then
        if worldBlock then
            worldBlock:Destroy()
            worldBlock = false
        end
    end
end

-- this function is called by the engine so it can not be removed (its logic could be changed though)
function IsInputLocked()
    return (viewLeft and viewLeft:IsInputLocked()) or (viewRight and viewRight:IsInputLocked())
end

function ForwardMouseWheelInput(event)
    if viewLeft and viewLeft:HitTest(event.MouseX, event.MouseY) then
        viewLeft:ZoomScale(event.MouseX, event.MouseY, event.WheelRotation, event.WheelDelta)
    elseif viewRight and viewRight:HitTest(event.MouseX, event.MouseY) then
        viewRight:ZoomScale(event.MouseX, event.MouseY, event.WheelRotation, event.WheelDelta)
    end
end

function SetHighlightEnabled(val)
    if viewLeft then
        viewLeft:SetHighlightEnabled(val)
    end
    if viewRight then
        viewRight:SetHighlightEnabled(val)
    end
end

function ToggleMainCartographicView()
    if viewLeft then
        viewLeft:SetCartographic(not viewLeft:IsCartographic())
    end    
end

function RegisterWorldView(view)
    if not MapControls[view._cameraName] then MapControls[view._cameraName] = {} end
    MapControls[view._cameraName] = view
end

function UnregisterWorldView(view)
    if MapControls[view._cameraName] then
        MapControls[view._cameraName] = nil
    end
end

function GetWorldViews()
    return MapControls
end