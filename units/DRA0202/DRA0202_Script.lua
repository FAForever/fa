--****************************************************************************
--**
--**  File     :  /cdimage/units/DRA0202/DRA0202_script.lua
--**  Author(s):  Dru Staltman, Eric Williamson
--**
--**  Summary  :  Cybran Bomber Fighter Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon
local CIFMissileCorsairWeapon = import("/lua/cybranweapons.lua").CIFMissileCorsairWeapon

-- upvalaue for perfomance
local TrashBagAdd = TrashBag.Add
local WaitSeconds = WaitSeconds
local EntityCategoryContains = EntityCategoryContains
local CreateRotator = CreateRotator

---@class DRA0202 : CAirUnit
DRA0202 = ClassUnit(CAirUnit) {
    Weapons = {
        AntiAirMissiles = ClassWeapon(CAAMissileNaniteWeapon) {},
        ---@class DRA0202_GroundMissile : CIFMissileCorsairWeapon
        GroundMissile = ClassWeapon(CIFMissileCorsairWeapon) {

            IdleState = State(CIFMissileCorsairWeapon.IdleState) {
                ---@param self DRA0202_GroundMissile
                Main = function(self)
                    CIFMissileCorsairWeapon.IdleState.Main(self)
                end,
                ---@param self DRA0202_GroundMissile
                OnGotTarget = function(self)
                    if self.unit:IsUnitState('Moving') then
                        self.unit:SetSpeedMult(1.0)
                    else
                        self.unit:SetBreakOffTriggerMult(2.0)
                        self.unit:SetBreakOffDistanceMult(8.0)
                        self.unit:SetSpeedMult(0.67)
                        CIFMissileCorsairWeapon.IdleState.OnGotTarget(self)
                    end
                end,
            },

            ---@param self DRA0202_GroundMissile
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

            ---@param self DRA0202_GroundMissile
            OnLostTarget = function(self)
                local unit = self.unit

                unit:SetBreakOffTriggerMult(1.0)
                unit:SetBreakOffDistanceMult(1.0)
                unit:SetSpeedMult(1.0)
                CIFMissileCorsairWeapon.OnLostTarget(self)
            end,
        },
    },

    ---@param self DRA0202
    ---@param target? Unit | Blip
    RotateWings = function(self, target)
        local trash = self.Trash

        if not self.LWingRotator then
            self.LWingRotator = CreateRotator(self, 'B01', 'x')
            TrashBagAdd(trash, self.LWingRotator)
        end
        if not self.RWingRotator then
            self.RWingRotator = CreateRotator(self, 'B03', 'x')
            TrashBagAdd(trash, self.RWingRotator)
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

    ---@param self DRA0202
    OnCreate = function(self)
        CAirUnit.OnCreate(self)
        local trash = self.Trash
        TrashBagAdd(trash, ForkThread(self.MonitorWings, self))
    end,

    ---@param self DRA0202
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

            WaitSeconds(1)
        end
    end,
}

TypeClass = DRA0202
