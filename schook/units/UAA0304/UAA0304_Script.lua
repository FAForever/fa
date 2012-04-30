#****************************************************************************
#**
#**  File     :  /cdimage/units/UAA0304/UAA0304_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Strategic Bomber Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AIFBombQuarkWeapon = import('/lua/aeonweapons.lua').AIFBombQuarkWeapon


UAA0304 = Class(AAirUnit) {
    Weapons = {
        Bomb = Class(AIFBombQuarkWeapon) {
		
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

TypeClass = UAA0304