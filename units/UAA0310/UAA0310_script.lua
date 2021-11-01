-- Automatically upvalued moho functions for performance
local CCollisionManipulatorMethods = _G.moho.CollisionManipulator
local CCollisionManipulatorMethodsEnableTerrainCheck = CCollisionManipulatorMethods.EnableTerrainCheck
local CCollisionManipulatorMethodsWatchBone = CCollisionManipulatorMethods.WatchBone

local EntityMethods = _G.moho.entity_methods
local EntityMethodsDetachAll = EntityMethods.DetachAll
local EntityMethodsDetachFrom = EntityMethods.DetachFrom
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local GlobalMethods = _G
local GlobalMethodsDamageArea = GlobalMethods.DamageArea
local GlobalMethodsIssueMoveOffFactory = GlobalMethods.IssueMoveOffFactory

local IAniManipulatorMethods = _G.moho.manipulator_methods
local IAniManipulatorMethodsDisable = IAniManipulatorMethods.Disable

local UnitMethods = _G.moho.unit_methods
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsSetBusy = UnitMethods.SetBusy
local UnitMethodsSetFocusEntity = UnitMethods.SetFocusEntity
local UnitMethodsShowBone = UnitMethods.ShowBone
-- End of automatically upvalued moho functions

-----------------------------------------------------------------
-- File     :  /cdimage/units/UAA0310/UAA0310_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon CZAR Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local AirTransport = import('/lua/defaultunits.lua').AirTransport
local aWeapons = import('/lua/aeonweapons.lua')
local AQuantumBeamGenerator = aWeapons.AQuantumBeamGenerator
local AAAZealotMissileWeapon = aWeapons.AAAZealotMissileWeapon
local AANDepthChargeBombWeapon = aWeapons.AANDepthChargeBombWeapon
local AAATemporalFizzWeapon = aWeapons.AAATemporalFizzWeapon
local explosion = import('/lua/defaultexplosions.lua')
local CzarShield = import('/lua/shield.lua').CzarShield

UAA0310 = Class(AirTransport)({
    DestroyNoFallRandomChance = 1.1,
    BuildAttachBone = 'UAA0310',

    Weapons = {
        QuantumBeamGeneratorWeapon = Class(AQuantumBeamGenerator)({}),
        SonicPulseBattery1 = Class(AAAZealotMissileWeapon)({}),
        SonicPulseBattery2 = Class(AAAZealotMissileWeapon)({}),
        SonicPulseBattery3 = Class(AAAZealotMissileWeapon)({}),
        SonicPulseBattery4 = Class(AAAZealotMissileWeapon)({}),
        DepthCharge01 = Class(AANDepthChargeBombWeapon)({}),
        DepthCharge02 = Class(AANDepthChargeBombWeapon)({}),
        AAFizz01 = Class(AAATemporalFizzWeapon)({}),
        AAFizz02 = Class(AAATemporalFizzWeapon)({}),
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        local wep = self:GetWeaponByLabel('QuantumBeamGeneratorWeapon')
        for _, v in wep.Beams do
            IAniManipulatorMethodsDisable(v.Beam)
            if wep.HoldFireThread then
                KillThread(wep.HoldFireThread)
            end
            v.Beam:Destroy()
        end

        self.detector = CreateCollisionDetector(self)
        self.Trash:Add(self.detector)
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Left_Turret01_Muzzle')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Right_Turret01_Muzzle')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Left_Turret02_WepFocus')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Right_Turret02_WepFocus')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Left_Turret03_Muzzle')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Right_Turret03_Muzzle')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Attachpoint01')
        CCollisionManipulatorMethodsWatchBone(self.detector, 'Attachpoint02')
        CCollisionManipulatorMethodsEnableTerrainCheck(self.detector, true)
        self.detector:Enable()

        AirTransport.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnAnimTerrainCollision = function(self, bone, x, y, z)
        GlobalMethodsDamageArea(self, {
            x,
            y,
            z,
        }, 5, 1000, 'Default', true, false)
        explosion.CreateDefaultHitExplosionAtBone(self, bone, 5.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {
            self:GetUnitSizes(),
        })
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AirTransport.OnStopBeingBuilt(self, builder, layer)
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

        UnitMethodsSetFocusEntity(self, self.MyShield)
        self:EnableShield()
        self.Trash:Add(self.MyShield)
    end,

    IdleState = State({
        Main = function(self)
            EntityMethodsDetachAll(self, self.BuildAttachBone)
            UnitMethodsSetBusy(self, false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AirTransport.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    }),

    BuildingState = State({
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bone = self.BuildAttachBone
            EntityMethodsDetachAll(self, bone)
            UnitMethodsHideBone(unitBuilding, 0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            AirTransport.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    }),

    FinishedBuildingState = State({
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            EntityMethodsDetachFrom(unitBuilding, true)
            EntityMethodsDetachAll(self, self.BuildAttachBone)
            if self:TransportHasAvailableStorage() then
                self:AddUnitToStorage(unitBuilding)
            else
                local worldPos = self:CalculateWorldPositionFromRelative({
                    0,
                    0,
                    -20,
                })
                GlobalMethodsIssueMoveOffFactory({
                    unitBuilding,
                }, worldPos)
                UnitMethodsShowBone(unitBuilding, 0, true)
            end
            EntityMethodsRequestRefreshUI(self)
            ChangeState(self, self.IdleState)
        end,
    }),
})

TypeClass = UAA0310
