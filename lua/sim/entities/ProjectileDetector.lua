
local Entity = import("/lua/sim/entity.lua").Entity

---@class ProjectileDetectorSpec
---@field Owner Unit
---@field Weapon Weapon
---@field Radius number
---@field Bone Bone

---@class ProjectileDetector : Entity
---@field Owner Unit
---@field Weapon Weapon
ProjectileDetector = Class(Entity) {

    ---@param self ProjectileDetector
    ---@param spec ProjectileDetectorSpec
    OnCreate = function(self, spec)
        self.Owner = spec.Owner
        self.Weapon = spec.Weapon
        self:SetCollisionShape("Sphere", 0, 0, 0, spec.Radius)
        self:AttachTo(spec.Owner, spec.Bone)
    end,

    ---@param self ProjectileDetector
    ---@param other Projectile
    ---@return boolean
    OnCollisionCheck = function(self, other)
        reprsl(other)
        self.Weapon:OnProjectileDetected(other)

        -- always return false
        return false
    end,
}