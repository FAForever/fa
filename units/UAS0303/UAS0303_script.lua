-- File     :  /cdimage/units/UAS0303/UAS0303_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon Aircraft Carrier Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------

local AircraftCarrier = import("/lua/defaultunits.lua").AircraftCarrier
local WeaponsFile = import("/lua/aeonweapons.lua")
local AAAZealotMissileWeapon = WeaponsFile.AAAZealotMissileWeapon
local AAMWillOWisp = WeaponsFile.AAMWillOWisp

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class UAS0303 : AircraftCarrier, ExternalFactoryComponent
UAS0303 = ClassUnit(AircraftCarrier, ExternalFactoryComponent) {

    FactoryAttachBone = 'ExternalFactoryPoint',

    Weapons = {
        AntiAirMissiles01 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiAirMissiles02 = ClassWeapon(AAAZealotMissileWeapon) {},
        AntiMissile = ClassWeapon(AAMWillOWisp) {},
    },

    BuildAttachBone = 'Attachpoint02',

    OnStopBeingBuilt = function(self, builder, layer)
        AircraftCarrier.OnStopBeingBuilt(self, builder, layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnLayerChange = function(self, new, old)
        AircraftCarrier.OnLayerChange(self, new, old)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        AircraftCarrier.OnKilled(self, instigator, type, overkillRatio)
        ExternalFactoryComponent.OnKilled(self, instigator, type, overkillRatio)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
            self:OnIdle()
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AircraftCarrier.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    },

    BuildingState = State {
        Main = function(self)
            ---@type Unit
            local unitBuilding = self.UnitBeingBuilt
            self:SetBusy(true)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            unitBuilding:AttachTo(self, bone)
            unitBuilding:HideBone(0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt, order)
            AircraftCarrier.OnStopBuild(self, unitBeingBuilt, order)
            ExternalFactoryComponent.OnStopBuildWithStorage(self, unitBeingBuilt)
        end,
    },
}

TypeClass = UAS0303
