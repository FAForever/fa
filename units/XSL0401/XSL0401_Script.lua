-----------------------------------------------------------------
-- File     :  /data/units/XSL0401/XSL0401_script.lua
-- Author(s):  Jessica St. Croix, Dru Staltman, Aaron Lundquist
-- Summary  :  Seraphim Experimental Assault Bot
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SWalkingLandUnit = import("/lua/seraphimunits.lua").SWalkingLandUnit
local WeaponsFile = import("/lua/seraphimweapons.lua")
local SDFExperimentalPhasonProj = WeaponsFile.SDFExperimentalPhasonProj
local SDFAireauWeapon = WeaponsFile.SDFAireauWeapon
local SDFSinnuntheWeapon = WeaponsFile.SDFSinnuntheWeapon
local SAAOlarisCannonWeapon = WeaponsFile.SAAOlarisCannonWeapon
local explosion = import("/lua/defaultexplosions.lua")
local CreateSeraphimExperimentalBuildBaseThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimExperimentalBuildBaseThread

---@class XSL0401 : SWalkingLandUnit
XSL0401 = ClassUnit(SWalkingLandUnit) {
    SpawnEffects = {
        '/effects/emitters/seraphim_othuy_spawn_01_emit.bp',
        '/effects/emitters/seraphim_othuy_spawn_02_emit.bp',
        '/effects/emitters/seraphim_othuy_spawn_03_emit.bp',
        '/effects/emitters/seraphim_othuy_spawn_04_emit.bp',
    },

    SpawnElectroStorm = function(self)
        local position = self:GetPosition()
        local spawnEffects = self.SpawnEffects

        -- Spawn the Energy Being
        local spiritUnit = CreateUnitHPR('XSL0402', self.Army, position[1], position[2], position[3], 0, 0, 0)
        -- Create effects for spawning of energy being
        for k, v in spawnEffects do
            CreateAttachedEmitter(spiritUnit, -1, self.Army, v)
        end
    end,

    OnReclaimed = function(self, entity)

        SWalkingLandUnit.OnReclaimed(self, entity)

        -- Spawn the Energy Being
        self:SpawnElectroStorm()
    end,

    Weapons = {
        EyeWeapon = ClassWeapon(SDFExperimentalPhasonProj) {},
        LeftArm = ClassWeapon(SDFAireauWeapon) {},
        RightArm = ClassWeapon(SDFSinnuntheWeapon) {
            PlayFxMuzzleChargeSequence = function(self, muzzle)
                -- CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
                if not self.ClawTopRotator then
                    self.ClawTopRotator = CreateRotator(self.unit, 'Top_Claw', 'x')
                    self.ClawBottomRotator = CreateRotator(self.unit, 'Bottom_Claw', 'x')

                    self.unit.Trash:Add(self.ClawTopRotator)
                    self.unit.Trash:Add(self.ClawBottomRotator)
                end

                self.ClawTopRotator:SetGoal(-45):SetSpeed(10)
                self.ClawBottomRotator:SetGoal(45):SetSpeed(10)

                SDFSinnuntheWeapon.PlayFxMuzzleChargeSequence(self, muzzle)

                self:ForkThread(function()
                    WaitSeconds(self.unit:GetBlueprint().Weapon[3].MuzzleChargeDelay)

                    self.ClawTopRotator:SetGoal(0):SetSpeed(50)
                    self.ClawBottomRotator:SetGoal(0):SetSpeed(50)
                end)
            end,
        },
        LeftAA = ClassWeapon(SAAOlarisCannonWeapon) {},
        RightAA = ClassWeapon(SAAOlarisCannonWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        SWalkingLandUnit.StartBeingBuiltEffects(self, builder, layer)
        self:ForkThread( CreateSeraphimExperimentalBuildBaseThread, builder, self.OnBeingBuiltEffectsBag, 2 )
    end,

    DeathThread = function(self, overkillRatio , instigator)
        local blueprint = self.Blueprint
        local bigExplosionBones = {'Torso', 'Head', 'pelvis'}
        local explosionBones = {'Right_Arm_B07', 'Right_Arm_B03',
                                'Left_Arm_B10', 'Left_Arm_B07',
                                'Chest_B01', 'Chest_B03',
                                'Right_Leg_B01', 'Right_Leg_B02', 'Right_Leg_B03',
                                'Left_Leg_B17', 'Left_Leg_B14', 'Left_Leg_B15'}
        explosion.CreateDefaultHitExplosionAtBone(self, bigExplosionBones[Random(1, 3)], 4.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ})
        WaitSeconds(2)

        local RandBoneIter = RandomIter(explosionBones)
        for i = 1, Random(4, 6) do
            local bone = RandBoneIter()
            explosion.CreateDefaultHitExplosionAtBone(self, bone, 1.0)
            WaitTicks(Random(1, 4))
        end

        WaitSeconds(3.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 5.0)

        if self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end

        self:DestroyAllDamageEffects()
        self:CreateWreckage(overkillRatio)

        -- CURRENTLY DISABLED UNTIL DESTRUCTION
        -- Create destruction debris out of the mesh, currently these projectiles look like crap,
        -- since projectile rotation and terrain collision doesn't work that great. These are left in
        -- hopes that this will look better in the future.. =)
        if self.ShowUnitDestructionDebris and overkillRatio then
            if overkillRatio <= 1 then
                self:CreateUnitDestructionDebris(true, true, false)
            elseif overkillRatio <= 2 then
                self:CreateUnitDestructionDebris(true, true, false)
            elseif overkillRatio <= 3 then
                self:CreateUnitDestructionDebris(true, true, true)
            else -- Vaporized
                self:CreateUnitDestructionDebris(true, true, true)
            end
        end

        -- only apply death damage when the unit is sufficiently build
        local bp = self.Blueprint
        local FractionThreshold = bp.General.FractionThreshold or 0.5
        if self:GetFractionComplete() >= FractionThreshold then 
            for i, numWeapons in bp.Weapon do
                if bp.Weapon[i].Label == 'CollossusDeath' then
                    DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end

        -- only spawn storm and do damage when the unit is finished building
        if self:GetFractionComplete() == 1 then
            self:SpawnElectroStorm()
        end

        self:PlayUnitSound('Destroyed')
        self:Destroy()
    end,
}
TypeClass = XSL0401