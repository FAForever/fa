local Control = import("/lua/maui/control.lua").Control

---@class Group : moho.group_methods, Control, InternalObject
Group = ClassUI(moho.group_methods, Control) {
    ---@param self Group
    ---@param parent Control
    ---@param debugname? string
    __init = function(self, parent, debugname)
        InternalCreateGroup(self, parent)
        if debugname then
            self:SetName(debugname)
        end
    end,
}
