----------------------------------------------------------------
-- File     :  /lua/aeonweapons.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos, Greg Kohne
-- Summary  :  Default definitions of Aeon weapons
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

local Entity = import("/lua/sim/entity.lua").Entity
local Weapon = import("/lua/sim/weapon.lua").Weapon
local WeaponFile = import("/lua/sim/defaultweapons.lua")
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local utilities = import('/lua/utilities.lua')
local Explosion = import("/lua/defaultexplosions.lua")
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class AIFBallisticMortarWeapon : DefaultProjectileWeapon
AIFBallisticMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AIFBallisticMortarFlash02,
}

---@class ADFReactonCannon : DefaultProjectileWeapon
ADFReactonCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/reacton_cannon_muzzle_charge_01_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_charge_02_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_charge_03_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_01_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_02_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_03_emit.bp',
    },
}

---@class ADFOverchargeWeapon : OverchargeWeapon
ADFOverchargeWeapon = Class(WeaponFile.OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.ACommanderOverchargeFlash01,
    DesiredWeaponLabel = 'RightDisruptor'
}

---@class ADFTractorClaw : Weapon
---@field TractorTrash TrashBag
---@field RunningTractorThread boolean
ADFTractorClaw = Class(Weapon) {

    VacuumFx = EffectTemplate.ACollossusTractorBeamVacuum01,
    TractorFx = EffectTemplate.ATractorAmbient,
    CrushFx = EffectTemplate.ACollossusTractorBeamCrush01,
    TractorMuzzleFx = { EffectTemplate.ACollossusTractorBeamGlow01 },
    BeamFx = { EffectTemplate.ACollossusTractorBeam01 },

    SliderVelocity = {
        TECH3 = 10,
        TECH2 = 13,
        TECH1 = 16,
    },

    --- Adds logic to catch edge cases
    ---@param self ADFTractorClaw
    ---@param spec table
    OnCreate = function(self, spec)
        Weapon.OnCreate(self, spec)

        -- make us quite a bit slower
        self.AimControl:SetResetPoseTime(4.0)

        -- add a unit callback to fix edge cases
        self.unit:AddUnitCallback(
            function(colossus, instigator)
                if self.RunningTractorThread then
                    -- reset target state
                    local blipOrUnit = self:GetCurrentTarget()
                    if not IsDestroyed(blipOrUnit) then 
                        local target = self:GetUnitBehindTarget(blipOrUnit)
                        if target then
                            self:MakeVulnerable(target)
                        end
                    end

                    -- detach everything from this weapon
                    self.unit:DetachAll(self.Blueprint.MuzzleSpecial)
                    self:SetEnabled(false)
                end
            end,
            'OnKilled'
        )
    end,

    --- Attempts to perform the tracting
    ---@param self ADFTractorClaw
    OnFire = function(self)
        -- only tractor one target at a time
        if self.RunningTractorThread then
            self:ForkThread(self.OnInvalidTargetThread)
            return
        end

        ---@type Blip | Unit
        local blipOrUnit = self:GetCurrentTarget()
        if not blipOrUnit then
            return
        end

        -- only tractor actual units
        local target = self:GetUnitBehindTarget(blipOrUnit)
        if not target then
            self:ForkThread(self.OnInvalidTargetThread)
            return
        end

        -- only tract units that are not being tracted at the moment
        if target.Tractored then
            self:ForkThread(self.OnInvalidTargetThread)
            return
        end

        -- start tractoring
        target.Tractored = true
        self.RunningTractorThread = true
        local muzzle = self.Blueprint.MuzzleSpecial
        self.TractorThreadInstance = ForkThread(self.TractorThread, self, target, muzzle)
    end,

    --- Disables the weapon to make sure we try and get a new target
    ---@param self ADFTractorClaw
    OnInvalidTargetThread = function(self)
        self:ResetTarget()
        self:SetEnabled(false)
        WaitSeconds(0.4)
        if not IsDestroyed(self) then
            self:SetEnabled(true)
        end
    end,

    --- Attempts to retrieve the unit behind the target, can return false if the blip is too far away from the unit due to jamming
    ---@param self ADFTractorClaw
    ---@param blip Blip | Unit
    ---@return Unit | boolean
    GetUnitBehindTarget = function(self, blip)
        if IsUnit(blip) then
            -- return the unit
            return blip
        else
            local blipPosition = blip:GetPosition()
            local unit = blip:GetSource()
            local unitPosition = unit:GetPosition()
            local distance = VDist3(blipPosition, unitPosition)
            if distance < 10 then
                return unit
            else
                return false
            end
        end
    end,

    --- Performs the tractoring, starting from this point all is good
    ---@param self ADFTractorClaw
    ---@param target Unit
    ---@param muzzle string
    TractorThread = function(self, target, muzzle)

        local unit = self.unit
        local trash = TrashBag()
        self.Trash:Add(trash)

        -- apparently `CreateEmitterAtBone` doesn't attach to the bone, only positions it at the bone
        local effectsEntity = Entity({Owner = unit})
        Warp(effectsEntity, unit:GetPosition(self.Blueprint.TurretBoneMuzzle))
        effectsEntity:AttachTo(unit, self.Blueprint.TurretBoneMuzzle)
        trash:Add(effectsEntity)

        -- create vacuum effect
        for k, effect in self.VacuumFx do
            trash:Add(CreateEmitterOnEntity(target, self.Army, effect):ScaleEmitter(0.75))
        end

        -- create tractor effect
        for k, effect in self.TractorFx do 
            trash:Add(CreateEmitterOnEntity(target, self.Army, effect))
        end

        -- create start effect
        for k, effect in self.TractorMuzzleFx do
            trash:Add(CreateEmitterOnEntity(effectsEntity, self.Army, effect))
        end

        -- compute the distance to set the slider
        local bonePosition = unit:GetPosition(muzzle)
        local targetPosition = target:GetPosition()
        local distance = VDist3(bonePosition, targetPosition)

        local slider = CreateSlider(unit, muzzle, 0, 0, distance, -1, true)
        trash:Add(slider)

        WaitTicks(1)
        WaitFor(slider)

        if (not IsDestroyed(target)) and (not IsDestroyed(unit)) then

            -- attach the slider to the target
            target:SetDoNotTarget(false)
            target:AttachBoneTo(-1, unit, muzzle)
            self:MakeImmune(target)

            -- make it stop what it was doing
            IssueClearCommands({target})

            local velocity = self.SliderVelocity[target.Blueprint.TechCategory] or 13

            -- start pulling back the slider
            slider:SetSpeed(velocity)
            slider:SetGoal(0, 0, 0)

            trash:Add(CreateRotator(target, 0, 'x', nil, 0, 15 + Random(0, 45), 20 + Random(0, 80)))
            trash:Add(CreateRotator(target, 0, 'y', nil, 0, 15 + Random(0, 15), 20 + Random(0, 80)))
            trash:Add(CreateRotator(target, 0, 'z', nil, 0, 15 + Random(0, 45), 20 + Random(0, 80)))

            WaitTicks(1)
            WaitFor(slider)

            -- we're at the arm, do destruction effects
            if (not IsDestroyed(target)) and (not IsDestroyed(unit)) and (not IsDestroyed(self)) then

                -- create crush effect
                for k, effect in self.CrushFx do
                    CreateEmitterAtBone(unit, muzzle, unit.Army, effect)
                end

                -- create light particles
                CreateLightParticle(unit, muzzle, self.Army, 1, 4, 'glow_02', 'ramp_blue_16')
                WaitTicks(1)

                if not IsDestroyed(unit) then 
                    

                    target.CanTakeDamage = true
                    while not IsDestroyed(target) and not IsDestroyed(unit) and target:GetHealth() >= 730 do
                        Damage(unit, bonePosition, target, 729, "Normal")
                        Explosion.CreateScalableUnitExplosion(target, 1, true)
                        WaitTicks(11)
                    end

                    CreateLightParticle(unit, muzzle, self.Army, 4, 2, 'glow_02', 'ramp_blue_16')
                    Explosion.CreateScalableUnitExplosion(target, 3, true)

                    -- deattach the unit, destroy the slider
                    unit:DetachAll(muzzle)
                    slider:Destroy()

                    -- remove the shield, if it is there
                    if target.MyShield then
                        target.MyShield:TurnOff()
                    end

                    -- create thread to take into account the fall
                    self:ForkThread(self.TargetFallThread, target, trash, muzzle)
                    self:ResetTarget()
                else 
                    self:MakeVulnerable(target)
                    trash:Destroy()
                end
            else 
                self:MakeVulnerable(target)
                trash:Destroy()
            end
        else 
            self:MakeVulnerable(target)
            trash:Destroy()
        end

        self.TractorThreadInstance = nil
        self.RunningTractorThread = false
    end,

    --- Semi-realistic fall from the tractor claw to the ground
    ---@param self ADFTractorClaw
    ---@param target Unit
    ---@param trash TrashBag
    ---@param muzzle string
    TargetFallThread = function(self, target, trash, muzzle)

        -- clean up the effects once the unit starts falling
        if not IsDestroyed(self) then
            self:ForkThread(self.TrashDelayedDestroyThread, trash)
        end

        -- if the unit is magically already destroyed, then just return - nothing we can do,
        -- we'll likely end up with a flying wreck :)
        if IsDestroyed(target) then
            return
        end

        -- air units drop on their own
        if target.Blueprint.CategoriesHash.AIR then
            target:Kill()
        -- assist land units with a natural drop
        else 
            -- let it create the wreck, with the rotator manipulators attached
            target.PlayDeathAnimation = false
            target.DestructionExplosionWaitDelayMin = 0
            target.DestructionExplosionWaitDelayMax = 0

            -- create a projectile that matches the velocity / orientation 
            local vx, vy, vz = target:GetVelocity()
            local projectile = target:CreateProjectileAtBone('/effects/entities/ADFTractorFall01/ADFTractorFall01_proj.bp', 0)
            projectile:SetVelocity(10 * vx, 10 * vy, 10 * vz)
            Warp(projectile, target:GetPosition(), target:GetOrientation())

            -- happens when the projectile is created underwater
            if IsDestroyed(projectile) then
                target:Kill()
            end

            projectile.OnImpact = function(projectile)
                if not IsDestroyed(target) then
                    target.CanTakeDamage = true
                    target:Kill()

                    CreateLightParticle(target, 0, self.Army, 4, 2, 'glow_02', 'ramp_blue_16')

                    local position = target:GetPosition()
                    DamageArea(target, position, 3, 1, 'TreeFire', false, false)
                    DamageArea(target, position, 2, 1, 'TreeForce', false, false)
                end

                projectile:Destroy()
            end
        end
    end,

    --- Delayed destruction of the trashbag, allows the wreck to copy over the rotators
    ---@param self ADFTractorClaw
    ---@param trash TrashBag
    TrashDelayedDestroyThread = function(self, trash)
        WaitTicks(2)
        trash:Destroy()
    end,

    ---@param self ADFTractorClaw
    ---@param target Unit
    MakeImmune = function (self, target)
        if not IsDestroyed(target) then
            target:SetDoNotTarget(true)
            target.CanTakeDamage = false
            target.DisallowCollisions = true
        end
    end,

    ---@param self ADFTractorClaw
    ---@param target Unit
    MakeVulnerable = function (self, target)
        if not IsDestroyed(target) then
            target:SetDoNotTarget(false)
            target.CanTakeDamage = true
            target.DisallowCollisions = false
            target.Tractored = nil
        end
    end,
}

