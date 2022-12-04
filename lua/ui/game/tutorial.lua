--*****************************************************************************
--* File: lua/modules/ui/game/tutorial.lua
--* Author: Ted Snook
--* Summary: Various UI functions for the tutorial
--*
--* Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh

function HighlightPanels(panels)
    local validPanels = {
        economy = {
            bitmap = UIUtil.UIFile('/game/resource-tutorial/resource_tutorial_bmp.dds'), 
            control = import("/lua/ui/game/economy.lua").GUI.bg,
        },
    }
    for _, panel in panels do
        if validPanels[panel] then
            local goalControl = validPanels[panel].control
            local bg = Bitmap(GetFrame(0))
            LayoutHelpers.FillParent(bg, GetFrame(0))
            bg:SetSolidColor('88000000')
            bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
            
            local textGroup = Bitmap(bg, validPanels[panel].bitmap) 
            LayoutHelpers.AtCenterIn(textGroup, GetFrame(0))
            textGroup:SetAlpha(0)
            
            local overlay = Bitmap(bg, validPanels[panel].bitmap)
            LayoutHelpers.AtLeftTopIn(overlay, goalControl)
            overlay.time = 0
            overlay:SetNeedsFrameUpdate(true)
            overlay.OnFrame = function(self, delta)
                self.time = self.time + delta
                if self.time >= 5.5 and self.time < 5.7 then
                    bg:SetAlpha(MATH_Lerp(self.time, 5.5, 5.7, 1, 0))
                    self.Top:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Top(), goalControl.Top()))
                    self.Left:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Left(), goalControl.Left()))
                    self.Right:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Right(), goalControl.Right()))
                    self.Bottom:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Bottom(), goalControl.Bottom()))
                    self.Height:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Height(), goalControl.Height()))
                    self.Width:Set(MATH_Lerp(self.time, 5.5, 5.7, textGroup.Width(), goalControl.Width()))
                elseif self.time < .2 then
                    bg:SetAlpha(MATH_Lerp(self.time, 0, .2, 0, 1))
                    self.Top:Set(MATH_Lerp(self.time, 0, .2, goalControl.Top(), textGroup.Top()))
                    self.Left:Set(MATH_Lerp(self.time, 0, .2, goalControl.Left(), textGroup.Left()))
                    self.Right:Set(MATH_Lerp(self.time, 0, .2, goalControl.Right(), textGroup.Right()))
                    self.Bottom:Set(MATH_Lerp(self.time, 0, .2, goalControl.Bottom(), textGroup.Bottom()))
                    self.Height:Set(MATH_Lerp(self.time, 0, .2, goalControl.Height(), textGroup.Height()))
                    self.Width:Set(MATH_Lerp(self.time, 0, .2, goalControl.Width(), textGroup.Width()))
                elseif self.time > .2 and self.time < 5.5 then
                    bg:SetAlpha(1)
                    self.Top:Set(textGroup.Top())
                    self.Left:Set(textGroup.Left())
                    self.Right:Set(textGroup.Right())
                    self.Bottom:Set(textGroup.Bottom())
                    self.Height:Set(textGroup.Height())
                    self.Width:Set(textGroup.Width())
                end
                
                if self.time > 5.7 then
                    if bg.OnFinished then
                        bg.OnFinished()
                    end
                    bg:Destroy()
                    bg.OnFinished = nil
                    bg = false
                end
            end
            
            bg:DisableHitTest(true)
        end
    end
end

local markers = {}
local clearFuncAdded = false

function AddCameraMarkers(inMarkers)
    for _, marker in inMarkers do
        local mesh = WorldMesh()
        mesh:SetMesh({
            MeshName = '/meshes/game/Arrow2_lod0.scm',
    	    TextureName = '/meshes/game/Arrow2_Albedo.dds',
    	    ShaderName = 'Unit',
        })
        mesh:SetLifetimeParameter(1000000)
        mesh:SetStance(marker.position)
        mesh:SetHidden(false)
        markers[marker.id] = {mesh = mesh, position = marker.position}
    end
    if not clearFuncAdded then
        clearFuncAdded = true
        CheckForMarkersInFrame()
        import("/lua/ui/game/gamemain.lua").AddOnUIDestroyedFunction(ClearMeshes)
    end
end

function CheckForMarkersInFrame()
    local markerGroup = Group(GetFrame(0))
    markerGroup.Height:Set(0)
    markerGroup.Width:Set(0)
    markerGroup.Left:Set(1)
    markerGroup.Top:Set(1)
    markerGroup:SetNeedsFrameUpdate(true)
    markerGroup:DisableHitTest()
    markerGroup.OnFrame = function(self, delta)
        if table.getsize(markers) > 0 then
            local view = import("/lua/ui/game/worldview.lua").viewLeft
            for markerid, markerInfo in markers do
                if markerInfo.AlreadySeen then continue end
                local coords = view:Project(markerInfo.position)
                local valid = true
                local id = markerid
                if coords[1] < view.Left() + (view.Width() / 4) or coords[1] > view.Right() - (view.Width() / 4) then
                    valid = false
                end
                if coords[2] < view.Top() + (view.Height() / 4) or coords[2] > view.Bottom() - (view.Height() / 4) then
                    valid = false
                end
                if valid then
                    markerInfo.AlreadySeen = true
                    SimCallback({Func = 'MarkerOnScreen', Args = id})
                end
            end
        end
    end
end

function RemoveCameraMarkers(inMarkers)
    for _, markerID in inMarkers do
        if markers[markerID] then
            markers[markerID].mesh:Destroy()
            markers[markerID] = nil
        end
    end
end

function ClearMeshes()
    for _, marker in markers do
        marker.mesh:Destroy()
    end
    markers = {}
end