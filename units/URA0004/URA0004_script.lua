-----------------------------------------------------------------
-- File     :  /cdimage/units/URA0001/URA0001_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Builder bot units
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- upvalued globals for performance
local CreateBuilderArmController = CreateBuilderArmController

-- upvalued moho functions for performance
local BuilderArmManipulator = _G.moho.BuilderArmManipulator 
local BuilderArmManipulatorSetAimingArc = BuilderArmManipulator.SetAimingArc
local BuilderArmManipulatorSetPrecedence = BuilderArmManipulator.SetPrecedence
BuilderArmManipulator = nil 

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

local CBuildBotUnit = import("/lua/cybranunits.lua").CBuildBotUnit
---@class URA0004 : CBuildBotUnit
URA0004 = ClassUnit(CBuildBotUnit) { 

    OnCreate = function(self)
        CBuildBotUnit.OnCreate(self)

        -- make the drone aim for the target
        local BuildArmManipulator = CreateBuilderArmController(self, 'URA0004' , 'URA0004', 0)
        BuilderArmManipulatorSetAimingArc(BuildArmManipulator, -180, 180, 360, -90, 90, 360)
        BuilderArmManipulatorSetPrecedence(BuildArmManipulator, 5)
        TrashBagAdd(self.Trash, BuildArmManipulator)

        -- run animation
        -- TODO
    end,

}
TypeClass = URA0004
