--****************************************************************************
--**
--**  File     :  /effects/Entities/UEFNukeEffect011/UEFNukeEffect01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Nuclear explosion script
--**
--**  Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

UEFNukeEffect01 = Class(NullShell) {

	OnCreate = function(self)
		NullShell.OnCreate(self)
		self:ForkThread(self.EffectThread)
	end,

	EffectThread = function(self)
		local scale = self.Blueprint.Display.UniformScale
		local scaleChange = 0.30 * scale

		self:SetScaleVelocity(scaleChange, scaleChange, scaleChange)
		self:SetVelocity(0, 0.25, 0)

		WaitTicks(40)
		scaleChange = -0.01 * scale
		self:SetScaleVelocity(scaleChange, 12 * scaleChange, scaleChange)
		self:SetVelocity(0, 3, 0)
		self:SetBallisticAcceleration(-0.5)

		WaitTicks(50)
		scaleChange = -0.1 * scale
		self:SetScaleVelocity(scaleChange, scaleChange, scaleChange)

	end,
}

TypeClass = UEFNukeEffect01
