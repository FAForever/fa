#
# UserCamera
#
# Provides direct control over a specific game camera. Also listens to request from the Sim and manipulates
# the cameras as instructed.
#

local ipairs = ipairs
local CPrefetchSetReset = moho.CPrefetchSet.Reset
local ForkThread = ForkThread
local unpack = unpack
local error = error
local WaitFor = WaitFor
local next = next

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
                CPrefetchSetReset(miniMapCam)
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
        # Move to specified marker
        if req.Marker then
            local position = req.Marker.position
            local hpr = req.Marker.orientation
            local zoom = req.Marker.zoom
            cam:MoveTo(position,hpr,zoom,req.Time)
        # Move to specified region (make region visible)
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
