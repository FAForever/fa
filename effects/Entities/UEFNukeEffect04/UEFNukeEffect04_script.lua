------------------------------------------------------------------------------
-- File     :  /effects/Entities/UEFNukeEffect02/UEFNukeEffect04_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Nuclear explosion script
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

--- UEFNukeEffect04
---@class UEFNukeEffect04 : NullShell
UEFNukeEffect04 = Class(NullShell) {

	---@param self UEFNukeEffect04
	OnCreate = function(self)
		NullShell.OnCreate(self)
		self:ForkThread(self.EffectThread)
	end,

	---@param self UEFNukeEffect04
	EffectThread = function(self)
		local army = self.Army

		WaitTicks(40)
		for k, v in EffectTemplate.TNukeBaseEffects01 do
			CreateEmitterOnEntity(self, army, v)
		end
	end,
}
TypeClass = UEFNukeEffect04