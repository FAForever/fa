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

local DefaultProjectileWeapon = import('/lua/sim/defaultweapons.lua').DefaultProjectileWeapon
local EffectTemplate = import('/lua/effecttemplates.lua')

local CategoriesChronoDampener = categories.MOBILE - (categories.COMMAND + categories.EXPERIMENTAL + categories.AIR)

---@class ADFChronoDampener : DefaultProjectileWeapon
ADFChronoDampener = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AChronoDampenerLarge,
    FxMuzzleFlashScale = 0.5,
    FxUnitStun = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
    FxUnitStunFlash = EffectTemplate.ADisruptorCannonMuzzle01,

    RackSalvoFiringState = State(DefaultProjectileWeapon.RackSalvoFiringState) {
        Main = function(self)
            local bp = self:GetBlueprint()
            ---@type Unit
            local unit = self.unit
            local primaryWeapon = unit:GetWeaponByLabel('RightDisruptor')

            -- Align to a tick which is a multiple of 50
            WaitTicks(51 - math.mod(GetGameTick(), 50))

            while true do

                if bp.Audio.Fire then
                    self:PlaySound(bp.Audio.Fire)
                end

                self:PlayFxMuzzleSequence(1)
                self:StartEconomyDrain()
                self:OnWeaponFired()

                -- some constants that need to go into blueprint
                local slices = 10

                -- extract information from the buff blueprint
                local buff = bp.Buffs[1]
                local stunDuration = buff.Duration
                local radius = (primaryWeapon and primaryWeapon:GetMaxRadius()) or buff.Radius
                local sliceSize = radius / slices

                for i = 1, slices do

                    local radius = i * sliceSize 
                    local targets = utilities.GetTrueEnemyUnitsInSphere(
                        self, 
                        self.unit:GetPosition(), 
                        radius, 
                        CategoriesChronoDampener
                    )

                    for k, target in targets do 

                        if not target:BeenDestroyed() then 
                            if buff.BuffType == 'STUN' then 
                                target:SetStunned(0.1 * stunDuration / slices + 0.1)
                            end
                        end

                        -- add initial effect
                        if not target.InitialStunFxApplied then 
                            for k, effect in self.FxUnitStunFlash do 
                                local emit = CreateEmitterOnEntity(target, target.Army, effect)
                                emit:ScaleEmitter(math.max(target.Blueprint.SizeX, target.Blueprint.SizeZ))
                            end

                            target.InitialStunFxApplied = true 
                        end

                        -- add effect on target
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

                    WaitTicks(stunDuration / slices + 1)
                end

                WaitTicks(51 - stunDuration)
            end
        end,

        OnFire = function(self)
        end,

        OnLostTarget = function(self)
            ChangeState(self, self.IdleState)
            DefaultProjectileWeapon.OnLostTarget(self)
        end,
    },

    ---@param self ADFChronoDampener
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
    end,
}