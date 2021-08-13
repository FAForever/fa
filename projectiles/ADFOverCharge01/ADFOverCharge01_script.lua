-- Aeon Mortar

local ALaserBotProjectile = import('/lua/aeonprojectiles.lua').ALaserBotProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local OverchargeProjectile = import('/lua/sim/DefaultProjectiles.lua').OverchargeProjectile

TDFOverCharge01 = Class(ALaserBotProjectile, OverchargeProjectile) {

    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,

    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local army = self.Army
            
            CreateDecal(pos, RandomFloat(0,2*math.pi), 'crater_radial01_albedo', '', 'Albedo', radius * 2, radius * 2, 150, 40, army)
            CreateDecal(pos, RandomFloat(0,2*math.pi), 'crater_radial01_albedo', '', 'Albedo', radius * 2, radius * 2, 150, 40, army)
        end
        
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        ALaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,
    
    OnCreate = function(self)
        OverchargeProjectile.OnCreate(self)
        ALaserBotProjectile.OnCreate(self)
    end,
}

TypeClass = TDFOverCharge01
