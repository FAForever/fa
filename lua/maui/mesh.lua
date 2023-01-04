-- Methods exposed from C++
-- SetMesh(meshBPName) the blueprint ID of the mesh you wish to render

local Control = import("/lua/maui/control.lua").Control

---@class Mesh : moho.mesh_methods, Control, InternalObject
Mesh = ClassUI(moho.mesh_methods, Control) {
    ---@param self Mesh
    ---@param parent Control
    ---@param debugname? string
    __init = function(self, parent, debugname)
        InternalCreateMesh(self, parent)
        if debugname then
            self:SetName(debugname)
        end
    end,
}
