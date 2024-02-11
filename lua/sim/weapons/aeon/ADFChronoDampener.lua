--**********************************************************************************
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
--**********************************************************************************

--- kept for mod backwards compatibility
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

local EffectTemplate = import("/lua/effecttemplates.lua")
local utilities = import('/lua/utilities.lua')

---@class ADFChronoDampener : DefaultProjectileWeapon
ADFChronoDampener = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AChronoDampenerLarge,
    FxMuzzleFlashScale = 0.5,
    FxUnitStun = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
    FxUnitStunFlash = EffectTemplate.Aeon_HeavyDisruptorCannonUnitHit,

    ---@param self ADFChronoDampener
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)
        -- Stores the original FX scale so it can be adjusted by range changes
        self.OriginalFxMuzzleFlashScale = self.FxMuzzleFlashScale

        local buff = self.Blueprint.Buffs[1]
        self.CategoriesToStun = ParseEntityCategory(buff.TargetAllow) - ParseEntityCategory(buff.TargetDisallow)
    end,

    ---@param self ADFChronoDampener
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
        local bp = self.Blueprint

        if bp.Audio.Fire then
            self:PlaySound(bp.Audio.Fire)
        end

        self.Trash:Add(ForkThread(self.ExpandingStunThread, self))
    end,

    --- Thread to avoid waiting in the firing cycle and stalling the main cannon.
    ---@param self ADFChronoDampener
    ExpandingStunThread = function(self)
        -- extract information from the buff blueprint
        local bp = self.Blueprint
        local reloadTimeTicks = MATH_IRound(10/bp.RateOfFire)
        local buff = bp.Buffs[1]
        local stunDuration = buff.Duration
        local radius = self:GetMaxRadius()
        local slices = 10
        local sliceSize = radius / slices
        local sliceTime = stunDuration * 10 / slices + 1
        local initialStunFxAppliedUnits = {}
        local tick = GetGameTick()

        for i = 1, slices do

            local radius = i * sliceSize
            local targets = utilities.GetTrueEnemyUnitsInSphere(
                self,
                self.unit:GetPosition(),
                radius,
                self.CategoriesToStun
            )
            local fxUnitStunFlashScale = (0.5 + (slices-i) / (slices-1) * 1.5)

            for k, target in targets do

                -- add stun effect only on targets our Chrono Dampener stunned
                if initialStunFxAppliedUnits[target] then
                    local count = target:GetBoneCount()
                    for k, effect in self.FxUnitStun do
                        local emit = CreateEmitterAtBone(
                            target, Random(0, count - 1), target.Army, effect
                        )

                        -- scale the effect a bit
                        emit:ScaleEmitter(0.5)

                        -- change lod to match outer lod of unit
                        local lods = target.Blueprint.Display.Mesh.LODs
                        if lods then
                            emit:SetEmitterParam("LODCUTOFF", lods[table.getn(lods)].LODCutoff)
                        end
                    end
                end

                -- prevent multiple Chrono Dampeners from stunlocking units with desynchronized firings
                if target.chronoProtectionTick > tick then
                    continue
                end

                -- add stun
                if not target:BeenDestroyed() then
                    if buff.BuffType == 'STUN' then
                        target:SetStunned(stunDuration * (slices - i + 1) / slices + 0.1)
                        target.chronoProtectionTick = tick + reloadTimeTicks
                    end
                end

                -- add initial flash effect
                for k, effect in self.FxUnitStunFlash do
                    local emit = CreateEmitterOnEntity(target, target.Army, effect)
                    emit:ScaleEmitter(fxUnitStunFlashScale * math.max(target.Blueprint.SizeX, target.Blueprint.SizeZ))
                end
                initialStunFxAppliedUnits[target] = true

                -- add initial stun effect on target
                local count = target:GetBoneCount()
                for k, effect in self.FxUnitStun do
                    local emit = CreateEmitterAtBone(
                        target, Random(0, count - 1), target.Army, effect
                    )

                    -- scale the effect a bit
                    emit:ScaleEmitter(0.5)

                    -- change lod to match outer lod of unit
                    local lods = target.Blueprint.Display.Mesh.LODs
                    if lods then
                        emit:SetEmitterParam("LODCUTOFF", lods[table.getn(lods)].LODCutoff)
                    end
                end
            end

            WaitTicks(sliceTime)
        end
    end,

    ---@param self ADFChronoDampener
    ---@param radius number
    ChangeMaxRadius = function(self, radius)
        DefaultProjectileWeapon.ChangeMaxRadius(self, radius)
        self.FxMuzzleFlashScale = self.OriginalFxMuzzleFlashScale * radius / self.Blueprint.MaxRadius
    end,
}
