--****************************************************************************
--** 
--**  File     :  /cdimage/units/UAC1101/UAC1101_script.lua 
--**  Author(s):  John Comes, David Tomandl 
--** 
--**  Summary  :  Aeon Residential Structure, Ver1
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ACivilianStructureUnit = import("/lua/aeonunits.lua").ACivilianStructureUnit

---@class UAC1101 : ACivilianStructureUnit
UAC1101 = ClassUnit(ACivilianStructureUnit) {

	BoneB01 = 'Energy_Beam_01',
	BoneSetE01 = {
		'Energy_Beam_02',
		'Energy_Beam_03',
		'Energy_Beam_04',		
		'Energy_Beam_05',
		'Energy_Beam_06',				
		'Energy_Beam_07',			
	},
	BoneB02 = 'Energy_Beam_08',
	BoneSetE02 = {
		'Energy_Beam_09',
		'Energy_Beam_10',
		'Energy_Beam_11',		
		'Energy_Beam_12',
		'Energy_Beam_13',				
		'Energy_Beam_14',			
	},	
	FxBeamAmbient = '/effects/emitters/structure_beam_ambient_01_emit.bp',

    OnCreate = function(self)
		ACivilianStructureUnit.OnCreate(self)
		local army = self:GetArmy()
		for k, v in self.BoneSetE01 do
			AttachBeamEntityToEntity(self, self.BoneB01, self, v, army, self.FxBeamAmbient ) 
		end
		for k, v in self.BoneSetE02 do
			AttachBeamEntityToEntity(self, self.BoneB02, self, v, army, self.FxBeamAmbient ) 
		end		
    end,
}


TypeClass = UAC1101


