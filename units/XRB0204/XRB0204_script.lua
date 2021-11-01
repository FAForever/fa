-- Automatically upvalued moho functions for performance
local UnitMethods = _G.moho.unit_methods
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsShowBone = UnitMethods.ShowBone
-- End of automatically upvalued moho functions

-----------------------------------------------------------------
-- File     :  /cdimage/units/XRB0204/XRB0204_script.lua
-- Author(s):  Dru Staltman, Gordon Duclos
-- Summary  :  Cybran Engineering tower
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit

XRB0204 = Class(CConstructionStructureUnit)({
    OnStartBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStartBeingBuilt(self, builder, layer)

        local target = self:GetBlueprint().General.UpgradesFrom

        -- Check if we're really being built on top of another unit (as an upgrade).
        -- We might be being rebuild by the slightly bugtacular SCU REBUILDER behaviour, in which
        -- case we want to show all our bones anyway.
        local upos = self:GetPosition()
        local candidates = GetUnitsInRect(Rect(upos[1], upos[3], upos[1], upos[3]))
        for k, v in candidates do
            if target == v:GetBlueprint().BlueprintId then
                UnitMethodsHideBone(self, 'xrb0304', true)
                UnitMethodsShowBone(self, 'TurretT2', true)
                UnitMethodsShowBone(self, 'Door2_B02', true)
                UnitMethodsShowBone(self, 'B02', true)
                UnitMethodsShowBone(self, 'Attachpoint02', true)
                return
            end
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStopBeingBuilt(self, builder, layer)

        UnitMethodsShowBone(self, 'xrb0304', true)
    end,
})

TypeClass = XRB0204
