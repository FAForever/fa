-----------------------------------------------------------------
-- File     :  /cdimage/units/XEA3204/XEA3204_script.lua
-- Author(s):  Dru Staltman
-- Summary  :  UEF CDR Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetCreator = UnitMethods.SetCreator
-- End of automatically upvalued moho functions

local TConstructionUnit = import('/lua/terranunits.lua').TConstructionUnit

XEA3204 = Class(TConstructionUnit)({
    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)
        self.docked = true
    end,

    SetParent = function(self, parent, podName)
        self.Parent = parent
        self.PodName = podName
        UnitMethodsSetCreator(self, parent)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Parent and not self.Parent.Dead then
            self.Parent:NotifyOfPodDeath(self.PodName)
            self.Parent = nil
        end
        TConstructionUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        TConstructionUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    OnStopBuild = function(self, unitBuilding)
        TConstructionUnit.OnStopBuild(self, unitBuilding)
    end,

    OnFailedToBuild = function(self)
        TConstructionUnit.OnFailedToBuild(self)
    end,

    -- Don't make wreckage
    CreateWreckage = function(self, overkillRatio)
        overkillRatio = 1.1
        TConstructionUnit.CreateWreckage(self, overkillRatio)
    end,
})

TypeClass = XEA3204
