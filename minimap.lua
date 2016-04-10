-- FAF hook for the GPG minimap file, which has the following public interface:
--
-- function SetLayout(layout)
-- function CommonLogic()
-- function CreateMinimap(parent)
-- function ToggleMinimap()
-- function GetMinimapState()
-- function Expand()
-- function Contract()


-- Fix the preference key that's used to persist minimap resource icons
local minimap_resources = Prefs.GetFromCurrentProfile('MiniMap_resource_icons') or false

do
    local oldCreateMinimap = CreateMinimap
    function CreateMinimap(parent)
        oldCreateMinimap(parent)
        controls.miniMap:EnableResourceRendering(minimap_resources)
        local frameCount = 0
        -- This is hooked to remove a call to EnableResourceRendering inside.
        -- FIXME: Is there a reason we're not just spawning a thread using WaitSeconds instead of this hack?
        controls.miniMap.OnFrame = function(self, elapsedTime)
            if frameCount == 1 then
                controls.miniMap:CameraReset()
                GetCamera(controls.miniMap._cameraName):SetMaxZoomMult(1.0)
                controls.miniMap.OnFrame = nil
            end
            frameCount = frameCount + 1
        end
    end
end
