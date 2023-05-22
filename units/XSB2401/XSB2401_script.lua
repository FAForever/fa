-----------------------------------------------------------------
-- File     :  /cdimage/units/XSB2401/XSB2401_script.lua
-- Author(s):  John Comes, David Tomandl, Matt Vainio
-- Summary  :  Seraphim Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFExperimentalStrategicMissile = import("/lua/seraphimweapons.lua").SIFExperimentalStrategicMissile
local CreateSeraphimExperimentalBuildBaseThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimExperimentalBuildBaseThread
local EffectTemplate = import("/lua/effecttemplates.lua")
local DeathNukeWeapon = import("/lua/sim/defaultweapons.lua").DeathNukeWeapon

---@class XSB2401 : SStructureUnit
XSB2401 = ClassUnit(SStructureUnit) {
    Weapons = {
        ExperimentalNuke = ClassWeapon(SIFExperimentalStrategicMissile) {
            OnWeaponFired = function(self)
                self.unit.Trash:Add(ForkThread(self.unit.HideMissile,self.unit))
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self.unit.Trash:Add(ForkThread(self.unit.ChargeNukeSound,self.unit))
                SIFExperimentalStrategicMissile.PlayFxWeaponUnpackSequence(self)
            end,
        },
        DeathWeapon = ClassWeapon(DeathNukeWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        SStructureUnit.StartBeingBuiltEffects(self, builder, layer)
        self.Trash:Add(ForkThread( CreateSeraphimExperimentalBuildBaseThread, builder, self.OnBeingBuiltEffectsBag, 2, self ))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        SStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local bp = self.Blueprint
        self.Trash:Add(CreateAnimator(self):PlayAnim(bp.Display.AnimationOpen))
        local missileBone = bp.Display.MissileBone
        if missileBone then
            if not self.MissileSlider then
                self.MissileSlider = CreateSlider(self, missileBone)
                self.Trash:Add(self.MissileSlider)
            end
        end
    end,

    OnSiloBuildStart = function(self, weapon)
        self.Trash:Add(ForkThread(self.RaiseMissile,self))
        self.Trash:Add(ForkThread(self.WatchBuild,self))
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

        local effectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        for bidx, bone in effectBones do
            for k, v in EffectTemplate.SJammerCrystalAmbient do
                if not self.MissileEffect[bidx] then
                    self.MissileEffect[bidx] = {}
                end
                self.MissileEffect[bidx][k] = CreateAttachedEmitter(self,bone, self.Army, v)
            end
        end
        self:PlayUnitSound('Construct')
        self:PlayUnitAmbientSound('ConstructLoop')
    end,

    StopBuildEffects = function(self)
        local effectBones = self.Blueprint.General.BuildBones.BuildEffectBones
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
        WaitTicks(6)

        local missileBone = self.Blueprint.Display.MissileBone
        if missileBone and self.NotCancelled then
            self:ShowBone(missileBone, true)
            if self.MissileSlider then
                self.MissileSlider:SetGoal(0, 0, 115)
                self.MissileSlider:SetSpeed(1.93)
            end
        end
    end,

    HideMissile = function(self)
        WaitTicks(2)
        self:RetractMissile()
    end,

    RetractMissile = function(self)
        local missileBone = self.Blueprint.Display.MissileBone
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
        WaitTicks(16)
        self:PlayUnitAmbientSound('NukeCharge')
        WaitTicks(96)
        self:StopUnitAmbientSound('NukeCharge')
    end,
}

TypeClass = XSB2401
