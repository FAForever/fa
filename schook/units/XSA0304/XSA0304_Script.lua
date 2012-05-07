#****************************************************************************
#**
#**  File     :  /units/XSA0304/XSA0304_script.lua
#**  Author(s):  Drew Staltman, Greg Kohne, Gordon Duclos
#**
#**  Summary  :  Seraphim Strategic Bomber Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SIFBombZhanaseeWeapon = import('/lua/seraphimweapons.lua').SIFBombZhanaseeWeapon

XSA0304 = Class(SAirUnit) {
    Weapons = {
        Bomb = Class(SIFBombZhanaseeWeapon) {
			CreateProjectileAtMuzzle = function(self, muzzle)
				local proj = self:CreateProjectileForWeapon(muzzle)
				proj.BombSpeedThread = proj:ForkThread(self.BombSpeedThread, self.unit:GetBlueprint().Air.MaxAirspeed, self)
			end,
			
			BombSpeedThread = function(bomb, bomberMaxSpeed, bombWeapon)
				#WARN ('BombSpeedThread started')
				#WARN('Bombermaxspeed is ' .. repr(bomberMaxSpeed))
				local minBombSpeed = 0.8 * (bomberMaxSpeed/10)
				WaitTicks(1)
				if not bomb:BeenDestroyed() then
					local vx,vy,vz = bomb:GetVelocity()
					local BombVelocity = {vx,vy,vz}
					#WARN ('BombVelocity is ' .. repr(BombVelocity))
					local BombSpeed = math.sqrt((vx*vx) + (vz*vz))
					#WARN ('BombSpeed and minBombSpeed are ' .. repr(BombSpeed) .. ' and ' .. repr(minBombSpeed))
					local bp = bombWeapon:GetBlueprint()
					if BombSpeed < minBombSpeed then
						bomb:Destroy()
						LOG('bomb has been destroyed due to low velocity')
					elseif bp.Audio.Fire then
						bombWeapon:PlaySound(bp.Audio.Fire)
					end
				end	
				KillThread(bomb.BombSpeedThread)
			
			end,
		},
    },
}
TypeClass = XSA0304