#****************************************************************************
#**
#**  File     :  /cdimage/units/XRB0204/XRB0204_script.lua
#**  Author(s):  Dru Staltman, Gordon Duclos
#**
#**  Summary  :  Cybran Engineering tower
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit

XRB0204 = Class(CConstructionStructureUnit) 
{
    OnStartBeingBuilt = function(self, builder, layer)
        CConstructionStructureUnit.OnStartBeingBuilt(self, builder, layer)
        self:HideBone('xrb0304', true)
        self:ShowBone('TurretT2', true)
        self:ShowBone('Door2_B02', true)
        self:ShowBone('B02', true)
        self:ShowBone('Attachpoint02', true)
    end,   
     
    OnStartBuild = function(self, unitBeingBuilt, order)
        self:ForkThread(self.OpenState, unitBeingBuilt, order )
    end,
    
    OnStopBuild = function(self, unitBeingBuilt)
        self:ForkThread(self.CloseState, unitBeingBuilt)        
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
TypeClass = XRB0204