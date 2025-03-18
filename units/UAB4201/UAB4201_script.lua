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
        AntiMissile = ClassWeapon(AAMWillOWisp) {
                PlayRackRecoil = function(self, rackList)
                    AAMWillOWisp.PlayRackRecoil(self, rackList)

                    local unit = self.unit
                    local rotatorManipulator = self.RotatorManipulator

                     --CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
                    if not rotatorManipulator then
                        rotatorManipulator = CreateRotator(unit, 'Dome', 'z', 20, 40, 40, 40)
                        rotatorManipulator:SetGoal(45)
                        self.RotatorManipulatorCounter = 1
                    else
                        self.RotatorManipulatorCounter = self.RotatorManipulatorCounter + 1
                        rotatorManipulator:SetGoal(45 * self.RotatorManipulatorCounter)
                    end
                    self.unit.Trash:Add(self.RotatorManipulator)
                end,
                
                PlayRackRecoilReturn = function(self, rackList)
                    AAMWillOWisp.PlayRackRecoilReturn(self, rackList)
                    if self.RotatorManipulatorCounter == 8 then
                        self.RotatorManipulator:Destroy()
                        self.RotatorManipulator = nil
                    end
                end,
            
            },
    },

}

TypeClass = UAB4201

