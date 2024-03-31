-- File     :  /data/projectiles/SDFChronatronCannon02/SDFChronatronCannon02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------
local SChronatronCannonOverCharge = import("/lua/seraphimprojectiles.lua").SChronatronCannonOverCharge
local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile

--- ChronatronCannon Projectile script, Seraphim commander overcharge, XSL0001
---@class SDFChronatronCannon02 : SChronatronCannonOverCharge, OverchargeProjectile
SDFChronatronCannon02 = ClassProjectile(SChronatronCannonOverCharge, OverchargeProjectile) {

    PolyTrails = { },

    ---@param self SDFChronatronCannon02
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because that is where the damage is determined
        OverchargeProjectile.OnImpact(self, targetType, targetEntity)
        SChronatronCannonOverCharge.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self SDFChronatronCannon02
    OnCreate = function(self)
        SChronatronCannonOverCharge.OnCreate(self)
        OverchargeProjectile.OnCreate(self)
    end,
}

if true then

    -- Nyan cat seasonal event

    local oldSDFChronatronCannon02 = SDFChronatronCannon02
    SDFChronatronCannon02 = Class(oldSDFChronatronCannon02) {
        ---@param self SDFChronatronCannon02
        OnCreate = function(self)
            local vx, vy, vz, w = unpack(self:GetOrientation())
            if vz >= 0 then
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_01.bp' }
            else
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_02.bp' }
            end

            oldSDFChronatronCannon02.OnCreate(self)
        end,
    }

end


TypeClass = SDFChronatronCannon02