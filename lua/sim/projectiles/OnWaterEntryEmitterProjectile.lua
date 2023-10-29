--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local Projectile = import("/lua/sim/projectile.lua").Projectile

-- upvalue scope for performance
local WaitTicks = WaitTicks
local IsDestroyed = IsDestroyed
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity

local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

---@class OnWaterEntryEmitterProjectile : Projectile
OnWaterEntryEmitterProjectile = ClassProjectile(Projectile) {
    FxTrails = { '/effects/emitters/torpedo_munition_trail_01_emit.bp', },
    FxTrailScale = 1,
    FxTrailOffset = 0,

    PolyTrail = '',
    PolyTrailOffset = 0,

    TrailDelay = 2,

    FxEnterWater = {
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    ---@param self OnWaterEntryEmitterProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        Projectile.OnCreate(self, inWater)

        if inWater then

            local army = self.Army
            local fxTrails = self.FxTrails
            local fxTrailScale = self.FxTrailScale
            local fxTrailOffset = self.FxTrailOffset

            local polyTrail = self.PolyTrail
            local polyTrailOffset = self.PolyTrailOffset

            for i in fxTrails do
                local effect = CreateEmitterOnEntity(self, army, fxTrails[i])

                -- only do these engine calls when they matter
                if fxTrailScale ~= 1 then
                    IEffectScaleEmitter(effect, fxTrailScale)
                end

                if fxTrailOffset ~= 1 then
                    IEffectOffsetEmitter(effect, 0, 0, fxTrailOffset)
                end
            end

            if polyTrail ~= '' then
                local effect = CreateTrail(self, -1, army, polyTrail)

                -- only do these engine calls when they matter
                if polyTrailOffset ~= 0 then
                    IEffectOffsetEmitter(effect, 0, 0, polyTrailOffset)
                end
            end
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    EnterWaterThread = function(self)
        WaitTicks(self.TrailDelay)

        if IsDestroyed(self) then
            return
        end

        local army = self.Army
        local fxTrails = self.FxTrails
        local fxTrailScale = self.FxTrailScale
        local fxTrailOffset = self.FxTrailOffset
        local polyTrail = self.PolyTrail
        local polyTrailOffset = self.PolyTrailOffset

        for i in fxTrails do
            local effect = CreateEmitterOnEntity(self, army, fxTrails[i])

            -- only do these engine calls when they matter
            if fxTrailScale ~= 1 then
                IEffectScaleEmitter(effect, fxTrailScale)
            end

            if fxTrailOffset ~= 1 then
                IEffectOffsetEmitter(effect, 0, 0, fxTrailOffset)
            end
        end

        if polyTrail ~= '' then
            local effect = CreateTrail(self, -1, army, polyTrail)

            -- only do these engine calls when they matter
            if polyTrailOffset ~= 0 then
                IEffectOffsetEmitter(effect, 0, 0, polyTrailOffset)
            end
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    OnEnterWater = function(self)
        Projectile.OnEnterWater(self)

        self:SetVelocityAlign(true)
        self:SetStayUpright(false)
        self:TrackTarget(true)
        self:StayUnderwater(true)

        -- adds the effects after a delay
        self.Trash:Add(ForkThread(self.EnterWaterThread, self))

        -- adjusts the velocity / acceleration, used for torpedo bombers
        if self.MovementThread then
            self.Trash:Add(ForkThread(self.MovementThread, self))
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Terrain' then
            -- we only fix this for projectiles that are supposed to go into the water
            local px, py, pz = self:GetPositionXYZ()
            local surfaceHeight = GetSurfaceHeight(px, pz)
            if py <= surfaceHeight - 0.1 then
                targetType = 'Underwater'
            end
        end

        Projectile.OnImpact(self, targetType, targetEntity)
    end,
}
