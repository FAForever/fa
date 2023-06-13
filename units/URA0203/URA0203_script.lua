--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0203/URA0203_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Gunship Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CDFRocketIridiumWeapon = import("/lua/cybranweapons.lua").CDFRocketIridiumWeapon

---@class URA0203 : CAirUnit
URA0203 = ClassUnit(CAirUnit) {
    Weapons = {
        Missile01 = ClassWeapon(CDFRocketIridiumWeapon) {},
    },

    DestructionPartsChassisToss = {'URA0203',},
    --DestructionPartsHighToss = {'Spinner', 'Front_Turret',},

    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        --self.Rotator = CreateRotator(self, 'Spinner', 'y', nil, 1000, 0, 0)
        --self.Trash:Add(self.Rotator)
    end,

    OnMotionVertEventChange = function(self, new, old)
        CAirUnit.OnMotionVertEventChange(self, new, old)

        -- We want to keep the ambient sound of the rotor
        -- playing during the landing sequence
        if (new == 'Down') then
            -- Keep the ambient hover sound going
            self:PlayUnitAmbientSound('AmbientMove')
        end

        if new == 'Bottom' then
            --KillThread( self.TakingOffThread )
            --self:SetImmobile(false)

            --if(self.Rotator) then
            --    self.Rotator:SetSpinDown(true):SetTargetSpeed(0):SetAccel(180)
            --end
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound( 'AmbientMove' )
        end

        --if old == 'Bottom' then
        --    self.TakingOffThread = ForkThread(self.TakingOff, self)
        --end
    end,

    --TakingOff = function(self)
    --    self:SetImmobile(true)
    --    self.Rotator:SetSpinDown(false):SetTargetSpeed(1000):SetAccel(500)
    --    WaitFor(self.Rotator)
    --    self:SetImmobile(false)
    --end,
}

TypeClass = URA0203