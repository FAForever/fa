--
-- SimCamera
--
-- SimCamera buffers control requests to push to the user layer at sync time. It provides facilities
-- for waiting on the camera to perform certain actions. At the moment, the facilities that wait can
-- not be used in multiplayer and are considered to finish immediately when running the simulation in
-- a headless mode. Thus the primary use for such features is in the single player campaign. We have
-- a plan to add multiplayer and headless support for these features but it may be some time before
-- this gets implemented.
--
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.

---@class SimCameraEvent
---@field Name string
---@field Type? string
---@field Exec string

local SyncCameraRequest = import("/lua/simsyncutils.lua").SyncCameraRequest

SingleEvent = import("/lua/system/singleevent.lua").SingleEvent
---@type table<string, SimCamera>
Cameras = {}

---The user layer calls this via SimCallback when the camera finishes moving to its target.
---@param name string
function OnCameraFinish(name)
    --LOG('Signal')
    Cameras[name]:EventSet()
end

---@class SimCamera : SingleEvent
---@field CameraName string
---@field Callback { Func: string, Args: string }
---@overload fun(name: string): SimCamera
SimCamera = Class(SingleEvent) {
    ---@param self SimCamera
    ---@param name string
    __init = function(self,name)
        self.CameraName = name
        self.Callback = {
            Func = "OnCameraFinish",
            Args = name,
        }
        Cameras[name] = self
    end,

    ---@param self SimCamera
    ---@param val number
    ---@deprecated
    ScaleMoveVelocity = function(self,val)
        WARN('ScaleMoveVelocity is defunct. Please remove.')
    end,

    ---Move the camera to a rectangle
    ---@param rectRegion Rectangle
    ---@param seconds? number
    MoveTo = function(self,rectRegion,seconds)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_MOVE',
            Region = rectRegion,
            Time = seconds or 0,
            Callback = self.Callback
        }
        SyncCameraRequest(request)
    end,

    --- Move the camera to the position of a marker.
    ---@param self SimCamera
    ---@param marker Marker
    ---@param seconds? number Defaults to 0, which will snap the camera to the marker.
    MoveToMarker = function(self,marker,seconds)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_MOVE',
            Marker = marker,
            Time = seconds or 0,
            Callback = self.Callback
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param rectRegion Rectangle
    SyncPlayableRect = function(self,rectRegion)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_SYNC_PLAYABLE_RECT',
            Region = rectRegion,
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param marker Marker
    SnapToMarker = function(self,marker)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_SNAP',
            Marker = marker,
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param units (Unit|Blip)[]
    ---@param zoom number
    ---@param seconds? number
    TrackEntities = function(self, units, zoom, seconds)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_TRACK_ENTITIES',
            Ents = {},
            Time = seconds or 0,
            Zoom = zoom,
            Callback = self.Callback
        }
        for k,v in units do
            table.insert( request.Ents, v:GetEntityId() )
        end
        SyncCameraRequest(request)
    end,

    --- Similar to `TrackEntities`, but this gives more control with the pitchAdjust parameter.
    ---@param ent Unit
    ---@param pitchAdjust number
    ---@param zoom number
    ---@param seconds? number
    ---@param transition? number
    NoseCam = function(self, ent, pitchAdjust, zoom, seconds, transition)
        local idNum
        if ent:GetAIBrain():GetArmyIndex() ~= ArmyBrains[1]:GetArmyIndex() then
            local entBlip = ent:GetBlip(1)
            if entBlip then
                idNum = entBlip:GetEntityId()
            end
        else
            idNum = ent:GetEntityId()
        end
        if idNum then
            local request = {
                Name = self.CameraName,
                Type = 'CAMERA_NOSE_CAM',
                Entity = idNum,
                PitchAdjust = pitchAdjust,
                Time = seconds or 0,
                Transition = transition or 0,
                Zoom = zoom,
                Callback = self.Callback
            }
            SyncCameraRequest(request)
        else
            error( '*CAMERA ERROR: Nose Cam not given valid unit or unit does not have a blip', 2 )
        end
    end,

    ---@param self SimCamera
    ---@param accModeName UserCameraAccelerationModes
    SetAccMode = function(self,accModeName)
        --LOG('Camera:SetAccMode')
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_SET_ACC_MODE',
            Data = accModeName,
            Callback = self.Callback
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param zoom number
    ---@param seconds? number
    SetZoom = function(self,zoom,seconds)
        --LOG('Camera:SetZoom')
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_SET_ZOOM',
            Zoom = zoom,
            Time = seconds or 0,
            Callback = self.Callback
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param location Vector
    ---@param unitHeading number
    ---@param headingRate number
    SpinAroundUnit = function(self, location, unitHeading, headingRate )
        local marker = {
            orientation = VECTOR3( unitHeading, .35, 0 ),
            position = location,
            zoom = FLOAT( 75 ),
        }
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_UNIT_SPIN',
            Marker = marker,
            HeadingRate = headingRate,
            Callback = self.Callback
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    ---@param headingRate number
    ---@param zoomRate? number
    Spin = function(self,headingRate,zoomRate)
        local request = {
            Name = self.CameraName,
            Type = 'CAMERA_SPIN',
            HeadingRate = headingRate,
            ZoomRate = zoomRate,
        }
        SyncCameraRequest(request)
    end,

    ---@param self SimCamera
    HoldRotation = function(self)
        SyncCameraRequest({ Name = self.CameraName, Exec = 'HoldRotation' })
    end,

    ---@param self SimCamera
    RevertRotation = function(self)
        SyncCameraRequest( { Name = self.CameraName, Exec = 'RevertRotation' } )
    end,

    ---@param self SimCamera
    UseGameClock = function(self)
        SyncCameraRequest( { Name = self.CameraName, Exec = 'UseGameClock' } )
    end,

    ---@param self SimCamera
    UseSystemClock = function(self)
        SyncCameraRequest( { Name = self.CameraName, Exec = 'UseSystemClock' } )
    end,

    ---@param self SimCamera
    EnableEaseInOut = function(self)
        SyncCameraRequest( { Name = self.CameraName, Exec = 'EnableEaseInOut' } )
    end,

    ---@param self SimCamera
    DisableEaseInOut = function(self)
        SyncCameraRequest( { Name = self.CameraName, Exec = 'DisableEaseInOut' } )
    end,

    ---@param self SimCamera
    Reset = function(self)
        SyncCameraRequest( {Name=self.CameraName, Exec='Reset'} )
    end,
}
