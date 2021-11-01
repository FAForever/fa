--****************************************************************************
--**
--**  File     :  /cdimage/units/DRA0202/DRA0202_script.lua
--**  Author(s):  Dru Staltman, Eric Williamson
--**
--**  Summary  :  Cybran Bomber Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetBreakOffDistanceMult = UnitMethods.SetBreakOffDistanceMult
local UnitMethodsSetBreakOffTriggerMult = UnitMethods.SetBreakOffTriggerMult
local UnitMethodsSetScriptBit = UnitMethods.SetScriptBit
local UnitMethodsSetSpeedMult = UnitMethods.SetSpeedMult
-- End of automatically upvalued moho functions

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CAAMissileNaniteWeapon = import('/lua/cybranweapons.lua').CAAMissileNaniteWeapon
local CIFMissileCorsairWeapon = import('/lua/cybranweapons.lua').CIFMissileCorsairWeapon

DRA0202 = Class(CAirUnit)({
    Weapons = {
        AntiAirMissiles = Class(CAAMissileNaniteWeapon)({}),
        GroundMissile = Class(CIFMissileCorsairWeapon)({

            IdleState = State(CIFMissileCorsairWeapon.IdleState)({
                Main = function(self)
                    CIFMissileCorsairWeapon.IdleState.Main(self)
                end,

                OnGotTarget = function(self)
                    if self.unit:IsUnitState('Moving') then
                        UnitMethodsSetSpeedMult(self.unit, 1.0)
                    else
                        UnitMethodsSetBreakOffTriggerMult(self.unit, 2.0)
                        UnitMethodsSetBreakOffDistanceMult(self.unit, 8.0)
                        UnitMethodsSetSpeedMult(self.unit, 0.67)
                        CIFMissileCorsairWeapon.IdleState.OnGotTarget(self)
                    end
                end,
            }),

            OnGotTarget = function(self)
                if self.unit:IsUnitState('Moving') then
                    UnitMethodsSetSpeedMult(self.unit, 1.0)
                else
                    UnitMethodsSetBreakOffTriggerMult(self.unit, 2.0)
                    UnitMethodsSetBreakOffDistanceMult(self.unit, 8.0)
                    UnitMethodsSetSpeedMult(self.unit, 0.67)
                    CIFMissileCorsairWeapon.OnGotTarget(self)
                end
            end,

            OnLostTarget = function(self)
                UnitMethodsSetBreakOffTriggerMult(self.unit, 1.0)
                UnitMethodsSetBreakOffDistanceMult(self.unit, 1.0)
                UnitMethodsSetSpeedMult(self.unit, 1.0)
                CIFMissileCorsairWeapon.OnLostTarget(self)
            end,
        }),
    },
    OnStopBeingBuilt = function(self, builder, layer)
        CAirUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionInactive()
        UnitMethodsSetScriptBit(self, 'RULEUTC_StealthToggle', true)
        EntityMethodsRequestRefreshUI(self)
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
        while self and not self.Dead do
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

})

TypeClass = DRA0202
