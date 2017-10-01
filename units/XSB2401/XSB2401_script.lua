-----------------------------------------------------------------
-- File     :  /cdimage/units/XSB2401/XSB2401_script.lua
-- Author(s):  John Comes, David Tomandl, Matt Vainio
-- Summary  :  Seraphim Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SIFExperimentalStrategicMissile = import('/lua/seraphimweapons.lua').SIFExperimentalStrategicMissile
local EffectUtil = import('/lua/EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

XSB2401 = Class(SStructureUnit) {
    Weapons = {
        ExperimentalNuke = Class(SIFExperimentalStrategicMissile) {
            OnWeaponFired = function(self)
                self.unit:ForkThread(self.unit.HideMissile)
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self.unit:ForkThread(self.unit.ChargeNukeSound)
                SIFExperimentalStrategicMissile.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local bp = self:GetBlueprint()
        self.Trash:Add(CreateAnimator(self):PlayAnim(bp.Display.AnimationOpen))
        self:ForkThread(self.PlayArmSounds)
        local missileBone = bp.Display.MissileBone
        if missileBone then
            if not self.MissileSlider then
                self.MissileSlider = CreateSlider(self, missileBone)
                self.Trash:Add(self.MissileSlider)
            end
        end
    end,

    OnSiloBuildStart = function(self, weapon)
        self:ForkThread(self.RaiseMissile)
        self:ForkThread(self.WatchBuild)
        self.MissileBuilt = false
        self:PlayBuildEffects()

        SStructureUnit.OnSiloBuildStart(self, weapon)
    end,

    OnSiloBuildEnd = function(self, weapon)
        self.MissileBuilt = true
        self:StopBuildEffects()

        SStructureUnit.OnSiloBuildEnd(self,weapon)
    end,

    PlayBuildEffects = function(self)
        if not self.MissileEffect then
            self.MissileEffect = {}
        end

        local effectBones = self:GetBlueprint().General.BuildBones.BuildEffectBones
        for bidx, bone in effectBones do
            for k, v in EffectTemplate.SJammerCrystalAmbient do
                if not self.MissileEffect[bidx] then
                    self.MissileEffect[bidx] = {}
                end
                self.MissileEffect[bidx][k] = CreateAttachedEmitter(self,bone, self:GetArmy(), v)
            end
        end
        self:PlayUnitSound('Construct')
        self:PlayUnitAmbientSound('ConstructLoop')
    end,

    StopBuildEffects = function(self)
        local effectBones = self:GetBlueprint().General.BuildBones.BuildEffectBones
        for bidx, bone in effectBones do
            for k, v in EffectTemplate.SJammerCrystalAmbient do
                self.MissileEffect[bidx][k]:Destroy()
            end
        end
        self:StopUnitAmbientSound('ConstructLoop')
        self:PlayUnitSound('ConstructStop')
    end,

    RaiseMissile = function(self)
        self.NotCancelled = true
        WaitSeconds(0.5)

        local missileBone = self:GetBlueprint().Display.MissileBone
        if missileBone and self.NotCancelled then
            self:ShowBone(missileBone, true)
            if self.MissileSlider then
                self.MissileSlider:SetGoal(0, 0, 115)
                self.MissileSlider:SetSpeed(1.93)
            end
        end
    end,

    HideMissile = function(self)
        WaitSeconds(0.1)
        self:RetractMissile()
    end,

    RetractMissile = function(self)
        local missileBone = self:GetBlueprint().Display.MissileBone
        if missileBone then
            self:HideBone(missileBone, true)
            if self.MissileSlider then
                self.MissileSlider:SetSpeed(400)
                self.MissileSlider:SetGoal(0,0,0)
            end
        end
    end,

    WatchBuild = function(self)
        while true do
            if not self:IsUnitState('SiloBuildingAmmo') and not self.MissileBuilt then
                self.NotCancelled = false
                self:RetractMissile()
                self:StopBuildEffects()
                return
            end
            WaitTicks(1)
        end
    end,

    ChargeNukeSound = function(self)
        WaitSeconds(1.5)
        self:PlayUnitAmbientSound('NukeCharge')
        WaitSeconds(9.5)
        self:StopUnitAmbientSound('NukeCharge')
    end,
}

TypeClass = XSB2401
