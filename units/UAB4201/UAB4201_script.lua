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
                -- Speed is set to do a rotation in 1 tick
                self.RotatorManipulator = TrashBagAdd(self.Trash, CreateRotator(self.unit, 'Dome', 'z', 0, 225, nil, nil))
            end,

            --- Rotate the dome when the volcano unpacks
            ---@param self UAB4201_AntiMissile
            PlayFxWeaponUnpackSequence = function(self)
                local rotations = self.RotatorManipulatorCounter
                self.RotatorManipulator:SetGoal(22.5 * rotations)
                self.RotatorManipulatorCounter = rotations + 1

                AAMWillOWisp.PlayFxWeaponUnpackSequence(self)
            end,

            --- Rotate the dome when the volcano packs. Ends on a 45 degree turn so that the mesh doesn't self-intersect.
            ---@param self UAB4201_AntiMissile
            PlayFxWeaponPackSequence = function(self)
                local rotations = self.RotatorManipulatorCounter
                self.RotatorManipulator:SetGoal(22.5 * rotations)
                self.RotatorManipulatorCounter = rotations < 16 and rotations + 1 or 1

                AAMWillOWisp.PlayFxWeaponPackSequence(self)
            end
        },
    },
}

TypeClass = UAB4201
