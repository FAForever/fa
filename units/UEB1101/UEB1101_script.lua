-- File     :  /cdimage/units/UEB1101/UEB1101_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Terran Power Generator Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TEnergyCreationUnit = import("/lua/terranunits.lua").TEnergyCreationUnit

---@class UEB1101 : TEnergyCreationUnit
UEB1101 = ClassUnit(TEnergyCreationUnit) {
    OnCreate = function(self)
        TEnergyCreationUnit.OnCreate(self)
        local Trash = self.Trash

        self.Sliders = {
            Slider1 = CreateSlider(self, 'B03'),
            Slider2 = CreateSlider(self, 'B04'),
            Slider3 = CreateSlider(self, 'B05'),
            Slider4 = CreateSlider(self, 'B06'),
        }
        self.Spinners = {
            Spinner1 = CreateRotator(self, 'B01', 'y', nil, 0, 60, 360):SetTargetSpeed(0),
            Spinner2 = CreateRotator(self, 'B02', 'y', nil, 0, 30, 360):SetTargetSpeed(0),
        }
        for k, v in self.Sliders do
            Trash:Add(v)
        end
        for k, v in self.Spinners do
            Trash:Add(v)
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        TEnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.OpeningState)
    end,

    OnDestroy = function(self)
        TEnergyCreationUnit.OnDestroy(self)
        ChangeState(self, self.DeadState)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        TEnergyCreationUnit.OnDamage(self, instigator, amount, vector, damageType)
        self.DamageSeconds = 10
        ChangeState(self, self.ClosingState)
    end,

    OpeningState = State {
        Main = function(self)
            local bp = self.Blueprint
            local Sliders = self.Sliders
            local Spinners = self.Spinners

            if bp.Audio.Activate then
                self:PlaySound(bp.Audio.Activate)
            end

            Sliders.Slider1:SetGoal(0, 0, -3)
            Sliders.Slider1:SetSpeed(5)
            Sliders.Slider2:SetGoal(-3, 0, 0)
            Sliders.Slider2:SetSpeed(5)
            Sliders.Slider3:SetGoal(0, 0, 3)
            Sliders.Slider3:SetSpeed(5)
            Sliders.Slider4:SetGoal(3, 0, 0)
            Sliders.Slider4:SetSpeed(5)
            for k, v in Sliders do
                WaitFor(v)
            end
            for k, v in Spinners do
                v:SetSpinDown(false)
            end
            Spinners.Spinner1:SetTargetSpeed(180)
            Spinners.Spinner2:SetTargetSpeed(-90)
            WaitTicks(51)
            ChangeState(self, self.IdleOpenState)
        end,
    },

    IdleOpenState = State {
        Main = function(self)
            self.Effect1 = CreateAttachedEmitter(self, 'Exhaust01', self.Army,
                '/effects/emitters/economy_electricity_01_emit.bp')
            self.Trash:Add(self.Effecct1)
        end,
    },

    ClosingState = State {
        Main = function(self)
            if self.Effect1 then
                self.Effect1:Destroy()
            end
            for k, v in self.Spinners do
                v:SetSpinDown(true)
                v:SetTargetSpeed(360)
            end
            for k, v in self.Spinners do
                WaitFor(v)
            end
            for k, v in self.Sliders do
                v:SetGoal(0, 0, 0)
                v:SetSpeed(20)
            end
            for k, v in self.Sliders do
                WaitFor(v)
            end
            ChangeState(self, self.ClosedIdleState)
        end,
    },

    ClosedIdleState = State {
        Main = function(self)
            local Damage = self.DamageSeconds
            while Damage > 0 do
                WaitTicks(11)
                Damage = Damage - 1
            end
            ChangeState(self, self.OpeningState)
        end,

        OnDamage = function(self, instigator, amount, vector, damageType)
            TEnergyCreationUnit.OnDamage(self, instigator, amount, vector, damageType)
            self.DamageSeconds = 10
        end,
    },
}

TypeClass = UEB1101
