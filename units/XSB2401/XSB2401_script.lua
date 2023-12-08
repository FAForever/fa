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
                self.unit:DestroyReloadEmitters()
                self.unit.Trash:Add(ForkThread(self.unit.HideMissile,self.unit))
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self.unit.Trash:Add(ForkThread(self.unit.ChargeNukeSound,self.unit))
                SIFExperimentalStrategicMissile.PlayFxWeaponUnpackSequence(self)
            end,

            PlayFxRackSalvoReloadSequence = function(self)
                self.unit.PlayReloadEffects(self)
                SIFExperimentalStrategicMissile.PlayFxRackSalvoReloadSequence(self)
            end,
        },
        DeathWeapon = ClassWeapon(DeathNukeWeapon) {},
    },

    ---@param self XSB2401
    ---@param builder Unit
    ---@param layer string
    StartBeingBuiltEffects = function(self, builder, layer)
        SStructureUnit.StartBeingBuiltEffects(self, builder, layer)
        self.Trash:Add(ForkThread( CreateSeraphimExperimentalBuildBaseThread, self, builder, self.OnBeingBuiltEffectsBag, 2 ))
    end,

    ---@param self XSB2401
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        SStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local bp = self.Blueprint
        local missileBone = bp.Display.MissileBone
        if missileBone then
            if not self.MissileSlider then
                self.MissileSlider = CreateSlider(self, missileBone)
                self.Trash:Add(self.MissileSlider)
                self.MissileSlider:SetSpeed(400)
            end
        end
        -- Convey to the player how the launcher reloads by showing the effect right when it is built
        -- Also creates the initial pulsing glow for when the launcher is reloaded and missile is built
        self.PlayReloadEffects(self:GetWeapon(1))
    end,

    ---@param self XSB2401
    ---@param weapon SIFExperimentalStrategicMissile
    OnSiloBuildStart = function(self, weapon)
        self.Trash:Add(ForkThread(self.RaiseMissileThread,self))
        self.Trash:Add(ForkThread(self.WatchBuild,self))
        self.MissileBuilt = false
        self:PlayBuildEffects()
        SStructureUnit.OnSiloBuildStart(self, weapon)
    end,

    --- @param self XSB2401
    --- @param weapon SIFExperimentalStrategicMissile
    OnSiloBuildEnd = function(self, weapon)
        self.MissileBuilt = true
        SStructureUnit.OnSiloBuildEnd(self,weapon)
    end,

    --- @param self XSB2401
    PlayBuildEffects = function(self)
        self:PlayUnitSound('Construct')
        self:PlayUnitAmbientSound('ConstructLoop')
    end,

    --- @param self XSB2401
    StopBuildEffects = function(self)
        self:StopUnitAmbientSound('ConstructLoop')
        self:PlayUnitSound('ConstructStop')
    end,

    --- Creates an emitter indicating the stage of the reload process.
    ---@param self XSB2401
    ---@param bidx number Index of the bone to use: 1, 2, 3 = "NO1", "NO2", "NO3"
    CreateReloadEmitter = function(self, bidx)
        if not self.MissileEffect then
            self.MissileEffect = {}
        end
        local scales = {0.8, 0.7, 0.45}
        local effectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        for k, v in EffectTemplate.SJammerCrystalAmbient do
            if not self.MissileEffect[bidx] then
                self.MissileEffect[bidx] = {}
            end
            self.MissileEffect[bidx][k] = CreateAttachedEmitter(self, effectBones[bidx], self.Army, v):OffsetEmitter(0, -0.2 * scales[bidx], -scales[bidx]):ScaleEmitter(scales[bidx])
        end
    end,

    --- @param self XSB2401
    DestroyReloadEmitters = function(self)
        local effectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        for bidx, bone in self.MissileEffect do
            for _, effect in self.MissileEffect[bidx] do
                effect:Destroy()
            end
        end
    end,

    -- Keep this function here instead of in the weapon so OnStopBeingBuilt can call it.
    --- @param weapon SIFExperimentalStrategicMissile
    PlayReloadEffects = function(weapon)
        local bp = weapon.Blueprint
        local muzzleBones = bp.RackBones[weapon.CurrentRackSalvoNumber].MuzzleBones
        local unit = weapon.unit
        local army = weapon.Army
        local scale = weapon.FxRackChargeMuzzleFlashScale

        -- Create the upwards lines and coalescing orbs effects
        for _, effect in EffectTemplate.SIFExperimentalStrategicLauncherReload01 do
            for _, muzzle in muzzleBones do
                CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
            end
        end

        -- Create the reload stage effects: 3 effects in the middle column and a blue glow when the missile is built and launcher is reloaded
        local reloadTime = bp.RackSalvoReloadTime
        weapon.Trash:Add(ForkThread(function()
            local stage = 0
            while stage < 3 do
                WaitSeconds(reloadTime/3)
                stage = stage + 1
                unit:CreateReloadEmitter(stage)
            end
            while not unit.MissileBuilt do
                WaitTicks(1)
            end
            local template = EffectTemplate.SIFExperimentalStrategicLauncherLoaded01
            for i, effect in template do
                if not unit.MissileEffect[stage + 1] then
                    unit.MissileEffect[stage + 1] = {}
                end
                for k, muzzle in muzzleBones do
                    unit.MissileEffect[stage + 1][k] = CreateAttachedEmitter(unit, muzzle, army, effect):ScaleEmitter(scale)
                end
            end
            unit:StopBuildEffects()
        end))
    end,

    --- Raises the missile depending on completion progress.
    --- @param self XSB2401
    RaiseMissileThread = function(self)
        self.NotCancelled = true
        WaitTicks(6)

        local missileBone = self.Blueprint.Display.MissileBone
        if missileBone and self.NotCancelled then
            self:ShowBone(missileBone, true)
            if self.MissileSlider then
                local progress = 0
                repeat
                    if not self.NotCancelled then return end
                    progress = self:GetWorkProgress()
                    self.MissileSlider:SetGoal(0, 0, 115 * progress)
                    WaitTicks(1)
                    -- Stopping at 100% progress is impossible; the work progress bar hides and resets to 0 when work is finished
                until progress >= 0.99
                self.MissileSlider:SetGoal(0, 0, 115)
            end
        end
    end,

    --- @param self XSB2401
    HideMissile = function(self)
        WaitTicks(2)
        self:RetractMissile()
    end,

    --- @param self XSB2401
    RetractMissile = function(self)
        local missileBone = self.Blueprint.Display.MissileBone
        if missileBone then
            self:HideBone(missileBone, true)
            if self.MissileSlider then
                self.MissileSlider:SetGoal(0,0,0)
            end
        end
    end,

    --- Hides the missile if building is cancelled.
    --- @param self XSB2401
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

    --- @param self XSB2401
    ChargeNukeSound = function(self)
        WaitTicks(16)
        self:PlayUnitAmbientSound('NukeCharge')
        WaitTicks(96)
        self:StopUnitAmbientSound('NukeCharge')
    end,
}

TypeClass = XSB2401
