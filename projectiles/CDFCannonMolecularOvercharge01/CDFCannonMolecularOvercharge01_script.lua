local CMolecularCannonProjectile = import("/lua/cybranprojectiles.lua").CMolecularCannonProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

--- Cybran Molecular Cannon
---@class CDFCannonMolecular01: CMolecularCannonProjectile, OverchargeProjectile
CDFCannonMolecular01 = ClassProjectile(CMolecularCannonProjectile, OverchargeProjectile) {
    PolyTrail = '/effects/emitters/default_polytrail_03_emit.bp',
    FxTrails = EffectTemplate.CCommanderOverchargeFxTrail01,

    -- Hit Effects
    FxImpactUnit = EffectTemplate.CCommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.CCommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.CCommanderOverchargeHit01,

    ---@param self CDFCannonMolecular01
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
        if self.Blueprint.Audio.ExistLoop then
            self.Loop = PlayLoop(self.Blueprint.Audio.ExistLoop)
        end

        CMolecularCannonProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,

    ---@param self CDFCannonMolecular01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- Nyan cat seasonal event
        if self.Loop then
            StopLoop(self.Loop)
        end

        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        CMolecularCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = CDFCannonMolecular01