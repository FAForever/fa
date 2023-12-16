------------------------------------------------------------------------------
-- File     :  /effects/Entities/UEFNukeEffect02/UEFNukeEffect02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Nuclear explosion script
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

-- upvalue for perfomance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks

---@class UEFNukeEffect02 : NullShell
UEFNukeEffect02 = Class(NullShell) {

	---@param self UEFNukeEffect02
	OnCreate = function(self)
		NullShell.OnCreate(self)
		local trash = self.Trash

		TrashBagAdd(trash, ForkThread(self.EffectThread,self))
	end,

	---@param self UEFNukeEffect02
	EffectThread = function(self)
		local army = self.Army

		WaitTicks(40)
		for k, v in EffectTemplate.TNukeHeadEffects01 do
			CreateEmitterOnEntity(self, army, v)
		end

		self:SetVelocity(0, 3, 0)
	end,
}
TypeClass = UEFNukeEffect02