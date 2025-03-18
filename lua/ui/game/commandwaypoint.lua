--*****************************************************************************
--* File: lua/modules/ui/game/commandwaypoint.lua
--* Author: Chad Queen
--* Summary: Houses information regarding the waypoint commands and lines
--*
--* Copyright © 2006 Gas Powered Games Corp.  All rights reserved.
--*****************************************************************************

local MathSqrt = math.sqrt

-- Basic settings for waypoint information
CommandWaypointParams = {

	ui_CurveSegments			= 32,   --How many segments to subdivide curves into
	ui_CurveSmoothness			= 35,   --How big to make curves when drawing command previews
	ui_PathSmoothness			= 2,    --How big to make curves when drawing path preview
	ui_CommandGraphMaxNodeUnits = 1,    --Limits the size of the waypoints based on the number of units using the waypoint
	ui_MinWaypointSize			= 7.0,  --Set the minimum pixel size of a waypoint
	ui_MaxWaypointSize			= 100.0,--Set the maximum pixel size of a waypoint
	ui_WaypointLineScale		= 1.0,
	ui_WaypointArrowLODCutoff	= 999999.0,
	ui_CommandClickScale		= 1.0,

}

function CalculateWaypointLineWidth(unitCount)
    local lineWidth = MathSqrt(unitCount)
    if lineWidth >= 10 then
        lineWidth = 10
    end

	return ( lineWidth )
end
