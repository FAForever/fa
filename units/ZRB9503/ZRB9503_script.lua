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

local Cybran2BuildArmComponent = import("/lua/sim/units/components/Cybran2BuildArmComponent.lua").Cybran2BuildArmComponent
local Cybran2BuildArmComponentOnCreate = Cybran2BuildArmComponent.OnCreate
local Cybran2BuildArmComponentStartArmsMoving = Cybran2BuildArmComponent.StartArmsMoving
local Cybran2BuildArmComponentStopArmsMoving = Cybran2BuildArmComponent.StopArmsMoving

---@class ZRB9503 : CSeaFactoryUnit, Cybran2BuildArmComponent
ZRB9503 = ClassUnit(CSeaFactoryUnit, Cybran2BuildArmComponent) {

    ArmBone1 = "Right_Arm02",
    ArmBone2 = "Right_Arm03",

    ---@param self ZRB9503
    OnCreate = function(self)
        CSeaFactoryUnitOnCreate(self)
        Cybran2BuildArmComponentOnCreate(self)
    end,

    ---@param self ZRB9503
    StartArmsMoving = function(self)
        CSeaFactoryUnitStartArmsMoving(self)
        Cybran2BuildArmComponentStartArmsMoving(self)
    end,

    ---@param self ZRB9503
    StopArmsMoving = function(self)
        CSeaFactoryUnitStopArmsMoving(self)
        Cybran2BuildArmComponentStopArmsMoving(self)
    end,

    CreateBuildEffects = Cybran2BuildArmComponent.CreateBuildEffects,
    MovingArmsThread = Cybran2BuildArmComponent.MovingArmsThread,
}

TypeClass = ZRB9503
