-- script for projectile TankShell
local Projectile = import("/lua/sim/projectile.lua").Projectile
ShellTankTerran01 = ClassProjectile(Projectile) {
    FxUnitHitScale = 1,
    FxImpactUnit = { },
    FxLandHitScale = 1,
    FxImpactLand = { },
    FxWaterHitScale = 1,
    FxImpactWater = { },
    FxUnderWaterHitScale = 0.25,
    FxAirUnitHitScale = 1,
    FxImpactAirUnit = { },
    FxNoneHitScale = 1,
    FxImpactNone = { },
    FxImpactLandScorch = false,
    FxImpactLandScorchScale = 1.0,

    FxMeta = {'/effects/emitters/quark_bomb_explosion_03_emit.bp',
                    '/effects/emitters/quark_bomb_explosion_04_emit.bp',
                    '/effects/emitters/quark_bomb_explosion_05_emit.bp',
                    '/effects/emitters/dust_cloud_02_emit.bp',
                    '/effects/emitters/dust_cloud_04_emit.bp',
                    '/effects/emitters/destruction_explosion_debris_04_emit.bp',
                    '/effects/emitters/destruction_explosion_debris_05_emit.bp',},

    OnCreate = function(self)
        Projectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.Thread,self))
    end,

    Thread = function(self)
        WaitTicks(5)
        while true do
            WaitTicks(Random(3,4))

            local x, y, z = unpack(self:GetPosition())
            MetaImpact(self, Vector(x, y, z), 2, 2)
            local army = self.Army
            for k, v in self.FxMeta do
                CreateEmitterAtEntity(self,army,v):ScaleEmitter(0.4)
            end
            self:ShakeCamera(5, 1, 0, 0.1)
            CreateSplat(self:GetPosition(),0,'scorch_001_albedo', 1, 1, 200, 500, army)
        end
    end,
}
TypeClass = ShellTankTerran01