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

local ADisruptorProjectile = import("/lua/aeonprojectiles.lua").AShieldDisruptorProjectile
local ADisruptorProjectileOnImpact = ADisruptorProjectile.OnImpact

--- Aeon Shield Disruptor Projectile, DAL0310
---@class ADFShieldDisruptor01 : AShieldDisruptorProjectile
ADFShieldDisruptor01 = ClassProjectile(ADisruptorProjectile) {

    ---@param self ADFShieldDisruptor01
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        ADisruptorProjectileOnImpact(self, targetType, targetEntity)

        -- try to find the shield that we hit
        if targetType ~= 'Shield' then
            targetEntity = targetEntity.MyShield
        end

        if not targetEntity then
            return
        end

        -- we directly damage the shield to prevent generating overspill damage
        local damage = targetEntity:GetHealth()
        if damage > 1300 then -- TODO: find a better way to pass this damage
            damage = 1300
        elseif damage < 1 then
            damage = 1
        end

        Damage(self, self:GetPosition(), targetEntity, damage, 'Normal')
    end,
}
TypeClass = ADFShieldDisruptor01
