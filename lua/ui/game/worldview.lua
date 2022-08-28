--*****************************************************************************
--* File: lua/modules/ui/game/wolrdview.lua
--* Author: Chris Blackwell
--* Summary: UI to manage the games main world view
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Factions = import('/lua/factions.lua').Factions

MapControls = {}

-- main views used
---@type WorldView | boolean
view = false
---@type WorldView | boolean
viewLeft = false
---@type WorldView | boolean
viewRight = false
---@type WorldView | boolean
viewStrategic1 = false
---@type WorldView | boolean
viewStrategic2 = false

-- likely used by secondary monitors, not sure?
secondaryView = false
tertiaryView = false

--- cached for later use
---@type Control | boolean
local parentForFrame = false

--- Destroys the world views
function Destroy()
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
end

--- Creates a single view
---@param parent Control
---@param mapGroup Control
local function CreateSingleView (parent, mapGroup)

    -- keep a reference for later use
    parentForFrame = parent

    -- populate main view (left side)
    viewLeft = import('/lua/ui/controls/worldview.lua').WorldView(mapGroup, 'WorldCamera', 1, false)
    viewLeft:Register('WorldCamera', nil, '<LOC map_view_0006>Main View', 2)
    viewLeft:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
    LayoutHelpers.FillParent(viewLeft, mapGroup)
    viewLeft:GetsGlobalCameraCommands(true)

    -- expands the entire view, used by various other modules to know the size of the screen
    view = Group(parent)
    view:DisableHitTest()
    LayoutHelpers.FillParent(view, mapGroup)

    ForkThread(
        function()
            LOG("Running!")
            WaitSeconds(5.0)

            viewLeft.Right:Set(
                function() return mapGroup.Right() - (0.5 * mapGroup.Height()) end
            )
            
            viewStrategic1 = import('/lua/ui/controls/worldview.lua').WorldView(mapGroup, 'CameraStrategic2', 1, false)
            viewStrategic1:Register('CameraStrategic1', nil, '<CameraStrategic1', 2)
            viewStrategic1:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow)
            viewStrategic1.Left:Set(viewLeft.Right)
            viewStrategic1.Right:Set(mapGroup.Right)
            viewStrategic1.Top:Set(mapGroup.Top)
            viewStrategic1.Bottom:Set(function() return mapGroup.Top() + (0.5 * mapGroup.Height()) end)

            -- strategic view
            viewStrategic2 = import('/lua/ui/controls/worldview.lua').WorldView(mapGroup, 'CameraStrategic2', 2, false)
            viewStrategic2:Register('CameraStrategic2', nil, 'CameraStrategic2', 2)
            viewStrategic2:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
            viewStrategic2.Left:Set(viewLeft.Right)
            viewStrategic2.Right:Set(mapGroup.Right)
            viewStrategic2.Top:Set(function() return mapGroup.Top() + (0.5 * mapGroup.Height()) end)
            viewStrategic2.Bottom:Set(mapGroup.Bottom)

        end
    )
end

--- Creates a dual view
---@param parent Control
---@param mapGroupLeft Control
---@param mapGroupRight Control
local function CreateDualView (parent, mapGroupLeft, mapGroupRight)

    -- keep a reference for later use
    parentForFrame = parent

    -- populate left side
    viewLeft = import('/lua/ui/controls/worldview.lua').WorldView(mapGroupLeft, 'WorldCamera', 1, false) -- depth value should be below minimap
    viewLeft:Register('WorldCamera', nil, '<LOC map_view_0004>Split View Left', 2)
    -- Note: UIRP values need to be a bitwise OR of flags. The lines below originally used the | operator but Travis CI doesn't like it. In these cases + works instead as long as the values never change.
    viewLeft:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
    LayoutHelpers.FillParent(viewLeft, mapGroupLeft)
    viewLeft:GetsGlobalCameraCommands(true)

    -- populate right side
    viewRight = import('/lua/ui/controls/worldview.lua').WorldView(mapGroupRight, 'WorldCamera2', 1, false) -- depth value should be below minimap
    viewRight:Register('WorldCamera2', nil, '<LOC map_view_0005>Split View Right', 2)
    viewRight:SetRenderPass(UIUtil.UIRP_UnderWorld + UIUtil.UIRP_PostGlow) -- don't change this or the camera will lag one frame behind
    LayoutHelpers.FillParent(viewRight, mapGroupRight)

    -- expands the entire view, used by various other modules to know the size of the screen
    view = Group(parent)
    view.Left:Set(mapGroupLeft.Left)
    view.Top:Set(mapGroupLeft.Top)
    view.Bottom:Set(mapGroupLeft.Bottom)
    view.Right:Set(mapGroupRight.Right)
    view:DisableHitTest()
end

local function CreateSingleStategicView (parent, mapGroup)

end

