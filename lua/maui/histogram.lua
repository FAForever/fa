--[[ 
ClassUI methods:

- SetXIncrement(int) - sets the increment of the units of the axis 
    (ie if set to 100 x axis goes from 0-100 to start, then if a value comes in at 350, will resize to 400)
- SetYIncrement(int)
- SetData(dataTable)
    dataTable format:
        {
            [1] = {
                color = colorVal,
                data = {table of numbers}
            }
            [2] = ...
        }
--]]
local Control = import("/lua/maui/control.lua").Control

---@deprecated
---@class Histogram : moho.histogram_methods, Control, InternalObject
Histogram = ClassUI(moho.histogram_methods, Control) {
    __init = function(self, parent, debugname)
        InternalCreateHistogram(self, parent)
        if debugname then
            self:SetName(debugname)
        end
    end,
}
