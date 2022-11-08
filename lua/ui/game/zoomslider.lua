--*****************************************************************************
--* File: lua/modules/ui/game/zoomslider.lua
--* Author: Ted Snook
--* Summary: Zoom slider
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Slider = import("/lua/maui/slider.lua").Slider

local ZOOM_INACTIVITY_TIMEOUT = 15  -- in seconds
local zoomInactivityTime = 0

local parent = false

local lastview = false
local currentCamSetting = 1
local cameraPositions = {}

local controls = {
    slider = false,
}

function SetLayout(layout)
    if layout == 'bottom' then
        DoBottomLayout()
    elseif layout == 'left' then
        DoLeftLayout()
    end
end

function SetupZoomSliderLayout(mapGroup)
    parent = mapGroup
    
    SetLayout(UIUtil.currentLayout)
end

function DoBottomLayout()
    if not controls.slider then
        controls.slider = Slider(parent, true, 5, 95, 
            UIUtil.UIFile('/game/zoom-control_bmp/zoom-control_btn_up.dds'),
            UIUtil.UIFile('/game/zoom-control_bmp/zoom-control_bmp.dds'))
    end
    controls.slider.Right:Set(function() return parent.Right() - 0 end)
    controls.slider.Bottom:Set(function() return parent.Bottom() - 7 end)
    controls.slider:Hide()
end

function DoLeftLayout()
    if not controls.slider then
        controls.slider = Slider(parent, true, 0, 100, 
            UIUtil.UIFile('/game/zoom-control_bmp/zoom-control_btn_up.dds'),
            UIUtil.UIFile('/game/zoom-control_bmp/zoom-control_bmp.dds'))
    end
    controls.slider.Right:Set(function() return parent.Right() - 10 end)
    controls.slider.Bottom:Set(function() return parent.Bottom() - 15 end)
    controls.slider:Hide()
end

function ZoomIn(speed)
    local cam = GetCamera('WorldCamera')
    local zoomInc = (cam:GetMaxZoom() - cam:GetMinZoom()) * speed
    local curZoom = cam:GetTargetZoom()
    cam:SetTargetZoom(math.max(curZoom - zoomInc, cam:GetMinZoom()))
end

function ZoomOut(speed)
    local cam = GetCamera('WorldCamera')
    local zoomInc = (cam:GetMaxZoom() - cam:GetMinZoom()) * speed
    local curZoom = cam:GetTargetZoom()
    cam:SetTargetZoom(math.min(curZoom + zoomInc, cam:GetMaxZoom()))
end

function SaveCameraPos()
    table.insert(cameraPositions, 1, GetCamera('WorldCamera'):SaveSettings())
    local sound = Sound({Bank = 'Interface', Cue = 'UI_Camera_Save_Position'})
    PlaySound(sound)
end

-- Focus={ <metatable=table: 17D498C0>
--    146.80799865723,
--    20.548700332642,
--    347.08599853516
--  },
--  Heading=-3.1415901184082,
--  Pitch=1.0239499807358,
--  Zoom=39.889518737793

function RemoveCamPos()
    if cameraPositions[currentCamSetting] then
        table.remove(cameraPositions, currentCamSetting)
        currentCamSetting = currentCamSetting + 1
    end
    local sound = Sound({Bank = 'Interface', Cue = 'UI_Camera_Delete_Position'})
    PlaySound(sound)
end

function RecallCameraPos()
    currentCamSetting = currentCamSetting + 1
    if cameraPositions[currentCamSetting] then
        GetCamera('WorldCamera'):RestoreSettings(cameraPositions[currentCamSetting])
    else
        currentCamSetting = 1
        if cameraPositions[1] then
            GetCamera('WorldCamera'):RestoreSettings(cameraPositions[1])
        end
    end
    local sound = Sound({Bank = 'Interface', Cue = 'UI_Camera_Recall_Position'})
    PlaySound(sound)
end

function ToggleWideView()
    if lastview then
        GetCamera('WorldCamera'):RestoreSettings(lastview)
        lastview = false
    else
        lastview = GetCamera('WorldCamera'):SaveSettings()
        GetCamera('WorldCamera'):Reset()
    end
end