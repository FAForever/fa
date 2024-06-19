-- File     :  /cdimage/units/UAB1104/UAB1104_script.lua
-- Author(s):  Jessica St. Croix, David Tomandl, John Comes
-- Summary  :  Aeon Mass Fabricator
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local AMassFabricationUnit = import("/lua/aeonunits.lua").AMassFabricationUnit

-- upvalue for perfomance
local CreateAnimator = CreateAnimator
local CreateRotator = CreateRotator
local Random = Random
local WaitFor = WaitFor
local TrashBagAdd = TrashBag.Add


---@class UAB1104 : AMassFabricationUnit
---@field Damaged boolean
---@field Open boolean
---@field AnimFinished boolean
---@field RotFinished boolean
---@field Clockwise boolean 
---@field AnimManip moho.AnimationManipulator
---@field Goal number
UAB1104 = ClassUnit(AMassFabricationUnit) {
    OnCreate = function(self)
        AMassFabricationUnit.OnCreate(self)
        local trash = self.Trash

        self.Damaged = false
        self.Open = false
        self.AnimFinished = true
        self.RotFinished = true
        self.Clockwise = true
        self.AnimManip = CreateAnimator(self)
        TrashBagAdd(trash, self.AnimManip)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        AMassFabricationUnit.OnStopBeingBuilt(self,builder,layer)
        ChangeState(self, self.OpenState)
    end,

    OpenState = State {
        Main = function(self)
            local bp = self.Blueprint
            local army = self.Army
            local trash = self.Trash

            if self.AmbientEffects then
                self.AmbientEffects:Destroy()
                self.AmbientEffects = nil
            end

            if not self.Open then
                self.Open = true
                self.AnimManip:PlayAnim(bp.Display.AnimationOpen):SetRate(1)
                WaitFor(self.AnimManip)
            end

            local rotator = self.Rotator
            if not rotator then
                rotator = CreateRotator(self, 'Axis', 'z', nil, 0, 50, 0)
                TrashBagAdd(trash, rotator)
                self.Rotator = rotator
            else
                rotator:SetSpinDown(false)
            end
            self.Goal = Random(120, 300)

            -- Ambient effects
            self.AmbientEffects = CreateEmitterAtEntity(self, army, '/effects/emitters/aeon_t1_massfab_ambient_01_emit.bp')
            TrashBagAdd(trash, self.AmbientEffects)

            while not self.Dead do
                -- spin clockwise
                if not self.Clockwise then
                    rotator:SetTargetSpeed(self.Goal)
                    self.Clockwise = true
                else
                    rotator:SetTargetSpeed(-self.Goal)
                    self.Clockwise = false
                end
                WaitFor(rotator)

                -- slow down to change directions
                rotator:SetTargetSpeed(0)
                WaitFor(rotator)
                rotator:SetSpeed(0)
                self.Goal = Random(120, 300)
            end
        end,

        OnProductionPaused = function(self)
            AMassFabricationUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    },

    InActiveState = State {
        Main = function(self)
            if self.AmbientEffects then
                self.AmbientEffects:Destroy()
                self.AmbientEffects = nil
            end

            if self.Open then
                local rotator = self.Rotator
                if rotator then
                    if self.Clockwise == true then
                        rotator:SetSpinDown(true)
                        rotator:SetTargetSpeed(self.Goal)
                    else
                        rotator:SetTargetSpeed(0)
                        WaitFor(rotator)
                        rotator:SetSpinDown(true)
                        rotator:SetTargetSpeed(self.Goal)
                    end
                    WaitFor(rotator)
                end

                local animManip = self.AnimManip

                animManip:SetRate(-1)
                self.Open = false
                WaitFor(animManip)
            end
        end,

        OnProductionUnpaused = function(self)
            AMassFabricationUnit.OnProductionUnpaused(self)
            ChangeState(self, self.OpenState)
        end,
    },
}

TypeClass = UAB1104
