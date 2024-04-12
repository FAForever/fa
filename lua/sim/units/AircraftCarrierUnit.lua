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

local SeaUnit = import("/lua/sim/units/seaunit.lua").SeaUnit
local SeaUnitOnKilled = SeaUnit.OnKilled
local SeaUnitOnTransportAttach = SeaUnit.OnTransportAttach
local SeaUnitOnTransportDetach = SeaUnit.OnTransportDetach
local SeaUnitOnAttachedKilled = SeaUnit.OnAttachedKilled
local SeaUnitOnStartTransportLoading = SeaUnit.OnStartTransportLoading
local SeaUnitOnStopTransportLoading = SeaUnit.OnStopTransportLoading

local BaseTransport = import("/lua/sim/units/components/transportunitcomponent.lua").BaseTransport
local BaseTransportOnTransportAttach = BaseTransport.OnTransportAttach
local BaseTransportOnTransportDetach = BaseTransport.OnTransportDetach
local BaseTransportOnAttachedKilled = BaseTransport.OnAttachedKilled
local BaseTransportOnStartTransportLoading = BaseTransport.OnStartTransportLoading
local BaseTransportOnStopTransportLoading = BaseTransport.OnStopTransportLoading
local BaseTransportDestroyedOnTransport = BaseTransport.DestroyedOnTransport

---@class AircraftCarrier : SeaUnit, BaseTransport
AircraftCarrier = ClassUnit(SeaUnit, BaseTransport) {

    DisableIntelOfCargo = true,

    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        SeaUnitOnTransportAttach(self, attachBone, unit)
        BaseTransportOnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        SeaUnitOnTransportDetach(self, attachBone, unit)
        BaseTransportOnTransportDetach(self, attachBone, unit)
    end,

    OnAttachedKilled = function(self, attached)
        SeaUnitOnAttachedKilled(self, attached)
        BaseTransportOnAttachedKilled(self, attached)
    end,

    ---@param self AircraftCarrier
    OnStartTransportLoading = function(self)
        SeaUnitOnStartTransportLoading(self)
        BaseTransportOnStartTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    OnStopTransportLoading = function(self)
        SeaUnitOnStopTransportLoading(self)
        BaseTransportOnStopTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    DestroyedOnTransport = function(self)
        -- SeaUnit.DestroyedOnTransport(self)
        BaseTransportDestroyedOnTransport(self)
    end,

    ---@param self AircraftCarrier
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SaveCargoMass()
        SeaUnitOnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}
