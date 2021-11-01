-----------------------------------------------------------------
-- File     :  /cdimage/units/UEA0003/UEA0003_script.lua
-- Summary  :  UEF sACU Pod Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape
local EntityMethodsSetVizToAllies = EntityMethods.SetVizToAllies
local EntityMethodsSetVizToEnemies = EntityMethods.SetVizToEnemies
local EntityMethodsSetVizToFocusPlayer = EntityMethods.SetVizToFocusPlayer
local EntityMethodsSetVizToNeutrals = EntityMethods.SetVizToNeutrals

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetDoNotTarget = UnitMethods.SetDoNotTarget
local UnitMethodsSetUnSelectable = UnitMethods.SetUnSelectable
-- End of automatically upvalued moho functions

local TConstructionUnit = import('/lua/terranunits.lua').TConstructionUnit

ZXA0001 = Class(TConstructionUnit)({
    OnCreate = function(self)
        TConstructionUnit.OnCreate(self)

        UnitMethodsSetUnSelectable(self, true)
        UnitMethodsSetDoNotTarget(self, true)
        EntityMethodsSetCollisionShape(self, 'None')
        EntityMethodsSetVizToAllies(self, 'Never')
        EntityMethodsSetVizToEnemies(self, 'Never')
        EntityMethodsSetVizToFocusPlayer(self, 'Never')
        EntityMethodsSetVizToNeutrals(self, 'Never')
    end,
})

TypeClass = ZXA0001
