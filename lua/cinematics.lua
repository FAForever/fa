#****************************************************************************
#**
#**  File     :  /lua/cinematics.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Helper functions for cinematics
#**
#**  Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
#
# One cautionary note: don't change the playable area during an in-game cinematic.
# If you do, and you move the camera to a marker in the new area, the engine
# may not handle it well.
#

SimCamera = import('/lua/simcamera.lua').SimCamera
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

function IsOpEnded()
    if ScenarioInfo.OpEnded then
        return true
    else
        return false
    end
end

# To be used when starting a cinematic / NIS
function EnterNISMode()
    ScenarioInfo.Camera = SimCamera('WorldCamera')
    LockInput()
    ScenarioInfo.Camera:UseGameClock()
    Sync.NISMode = 'on'
    ScenarioInfo.OpEnded = true
    #Take Away UI
    #Set Game Speed to normal
end

# Used at the end of a cinematic / NIS
function ExitNISMode()
    #Set Game Speed to user value
    #Restore UI
    ScenarioInfo.OpEnded = false
    CameraRevertRotation()
    Sync.NISMode = 'off'
    ScenarioInfo.Camera:UseSystemClock()
    SetInvincible( nil, true )
    UnlockInput()
    ScenarioInfo.Camera = nil
end

function SetInvincible( area, invinBool )
    if not invinBool then
        local checkAreas = {}
        if area and type(area) == 'table' then
            for k,v in area do
                table.insert( checkAreas, ScenarioUtils.AreaToRect(v) )
            end
        elseif area then
            table.insert( checkAreas, ScenarioUtils.AreaToRect(area) )
        end
        local unitTable = {}
        for k,v in checkAreas do
            for uNum,unit in GetUnitsInRect( v ) do
                table.insert( unitTable, unit )
            end
        end
        ScenarioFramework.FlagUnkillableSelect( 1, unitTable )
    else
        ScenarioFramework.UnflagUnkillable( 1 )
    end
end

# This will move the camera to the position of a marker
function CameraMoveToMarker( marker, seconds )

    # Adding this in case we just want to start the camera
    # somewhere at the beginning of an operation without
    # playing a full NIS
    if not ScenarioInfo.Camera then
        ScenarioInfo.Camera = SimCamera('WorldCamera')
    end

    if type(marker) == 'string' then
        marker = ScenarioUtils.GetMarker(marker)
    end

    # Move the camera
    ScenarioInfo.Camera:MoveToMarker( marker, seconds )

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
    end
end

# This will move the camera to a rectangle
function CameraMoveToRectangle( rectangle, seconds )

    # Adding this in case we just want to start the camera
    # somewhere at the beginning of an operation without
    # playing a full NIS
    if not ScenarioInfo.Camera then
        ScenarioInfo.Camera = SimCamera('WorldCamera')
    end

    # Move the camera
    ScenarioInfo.Camera:MoveTo( rectangle, seconds )

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
    end
end

# See track entities
function CameraTrackEntity( entity, zoom, seconds )
    CameraTrackEntities({entity}, zoom, seconds)
end

# This will make the camera track a group of entities.
# The "seconds" field is how long it will take to get in place.
# After that the camera will follow that unit until told to do something else.
# Zoom is measured in LOD units.  It's the value of the width of the view frustum
# at the focus point
function CameraTrackEntities( units, zoom, seconds )
    local army = GetFocusArmy()
    if army == -1 then
        army = 1
    end
    for i,v in units do
        if army ~= v:GetArmy() then
            units[i] = v:GetBlip(army)
        end
    end

    # Watch the entities
    ScenarioInfo.Camera:TrackEntities( units, zoom, seconds )

    # Keep it from pitching up all the way
    ScenarioInfo.Camera:HoldRotation()

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
    end
end

# Similar to CameraTrackEntity, but this gives more control with the
# pitchAdjust parameter.
function CameraThirdPerson( entity, pitchAdjust, zoom, seconds )
    ScenarioInfo.Camera:NoseCam( entity, pitchAdjust, zoom, seconds )

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
    end
end

# This will modify the current zoom of the camera without
# adjusting its position.
function CameraSetZoom( zoom, seconds )
    # Move the camera
    ScenarioInfo.Camera:SetZoom( zoom, seconds )

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
    end
end

# This will spin/zoom the camera for the specified
# number of seconds, then stop the camera again.
# Using it with 0 seconds will keep the camera
# spinning/zooming until the next command.
function CameraSpinAndZoom( spin, zoom, seconds )
    # Move the camera
    ScenarioInfo.Camera:Spin( spin, zoom )

    if ( seconds ) and ( seconds != 0 ) then
        # Wait for it to be done
        WaitForCamera()
        # Stop the camera
        ScenarioInfo.Camera:Spin( 0, 0 )
    end
end

# This will bring the camera to the highest zoomed-out level.
function CameraReset()
    ScenarioInfo.Camera:Reset()
end

# This will reset the azimuth back to default and change
# the rotation back to default as well
function CameraRevertRotation()
    ScenarioInfo.Camera:RevertRotation()
end

# Used by other functions to make sure that they don't return
# before the camera is done moving.
function WaitForCamera()
    # Wait for it to be done
    ScenarioInfo.Camera:WaitFor()

    # Reset the event tracker, so that the next
    # camera action can be waited for
    ScenarioInfo.Camera:EventReset()
end
