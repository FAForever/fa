--****************************************************************************
--**
--**  File     :  /cdimage/units/XSS0303/XSS0303_script.lua
--**  Author(s):  Greg Kohne, Drew Staltman, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Aircraft Carrier Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AircraftCarrier = import("/lua/defaultunits.lua").AircraftCarrier
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SAALosaareAutoCannonWeapon = SeraphimWeapons.SAALosaareAutoCannonWeaponSeaUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon
local SAMElectrumMissileDefense = SeraphimWeapons.SAMElectrumMissileDefense

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class XSS0303 : AircraftCarrier, ExternalFactoryComponent
XSS0303 = ClassUnit(AircraftCarrier, ExternalFactoryComponent) {

    Weapons = {
        AntiAirRight = ClassWeapon(SAALosaareAutoCannonWeapon) {},
        AntiAirLeft = ClassWeapon(SAALosaareAutoCannonWeapon) {},
        CruiseMissiles = ClassWeapon(SLaanseMissileWeapon) {},
        AntiMissile = ClassWeapon(SAMElectrumMissileDefense) {},
    },

    FactoryAttachBone = 'ExternalFactoryPoint',
    BuildAttachBone = 'XSS0303',

    OnStopBeingBuilt = function(self,builder,layer)
        AircraftCarrier.OnStopBeingBuilt(self,builder,layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnPaused = function(self)
        AircraftCarrier.OnPaused(self)
        ExternalFactoryComponent.OnPaused(self)
    end,

    OnUnpaused = function(self)
        AircraftCarrier.OnUnpaused(self)
        ExternalFactoryComponent.OnUnpaused(self)
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
            local unitBuilding = self.UnitBeingBuilt
            self:SetBusy(true)
            local bone = self.BuildAttachBone
            self:DetachAll(bone)
            unitBuilding:AttachTo(self, bone)
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

TypeClass = XSS0303