---@class ADFTractorClawStructure : DefaultBeamWeapon
ADFTractorClawStructure = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
}

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
                local sliceSize = buff.Radius / slices

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

---@class ADFQuadLaserLightWeapon : DefaultProjectileWeapon
ADFQuadLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class ADFLaserLightWeapon : DefaultProjectileWeapon
ADFLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class ADFSonicPulsarWeapon : DefaultProjectileWeapon
ADFSonicPulsarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_02_emit.bp'},
    FxMuzzleFlashScale = 0.5,
}

---@class ADFLaserHeavyWeapon : DefaultProjectileWeapon
ADFLaserHeavyWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {},
}

---@class ADFGravitonProjectorWeapon : DefaultProjectileWeapon
ADFGravitonProjectorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AGravitonBolterMuzzleFlash01,
}

---@class ADFDisruptorCannonWeapon : DefaultProjectileWeapon
ADFDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ADisruptorCannonMuzzle01,
}

---@class ADFDisruptorWeapon : DefaultProjectileWeapon
ADFDisruptorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASDisruptorCannonMuzzle01,
    FxChargeMuzzleFlash = EffectTemplate.ASDisruptorCannonChargeMuzzle01,
}

---@class ADFCannonQuantumWeapon : DefaultProjectileWeapon
ADFCannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle01,
}

