-- Automatically upvalued moho functions for performance
local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetAccel = CRotateManipulatorMethods.SetAccel
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed
-- End of automatically upvalued moho functions

#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1104/URB1104_script.lua
#**  Author(s):  Jessica St. Croix, David Tomandl
#**
#**  Summary  :  Cybran Mass Fabricator
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CMassFabricationUnit = import('/lua/cybranunits.lua').CMassFabricationUnit

URB1104 = Class(CMassFabricationUnit)({
    DestructionPartsLowToss = {
        'Blade',
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CMassFabricationUnit.OnStopBeingBuilt(self, builder, layer)
        self.Rotator = CreateRotator(self, 'Blade', 'z')
        self.Trash:Add(self.Rotator)
        CRotateManipulatorMethodsSetAccel(self.Rotator, 40)
        CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, 150)
    end,

    OnProductionUnpaused = function(self)
        CMassFabricationUnit.OnProductionUnpaused(self)
        if self.Rotator then
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, 150)
        end
    end,

    OnProductionPaused = function(self)
        CMassFabricationUnit.OnProductionPaused(self)
        if self.Rotator then
            CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, 0)
        end
    end,
})

TypeClass = URB1104