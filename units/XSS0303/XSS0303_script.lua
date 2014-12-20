#****************************************************************************
#**
#**  File     :  /cdimage/units/XSS0303/XSS0303_script.lua
#**  Author(s):  Greg Kohne, Drew Staltman, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Aircraft Carrier Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAALosaareAutoCannonWeapon = SeraphimWeapons.SAALosaareAutoCannonWeaponSeaUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon

XSS0303 = Class(SSeaUnit) {

    Weapons = {
        AntiAirRight = Class(SAALosaareAutoCannonWeapon) {},
        AntiAirLeft = Class(SAALosaareAutoCannonWeapon) {},
        CruiseMissiles = Class(SLaanseMissileWeapon) {},
    },
    
    
    BuildAttachBone = 'XSS0303',

    OnStopBeingBuilt = function(self,builder,layer)
        SSeaUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        SSeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
            SSeaUnit.OnStartBuild(self, unitBuilding, order)
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
            SSeaUnit.OnStopBuild(self, unitBeingBuilt)
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

