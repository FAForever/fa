------------------------------------------------------------------------------
-- File     :  /effects/Entities/UEFNukeEffect02/UEFNukeEffect05_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Nuclear explosion script
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

--- UEFNukeEffect05
---@class UEFNukeEffect05 : NullShell
UEFNukeEffect05 = Class(NullShell) {

	---@param self UEFNukeEffect05
	OnCreate = function(self)
		NullShell.OnCreate(self)

		self.Trash:Add(ForkThread(self.EffectThread,self))
	end,

	---@param self UEFNukeEffect05
	EffectThread = function(self)
		local army = self.Army

		for k, v in EffectTemplate.TNukeBaseEffects02 do
			CreateEmitterOnEntity(self, army, v)
		end
	end,
}
TypeClass = UEFNukeEffect05