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
        TrashBagAdd(trash,self.AnimManip)
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

            if not self.Rotator then
                self.Rotator = CreateRotator(self, 'Axis', 'z', nil, 0, 50, 0)
                TrashBagAdd(trash,self.Rotator)
            else
                self.Rotator:SetSpinDown(false)
            end
            self.Goal = Random(120, 300)

            -- Ambient effects
            self.AmbientEffects = CreateEmitterAtEntity(self, army, '/effects/emitters/aeon_t1_massfab_ambient_01_emit.bp')
            TrashBagAdd(trash,self.AmbientEffects)

            while not self.Dead do
                -- spin clockwise
                if not self.Clockwise then
                    self.Rotator:SetTargetSpeed(self.Goal)
                    self.Clockwise = true
                else
                    self.Rotator:SetTargetSpeed(-self.Goal)
                    self.Clockwise = false
                end
                WaitFor(self.Rotator)

                -- slow down to change directions
                self.Rotator:SetTargetSpeed(0)
                WaitFor(self.Rotator)
                self.Rotator:SetSpeed(0)
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

            if self.Open and self.Rotator then
                if self.Clockwise == true then
                    self.Rotator:SetSpinDown(true)
                    self.Rotator:SetTargetSpeed(self.Goal)
                else
                    self.Rotator:SetTargetSpeed(0)
                    WaitFor(self.Rotator)
                    self.Rotator:SetSpinDown(true)
                    self.Rotator:SetTargetSpeed(self.Goal)
                end
                WaitFor(self.Rotator)
            end

            if self.Open then
                self.AnimManip:SetRate(-1)
                self.Open = false
                WaitFor(self.AnimManip)
            end
        end,

        OnProductionUnpaused = function(self)
            AMassFabricationUnit.OnProductionUnpaused(self)
            ChangeState(self, self.OpenState)
        end,
    },
}

TypeClass = UAB1104
