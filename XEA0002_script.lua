#****************************************************************************
#**
#**  File     :  /cdimage/units/XEA0002/XEA0002_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos
#**
#**  Summary  :  UEF Defense Satelite Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TOrbitalDeathLaserBeamWeapon = import('/lua/terranweapons.lua').TOrbitalDeathLaserBeamWeapon
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

XEA0002 = Class(TAirUnit) {
    DestroyNoFallRandomChance = 1.1,
    
    HideBones = { 'Shell01', 'Shell02', 'Shell03', 'Shell04', },
    
    Weapons = {
        OrbitalDeathLaserWeapon = Class(TOrbitalDeathLaserBeamWeapon){},
    },
    
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.IsDying then 
            return 
        end
        
        local wep = self:GetWeaponByLabel('OrbitalDeathLaserWeapon')
        for k, v in wep.Beams do
            v.Beam:Disable()
        end      
        
        self.IsDying = true
        self.Parent:Kill(instigator, type, 0)
        
        TAirUnit.OnKilled(self, instigator, type, overkillRatio)        
    end,
    
    Open = function(self)
        ChangeState( self, self.OpenState )
    end,
    
    OpenState = State() {
        Main = function(self)
            self.OpenAnim = CreateAnimator(self)
            self.OpenAnim:PlayAnim( '/units/XEA0002/xea0002_aopen01.sca' )
            self.Trash:Add( self.OpenAnim )
            WaitFor( self.OpenAnim )
            
            self.OpenAnim:PlayAnim( '/units/XEA0002/xea0002_aopen02.sca' )
            
            for k,v in self.HideBones do
                self:HideBone( v, true )
            end
        end,
    },
    
    --Make this unit invulnerable - Not any more! (IceDreamer)
    OnDamage = function(self, instigator, amount, vector, damageType)
		if EntityCategoryContains(categories.NUKE, instigator) then
			self:Destroy()
		end
    end,
}
TypeClass = XEA0002