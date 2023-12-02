---@class BaseTransport
---@field DisableIntelOfCargo boolean
BaseTransport = ClassSimple {

    ---@param self BaseTransport | Unit
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:RequestRefreshUI()

        local slots = self.slots
        if slots then
            for i = 1, self:GetBoneCount() do
                if self:GetBoneName(i) == attachBone then
                    slots[i] = unit
                    unit.attachmentBone = i
                end
            end
        end
    end,

    ---@param self BaseTransport | Unit
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:RequestRefreshUI()

        local slots = self.slots
        local attachmentBone = unit.attachmentBone
        if slots and attachmentBone then
            slots[attachmentBone] = nil
            unit.attachmentBone = nil
        end
    end,

    -- When one of our attached units gets killed, detach it
    ---@param self BaseTransport | Unit
    ---@param attached Unit
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    ---@param self BaseTransport | Unit
    OnStartTransportLoading = function(self)
        -- We keep the aibrain up to date with the last transport to start loading so, among other
        -- things, we can determine which transport is being referenced during an OnTransportFull
        -- event (As this function is called immediately before that one).
        self.transData = {}
        self:GetAIBrain().loadingTransport = self
    end,

    ---@param self BaseTransport | Unit
    OnStopTransportLoading = function(self)
    end,

    ---@param self BaseTransport | Unit
    DestroyedOnTransport = function(self)
    end,

    -- Detaches cargo from a dying unit
    ---@param self BaseTransport | Unit
    DetachCargo = function(self)
        if self.Dead then return end -- Bail out early from overkill damage when already dead to avoid crashing

        local cargo = self:GetCargo()
        for _, unit in cargo do
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then -- Kill the contents of a transport in a transport, however that happened
                for k, subUnit in unit:GetCargo() do
                    subUnit:Kill()
                end
            end
            unit:DetachFrom()
        end
    end,

    ---@param self BaseTransport | Unit
    SaveCargoMass = function(self)
        local mass = 0
        for _, unit in self:GetCargo() do
            mass = mass + unit:GetVeterancyValue()
            unit.veterancyDispersed = true
        end
        self.cargoMass = mass
    end
}

