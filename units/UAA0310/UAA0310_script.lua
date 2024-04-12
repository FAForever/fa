-----------------------------------------------------------------
-- File     :  /cdimage/units/UAA0310/UAA0310_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon CZAR Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local aWeapons = import("/lua/aeonweapons.lua")
local AQuantumBeamGenerator = aWeapons.AQuantumBeamGenerator
local AAAZealotMissileWeapon = aWeapons.AAAZealotMissileWeapon
local AANDepthChargeBombWeapon = aWeapons.AANDepthChargeBombWeapon
local AAATemporalFizzWeapon = aWeapons.AAATemporalFizzWeapon
local explosion = import("/lua/defaultexplosions.lua")
local CzarShield = import("/lua/shield.lua").CzarShield

local CreateAeonCZARBuildingEffects = import("/lua/effectutilities.lua").CreateAeonCZARBuildingEffects

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class UAA0310 : AirTransport, ExternalFactoryComponent
UAA0310 = ClassUnit(AirTransport, ExternalFactoryComponent) {
    DestroyNoFallRandomChance = 1.1,
    BuildAttachBone = 'Attachpoint01',
    FactoryAttachBone = 'Attachpoint02',

    Weapons = {
        QuantumBeamGeneratorWeapon = ClassWeapon(AQuantumBeamGenerator) {},
        SonicPulseBattery1 = ClassWeapon(AAAZealotMissileWeapon) {},
        SonicPulseBattery2 = ClassWeapon(AAAZealotMissileWeapon) {},
        SonicPulseBattery3 = ClassWeapon(AAAZealotMissileWeapon) {},
        SonicPulseBattery4 = ClassWeapon(AAAZealotMissileWeapon) {},
        DepthCharge01 = ClassWeapon(AANDepthChargeBombWeapon) {},
        DepthCharge02 = ClassWeapon(AANDepthChargeBombWeapon) {},
        AAFizz01 = ClassWeapon(AAATemporalFizzWeapon) {},
        AAFizz02 = ClassWeapon(AAATemporalFizzWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        AirTransport.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonCZARBuildingEffects(self)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        ExternalFactoryComponent.OnKilled(self, instigator, type, overkillRatio)

        local wep = self:GetWeaponByLabel('QuantumBeamGeneratorWeapon')
        for _, v in wep.Beams do
            v.Beam:Disable()
            if wep.HoldFireThread then
                KillThread(wep.HoldFireThread)
            end
            v.Beam:Destroy()
        end

        self.detector = CreateCollisionDetector(self)
        self.Trash:Add(self.detector)
        self.detector:WatchBone('Left_Turret01_Muzzle')
        self.detector:WatchBone('Right_Turret01_Muzzle')
        self.detector:WatchBone('Left_Turret02_WepFocus')
        self.detector:WatchBone('Right_Turret02_WepFocus')
        self.detector:WatchBone('Left_Turret03_Muzzle')
        self.detector:WatchBone('Right_Turret03_Muzzle')
        self.detector:WatchBone('Attachpoint01')
        self.detector:WatchBone('Attachpoint02')
        self.detector:EnableTerrainCheck(true)
        self.detector:Enable()

        AirTransport.OnKilled(self, instigator, type, overkillRatio)
    end,

    ---@param self UAS0401
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        AirTransport.OnLayerChange(self, new, old)
    end,

    OnAnimTerrainCollision = function(self, bone, x, y, z)
        local blueprint = self.Blueprint
        local position = { x, y, z }
        DamageArea(self, position, 5, 1000, 'Default', true, false)
        DamageArea(self, position, 5, 1, 'TreeForce', false)
        explosion.CreateDefaultHitExplosionAtBone(self, bone, 5.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self),
            { blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ })
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AirTransport.OnStopBeingBuilt(self, builder, layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AirTransport.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    CreateShield = function(self, bpShield)
        local bpShield = table.deepcopy(bpShield)
        self:DestroyShield()

        self.MyShield = CzarShield(bpShield, self)

        self:SetFocusEntity(self.MyShield)
        self:EnableShield()
        self.Trash:Add(self.MyShield)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
            self:OnIdle()
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AirTransport.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bone = self.BuildAttachBone
            unitBuilding:AttachBoneTo(-2, self, bone)
            unitBuilding:HideBone(0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            AirTransport.OnStopBuild(self, unitBeingBuilt)
            ExternalFactoryComponent.OnStopBuildWithStorage(self, unitBeingBuilt)
        end,
    },
}

TypeClass = UAA0310
