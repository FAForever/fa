#****************************************************************************
#**
#**  File     :  /cdimage/units/XRB0204/XRB0204_script.lua
#**  Author(s):  Dru Staltman
#**
#**  Summary  :  Cybran Engineering tower
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit

XRB0104 = Class(CConstructionStructureUnit) 
{
    OnStartBuild = function(self, unitBeingBuilt, order)
        if self.buildingThread then
            KillThread( self.buildingThread)
        end

        self.buildingThread = self:ForkThread(self.OpenState, unitBeingBuilt, order )

    end,
    
    OnStopBuild = function(self, unitBeingBuilt)
        if self.buildingThread then
            KillThread( self.buildingThread)
        end
        self.buildingThread = self:ForkThread(self.CloseState, unitBeingBuilt)        
    end,

    OpenState = function(self, unitBeingBuilt, order)
            if not self.AnimationManipulator then
                self.AnimationManipulator = CreateAnimator(self)
                self.Trash:Add(self.AnimationManipulator)
            end
            self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationOpen, false):SetRate(1)
            WaitFor(self.AnimationManipulator)
            CConstructionStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
        end,

    CloseState = function(self, unitBeingBuilt)
            if not self.AnimationManipulator then
                self.AnimationManipulator = CreateAnimator(self)
                self.Trash:Add(self.AnimationManipulator)
            end
            self.AnimationManipulator:SetRate(-1)
            WaitFor(self.AnimationManipulator)
            CConstructionStructureUnit.OnStopBuild(self, unitBeingBuilt)
        end,

}
TypeClass = XRB0104