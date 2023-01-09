--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB4203/XSB4203_script.lua
--**
--**  Summary  :  Seraphim Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SRadarJammerUnit = import("/lua/seraphimunits.lua").SRadarJammerUnit
local EffectTemplates = import("/lua/effecttemplates.lua")

---@class XSB4203 : SRadarJammerUnit
---@field StealthEffectsBag TrashBag
---@field StealthRotator moho.RotateManipulator
XSB4203 = Class(SRadarJammerUnit) {
    IntelEffects = {
		{
			Bones = {
				'XSB4203',
			},
			Offset = {
				0,
				3.5,
				0,
			},
			Type = 'Jammer01',
		},
    },

	OnCreate = function(self)
		SRadarJammerUnit.OnCreate(self)
		self.StealthEffectsBag = TrashBag()
		self.StealthRotator = CreateRotator(self, 'N01', "y", nil, 0, 1, 12)

		self.Trash:Add(self.StealthEffectsBag)
		self.Trash:Add(self.StealthRotator)
	end,

	DestroyAllTrashBags = function(self)
		SRadarJammerUnit.DestroyAllTrashBags(self)
		self.StealthEffectsBag:Destroy()
	end,

    ---@param self XSB4203
    ---@param type IntelType
    OnIntelEnabled = function(self, type)
		SRadarJammerUnit.OnIntelEnabled(self)
		if type == "RadarStealthField" or type == nil then
			local army = self.Army
			local trash = self.StealthEffectsBag
			self.StealthRotator:SetSpinDown(false)
			self.StealthRotator:SetTargetSpeed(12)
			self.StealthRotator:SetAccel(1)

			-- center
			for _, v in EffectTemplates.SeraphimSubCommanderGateway02 do
				trash:Add(CreateAttachedEmitter(self, 'XSB4203', army, v):OffsetEmitter(0, 0.3, -0.5):ScaleEmitter(0.5))
			end

			-- top
			for _, v in EffectTemplates.SeraphimSubCommanderGateway02 do
				trash:Add(CreateAttachedEmitter(self, 'N01', army, v):OffsetEmitter(0, 0.7, -1))
			end
		end
	end,

    ---@param self XSB4203
    ---@param disabler string
    ---@param type IntelType
    OnIntelDisabled = function(self, disabler, type)
		SRadarJammerUnit.OnIntelDisabled(self)

		self.StealthRotator:SetTargetSpeed(0)
		self.StealthRotator:SetSpinDown(true)
		self.StealthEffectsBag:Destroy()
	end,
}

TypeClass = XSB4203