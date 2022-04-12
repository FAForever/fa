-- Class methods:
-- number GetTopmostDepth() - returns the topmost depth value regardless of hiding

local Control = import('control.lua').Control

Frame = Class(moho.frame_methods, Control) {

    __init = function(self, debugname)
        InternalCreateFrame(self)
        self.Depth:Set(0)
        if debugname then
            self:SetName(debugname)
        end
    end
}

