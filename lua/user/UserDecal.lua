
---@class UserDecal : moho.userDecal_methods
UserDecal = Class(moho.userDecal_methods) {
    __init = function(self)
        _c_CreateDecal(self)
    end,
    
    -- SetPositionByScreen(vector2)
    -- SetTexture(string)
    -- SetScale(vector3)
}