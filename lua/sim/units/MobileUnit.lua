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

local Unit = import("/lua/sim/unit.lua").Unit
local UnitOnCreate = Unit.OnCreate
local UnitOnKilled = Unit.OnKilled
local UnitDestroyAllTrashBags = Unit.DestroyAllTrashBags
local UnitCreateMovementEffects = Unit.CreateMovementEffects
local UnitDestroyMovementEffects = Unit.DestroyMovementEffects
local UnitStartBeingBuiltEffects = Unit.StartBeingBuiltEffects
local UnitOnStopBeingBuilt = Unit.OnStopBeingBuilt
local UnitOnLayerChange = Unit.OnLayerChange
local UnitOnDetachedFromTransport = Unit.OnDetachedFromTransport

local TreadComponent = import("/lua/defaultcomponents.lua").TreadComponent
local TreadComponentOnCreate = TreadComponent.OnCreate
local TreadComponentCreateMovementEffects = TreadComponent.CreateMovementEffects
local TreadComponentDestroyMovementEffects = TreadComponent.DestroyMovementEffects

-- pre-import for performance
local CreateUEFUnitBeingBuiltEffects = import("/lua/effectutilities.lua").CreateUEFUnitBeingBuiltEffects

-- upvalue scope for performance
local TrashBag = TrashBag

---@class MobileUnit : Unit, TreadComponent
---@field MovementEffectsBag TrashBag
---@field TopSpeedEffectsBag TrashBag
---@field BeamExhaustEffectsBag TrashBag
---@field TransportBeamEffectsBag? TrashBag
---@field OnBeingBuiltEffectsBag? TrashBag
MobileUnit = ClassUnit(Unit, TreadComponent) {

    ---@param self MobileUnit
    OnCreate = function(self)
        UnitOnCreate(self)
        TreadComponentOnCreate(self)

        self.MovementEffectsBag = TrashBag()
        self.TopSpeedEffectsBag = TrashBag()
        self.BeamExhaustEffectsBag = TrashBag()
    end,

    ---@param self MobileUnit
    DestroyAllTrashBags = function(self)
        UnitDestroyAllTrashBags(self)

        self.MovementEffectsBag:Destroy()
        self.TopSpeedEffectsBag:Destroy()
        self.BeamExhaustEffectsBag:Destroy()

        -- only exists if unit is transported
        local transportBeamEffectsBag = self.TransportBeamEffectsBag
        if transportBeamEffectsBag then
            transportBeamEffectsBag:Destroy()
        end
    end,

    ---@param self MobileUnit
    ---@param effectsBag TrashBag
    ---@param typeSuffix string
    ---@param terrainType string
    CreateMovementEffects = function(self, effectsBag, typeSuffix, terrainType)
        UnitCreateMovementEffects(self, effectsBag, typeSuffix, terrainType)
        TreadComponentCreateMovementEffects(self)
    end,

    ---@param self MobileUnit
    DestroyMovementEffects = function(self)
        UnitDestroyMovementEffects(self)
        TreadComponentDestroyMovementEffects(self)
    end,

    ---@param self MobileUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.willBeKilledByTransport then
            self.willBeKilledByTransport = false
        else
            UnitOnKilled(self, instigator, type, overkillRatio)
        end
    end,

    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        UnitStartBeingBuiltEffects(self, builder, layer)
        if self.Blueprint.FactionCategory == 'UEF' then
            CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
    end,

    -- Units with layer change effects (amphibious units like Megalith) need
    -- those changes applied when build ends, so we need to trigger the
    -- layer change event
    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        UnitOnStopBeingBuilt(self, builder, layer)
        self:OnLayerChange(layer, 'None')
    end,

    ---@param self MobileUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)
        UnitOnLayerChange(self, new, old)

        -- Do this after the default function so the engine-bug guard in unit.lua works
        if self.transportDrop then
            self.transportDrop = nil
            self:SetImmobile(false)
        end
    end,

    ---@param self MobileUnit
    ---@param transport AirUnit
    ---@param bone Bone
    OnDetachedFromTransport = function(self, transport, bone)
        UnitOnDetachedFromTransport(self, transport, bone)

        -- Set unit immobile to prevent it to accelerating in the air, cleared in OnLayerChange
        if not self.Blueprint.CategoriesHash["AIR"] then
            self:SetImmobile(true)
            self.transportDrop = true
        end
    end,
}
