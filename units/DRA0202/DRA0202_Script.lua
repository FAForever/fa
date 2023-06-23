-- File     :  /cdimage/units/DRA0202/DRA0202_script.lua
-- Author(s):  Dru Staltman, Eric Williamson
-- Summary  :  Cybran Bomber Fighter Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon
local CIFMissileCorsairWeapon = import("/lua/cybranweapons.lua").CIFMissileCorsairWeapon

---@class DRA0202 : CAirUnit
DRA0202 = ClassUnit(CAirUnit) {
    Weapons = {
        AntiAirMissiles = ClassWeapon(CAAMissileNaniteWeapon) {},
        GroundMissile = ClassWeapon(CIFMissileCorsairWeapon) {

            IdleState = State(CIFMissileCorsairWeapon.IdleState) {
                Main = function(self)
                    CIFMissileCorsairWeapon.IdleState.Main(self)
                end,

                OnGotTarget = function(self)
                    local unit = self.unit
                    if unit:IsUnitState('Moving') then
                        unit:SetSpeedMult(1.0)
                    else
                        unit:SetBreakOffTriggerMult(2.0)
                        unit:SetBreakOffDistanceMult(8.0)
                        unit:SetSpeedMult(0.67)
                        CIFMissileCorsairWeapon.IdleState.OnGotTarget(self)
                    end
                end,
            },

            OnGotTarget = function(self)
                local unit = self.unit
                if unit:IsUnitState('Moving') then
                    unit:SetSpeedMult(1.0)
                else
                    unit:SetBreakOffTriggerMult(2.0)
                    unit:SetBreakOffDistanceMult(8.0)
                    unit:SetSpeedMult(0.67)
                    CIFMissileCorsairWeapon.OnGotTarget(self)
                end
            end,

            OnLostTarget = function(self)
                local unit = self.unit
                unit:SetBreakOffTriggerMult(1.0)
                unit:SetBreakOffDistanceMult(1.0)
                unit:SetSpeedMult(1.0)
                CIFMissileCorsairWeapon.OnLostTarget(self)
            end,
        },
    },
    
    OnStopBeingBuilt = function(self, builder, layer)
        CAirUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionInactive()
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self:RequestRefreshUI()
    end,

    RotateWings = function(self, target)
        local lWingRotator = self.LWingRotator
        if not lWingRotator then
            lWingRotator = CreateRotator(self, 'B01', 'x')
            self.LWingRotator = lWingRotator
            self.Trash:Add(lWingRotator)
        end
        local rWingRotator = self.RWingRotator
        if not rWingRotator then
            rWingRotator = CreateRotator(self, 'B03', 'x')
            self.RWingRotator = rWingRotator
            self.Trash:Add(rWingRotator)
        end
        
        local fighterAngle = 0
        local bomberAngle = -90
        local wingSpeed = 45
        
        lWingRotator:SetSpeed(wingSpeed)
        rWingRotator:SetSpeed(wingSpeed)
        if target and EntityCategoryContains(categories.AIR, target) then
            lWingRotator:SetGoal(fighterAngle)
            rWingRotator:SetGoal(fighterAngle)
        else
            lWingRotator:SetGoal(bomberAngle)
            rWingRotator:SetGoal(bomberAngle)
        end
    end,

    OnCreate = function(self)
        CAirUnit.OnCreate(self)
        self.Trash:Add(ForkThread(self.MonitorWings,self))
    end,

    MonitorWings = function(self)
        local airTarget
        while self and not self.Dead do
            local airTargetWeapon = self:GetWeaponByLabel('AntiAirMissiles')
            if airTargetWeapon then
                airTarget = airTargetWeapon:GetCurrentTarget()
            end

            if airTarget then
                self:RotateWings(airTarget)
            else
                self:RotateWings(nil)
            end
            WaitTicks(11)
        end
    end,
}
TypeClass = DRA0202