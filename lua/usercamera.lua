
StoredCameraSettings = { }
OldCameraSettings = false

local cameraToManipulate = 'WorldCamera'

local saveCameraPositionSound = Sound({Bank = 'Interface', Cue = 'UI_Camera_Save_Position'})
local restoreCameraPositionSound = Sound({Bank = 'Interface', Cue = 'UI_Camera_Recall_Position'})

function Test2()
    import("/lua/ui/game/commandmode.lua").StartCommandMode('build', { name = 'uel0105'})
end

--- Stores the camera settings, allowing you to restore it at a later moment
---@param id number
function SaveCameraPosition(id)
    local camera = GetCamera(cameraToManipulate)
    StoredCameraSettings[id] = camera:SaveSettings()
    PlaySound(saveCameraPositionSound)
end

--- Restores the camera settings while keeping track where the camera was, allowing you to toggle in between
---@param id number
function RestoreCameraPosition(id)
    if StoredCameraSettings[id] then
        local camera = GetCamera(cameraToManipulate)

        OldCameraSettings = camera:SaveSettings()
        camera:RestoreSettings(StoredCameraSettings[id])

        PlaySound(restoreCameraPositionSound)
    end
end

--- Restores the camera settings to before you used one of the camera hotkeys
function RestorePreviousCameraPosition()
    if OldCameraSettings then
        local camera = GetCamera(cameraToManipulate)
        camera:RestoreSettings(OldCameraSettings)
        OldCameraSettings = false

        PlaySound(restoreCameraPositionSound)
    end
end

--- 
---@param req any
function WaitForCamera(req)
    local cam = GetCamera(req.Name)

    if req.Type == 'CAMERA_TRACK_ENTITIES' then
        cam:TrackEntities(req.Ents,req.Zoom,req.Time)
    elseif req.Type == 'CAMERA_NOSE_CAM' then
        cam:NoseCam(req.Entity, req.PitchAdjust, req.Zoom, req.Time, req.Transition)
    elseif req.Type == 'CAMERA_SET_ACC_MODE' then
        cam:SetAccMode(req.Data)
    elseif req.Type == 'CAMERA_SET_ZOOM' then
        cam:SetZoom(req.Zoom, req.Time)
    elseif req.Type == 'CAMERA_MOVE' then
        -- Move to specified marker
        if req.Marker then
            local position = req.Marker.position
            local hpr = req.Marker.orientation
            local zoom = req.Marker.zoom
            cam:MoveTo(position,hpr,zoom,req.Time)
        -- Move to specified region (make region visible)
        elseif req.Region then
            cam:MoveToRegion(req.Region,req.Time)
        else
            error("Invalid move request: " .. repr(req))
            SimCallback(req.Callback)
            return
        end
    else
        error("Invalid camera request: " .. repr(req))
        SimCallback(req.Callback)
        return
    end

    if req.Time > 0 then
        WaitFor(cam)
        SimCallback(req.Callback)
    end
end

---comment
---@param reqs any
function ProcessCameraRequests(reqs)
    for k,v in Sync.CameraRequests do
        if v.Exec then
            local cam = GetCamera(v.Name)
            if v.Params then
                cam[v.Exec](cam, unpack(v.Params))
            else
                cam[v.Exec](cam)
            end
        elseif v.Type == 'CAMERA_MOVE' then
            ForkThread(WaitForCamera, v)
        elseif v.Type == 'CAMERA_TRACK_ENTITIES' then
            ForkThread(WaitForCamera,v)
        elseif v.Type == 'CAMERA_NOSE_CAM' then
            ForkThread(WaitForCamera,v)
        elseif v.Type == 'CAMERA_SET_ACC_MODE' then
            ForkThread(WaitForCamera,v)
        elseif v.Type == 'CAMERA_SET_ZOOM' then
            ForkThread(WaitForCamera,v)
        elseif v.Type == 'CAMERA_SYNC_PLAYABLE_RECT' then
            SyncPlayableRect(v.Region)
            local miniMapCam = GetCamera('MiniMap')
            if miniMapCam then
                miniMapCam:Reset()
            end
        elseif v.Type == 'CAMERA_SNAP' then
            local position = v.Marker.position
            local hpr = v.Marker.orientation
            local zoom = v.Marker.zoom
            GetCamera(v.Name):SnapTo(position, hpr, zoom)
        elseif v.Type == 'CAMERA_SPIN' then
            GetCamera(v.Name):Spin(v.HeadingRate, v.ZoomRate or 0)
        elseif v.Type == 'CAMERA_UNIT_SPIN' then
            local cam = GetCamera(v.Name)
            cam:SnapTo( v.Marker.position, v.Marker.orientation, v.Marker.zoom)
            cam:Spin(v.HeadingRate)
        else
            error("Unknown Camera Request type specified.")
        end
    end
end

