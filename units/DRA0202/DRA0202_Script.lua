#****************************************************************************
#**
#**  File     :  /cdimage/units/DRA0202/DRA0202_script.lua
#**  Author(s):  Dru Staltman, Eric Williamson
#**
#**  Summary  :  Cybran Bomber Fighter Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CAAMissileNaniteWeapon = import('/lua/cybranweapons.lua').CAAMissileNaniteWeapon
local CIFMissileCorsairWeapon = import('/lua/cybranweapons.lua').CIFMissileCorsairWeapon

DRA0202 = Class(CAirUnit) {
    Weapons = {
        AntiAirMissiles = Class(CAAMissileNaniteWeapon) {},
        GroundMissile = Class(CIFMissileCorsairWeapon) {
        
            IdleState = State (CIFMissileCorsairWeapon.IdleState) {
                Main = function(self)
                    CIFMissileCorsairWeapon.IdleState.Main(self)
                end,
                
                OnGotTarget = function(self)
                    self.unit:SetBreakOffTriggerMult(2.0)
                    self.unit:SetBreakOffDistanceMult(8.0)
                    local speedMulti = 0.67 * self.unit:GetSpeedModifier()   # [168]
                    self.unit:SetSpeedMult(speedMulti)
                    CIFMissileCorsairWeapon.IdleState.OnGotTarget(self)
                end,            
            },
        
            OnGotTarget = function(self)
                self.unit:SetBreakOffTriggerMult(2.0)
                self.unit:SetBreakOffDistanceMult(8.0)
                local speedMulti = 0.67 * self.unit:GetSpeedModifier()   # [168]
                self.unit:SetSpeedMult(speedMulti)
                CIFMissileCorsairWeapon.OnGotTarget(self)
            end,
        
            OnLostTarget = function(self)
                self.unit:SetBreakOffTriggerMult(1.0)
                self.unit:SetBreakOffDistanceMult(1.0)
                local speedMulti = self.unit:GetSpeedModifier()   # [168]
                self.unit:SetSpeedMult(speedMulti)
                CIFMissileCorsairWeapon.OnLostTarget(self)
            end,
        },
    },
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,
 
    RotateWings = function(self, target)
        if not self.LWingRotator then
            self.LWingRotator = CreateRotator(self, 'B01', 'x')
            self.Trash:Add(self.LWingRotator)
        end
        if not self.RWingRotator then
            self.RWingRotator = CreateRotator(self, 'B03', 'x')
            self.Trash:Add(self.RWingRotator)
        end
        local fighterAngle = 0
        local bomberAngle = -90
        local wingSpeed = 45
        if target and EntityCategoryContains(categories.AIR, target) then
            if self.LWingRotator then
                self.LWingRotator:SetSpeed(wingSpeed)
                self.LWingRotator:SetGoal(-fighterAngle)
            end
            if self.RWingRotator then
                self.RWingRotator:SetSpeed(wingSpeed)
                self.RWingRotator:SetGoal(fighterAngle)
            end
        else
            if self.LWingRotator then
                self.LWingRotator:SetSpeed(wingSpeed)
                self.LWingRotator:SetGoal(-bomberAngle)
            end
            if self.RWingRotator then
                self.RWingRotator:SetSpeed(wingSpeed)
                self.RWingRotator:SetGoal(bomberAngle)
            end                
        end  
    end, 
 
    OnCreate = function(self)
        CAirUnit.OnCreate(self)
        self:ForkThread(self.MonitorWings)
    end,
    
    MonitorWings = function(self)
        local airTarget
        while self and not self:IsDead() do
            WaitSeconds(1)
            local airTargetWeapon = self:GetWeaponByLabel('AntiAirMissiles')
            if airTargetWeapon then     
                airTarget = airTargetWeapon:GetCurrentTarget()
            end

            if airTarget then
                self:RotateWings(airTarget)                            
            else
                self:RotateWings(nil)
            end
        end
    end, 
	
	GetSpeedModifier = function(self)
        # this returns 1 when the plane has fuel or 0.25 when it doesn't have fuel. The movement speed penalty for
        # running out of fuel is 75% so planes with no fuel fly at 25% of max speed. [168]
        if self:GetFuelRatio() == 0 then
            return 0.25
        end
        return 1
    end,
    
}

TypeClass = DRA0202
