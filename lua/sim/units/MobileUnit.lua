
local EffectUtil = import("/lua/effectutilities.lua")

local Unit = import("/lua/sim/unit.lua").Unit
local TreadComponent = import("/lua/defaultcomponents.lua").TreadComponent

---@class MobileUnit : Unit, TreadComponent
---@field MovementEffectsBag TrashBag
---@field TopSpeedEffectsBag TrashBag
---@field BeamExhaustEffectsBag TrashBag
---@field TransportBeamEffectsBag? TrashBag
MobileUnit = ClassUnit(Unit, TreadComponent) {

    ---@param self MobileUnit
    OnCreate = function(self)
        Unit.OnCreate(self)
        TreadComponent.OnCreate(self)

        self.MovementEffectsBag = TrashBag()
        self.TopSpeedEffectsBag = TrashBag()
        self.BeamExhaustEffectsBag = TrashBag()
    end,

    DestroyAllTrashBags = function(self)
        Unit.DestroyAllTrashBags(self)

        self.MovementEffectsBag:Destroy()
        self.TopSpeedEffectsBag:Destroy()
        self.BeamExhaustEffectsBag:Destroy()

        -- only exists if unit is transported
        if self.TransportBeamEffectsBag then
            self.TransportBeamEffectsBag:Destroy()
        end
    end,

    CreateMovementEffects = function(self, effectsBag, typeSuffix, terrainType)
        Unit.CreateMovementEffects(self, effectsBag, typeSuffix, terrainType)
        TreadComponent.CreateMovementEffects(self)
    end,

    DestroyMovementEffects = function(self)
        Unit.DestroyMovementEffects(self)
        TreadComponent.DestroyMovementEffects(self)
    end,

    ---@param self MobileUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        -- This unit was in a transport and should create a wreck on crash
        if self.killedInTransport then
            self.killedInTransport = false
        else
            Unit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,

    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        if self.Blueprint.FactionCategory == 'UEF' then
            EffectUtil.CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
    end,

    -- Units with layer change effects (amphibious units like Megalith) need
    -- those changes applied when build ends, so we need to trigger the
    -- layer change event
    ---@param self MobileUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
       Unit.OnStopBeingBuilt(self, builder, layer)
       self:OnLayerChange(layer, 'None')
    end,

    ---@param self MobileUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)
        Unit.OnLayerChange(self, new, old)

        -- Do this after the default function so the engine-bug guard in unit.lua works
        if self.transportDrop then
            self.transportDrop = nil
            self:SetImmobile(false)
        end
    end,

    ---comment
    ---@param self MobileUnit
    ---@param transport AirUnit
    ---@param bone Bone
    OnDetachedFromTransport = function(self, transport, bone)
        Unit.OnDetachedFromTransport(self, transport, bone)

        -- Set unit immobile to prevent it to accelerating in the air, cleared in OnLayerChange
        if not self.Blueprint.CategoriesHash["AIR"] then
            self:SetImmobile(true)
            self.transportDrop = true
        end
    end,
}