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
        Gun01 = ClassWeapon(CIFArtilleryWeapon) {

            OnCreate = function(self)
                CIFArtilleryWeapon.OnCreate(self)
                self.losttarget = false
                self.initialaim = true
                self.PitchRotators = {}
                self.restdirvector = {}
                self.currentbarrel = 1
            end,

            OnLostTarget = function(self)
                CIFArtilleryWeapon.OnLostTarget(self)
                self.losttarget = true
            end,

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

            LaunchEffects = function(self)
                local FxLaunch = EffectTemplate.CArtilleryFlash02
                for k, v in FxLaunch do
                    CreateEmitterAtEntity(self.unit, self.unit.Army, v)
                end
            end,

            CreateProjectileAtMuzzle = function(self, muzzle)
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

                    local barrel = self.currentbarrel
                    local basedirvector = {}

                    self.Goal = 0
                    self.restdirvector.x, self.restdirvector.y, self.restdirvector.z = self.unit:GetBoneDirection(barrelBones
                        [barrel])
                    basedirvector.x, basedirvector.y, basedirvector.z = self.unit:GetBoneDirection('Turret_Aim')
                    self.basediftorest = Util.GetAngleInBetween(self.restdirvector, basedirvector)
                end

                if self.losttarget or self.initialaim then
                    local dirvector = {}
                    dirvector.x, dirvector.y, dirvector.z = self.unit:GetBoneDirection('Turret_Aim_Barrel')
                    local basedirvector = {}
                    basedirvector.x, basedirvector.y, basedirvector.z = self.unit:GetBoneDirection('Turret_Aim')

                    local basediftoaim = Util.GetAngleInBetween(dirvector, basedirvector)


                    self.pitchdif = self.basediftorest - basediftoaim

                    for k, v in barrelBones do
                        self.PitchRotators[k]:SetGoal(self.pitchdif)
                    end

                    WaitFor(self.PitchRotators[1])

                    WaitTicks(3)

                    if self.losttarget then
                        self.losttarget = false
                    end

                    if self.initialaim then
                        self.initialaim = false
                    end
                end

                local muzzleIdx = 0
                for i = 1, self.unit:GetBoneCount() do
                    if self.unit:GetBoneName(i) == 'Turret_Aim_Barrel_Muzzle' then
                        muzzleIdx = i
                        break
                    end
                end

                CIFArtilleryWeapon.CreateProjectileAtMuzzle(self, muzzleIdx)
                self.Trash:Add(ForkThread(self.LaunchEffects, self))
                self.Trash:Add(ForkThread(self.RotateBarrels, self))
            end,

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
