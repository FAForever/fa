-- File     :  /cdimage/units/DEA0202/DEA0202_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
-- Summary  :  UEF Supersonic Fighter Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TAirToAirLinkedRailgun = import("/lua/terranweapons.lua").TAirToAirLinkedRailgun
local TIFCarpetBombWeapon = import("/lua/terranweapons.lua").TIFCarpetBombWeapon

---@class DEA0202 : TAirUnit
DEA0202 = ClassUnit(TAirUnit) {
    Weapons = {
        RightBeam = ClassWeapon(TAirToAirLinkedRailgun) {},
        LeftBeam = ClassWeapon(TAirToAirLinkedRailgun) {},
        Bomb = ClassWeapon(TIFCarpetBombWeapon) {

            IdleState = State(TIFCarpetBombWeapon.IdleState) {
                Main = function(self)
                    TIFCarpetBombWeapon.IdleState.Main(self)
                end,

                OnGotTarget = function(self)
                    local unit = self.unit
                    if unit:IsUnitState('Moving') then
                        unit:SetSpeedMult(1.0)
                    else
                        unit:SetBreakOffTriggerMult(2.0)
                        unit:SetBreakOffDistanceMult(8.0)
                        unit:SetSpeedMult(0.67)
                        TIFCarpetBombWeapon.IdleState.OnGotTarget(self)
                    end
                end,
                OnFire = function(self)
                    local unit = self.unit
                    unit:RotateWings(self:GetCurrentTarget())
                    TIFCarpetBombWeapon.IdleState.OnFire(self)
                end,
            },

            OnFire = function(self)
                local unit = self.unit
                unit:RotateWings(self:GetCurrentTarget())
                TIFCarpetBombWeapon.OnFire(self)
            end,

            OnGotTarget = function(self)
                local unit = self.unit
                if unit:IsUnitState('Moving') then
                    unit:SetSpeedMult(1.0)
                else
                    unit:SetBreakOffTriggerMult(2.0)
                    unit:SetBreakOffDistanceMult(8.0)
                    unit:SetSpeedMult(0.67)
                    TIFCarpetBombWeapon.OnGotTarget(self)
                end
            end,

            OnLostTarget = function(self)
                local unit = self.unit
                unit:SetBreakOffTriggerMult(1.0)
                unit:SetBreakOffDistanceMult(1.0)
                unit:SetSpeedMult(1.0)
                TIFCarpetBombWeapon.OnLostTarget(self)
            end,
        },
    },

    RotateWings = function(self, target)
        local LWingRotator = self.LWingRotator
        local RWingRotator = self.LWingRotator
        if not LWingRotator then
            LWingRotator = CreateRotator(self, 'Left_Wing', 'y')
            self.Trash:Add(LWingRotator)
        end
        if not RWingRotator then
            RWingRotator = CreateRotator(self, 'Right_Wing', 'y')
            self.Trash:Add(RWingRotator)
        end
        local fighterAngle = -105
        local bomberAngle = 0
        local wingSpeed = 45
        if target and EntityCategoryContains(categories.AIR, target) then
            if LWingRotator then
                LWingRotator:SetSpeed(wingSpeed)
                LWingRotator:SetGoal(-fighterAngle)
            end
            if RWingRotator then
                RWingRotator:SetSpeed(wingSpeed)
                RWingRotator:SetGoal(fighterAngle)
            end
        else
            if LWingRotator then
                LWingRotator:SetSpeed(wingSpeed)
                LWingRotator:SetGoal(-bomberAngle)
            end
            if RWingRotator then
                RWingRotator:SetSpeed(wingSpeed)
                RWingRotator:SetGoal(bomberAngle)
            end
        end
    end,

    OnCreate = function(self)
        TAirUnit.OnCreate(self)
        self.Trash:Add(ForkThread(self.MonitorWings, self))
    end,

    MonitorWings = function(self)
        local airTargetRight
        local airTargetLeft
        while self and not self.Dead do
            local airTargetWeapon = self:GetWeaponByLabel('RightBeam')
            if airTargetWeapon then
                airTargetRight = airTargetWeapon:GetCurrentTarget()
            end
            airTargetWeapon = self:GetWeaponByLabel('LeftBeam')
            if airTargetWeapon then
                airTargetLeft = airTargetWeapon:GetCurrentTarget()
            end

            if airTargetRight then
                self:RotateWings(airTargetRight)
            elseif airTargetLeft then
                self:RotateWings(airTargetLeft)
            else
                self:RotateWings(nil)
            end
            WaitTicks(11)
        end
    end,
}
TypeClass = DEA0202
