-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/URS0303/URS0303_script.lua
-- **  Author(s):  David Tomandl, Andres Mendez
-- **
-- **  Summary  :  Cybran Aircraft Carrier Script
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsDetachAll = EntityMethods.DetachAll
local EntityMethodsDetachFrom = EntityMethods.DetachFrom
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local GlobalMethods = _G
local GlobalMethodsIssueMoveOffFactory = GlobalMethods.IssueMoveOffFactory

local UnitMethods = _G.moho.unit_methods
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsSetBusy = UnitMethods.SetBusy
local UnitMethodsShowBone = UnitMethods.ShowBone
-- End of automatically upvalued moho functions

local AircraftCarrier = import('/lua/defaultunits.lua').AircraftCarrier
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CAAAutocannon = CybranWeaponsFile.CAAAutocannon
local CAMZapperWeapon = CybranWeaponsFile.CAMZapperWeapon
local loading = false

URS0303 = Class(AircraftCarrier)({

    Weapons = {
        -- Weapons
        --  4 AA Autocannon w/ Guided Rounds
        --  1 "Zapper" Anti-Missile

        AAGun01 = Class(CAAAutocannon)({}),
        AAGun02 = Class(CAAAutocannon)({}),
        AAGun03 = Class(CAAAutocannon)({}),
        AAGun04 = Class(CAAAutocannon)({}),

        Zapper = Class(CAMZapperWeapon)({}),

    },

    BuildAttachBone = 'Attachpoint',

    OnStopBeingBuilt = function(self, builder, layer)
        AircraftCarrier.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State({
        Main = function(self)
            EntityMethodsDetachAll(self, self.BuildAttachBone)
            UnitMethodsSetBusy(self, false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            AircraftCarrier.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
        end,
    }),

    BuildingState = State({
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            UnitMethodsSetBusy(self, true)
            local bone = self.BuildAttachBone
            EntityMethodsDetachAll(self, bone)
            UnitMethodsHideBone(unitBuilding, 0, true)
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            AircraftCarrier.OnStopBuild(self, unitBeingBuilt)
            ChangeState(self, self.FinishedBuildingState)
        end,
    }),

    FinishedBuildingState = State({
        Main = function(self)
            UnitMethodsSetBusy(self, true)
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
            UnitMethodsSetBusy(self, false)
            EntityMethodsRequestRefreshUI(self)
            ChangeState(self, self.IdleState)
        end,
    }),


})

TypeClass = URS0303

