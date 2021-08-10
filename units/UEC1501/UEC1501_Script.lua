#****************************************************************************
#** 
#**  File     :  /cdimage/units/UEC1501/UEC1501_script.lua 
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos
#** 
#**  Summary  :  Earth Manufacturing Center, Ver1
#** 
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TCivilianStructureUnit = import('/lua/terranunits.lua').TCivilianStructureUnit

UEC1501 = Class(TCivilianStructureUnit) {
	
	EffectBones01 = {
		'Smoke_Left01', 'Smoke_Left02', 'Smoke_Left03', 'Smoke_Left04',	'Smoke_Left_05',					
		'Smoke_Right01', 'Smoke_Right02', 'Smoke_Right03', 'Smoke_Right04',							
	},
	
	EffectBones02 = {
		'Smoke_Right05', 'Smoke_Right06',
	},

    OnCreate = function(self)
		TCivilianStructureUnit.OnCreate(self)
		local army = self:GetArmy()
        for k, v in self.EffectBones01 do
            CreateAttachedEmitter(self,v,army,'/effects/emitters/uec1501_smoke_01_emit.bp')
        end		
        for k, v in self.EffectBones02 do
            CreateAttachedEmitter(self,v,army,'/effects/emitters/uec1501_smoke_02_emit.bp')
        end		        
    end,
}


TypeClass = UEC1501

