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

local ExternalFactoryComponent = import("/lua/defaultcomponents.lua").ExternalFactoryComponent

---@class URS0303 : AircraftCarrier, ExternalFactoryComponent
URS0303 = ClassUnit(AircraftCarrier, ExternalFactoryComponent) {

    Weapons = {
        AAGun01 = ClassWeapon(CAAAutocannon) {},
        AAGun02 = ClassWeapon(CAAAutocannon) {},
        AAGun03 = ClassWeapon(CAAAutocannon) {},
        AAGun04 = ClassWeapon(CAAAutocannon) {},
        Zapper = ClassWeapon(CAMZapperWeapon) {},
    },

    FactoryAttachBone = 'ExternalFactoryPoint',
    BuildAttachBone = 'Launchpoint',

    OnStopBeingBuilt = function(self, builder, layer)
        AircraftCarrier.OnStopBeingBuilt(self, builder, layer)
        ExternalFactoryComponent.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    UpdateStat = function(self, stat, value)
        AircraftCarrier.UpdateStat(self, stat, value)
        ExternalFactoryComponent.UpdateStat(self, stat, value)
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

            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:DetachAll(self.BuildAttachBone)

            if not self:TransportHasAvailableStorage() or self:GetScriptBit('RULEUTC_WeaponToggle') then
                local worldPos = self:CalculateWorldPositionFromRelative({0, 0, 20})
                IssueToUnitMove(unitBeingBuilt, worldPos)
                unitBuilding:ShowBone(0, true)
            else
                self:AddUnitToStorage(unitBuilding)
            end

            self:RequestRefreshUI()
            ChangeState(self, self.IdleState)
        end,
    },
}

TypeClass = URS0303
