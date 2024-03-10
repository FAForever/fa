--****************************************************************************
--**
--**  File     :  /cdimage/units/DEA0202/DEA0202_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Matt Vainio
--**
--**  Summary  :  UEF Supersonic Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TAirToAirLinkedRailgun = import("/lua/terranweapons.lua").TAirToAirLinkedRailgun
local TIFCarpetBombWeapon = import("/lua/terranweapons.lua").TIFCarpetBombWeapon

-- upvalaue for perfomance
local TrashBagAdd = TrashBag.Add

---@class DEA0202 : TAirUnit
DEA0202 = ClassUnit(TAirUnit) {
    Weapons = {
        RightBeam = ClassWeapon(TAirToAirLinkedRailgun) {},
        LeftBeam = ClassWeapon(TAirToAirLinkedRailgun) {},
        Bomb = ClassWeapon(TIFCarpetBombWeapon) {

            IdleState = State(TIFCarpetBombWeapon.IdleState) {

                ---@param self DEA0202
                Main = function(self)
                    TIFCarpetBombWeapon.IdleState.Main(self)
                end,

                ---@param self DEA0202
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

                ---@param self DEA0202
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
        local trash = self.Trash

        if not self.LWingRotator then
            self.LWingRotator = CreateRotator(self, 'Left_Wing', 'y')
            TrashBagAdd(trash,self.LWingRotator)
        end
        if not self.RWingRotator then
            self.RWingRotator = CreateRotator(self, 'Right_Wing', 'y')
            TrashBagAdd(trash,self.RWingRotator)
        end
        local fighterAngle = -105
        local bomberAngle = 0
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
        TAirUnit.OnCreate(self)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread(self.MonitorWings, self))
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

            WaitSeconds(1)
        end
    end,
}

TypeClass = DEA0202