--- Called by the engine to populate the main view
---@param parent any
---@param mapGroup any
---@param mapGroupRight any
function CreateMainWorldView(parent, mapGroup, mapGroupRight)

    -- clean up previous views
    Destroy()

    -- keep a reference for later use
    parentForFrame = parent


    if not mapGroupRight then
        CreateSingleView(parent, mapGroup)
    else
        CreateDualView(parent, mapGroup, mapGroupRight)
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

-- TODO: move these to a separate file

positionMarkers = {}


local function CreatePositionMarker(army, worldView)
    local data = positionMarkers[army]
    if not data then return end

    positionMarkers[army].views = data.views + 1

    local marker = Bitmap(worldView)
    marker:DisableHitTest()
    marker.Left:Set(-1000)
    marker.Top:Set(-1000)
    marker.Depth:Set(13)
    marker:SetSolidColor('black')
    marker:SetNeedsFrameUpdate(true)
    marker.army = data.army
    marker.pos = data.pos

    marker.frame = Bitmap(marker)
    marker.frame:DisableHitTest()
    LayoutHelpers.FillParentFixedBorder(marker.frame, marker, -2)
    marker.frame:SetSolidColor(data.color)
    marker.frame.Depth:Set(marker:Depth() - 1)

    marker.name = UIUtil.CreateText(marker, data.name, 12, UIUtil.bodyFont)
	marker.name:DisableHitTest()
    marker.name:SetColor('white')

    if Factions[data.faction] then
        marker.icon = Bitmap(marker, UIUtil.UIFile(Factions[data.faction].LargeIcon))
        marker.icon:DisableHitTest()
        marker.icon.Width:Set(marker.name.Height())
        marker.icon.Height:Set(marker.name.Height())
        LayoutHelpers.LeftOf(marker.icon, marker.name, 2)
        LayoutHelpers.AtVerticalCenterIn(marker.icon, marker)

        LayoutHelpers.AtCenterIn(marker.name, marker, 0, marker.icon:Width() / 2)
        marker.Width:Set(marker.icon:Width() + marker.name:Width() + 6)
        marker.Height:Set(marker.name:Height() + 4)
    else
        LayoutHelpers.AtCenterIn(marker.name, marker, 0, 0)
        marker.Width:Set(marker.name:Width() + 4)
        marker.Height:Set(marker.name:Height() + 4)
    end

    marker.OnDestroy = function(self)
        local views = positionMarkers[self.army].views
        if views then
            positionMarkers[self.army].views = views - 1
        end
    end

    -- If we leave hit test enabled on the marker and ignore every event except a click, it still interferes with using the middle mouse button to pan the map.
    -- That often happens even if the cursor is nowhere near the marker, so it's unusable. This way isn't pretty, but at least it works correctly.
    local oldWVHandleEvent = worldView.HandleEvent
    worldView.HandleEvent = function(self, event)
        if marker and event.Type == 'ButtonPress' and not event.Modifiers.Middle and marker.frame:HitTest(event.MouseX, event.MouseY) then
            if positionMarkers[marker.army].views == 1 then
                positionMarkers[marker.army] = nil
            end
            marker:Destroy()
            marker = false
            return true
        end
        oldWVHandleEvent(self, event)
    end

    marker.OnFrame = function(self, delta)
        if not worldView:IsHidden() then
            local pos = worldView:Project(self.pos)
            LayoutHelpers.AtLeftTopIn(self, worldView, (pos.x - self.Width() / 2) / LayoutHelpers.GetPixelScaleFactor(), (pos.y - self.Height() / 2) / LayoutHelpers.GetPixelScaleFactor())

            if (self:Left() < worldView:Left() or self:Top() < worldView:Top() or self:Right() > worldView:Right() or self:Bottom() > worldView:Bottom()) then
                if not self:IsHidden() then
                    self:Hide()
                end
            elseif self:IsHidden() then
                self:Show()
            end
        end
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

    if view._cameraName ~= 'MiniMap' then
        for army, data in positionMarkers do
            CreatePositionMarker(army, view)
        end
    end
end

function UnregisterWorldView(view)
    if MapControls[view._cameraName] then
        MapControls[view._cameraName] = nil
    end
end

function GetWorldViews()
    return MapControls
end



function MarkStartPositions(startPositions)
    if not startPositions then return end

    local armyInfo = GetArmiesTable()
    local armiesTable = armyInfo.armiesTable
    local focusArmy = armyInfo.focusArmy

    for armyId, armyData in armiesTable do
        if not armyData.civilian and startPositions[armyData.name] and (focusArmy == -1 or IsEnemy(armyId, focusArmy)) then
            local pos = startPositions[armyData.name]
            local name = armyData.nickname
            local faction = armyData.faction + 1
            local color = armyData.color

            positionMarkers[armyId] = {army = armyId, pos = pos, name = name, faction = faction, color = color, views = 0}

            for viewName, view in MapControls do
                if viewName ~= 'MiniMap' then
                    CreatePositionMarker(armyId, view)
                end
            end
        end
    end
end