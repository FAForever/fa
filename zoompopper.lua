--*****************************************************************************
--* File: lua/ui/game/zoompopper.lua
--* Author: III_Demon (Edited for FA by Warma)
--* Summary: Zoom POP! FAST!
--*
--* Copyright © 2xxx me,  All wrongs reversed.
--*****************************************************************************

function ToggleZoomPop()
   local cam = GetCamera('WorldCamera')
   local zoomRatio = (cam:GetTargetZoom() / cam:GetMaxZoom())   -- 0.5 is a good level for 'zoomed most of the way out'

   if zoomRatio > 0.4 then
      local zoom = import('/lua/user/prefs.lua').GetFromCurrentProfile('options').gui_zoom_pop_distance
      if zoom == nil then
         zoom = 80
      end
      local hpr = Vector(3.14159, (1-20/90)*(1.5708), 0)   -- I don't know the actual formula for the camera orientation but this is close
      cam:SnapTo(GetMouseWorldPos(), hpr, zoom)
      cam:RevertRotation() -- Revert to basic rotation scheme after popping in. Will move the camera uunless the camera tilt is already correct
   else
      cam:Reset()
   end
end 
