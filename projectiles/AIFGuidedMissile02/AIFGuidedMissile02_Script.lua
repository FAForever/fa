-------------------------------------------------------------------------------
--  File     :  /data/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_script.lua
--  Author(s):  Gordon Duclos
--  Summary  :  Aeon Guided Split Missile, DAA0206
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
AIFGuidedMissile02 = ClassProjectile(AGuidedMissileProjectile) {
    OnCreate = function(self)
		AGuidedMissileProjectile.OnCreate(self)
		self.Trash:Add(ForkThread(self.MovementThread, self))
    end,

	MovementThread = function(self)
		WaitTicks(7)
		self:TrackTarget(true)
	end,
}
TypeClass = AIFGuidedMissile02