---@class ADFCannonOblivionWeapon : DefaultProjectileWeapon
ADFCannonOblivionWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/oblivion_cannon_flash_01_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_02_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_03_emit.bp',
    },
}

---@class ADFCannonOblivionWeapon02 : DefaultProjectileWeapon
ADFCannonOblivionWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AOblivionCannonMuzzleFlash02,
    FxChargeMuzzleFlash = EffectTemplate.AOblivionCannonChargeMuzzleFlash02,
}

---@class ADFCannonOblivionWeapon03 : DefaultProjectileWeapon
ADFCannonOblivionWeapon03 = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/oblivion_cannon_flash_04_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_05_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_06_emit.bp',
    },
}

---@class AIFMortarWeapon : DefaultProjectileWeapon
AIFMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

---@class AIFBombGravitonWeapon : DefaultProjectileWeapon
AIFBombGravitonWeapon = Class(DefaultProjectileWeapon) {}

---@class AIFArtilleryMiasmaShellWeapon : DefaultProjectileWeapon
AIFArtilleryMiasmaShellWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},

    ---@param self AIFArtilleryMiasmaShellWeapon
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Radius = blueprint.DamageRadius,
            Type = 'Normal',
            DamageFriendly = blueprint.DamageFriendly,
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AIFArtillerySonanceShellWeapon : DefaultProjectileWeapon
AIFArtillerySonanceShellWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/aeon_sonance_muzzle_01_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_02_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_03_emit.bp',
    },
}

