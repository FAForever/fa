--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB1301/UEB1301_script.lua
--**  Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Tier 3 Power Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TEnergyCreationUnit = import("/lua/terranunits.lua").TEnergyCreationUnit


-- Upvalue for performance
local 


---@class UEB1301 : TEnergyCreationUnit
UEB1301 = ClassUnit(TEnergyCreationUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        TEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            -- Play the "activate" sound
            local bp = self.Blueprint
            if bp.Audio.Activate then
                self:PlaySound(bp.Audio.Activate)
            end
        end,

        OnInActive = function(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
        end,

        OnActive = function(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}

TypeClass = UEB1301