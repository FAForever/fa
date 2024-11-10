-- File     :  /cdimage/units/URL0304/URL0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Heavy Mobile Artillery Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CLandUnit = import("/lua/cybranunits.lua").CLandUnit
local CIFArtilleryWeapon = import("/lua/cybranweapons.lua").CIFArtilleryWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")
local barrelBones = { 'Turret_Barrel_F_B01', 'Turret_Barrel_E_B01', 'Turret_Barrel_D_B01', 'Turret_Barrel_C_B01',
    'Turret_Barrel_B_B01', 'Turret_Barrel_A_B01' }
local recoilBones = { 'Turret_Barrel_F_B02', 'Turret_Barrel_E_B02', 'Turret_Barrel_D_B02', 'Turret_Barrel_C_B02',
    'Turret_Barrel_B_B02', 'Turret_Barrel_A_B02' }
local muzzleBones = { 'Turret_Barrel_F_B03', 'Turret_Barrel_E_B03', 'Turret_Barrel_D_B03', 'Turret_Barrel_C_B03',
    'Turret_Barrel_B_B03', 'Turret_Barrel_A_B03' }

---@class URL0401 : CLandUnit
URL0401 = ClassUnit(CLandUnit) {

    Weapons = {
        ---@class URL0401_Gun01 : CIFArtilleryWeapon
        ---@field losttarget boolean
        ---@field initialaim boolean
        ---@field PitchRotators moho.RotateManipulator[] # Pitch rotators for the fake turret barrels
        ---@field currentbarrel number # Which barrel is currently aligned with the aim's yaw
        ---@field Goal number # Yaw goal of fake barrels
        ---@field restdirvector Vector
        ---@field dirvector Vector
        ---@field basedirvector Vector
        ---@field basediftorest number # "BaseDifToRest" angle in between Yaw aim bone and the resting fake barrel
        ---@field pitchdif number # "PitchDif" angle in between fake barrel pitch and aim barrel pitch
        ---@field rotatedbarrel true? # unused
        ---@field Rotator moho.RotateManipulator # Yaw rotator for the `"Turret_Fake"` bone created every time the weapon fires after being packed
        ---@field unit URL0401
        Gun01 = ClassWeapon(CIFArtilleryWeapon) {
            ---@param self URL0401_Gun01
            OnCreate = function(self)
                CIFArtilleryWeapon.OnCreate(self)
                self.losttarget = false
                self.initialaim = true
                self.PitchRotators = {}
                self.restdirvector = Vector(0, 0, 0)
                self.dirvector = Vector(0, 0, 0)
                self.basedirvector = Vector(0, 0, 0)
                self.currentbarrel = 1
            end,

            ---@param self URL0401_Gun01
            OnLostTarget = function(self)
                CIFArtilleryWeapon.OnLostTarget(self)
                self.losttarget = true
            end,

            ---@param self URL0401_Gun01
            PlayFxWeaponPackSequence = function(self)
                if self.PitchRotators then
                    for k, v in barrelBones do
                        if self.PitchRotators[k] then
                            self.PitchRotators[k]:Destroy()
                            self.PitchRotators[k] = nil
                        end
                    end
                end
                self.losttarget = false
                self.initialaim = true
                CIFArtilleryWeapon.PlayFxWeaponPackSequence(self)
            end,

            ---@param self URL0401_Gun01
            LaunchEffects = function(self)
                local FxLaunch = EffectTemplate.CArtilleryFlash02
                for k, v in FxLaunch do
                    CreateEmitterAtEntity(self.unit, self.unit.Army, v)
                end
            end,

            ---@param self URL0401_Gun01
            ---@param muzzle Bone
            CreateProjectileAtMuzzle = function(self, muzzle)
                -- set up the yaw and pitch rotators for the fake barrels since we just unpacked
                -- Creates the animation where the barrels are at their lowest pitch and look spread out
                if self.initialaim then
                    self.Rotator = CreateRotator(self.unit, 'Turret_Fake', 'y')
                    self.unit.Trash:Add(self.Rotator)

                    for k, v in barrelBones do
                        local tmprotator = CreateRotator(self.unit, v, 'x')
                        tmprotator:SetSpeed(30)
                        tmprotator:SetGoal(0)
                        self.PitchRotators[k] = tmprotator
                        self.unit.Trash:Add(self.PitchRotators[k])
                    end

                    -- fake barrel with the same yaw as the aim yaw
                    local barrel = self.currentbarrel
                    local basedirvector = self.basedirvector

                    self.Goal = 0
                    self.restdirvector[1], self.restdirvector[2], self.restdirvector[3] = self.unit:GetBoneDirection(barrelBones
                        [barrel])
                    basedirvector[1], basedirvector[2], basedirvector[3] = self.unit:GetBoneDirection('Turret_Aim')
                    self.basediftorest = Util.GetAngleInBetween(self.restdirvector, basedirvector)
                end

                -- since we got a new target, adjust the pitch of the fake barrels to match the aim barrel
                if self.losttarget or self.initialaim then
                    local dirvector = self.dirvector
                    dirvector[1], dirvector[2], dirvector[3] = self.unit:GetBoneDirection('Turret_Aim_Barrel')
                    local basedirvector = self.basedirvector
                    basedirvector[1], basedirvector[2], basedirvector[3] = self.unit:GetBoneDirection('Turret_Aim')

                    local basediftoaim = Util.GetAngleInBetween(dirvector, basedirvector)


                    self.pitchdif = self.basediftorest - basediftoaim

                    for k, v in barrelBones do
                        self.PitchRotators[k]:SetGoal(self.pitchdif)
                    end

                    WaitFor(self.PitchRotators[1])
                    -- Wait for aesthetics, to let the barrel rest at the final position a bit before firing
                    WaitTicks(3)

                    if self.losttarget then
                        self.losttarget = false
                    end

                    if self.initialaim then
                        self.initialaim = false
                    end
                end

                CIFArtilleryWeapon.CreateProjectileAtMuzzle(self, muzzle)
                self.Trash:Add(ForkThread(self.LaunchEffects, self))
                self.Trash:Add(ForkThread(self.RotateBarrels, self))
            end,

            ---@param self URL0401_Gun01
            RotateBarrels = function(self)
                if not self.losttarget then
                    self.Rotator:SetSpeed(320)
                    self.Goal = self.Goal + 60
                    if self.Goal >= 360 then
                        self.Goal = 0
                    end
                    WaitTicks(2)
                    self.Rotator:SetGoal(self.Goal)
                    self.currentbarrel = self.currentbarrel + 1
                    if self.currentbarrel > 6 then
                        self.currentbarrel = 1
                    end
                    self.rotatedbarrel = true
                end
            end,
        },
    },
}

TypeClass = URL0401
