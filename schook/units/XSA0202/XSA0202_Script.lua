#****************************************************************************
#**
#**  File     :  /data/units/XSA0202/XSA0202_script.lua
#**  Author(s):  Jessica St. Croix, Gordon Duclos, Matt Vainio, Aaron Lundquist
#**
#**  Summary  :  Seraphim Fighter/Bomber Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAAShleoCannonWeapon = SeraphimWeapons.SAAShleoCannonWeapon
local SDFBombOtheWeapon = SeraphimWeapons.SDFBombOtheWeapon

XSA0202 = Class(SAirUnit) {
    Weapons = {
        ShleoAAGun01 = Class(SAAShleoCannonWeapon) {
			FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',},
        },
        ShleoAAGun02 = Class(SAAShleoCannonWeapon) {
			FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_02_emit.bp',},
        },
        Bomb = Class(SDFBombOtheWeapon) {
                
            IdleState = State (SDFBombOtheWeapon.IdleState) {
                Main = function(self)
                    SDFBombOtheWeapon.IdleState.Main(self)
                end,
                
                OnGotTarget = function(self)
                    self.unit:SetBreakOffTriggerMult(2.0)
                    self.unit:SetBreakOffDistanceMult(8.0)
                    self.unit:SetSpeedMult(0.67)
                    SDFBombOtheWeapon.OnGotTarget(self)
					local speedMulti = 0.67 * self.unit:GetSpeedModifier()   # [168]
                    self.unit:SetSpeedMult(speedMulti)
                end,                
            },
        
            OnGotTarget = function(self)
                self.unit:SetBreakOffTriggerMult(2.0)
                self.unit:SetBreakOffDistanceMult(8.0)
                self.unit:SetSpeedMult(0.67)
                SDFBombOtheWeapon.OnGotTarget(self)
				local speedMulti = 0.67 * self.unit:GetSpeedModifier()   # [168]
                self.unit:SetSpeedMult(speedMulti)
            end,
        
            OnLostTarget = function(self)
                self.unit:SetBreakOffTriggerMult(1.0)
                self.unit:SetBreakOffDistanceMult(1.0)
                self.unit:SetSpeedMult(1.0)
                SDFBombOtheWeapon.OnLostTarget(self)
                local speedMulti = self.unit:GetSpeedModifier()   # [168]
                self.unit:SetSpeedMult(speedMulti)
            end,  

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
	
	GetSpeedModifier = function(self)
        # this returns 1 when the plane has fuel or 0.25 when it doesn't have fuel. The movement speed penalty for
        # running out of fuel is 75% so planes with no fuel fly at 25% of max speed. [168]
        if self:GetFuelRatio() == 0 then
            return 0.25
        end
        return 1
    end,
}
TypeClass = XSA0202