
---@class DebrisComponent
DebrisComponent = ClassSimple {

    DebrisBlueprints = {
        '/effects/entities/DebrisMisc04/DebrisMisc04_proj.bp'
    },

    ---@param self DebrisComponent | Projectile
    CreateDebris = function(self)
        local blueprint = table.random(self.DebrisBlueprints)
        return self:CreateChildProjectile(blueprint)
    end,
}