---@class AIFBombQuarkWeapon : DefaultProjectileWeapon
AIFBombQuarkWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp', },
}

---@class AANDepthChargeBombWeapon : DefaultProjectileWeapon
AANDepthChargeBombWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp', },

    ---@param self AANDepthChargeBombWeapon
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AANDepthChargeBombWeapon02 : DefaultProjectileWeapon
AANDepthChargeBombWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_01_emit.bp', },

    ---@param self AANDepthChargeBombWeapon02
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AANTorpedoCluster : DefaultProjectileWeapon
AANTorpedoCluster = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_torpedocluster_flash_01_emit.bp', },

    ---@param self AANTorpedoCluster
    ---@param bone Bone
    ---@return Projectile
    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AIFSmartCharge : DefaultProjectileWeapon
AIFSmartCharge = Class(DefaultProjectileWeapon) {

    ---@param self AIFSmartCharge
    ---@param muzzle string
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

---@class AANChronoTorpedoWeapon : DefaultProjectileWeapon
AANChronoTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
   },
}

---@class AIFQuasarAntiTorpedoWeapon : DefaultProjectileWeapon
AIFQuasarAntiTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AQuasarAntiTorpedoFlash,
}

---@class AKamikazeWeapon : KamikazeWeapon
AKamikazeWeapon = Class(KamikazeWeapon) {
    FxMuzzleFlash = {},
}

