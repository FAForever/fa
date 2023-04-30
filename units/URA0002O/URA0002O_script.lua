-----------------------------------------------------------------
-- File     :  /cdimage/units/URA0001/URA0001_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Builder bot units
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- upvalued globals for performance
local CreateBuilderArmController = CreateBuilderArmController

-- upvalued moho functions for performance
local BuilderArmManipulatorSetAimingArc = _G.moho.BuilderArmManipulator.SetAimingArc
local BuilderArmManipulatorSetPrecedence = _G.moho.BuilderArmManipulator.SetPrecedence

-- upvalued trashbag functions for performance
local TrashBagAdd = _G.TrashBag.Add

local CBuildBotUnit = import("/lua/cybranunits.lua").CBuildBotUnit
URA0002O = ClassDummyUnit(CBuildBotUnit) { 
    OnCreate = function(self)
        CBuildBotUnit.OnCreate(self)

        -- prevent collisions
        self:SetCollisionShape('None')

        -- make the drone aim for the target
        local BuildArmManipulator = CreateBuilderArmController(self, 'URA0002' , 'URA0002', 0)
        BuilderArmManipulatorSetAimingArc(BuildArmManipulator, -180, 180, 360, -90, 90, 360)
        BuilderArmManipulatorSetPrecedence(BuildArmManipulator, 5)
        TrashBagAdd(self.Trash, BuildArmManipulator)
    end,
}
TypeClass = URA0002O
