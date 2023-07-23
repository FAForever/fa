-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/URS0303/URS0303_script.lua
-- **  Author(s):  David Tomandl, Andres Mendez
-- **
-- **  Summary  :  Cybran Aircraft Carrier Script
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AircraftCarrier = import("/lua/defaultunits.lua").AircraftCarrier
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CAAAutocannon = CybranWeaponsFile.CAAAutocannon
local CAMZapperWeapon = CybranWeaponsFile.CAMZapperWeapon03
local loading = false

---@class URS0303 : AircraftCarrier
URS0303 = ClassUnit(AircraftCarrier) {

    Weapons = {
    -- Weapons
    --  4 AA Autocannon w/ Guided Rounds
    --  1 "Zapper" Anti-Missile

        AAGun01 = ClassWeapon(CAAAutocannon) {},
        AAGun02 = ClassWeapon(CAAAutocannon) {},
        AAGun03 = ClassWeapon(CAAAutocannon) {},
        AAGun04 = ClassWeapon(CAAAutocannon) {},

        Zapper = ClassWeapon(CAMZapperWeapon) {},

    },

    BuildAttachBone = 'Attachpoint',

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

TypeClass = URS0303

