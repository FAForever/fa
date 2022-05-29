#****************************************************************************
#**
#**  File     :  /cdimage/units/URB1201/URB1201_script.lua
#**  Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Tier 2 Power Generator Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CEnergyCreationUnit = import('/lua/cybranunits.lua').CEnergyCreationUnit

URB1201 = Class(CEnergyCreationUnit) {
    AmbientEffects = 'CT2PowerAmbient',
    
    OnStopBeingBuilt = function(self,builder,layer)
        CEnergyCreationUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.ActiveState)
    end,

    ActiveState = State {
        Main = function(self)
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.Activate then
                self:PlaySound(myBlueprint.Audio.Activate)
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

TypeClass = URB1201