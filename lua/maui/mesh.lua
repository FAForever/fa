-- Methods exposed from C++
-- SetMesh(meshBPName) the blueprint ID of the mesh you wish to render

local Control = import('control.lua').Control

Mesh = Class(moho.mesh_methods, Control) {
    __init = function(self, parent, debugname)
        InternalCreateMesh(self, parent)
        if debugname then
            self:SetName(debugname)
        end
    end,
}
