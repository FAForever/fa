-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0401/UEL0401_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  UEF Mobile Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TMobileFactoryUnit = import("/lua/terranunits.lua").TMobileFactoryUnit
local WeaponsFile = import("/lua/terranweapons.lua")
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")

local DefaultExplosions = import("/lua/defaultexplosions.lua")

---@class UEL0401 : TMobileFactoryUnit
UEL0401 = ClassUnit(TMobileFactoryUnit) {
    PrepareToBuildAnimRate = 5,
    BuildAttachBone = 'Build_Attachpoint',
    RollOffBones = {'Arm_Right03_Build_Emitter', 'Arm_Left03_Build_Emitter', },

    ExplosionBones = {
        'Turret_Right01',
        'Turret_Right02',
        'Turret_Left01',
        'Turret_Left02',
        'Wheel_Right01',
        'Wheel_Right02',
        'Wheel_Left01',
        'Wheel_Left02',
        'Turret_Left_AA',
        'Turret_Right_AA',
        'Attachpoint01',
        'Attachpoint02',
        'Attachpoint03',
        'Bay_Cover',
    },

    Weapons = {
        RightTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        RightTurret02 = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret01 = ClassWeapon(TDFGaussCannonWeapon) {},
        LeftTurret02 = ClassWeapon(TDFGaussCannonWeapon) {},
        RightRiotgun = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        LeftRiotgun = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        RightAAGun = ClassWeapon(TAALinkedRailgun) {},
        LeftAAGun = ClassWeapon(TAALinkedRailgun) {},
        Torpedo = ClassWeapon(TANTorpedoAngler) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TMobileFactoryUnit.OnStopBeingBuilt(self, builder, layer)
        self.PrepareToBuildManipulator = CreateAnimator(self)
        self.PrepareToBuildManipulator:PlayAnim(self:GetBlueprint().Display.AnimationBuild, false):SetRate(0)
        self.ReleaseEffectsBag = {}
        self.AttachmentSliderManip = CreateSlider(self, self.BuildAttachBone)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        TMobileFactoryUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    -- This unit needs to not be allowed to build while underwater
    -- Additionally, if it goes underwater while building it needs to cancel the current order
    OnLayerChange = function(self, new, old)
        TMobileFactoryUnit.OnLayerChange(self, new, old)
        if new == 'Land' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        elseif new == 'Seabed' then
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end
    end,

    IdleState = State {
        OnStartBuild = function(self, unitBuilding, order)
            TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            ChangeState(self, self.BuildingState)
        end,

        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            if not self.UnitBeingBuilt.Dead then
                unitBuilding:AttachBoneTo(-2, self, bone)
                local unitHeight = unitBuilding:GetBlueprint().SizeY
                self.AttachmentSliderManip:SetGoal(0, unitHeight, 0)
                self.AttachmentSliderManip:SetSpeed(-1)
                unitBuilding:HideBone(0, true)
            end
            WaitSeconds(3)
            unitBuilding:ShowBone(0, true)
            WaitFor(self.PrepareToBuildManipulator)
            local unitBuilding = self.UnitBeingBuilt
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)

            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if not unitBuilding.Dead then
                unitBuilding:ShowBone(0, true)
            end
            WaitFor(self.PrepareToBuildManipulator)
            WaitFor(self.AttachmentSliderManip)

            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(10)
            self.AttachmentSliderManip:SetGoal(0, 0, 17)
            WaitFor(self.AttachmentSliderManip)

            self.AttachmentSliderManip:SetGoal(0, -3, 17)
            WaitFor(self.AttachmentSliderManip)

            if not unitBuilding.Dead then
                unitBuilding:DetachFrom(true)
                self:DetachAll(self.BuildAttachBone)
                local  worldPos = self:CalculateWorldPositionFromRelative({0, 0, -15})
                IssueMoveOffFactory({unitBuilding}, worldPos)
            end

            self:DestroyRollOffEffects()
            ChangeState(self, self.IdleState)
        end,
    },

    CreateRollOffEffects = function(self)
        local army = self.Army
        local unitB = self.UnitBeingBuilt
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = AttachBeamEntityToEntity(unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = CreateEmitterAtBone(self, v, army, EffectTemplate.TTransportGlow01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,

    ---@param self UEL0401
    ---@param overkillRatio number
    ---@param instigator Unit
    DeathThread = function(self, overkillRatio, instigator)

        self:PlayUnitSound('Destroyed')

        -- transform data
        local explosionBones = { }
        local explosionBoneCount = table.getn(self.ExplosionBones)

        if instigator then
            -- if there is an instigator, favor exploding bits that are near the instigator
            local ix, iy, iz = instigator:GetPositionXYZ()
            for k, bone in self.ExplosionBones do
                local bonePosition = self:GetPosition(bone)
                local dx = bonePosition[1] - ix
                local dy = bonePosition[2] - iy
                local dz = bonePosition[3] - iz
                local distance = dx * dx + dy * dy + dz * dz
                explosionBones[k] =  {
                    Distance = distance,
                    BoneName = bone,
                    Position = bonePosition
                }
            end

            -- sort the order
            table.sort(explosionBones, function(e1, e2) return e1.Distance < e2.Distance end)
        else
            -- if there is no instigator (self destruct, for example) then take a random direction
            for k, bone in self.ExplosionBones do
                local bonePosition = self:GetPosition(bone)
                explosionBones[k] =  {
                    Distance = 0,
                    BoneName = bone,
                    Position = bonePosition
                }
            end

            -- shuffle the order
            for k = explosionBoneCount, 1, -1 do
                local j = (Random(1, k)) ^ 0;
                local value = explosionBones[j];
                explosionBones[j] = explosionBones[k];
                explosionBones[k] = value;
            end
        end

        -- create a few random sparks
        CreateAttachedEmitter(self, -1, self.Army, '/effects/emitters/explosion_fire_sparks_02_emit.bp')

        -- create explosions that gradually move away from the instigator
        self:PlayUnitSound('Destroyed')
        for k = 1, 2 do
            local index = Random(1, 3)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 2, 1, "TreeFire", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2, { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        for k = 1, 3 do
            local index = Random(2, 5)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 3, 1, "TreeFire", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2, { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        DefaultExplosions.CreateScalableUnitExplosion(self)
        for k = 1, 3 do
            local index = Random(3, 7)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 4, 1, "TreeForce", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2, { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        WaitTicks(1)
        self:PlayUnitSound('Destroyed')
        DefaultExplosions.CreateScalableUnitExplosion(self)
        for k = 1, 5 do
            local index = Random(4, explosionBoneCount)
            local bone = explosionBones[index]
            DamageArea(self, bone.Position, 5, 1, "TreeForce", false, false)
            DefaultExplosions.CreateDefaultHitExplosionAtBone(self, bone.BoneName, 1.0)
            DefaultExplosions.CreateFirePlume(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateSmallDebrisEmitters(self, self.Army, bone.BoneName)
            DefaultExplosions.CreateDebrisProjectiles(self, 0.2, { self.Blueprint.SizeX, self.Blueprint.SizeY, self.Blueprint.SizeZ })
        end

        self:DestroyUnit(overkillRatio)
    end,
}

TypeClass = UEL0401
