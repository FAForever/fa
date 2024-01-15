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

local Cybran3BuildArmComponent = import("/lua/sim/units/components/Cybran3BuildArmComponent.lua").Cybran3BuildArmComponent
local Cybran3BuildArmComponentOnCreate = Cybran3BuildArmComponent.OnCreate
local Cybran3BuildArmComponentStopArmsMoving = Cybran3BuildArmComponent.StopArmsMoving

---@class ZRB0603 : CSeaFactoryUnit, Cybran3BuildArmComponent
ZRB0603 = ClassUnit(CSeaFactoryUnit, Cybran3BuildArmComponent) {

    ArmBone1 = "Right_Arm03",
    ArmBone2 = "Right_Arm02",
    ArmBone3 = "Right_Arm01",

    ArmOffset1 = 2.4249, -- LOG(self:GetPosition('Attachpoint')[3] - self:GetPosition(self.ArmBone1)[3])
    ArmOffset2 = 1.2151, -- LOG(self:GetPosition('Attachpoint')[3] - self:GetPosition(self.ArmBone2)[3])
    ArmOffset3 = 0.0259, -- LOG(self:GetPosition('Attachpoint')[3] - self:GetPosition(self.ArmBone3)[3])

    ---@param self ZRB0603
    OnCreate = function(self)
        CSeaFactoryUnitOnCreate(self)
        Cybran3BuildArmComponentOnCreate(self)
    end,

    ---@param self ZRB0603
    StartArmsMoving = function(self)
        CSeaFactoryUnitStartArmsMoving(self)
    end,

    ---@param self ZRB0603
    StopArmsMoving = function(self)
        CSeaFactoryUnitStopArmsMoving(self)
        Cybran3BuildArmComponentStopArmsMoving(self)
    end,

    MovingArmsThread = Cybran3BuildArmComponent.MovingArmsThread,
    CreateBuildEffects = Cybran3BuildArmComponent.CreateBuildEffects,
}

TypeClass = ZRB0603
