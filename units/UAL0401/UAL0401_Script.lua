-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0401/UAL0401_script.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Aeon Galactic Colossus Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local WeaponsFile = import("/lua/aeonweapons.lua")
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local ADFTractorClaw = WeaponsFile.ADFTractorClaw
local explosion = import("/lua/defaultexplosions.lua")
local CreateAeonColossusBuildingEffects = import("/lua/effectutilities.lua").CreateAeonColossusBuildingEffects

-- upvalue for performance
local MathSqrt = math.sqrt
local MathCos = math.cos
local MathSin = math.sin
local MathAtan2 = math.atan2
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks

-- store for performance
local ZeroDegrees = Vector(0, 0, 1)
local SignCheck = Vector(1, 0, 0)

---@class UAL0401 : AWalkingLandUnit
UAL0401 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        EyeWeapon = ClassWeapon(ADFPhasonLaser) {
            CreateProjectileAtMuzzle = function(self, muzzle)
                local projectile = ADFPhasonLaser.CreateProjectileAtMuzzle(self, muzzle)

                -- if possible, try not to fire on units that we're tractoring
                local target = self:GetCurrentTarget()
                if target then
                    local unit = (IsUnit(target) and target) or target:GetSource()
                    if unit and unit.Tractored then
                        self:ResetTarget()
                    end
                end

                return projectile
            end,
        },
        RightArmTractor = ClassWeapon(ADFTractorClaw) {},
        LeftArmTractor = ClassWeapon(ADFTractorClaw) {},
    },

    ---@param self UAL0401
    ---@param spec table
    OnCreate = function(self, spec)
        AWalkingLandUnit.OnCreate(self, spec)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread(self.AdjustWeaponsThread, self))
    end,

    ---@param self UAL0401
    AdjustWeaponsThread = function(self)
        while not self.Dead do
            -- only perform this logic if the unit is on the move
            if self:IsUnitState("Moving") then

                -- compute the direction of the heading
                local sx, sy, sz = self:GetPositionXYZ()
                local heading = self:GetHeading()
                local hx, hz = MathSin(heading), MathCos(heading)

                for k = 1, self.WeaponCount do
                    -- retrieve weapon and its target
                    local weapon = self:GetWeapon(k)
                    local target = weapon:GetCurrentTarget()

                    if target then
                        -- compute direction and normalize
                        local tx, ty, tz = target:GetPositionXYZ()
                        local dx, dz = tx - sx, tz - sz
                        local invLength = 1.0 / MathSqrt(dx * dx + dz * dz)
                        dx, dz = invLength * dx, invLength * dz

                        -- compute dot product between weapon target and our heading, if it is lower than 0 it means the target is behind us
                        local dot = dx * hx + dz * hz
                        if dot < 0 then
                            weapon:ResetTarget()
                        end
                    end
                end
            end

            WaitTicks(3)
        end
    end,

    ---@param self UAL0401
    ---@param layer string
    StartBeingBuiltEffects = function(self, builder, layer)
        AWalkingLandUnit.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonColossusBuildingEffects(self)
        local bp = self.Blueprint
        -- adjust collision box due to build animation
        self:SetCollisionShape('Box',0.3,3.25,-0.65,bp.SizeX * 0.5, bp.SizeY * 0.5, (bp.SizeZ * 0.7))
    end,

    ---@param self UAL0401
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self,builder,layer)
        AWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        -- adjust collision box due to build animation
        self:RevertCollisionShape()
    end,

    ---@param self UAL0401
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)

        local wep = self:GetWeaponByLabel('EyeWeapon')
        local bp = wep.Blueprint
        if bp.Audio.BeamStop then
            wep:PlaySound(bp.Audio.BeamStop)
        end

        if bp.Audio.BeamLoop and wep.Beams[1].Beam then
            wep.Beams[1].Beam:SetAmbientSound(nil, nil)
        end

        for k, v in wep.Beams do
            v.Beam:Disable()
        end
    end,

    ---@param self UAL0401
    ---@param overkillRatio number
    ---@param instigator Unit unused
    DeathThread = function(self, overkillRatio, instigator)
        local bp = self.Blueprint
        self:PlayUnitSound('Destroyed')
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 4.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self),
            { bp.SizeX, bp.SizeY, bp.SizeZ })
        WaitTicks(1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B02', 1.0)
        WaitTicks(1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)
        WaitTicks(1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Arm_B02', 1.0)
        WaitTicks(3)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Arm_B01', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)

        WaitTicks(15)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B02', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Leg_B01', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Leg_B02', 1.0)
        WaitTicks(38)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 5.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Arm_B02', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Arm_B01', 1.0)
        if self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end

        -- only apply death damage when the unit is sufficiently build
        local FractionThreshold = bp.General.FractionThreshold or 0.5
        if self:GetFractionComplete() >= FractionThreshold then
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = MathAtan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if bp.Weapon[i].Label == 'CollossusDeath' then
                    position[3] = position[3] + 5 * MathCos(a)
                    position[1] = position[1] + 5 * MathSin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType,
                        bp.Weapon[i].DamageFriendly)
                    break
                end
            end
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
                self:CreateUnitDestructionDebris(true, true, true)
            else
                self:CreateUnitDestructionDebris(true, true, true)
            end
        end
        self:Destroy()
    end,
}
TypeClass = UAL0401

-- Kept for Mod Backwards Compatability
local Utilities = import("/lua/utilities.lua")
