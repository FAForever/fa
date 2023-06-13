-- File     :  /cdimage/units/UAS0303/UAS0303_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon Aircraft Carrier Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------

local AircraftCarrier = import("/lua/defaultunits.lua").AircraftCarrier
local WeaponsFile = import("/lua/aeonweapons.lua")
local AAAZealotMissileWeapon = WeaponsFile.AAAZealotMissileWeapon
local AAMWillOWisp = WeaponsFile.AAMWillOWisp

---@class UAS0303 : AircraftCarrier
UAS0303 = ClassUnit(AircraftCarrier) {

    Weapons = {
        AntiAirMissiles01 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiAirMissiles02 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiMissile = ClassWeapon(AAMWillOWisp) {},
    },

    BuildAttachBone = 'UAS0303',

    OnStopBeingBuilt = function(self,builder,layer)
        AircraftCarrier.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AircraftCarrier.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            self:SetBusy(true)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            unitBuilding:HideBone(0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            AircraftCarrier.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    },

    FinishedBuildingState = State {
        Main = function(self)
            self:SetBusy(true)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)
            if self:TransportHasAvailableStorage() then
                self:AddUnitToStorage(unitBuilding)
            else
                local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
                IssueMoveOffFactory({unitBuilding}, worldPos)
                unitBuilding:ShowBone(0,true)
            end
            self:SetBusy(false)
            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
        end,
    },
}

TypeClass = UAS0303

