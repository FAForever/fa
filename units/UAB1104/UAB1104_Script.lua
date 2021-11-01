-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local CRotateManipulatorMethods = _G.moho.RotateManipulator
local CRotateManipulatorMethodsSetSpinDown = CRotateManipulatorMethods.SetSpinDown
local CRotateManipulatorMethodsSetTargetSpeed = CRotateManipulatorMethods.SetTargetSpeed
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/UAB1104/UAB1104_script.lua
--#**  Author(s):  Jessica St. Croix, David Tomandl, John Comes
--#**
--#**  Summary  :  Aeon Mass Fabricator
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local AMassFabricationUnit = import('/lua/aeonunits.lua').AMassFabricationUnit

UAB1104 = Class(AMassFabricationUnit)({
    OnCreate = function(self)
        AMassFabricationUnit.OnCreate(self)
        self.Damaged = false
        self.Open = false
        self.AnimFinished = true
        self.RotFinished = true
        self.Clockwise = true
        self.AnimManip = CreateAnimator(self)
        self.Trash:Add(self.AnimManip)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AMassFabricationUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.OpenState)
    end,

    OpenState = State({
        Main = function(self)
            if self.AmbientEffects then
                self.AmbientEffects:Destroy()
                self.AmbientEffects = nil
            end

            if not self.Open then
                self.Open = true
                CAnimationManipulatorMethodsPlayAnim(self.AnimManip, self:GetBlueprint().Display.AnimationOpen)
                CAnimationManipulatorMethodsSetRate(self.AnimManip, 1)
                WaitFor(self.AnimManip)
            end

            if not self.Rotator then
                self.Rotator = CreateRotator(self, 'Axis', 'z', nil, 0, 50, 0)
                self.Trash:Add(self.Rotator)
            else
                CRotateManipulatorMethodsSetSpinDown(self.Rotator, false)
            end
            self.Goal = Random(120, 300)

            -- Ambient effects
            self.AmbientEffects = CreateEmitterAtEntity(self, self.Army, '/effects/emitters/aeon_t1_massfab_ambient_01_emit.bp')
            self.Trash:Add(self.AmbientEffects)

            while not self.Dead do
                -- spin clockwise
                if not self.Clockwise then
                    CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, self.Goal)
                    self.Clockwise = true
                else
                    CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, -self.Goal)
                    self.Clockwise = false
                end
                WaitFor(self.Rotator)

                -- slow down to change directions
                CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, 0)
                WaitFor(self.Rotator)
                self.Rotator:SetSpeed(0)
                self.Goal = Random(120, 300)
            end
        end,

        OnProductionPaused = function(self)
            AMassFabricationUnit.OnProductionPaused(self)
            ChangeState(self, self.InActiveState)
        end,
    }),

    InActiveState = State({
        Main = function(self)
            if self.AmbientEffects then
                self.AmbientEffects:Destroy()
                self.AmbientEffects = nil
            end

            if self.Open then
                if self.Clockwise == true then
                    CRotateManipulatorMethodsSetSpinDown(self.Rotator, true)
                    CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, self.Goal)
                else
                    CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, 0)
                    WaitFor(self.Rotator)
                    CRotateManipulatorMethodsSetSpinDown(self.Rotator, true)
                    CRotateManipulatorMethodsSetTargetSpeed(self.Rotator, self.Goal)
                end
                WaitFor(self.Rotator)
            end

            if self.Open then
                CAnimationManipulatorMethodsSetRate(self.AnimManip, -1)
                self.Open = false
                WaitFor(self.AnimManip)
            end
        end,

        OnProductionUnpaused = function(self)
            AMassFabricationUnit.OnProductionUnpaused(self)
            ChangeState(self, self.OpenState)
        end,
    }),
})

TypeClass = UAB1104
