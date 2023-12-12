--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local CSeaFactoryUnit = import("/lua/cybranunits.lua").CSeaFactoryUnit
local CSeaFactoryUnitOnCreate = CSeaFactoryUnit.OnCreate
local CSeaFactoryUnitStartArmsMoving = CSeaFactoryUnit.StartArmsMoving
local CSeaFactoryUnitStopArmsMoving = CSeaFactoryUnit.StopArmsMoving

local Cybran1BuildArmComponent = import("/lua/sim/units/components/Cybran1BuildArmComponent.lua").Cybran1BuildArmComponent
local Cybran1BuildArmComponentOnCreate = Cybran1BuildArmComponent.OnCreate
local Cybran1BuildArmComponentStartArmsMoving = Cybran1BuildArmComponent.StartArmsMoving
local Cybran1BuildArmComponentStopArmsMoving = Cybran1BuildArmComponent.StopArmsMoving

---@class URB0103 : CSeaFactoryUnit, Cybran1BuildArmComponent
URB0103 = ClassUnit(CSeaFactoryUnit, Cybran1BuildArmComponent) {

    ArmBone1 = "Right_Arm03",

    ---@param self URB0103
    OnCreate = function(self)
        CSeaFactoryUnitOnCreate(self)
        Cybran1BuildArmComponentOnCreate(self)
    end,

    ---@param self URB0103
    StartArmsMoving = function(self)
        CSeaFactoryUnitStartArmsMoving(self)
        Cybran1BuildArmComponentStartArmsMoving(self)
    end,

    ---@param self URB0103
    StopArmsMoving = function(self)
        CSeaFactoryUnitStopArmsMoving(self)
        Cybran1BuildArmComponentStopArmsMoving(self)
    end,

    CreateBuildEffects = Cybran1BuildArmComponent.CreateBuildEffects,
    MovingArmsThread = Cybran1BuildArmComponent.MovingArmsThread,
}

TypeClass = URB0103
