#****************************************************************************
#** 
#**  File     :  /cdimage/units/XRC1101/XRC1101_script.lua 
#** 
#**  Authors: Greg Kohne
#** 
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CCivilianStructureUnit = import('/lua/cybranunits.lua').CCivilianStructureUnit
local SSQuantumJammerTowerAmbient = import('/lua/EffectTemplates.lua').SJammerTowerAmbient

XRC1101 = Class(CCivilianStructureUnit) 

{
   OnCreate = function(self, builder, layer)
        ###Place emitters on certain light bones on the mesh.
        for k, v in SSQuantumJammerTowerAmbient do
            CreateAttachedEmitter(self, 'Jammer', self:GetArmy(), v)
        end
               
        self:ForkThread(self.LandBlipThread)
        self:ForkThread(self.AirBlipThread)
        
        CCivilianStructureUnit.OnCreate(self)
        
                
            
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationIdle, true)
    end,
        
}


TypeClass = XRC1101

