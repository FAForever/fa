--
-- script for projectile CDFTrackerProjectile
--
local CDFTrackerProjectile = import("/lua/cybranprojectiles.lua").CDFTrackerProjectile

CDFTracker01 = ClassProjectile(CDFTrackerProjectile) {
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