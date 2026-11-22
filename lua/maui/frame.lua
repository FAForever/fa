-- Class methods:
-- number GetTopmostDepth() - returns the topmost depth value regardless of hiding

local Control = import("/lua/maui/control.lua").Control

--- A frame is a Control group that has its Left, Width, Top, and Height lazyvars
--- set when the window is resized.
--- It also has methods to manage what head it is displayed on and a getter for the topmost depth control.
---@class Frame : moho.frame_methods, Control, InternalObject
Frame = ClassUI(moho.frame_methods, Control) {
    ---@param self Frame
    ---@param debugname? string
    __init = function(self, debugname)
        InternalCreateFrame(self)
        self.Depth:Set(0)
        if debugname then
            self:SetName(debugname)
        end
    end
}
