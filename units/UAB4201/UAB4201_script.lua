--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB4201/UAB4201_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Phalanx Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAMWillOWisp = import("/lua/aeonweapons.lua").AAMWillOWisp

-- upvalue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB4201 : AStructureUnit
UAB4201 = ClassUnit(AStructureUnit) {
    Weapons = {
        ---@class UAB4201_AntiMissile: AAMWillOWisp
        ---@field RotatorManipulator moho.RotateManipulator
        ---@field RotatorManipulatorCounter number
        AntiMissile = ClassWeapon(AAMWillOWisp) {
            RotatorManipulatorCounter = 1,

            ---@param self UAB4201_AntiMissile
            OnCreate = function(self)
                AAMWillOWisp.OnCreate(self)
                self.RotatorManipulator = TrashBagAdd(self.Trash, CreateRotator(self.unit, 'Dome', 'z', 0, 40, nil, nil))
            end,

            --- Rotate the dome 45 degrees when the volcano fires.
            ---@param self UAB4201_AntiMissile
            PlayFxWeaponUnpackSequence = function(self)
                local rotations = self.RotatorManipulatorCounter
                self.RotatorManipulator:SetGoal(45 * rotations)
                self.RotatorManipulatorCounter = rotations < 8 and rotations + 1 or 0
                AAMWillOWisp.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },
}

TypeClass = UAB4201
