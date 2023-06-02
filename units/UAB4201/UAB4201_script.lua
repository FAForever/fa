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

---@class UAB4201 : AStructureUnit
UAB4201 = ClassUnit(AStructureUnit) {
    Weapons = {
        AntiMissile = ClassWeapon(AAMWillOWisp) {
                PlayRackRecoil = function(self, rackList)
                    AAMWillOWisp.PlayRackRecoil(self, rackList)
                     --CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
                    if not self.RotatorManipulator then
                        self.RotatorManipulator = CreateRotator(self.unit, 'Dome', 'z', 20, 40, 40, 40)
                        self.RotatorManipulator:SetGoal(45)
                        self.RotatorManipulatorCounter = 1
                    else
                        self.RotatorManipulatorCounter = self.RotatorManipulatorCounter + 1
                        self.RotatorManipulator:SetGoal(45 * self.RotatorManipulatorCounter)
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

