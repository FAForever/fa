--******************************************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local ALaserBotProjectile = import("/lua/aeonprojectiles.lua").ALaserBotProjectile
local ALaserBotProjectileOnCreate = ALaserBotProjectile.OnCreate
local ALaserBotProjectileOnImpact = ALaserBotProjectile.OnImpact

local OverchargeProjectile = import("/lua/sim/defaultprojectiles.lua").OverchargeProjectile
local OverchargeProjectileOnCreate = OverchargeProjectile.OnCreate
local OverchargeProjectileOnImpact = OverchargeProjectile.OnImpact

local EffectTemplate = import("/lua/effecttemplates.lua")

-- Aeon Mortar
---@class TDFOverCharge01 : ALaserBotProjectile, OverchargeProjectile
TDFOverCharge01 = ClassProjectile(ALaserBotProjectile, OverchargeProjectile) {
    PolyTrail = '/effects/emitters/aeon_commander_overcharge_trail_01_emit.bp',
    FxTrails = EffectTemplate.ACommanderOverchargeFXTrail01,
    FxImpactUnit = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactProp = EffectTemplate.ACommanderOverchargeHit01,
    FxImpactLand = EffectTemplate.ACommanderOverchargeHit01,

    ---@param self TDFOverCharge01
    OnCreate = function(self)
        ALaserBotProjectileOnCreate(self)
        OverchargeProjectileOnCreate(self)
    end,

    ---@param self TDFOverCharge01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        -- we need to run this the overcharge logic before running the usual on impact because
        -- that is where the damage is determined
        OverchargeProjectileOnImpact(self, targetType, targetEntity)
        ALaserBotProjectileOnImpact(self, targetType, targetEntity)
    end,
}

if true then

    -- Nyan cat seasonal event

    local oldTDFOverCharge01 = TDFOverCharge01
    TDFOverCharge01 = Class(oldTDFOverCharge01) {
        ---@param self TDFOverCharge01
        OnCreate = function(self)
            local vx, vy, vz, w = unpack(self:GetOrientation())
            if vz >= 0 then
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_01.bp' }
            else
                self.FxTrails = { '/effects/emitters/nyan_trail.bp',
                    '/effects/emitters/nyan_02.bp' }
            end

            oldTDFOverCharge01.OnCreate(self)
        end,
    }

end


TypeClass = TDFOverCharge01
