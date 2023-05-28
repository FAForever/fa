-- Class methods
-- Destroy()
-- SetMesh(meshDesc)
--  UniformScale = number (optional, defaults to 1.0)
--  Color = color desc (optional, defaults to FFFFFFFF)
--  LODCutoff = number (optional, defaults to DEFAULTCUTOFF (1000))
--  BlueprintID = blueprint ID for mesh info
--  MeshName = mesh resource name, if this is present as well as BlueprintID, MeshName will be used no BPID
--  ShaderName = required if MeshName used, ignored if BlueprintID used, the shader name from Mesh.fx
--  TextureName = required if MeshName used, ignored if BlueprintID used, the texture resource name
-- SetStance(vector position, [quaternion orientation])
--  Stance is position and orientation, this function sets a static stance, others will allow interpolation between one and the other
-- SetHidden(bool hidden)
-- bool IsHidden()
-- SetColor(bool hidden)
--  The team color
-- SetScale(vector scale)
-- SetAuxiliaryParameter(float param)
-- SetFractionCompleteParameter(float param)
-- SetFractionHealthParameter(float param)
-- SetLifetimeParameter(float param)
--  The parameter functions set values that can be accessed by the shader
---@class WorldMesh : moho.world_mesh_methods
WorldMesh = ClassUI(moho.world_mesh_methods) {
    ---@param self WorldMesh
    __init = function(self)
        InternalCreateWorldMesh(self)
    end,
}