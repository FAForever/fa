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
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        CMolecularCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self CDFCannonMolecular01
    OnCreate = function(self)
        CMolecularCannonProjectile.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}

if true then

    local oldCDFCannonMolecular01 = CDFCannonMolecular01
    CDFCannonMolecular01 = Class(oldCDFCannonMolecular01) {
        ---@param self CDFCannonMolecular01
        OnCreate = function(self)
            local vx, vy, vz, w = unpack(self:GetOrientation())
            if vz >= 0 then
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_01.bp' }
            else
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_02.bp' }
            end

            oldCDFCannonMolecular01.OnCreate(self)
        end,
    }

end


TypeClass = CDFCannonMolecular01
