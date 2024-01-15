local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local fps = false

function ShowFPS()
    if fps then
        fps:Destroy()
        fps = false
        return
    end
    
    fps = UIUtil.CreateText(GetFrame(0), '', 12)
    fps:SetColor('ffffff')
    fps:SetFont(UIUtil.fixedFont, 12)
    fps:SetDropShadow(true)
    fps:DisableHitTest()
    fps.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    LayoutHelpers.AtRightTopIn(fps, GetFrame(0), 425, 0)
    
    fps:SetNeedsFrameUpdate(true)
    fps.OnFrame = function(self, deltatime)
        if not self.timer or self.timer > 0.4 then
            for key, val in __EngineStats.Children do
                if val.Name == 'Frame' then
                    for childKey, childVal in val.Children do
                        if childVal.Name == 'FPS' then
                            self:SetText(string.format("FPS: %.0f", childVal.Value))
                            break
                        end
                    end
                    break
                end
            end
            self.timer = 0
        else
            self.timer = self.timer + deltatime
        end
    end
end