---@class AIFQuantumWarhead : DefaultProjectileWeapon
AIFQuantumWarhead = Class(DefaultProjectileWeapon) {
}

---@class ACruiseMissileWeapon : DefaultProjectileWeapon
ACruiseMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_missile_launch_01_emit.bp', },
}

---@class ADFLaserHighIntensityWeapon : DefaultProjectileWeapon
ADFLaserHighIntensityWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AHighIntensityLaserFlash01,
}

---@class AAATemporalFizzWeapon : DefaultProjectileWeapon
AAATemporalFizzWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = {'/effects/emitters/temporal_fizz_muzzle_charge_01_emit.bp', },
    FxMuzzleFlash = {'/effects/emitters/temporal_fizz_muzzle_flash_01_emit.bp', },
    ChargeEffectMuzzles = {},

    ---@param self AAATemporalFizzWeapon
    PlayFxRackSalvoChargeSequence = function(self)
        DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence(self)
        for _, v in self.ChargeEffectMuzzles do
            for i, j in self.FxChargeEffects do
                CreateAttachedEmitter(self.unit, v, self.unit.Army, j)
            end
        end
    end,
}

---@class AAASonicPulseBatteryWeapon : DefaultProjectileWeapon
AAASonicPulseBatteryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_01_emit.bp', },
}

---@class AAAZealotMissileWeapon : DefaultProjectileWeapon
AAAZealotMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CZealotLaunch01,
}

---@class AAAZealot02MissileWeapon : DefaultProjectileWeapon
AAAZealot02MissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class AAALightDisplacementAutocannonMissileWeapon : DefaultProjectileWeapon
AAALightDisplacementAutocannonMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ALightDisplacementAutocannonMissileMuzzleFlash,
}

---@class AAAAutocannonQuantumWeapon : DefaultProjectileWeapon
AAAAutocannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/quantum_displacement_cannon_flash_01_emit.bp', },

}

---@class AIFMissileTacticalSerpentineWeapon : DefaultProjectileWeapon
AIFMissileTacticalSerpentineWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_missile_launch_02_emit.bp', },
}

---@class AIFMissileTacticalSerpentine02Weapon : DefaultProjectileWeapon
AIFMissileTacticalSerpentine02Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASerpFlash01,
}

---@class AQuantumBeamGenerator : DefaultBeamWeapon
AQuantumBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = QuantumBeamGeneratorCollisionBeam,

    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

    ---@param self AQuantumBeamGenerator
    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        for _, v in self.FxUpackingChargeEffects do
            for i, j in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, j, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
            end
        end
        DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
    end,
}

---@class AAMSaintWeapon : DefaultProjectileWeapon
AAMSaintWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASaintLaunch01,
}

---@class AAMWillOWisp : DefaultProjectileWeapon
AAMWillOWisp = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AAntiMissileFlareFlash,
}

---@class ADFPhasonLaser : DefaultBeamWeapon
ADFPhasonLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.PhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self ADFPhasonLaser
    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local bp = self:GetBlueprint()
            for _, v in self.FxUpackingChargeEffects do
                for i, j in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, j, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class ADFQuantumAutogunWeapon : DefaultProjectileWeapon
ADFQuantumAutogunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_DualQuantumAutoGunMuzzleFlash,
}

---@class ADFHeavyDisruptorCannonWeapon : DefaultProjectileWeapon
ADFHeavyDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
}

---@class AIFQuanticArtillery : DefaultProjectileWeapon
AIFQuanticArtillery = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_QuanticClusterMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_QuanticClusterChargeMuzzleFlash,
}


-- kept for mod backwards compatibility
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local EffectUtil = import("/lua/effectutilities.lua")