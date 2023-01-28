-- File     :  /cdimage/units/UEB1104/UEB1104_script.lua
-- Author(s):  Jessica St. Croix, David Tomandl
-- Summary  :  UEF Mass Fabricator
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TMassFabricationUnit = import("/lua/terranunits.lua").TMassFabricationUnit

---@class UEB1104 : TMassFabricationUnit
UEB1104 = ClassUnit(TMassFabricationUnit) {
    DestructionPartsLowToss = { 'B01', 'B02', },
    DestructionPartsChassisToss = { 'UEB1104' },
    GoToActive = false,
    Closed = false,

    OnCreate = function(self)
        TMassFabricationUnit.OnCreate(self)
        self.SliderManip = CreateSlider(self, 'B03')
        ChangeState(self, self.CreateState)
    end,

    CreateState = State {
        Main = function(self)
            self:HideBone('UEB1104', true)
            self.SliderManip:SetGoal(0, -1, 0)
            self.SliderManip:SetSpeed(-1)
            WaitFor(self.SliderManip)
            self:ShowBone('UEB1104', true)
            self.Closed = true
            if self.GoToActive == true then
                ChangeState(self, self.ActiveState)
            end
        end,
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TMassFabricationUnit.OnStopBeingBuilt(self, builder, layer)
        if self.Closed == true then
            ChangeState(self, self.ActiveState)
        else
            self.GoToActive = true
            ChangeState(self, self.CreateState)
        end
    end,

    ActiveState = State {
        Main = function(self)
            local myBlueprint = self.Blueprint
            if myBlueprint.Audio.Activate then
                self:PlaySound(myBlueprint.Audio.Activate)
            end
            self:PlayUnitAmbientSound('ActiveLoop')
            self.SliderManip:SetGoal(0, 0, 0)
            self.SliderManip:SetSpeed(3)
            WaitFor(self.SliderManip)
        end,

        OnConsumptionInActive = function(self)
            TMassFabricationUnit.OnConsumptionInActive(self)
            ChangeState(self, self.InactiveState)
        end,
    },

    InactiveState = State {
        Main = function(self)
            self:StopUnitAmbientSound('ActiveLoop')
            self.SliderManip:SetGoal(0, -1, 0)
            self.SliderManip:SetSpeed(3)
            WaitFor(self.SliderManip)
        end,

        OnConsumptionActive = function(self)
            TMassFabricationUnit.OnConsumptionActive(self)
            ChangeState(self, self.ActiveState)
        end,
    },
}
TypeClass = UEB1104
