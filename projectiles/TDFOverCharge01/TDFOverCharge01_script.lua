local TLaserBotProjectile = import("/lua/terranprojectiles.lua").TLaserBotProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

--- UEF Blaster
---@class TDFOverCharge01: TLaserBotProjectile, OverchargeProjectile
TDFOverCharge01 = ClassProjectile(TLaserBotProjectile, OverchargeProjectile) {
    FxTrails = EffectTemplate.TCommanderOverchargeFXTrail01,
    FxTrailScale = 1.0,

    -- Hit Effects
    FxImpactUnit =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactProp =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactLand =  EffectTemplate.TCommanderOverchargeHit01,
    FxImpactAirUnit =  EffectTemplate.TCommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        -- Nyan cat seasonal event
        local vx, vy, vz, w = unpack(self:GetOrientation())
        if vz >= 0 then
            self.FxTrails = {
                '/effects/emitters/nyan_trail.bp',
                '/effects/emitters/nyan_01.bp'
            }
        else
            self.FxTrails = {
                '/effects/emitters/nyan_trail.bp',
                '/effects/emitters/nyan_02.bp'
            }
        end

        TLaserBotProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        TLaserBotProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TDFOverCharge01