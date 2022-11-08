local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local fps = false

function ShowFPS()
    if fps then
        fps:Destroy()
        fps = false
        return
    end
    
    fps = UIUtil.CreateText(GetFrame(0), '', 30)
    fps:SetColor('ffffffff')
    fps:SetDropShadow(true)
    fps:DisableHitTest()
    fps.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    LayoutHelpers.AtLeftTopIn(fps, GetFrame(0))
    
    fps:SetNeedsFrameUpdate(true)
    fps.OnFrame = function(self, deltatime)
        for key, val in __EngineStats.Children do
            if val.Name == 'Frame' then
                for childKey, childVal in val.Children do
                    if childVal.Name == 'FPS' then
                        self:SetText(string.format("%2.1f", childVal.Value))
                        break
                    end
                end
                break
            end
        end
    end
end