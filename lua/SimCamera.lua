#
# SimCamera
#
# SimCamera buffers control requests to push to the user layer at sync time. It provides facilities
# for waiting on the camera to perform certain actions. At the moment, the facilities that wait can
# not be used in multiplayer and are considered to finish immediately when running the simulation in
# a headless mode. Thus the primary use for such features is in the single player campaign. We have
# a plan to add multiplayer and headless support for these features but it may be some time before
# this gets implemented.
#
# Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.

local ipairs = ipairs
local aibrain_methodsGetArmyIndex = moho.aibrain_methods.GetArmyIndex
local LOG = LOG
local WARN = WARN
local unit_methodsGetBlip = moho.unit_methods.GetBlip
local error = error
local next = next
local tableInsert = table.insert

local SingleEvent = import('/lua/system/SingleEvent.lua').SingleEvent

# Name / Object table for cameras
Cameras = {}

# The user layer calls this via SimCallback when the camera finishes moving to its target.
function OnCameraFinish(name)
    #LOG('Signal')
    Cameras[name]:EventSet()
end

SimCamera = Class(SingleEvent) {
    __init = function(self,name)
        self.CameraName = name
        self.Callback = {
            Func = "OnCameraFinish",
            Args = name,
        }
        Cameras[name] = self
    end,

    ScaleMoveVelocity = function(self,val)
        WARN('ScaleMoveVelocity is defunct. Please remove.')
    end,

    MoveTo = function(self,rectRegion,seconds)
        #LOG('Camera:MoveTo ', repr(rectRegion), ' ',seconds)
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_MOVE',
            Region = rectRegion,
            Time = seconds or 0,
            Callback = self.Callback
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    MoveToMarker = function(self,marker,seconds)
        #LOG('Camera:MoveToMarker ', repr(marker.type), ' ',seconds)
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_MOVE',
            Marker = marker,
            Time = seconds or 0,
            Callback = self.Callback
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    SyncPlayableRect = function(self,rectRegion)
        LOG('Camera:SyncPlayableRect ', repr(rectRegion))
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_SYNC_PLAYABLE_RECT',
            Region = rectRegion,
        }
        LOG('Request: ',repr(request))
        tableInsert( Sync.CameraRequests, request )
    end,

    SnapToMarker = function(self,marker)
        #LOG('Camera:SnapToMarker('..repr(marker.type)..')')
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_SNAP',
            Marker = marker,
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    TrackEntities = function(self, units, zoom, seconds)
        #LOG('Camera:TrackEntities')
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_TRACK_ENTITIES',
            Ents = {},
            Time = seconds or 0,
            Zoom = zoom,
            Callback = self.Callback
        }
        for k,v in units do
            tableInsert( request.Ents, v:GetEntityId() )
        end
        tableInsert( Sync.CameraRequests, request )
    end,

    NoseCam = function(self, ent, pitchAdjust, zoom, seconds, transition)
        #LOG('Camera:NoseCam')
        local idNum = false
        if ent:GetAIBrain():GetArmyIndex() ~= aibrain_methodsGetArmyIndex(ArmyBrains[1]) then
            local entBlip = unit_methodsGetBlip(ent, 1)
            if entBlip then
                idNum = entBlip:GetEntityId()
            end
        else
            idNum = ent:GetEntityId()
        end
        if idNum then
            request = {
                Name = self.CameraName,
                Type = 'CAMERA_NOSE_CAM',
                Entity = idNum,
                PitchAdjust = pitchAdjust,
                Time = seconds or 0,
                Transition = transition or 0,
                Zoom = zoom,
                Callback = self.Callback
            }
            tableInsert( Sync.CameraRequests, request )
        else
            error( '*CAMERA ERROR: Nose Cam not given valid unit or unit does not have a blip', 2 )
        end
    end,

    SetAccMode = function(self,accModeName)
        #LOG('Camera:SetAccMode')
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_SET_ACC_MODE',
            Data = accModeName,
            Callback = self.Callback
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    SetZoom = function(self,zoom,seconds)
        #LOG('Camera:SetZoom')
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_SET_ZOOM',
            Zoom = zoom,
            Time = seconds or 0,
            Callback = self.Callback
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    SpinAroundUnit = function(self, location, unitHeading, headingRate )
        local marker = {
            orientation = VECTOR3( unitHeading, .35, 0 ),
            position = location,
            zoom = FLOAT( 75 ),
        }
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_UNIT_SPIN',
            Marker = marker,
            HeadingRate = headingRate,
            Callback = self.Callback
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    Spin = function(self,headingRate,zoomRate)
        request = {
            Name = self.CameraName,
            Type = 'CAMERA_SPIN',
            HeadingRate = headingRate,
            ZoomRate = zoomRate,
        }
        tableInsert( Sync.CameraRequests, request )
    end,

    HoldRotation = function(self)
        #LOG('Camera:HoldRotation')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'HoldRotation' } )
    end,

    RevertRotation = function(self)
        #LOG('Camera:RevertRotation')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'RevertRotation' } )
    end,

    UseGameClock = function(self)
        #LOG('Camera:UseGameClock')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'UseGameClock' } )
    end,

    UseSystemClock = function(self)
        #LOG('Camera:UseSystemClock')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'UseSystemClock' } )
    end,

    EnableEaseInOut = function(self)
        #LOG('Camera:EnableEaseInOut')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'EnableEaseInOut' } )
    end,

    DisableEaseInOut = function(self)
        #LOG('Camera:DisableEaseInOut')
        tableInsert( Sync.CameraRequests, { Name = self.CameraName, Exec = 'DisableEaseInOut' } )
    end,

    Reset = function(self)
        #LOG('Camera:Reset')
        tableInsert( Sync.CameraRequests, {Name=self.CameraName, Exec='Reset'} )
    end,
}
