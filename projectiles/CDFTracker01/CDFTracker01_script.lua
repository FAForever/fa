local CDFTrackerProjectile = import("/lua/cybranprojectiles.lua").CDFTrackerProjectile

--- Cybran Tracker Projectile
---@class CDFTracker01 : CDFTrackerProjectile
CDFTracker01 = ClassProjectile(CDFTrackerProjectile) {

    ---@param self CDFTracker01
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
    OnImpact = function(self, TargetType, TargetEntity)
        if TargetEntity then
            local x,y,z = unpack(TargetEntity:GetPosition())
            local tracker = CreateUnit('URB5206', self.Army, x, y, z, 0, 0, 0, 0)
            tracker:AttachTo(TargetEntity, -1)
        end
        CDFTrackerProjectile.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = CDFTracker01