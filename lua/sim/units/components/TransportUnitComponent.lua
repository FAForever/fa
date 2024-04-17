---@class BaseTransport
---@field DisableIntelOfCargo boolean
---@field cargoCache? table
---@field killInstigator? Unit
---@field killDamageType string
---@field killExcessDamageRatio number
---@field cargoMass number
---@field slots table
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

    --- This function is called when a transport is killed. It kills all units inside the transport and
    --- disperses veterancy as appropriate.
    --- For units that store their cargo externally, it caches the cargo for later impact.
    ---@param self BaseTransport | Unit
    ---@param instigator Unit
    ---@param damageType string
    ---@param excessDamageRatio number
    ---@param disperseVeterancy? boolean -- To prevent lower recursions from jumping the gun on veterancy
    ---@return number? cargoMass -- The total mass value of the cargo
    KillCargo = function(self, instigator, damageType, excessDamageRatio, disperseVeterancy)

        -- If we're dead already, bail to avoid crashing
        if self.Dead then return 0 end

        local cargo = self:GetCargo()

        -- If we have storage slots, don't cache our cargo, because it's stored inside and
        -- we'll never have to deal with it again
        local cacheCargo = (self:GetBlueprint().Transport.StorageSlots and false) and true

        if cacheCargo and not table.empty(cargo) then
            self.killInstigator = instigator
            self.killDamageType = damageType
            self.killExcessDamageRatio = excessDamageRatio
            self.cargoCache = {}
        end

        -- Count our cargo's total veterancy value to disperse
        local cargoMass = 0

        for _, unit in cargo do
            -- Kill the contents of a transport in a transport, however that happened
            -- now with recursion!
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then
                cargoMass = cargoMass + unit:KillCargo(instigator,  damageType, excessDamageRatio, false)
            end

            -- cache the cargo so we can impact it later (if needed)
            -- exception for command units, which explode immediately
            if not EntityCategoryContains(categories.COMMAND, unit) and cacheCargo then
                unit.killedInTransport = true
                table.insert(self.cargoCache, unit)
            end

            -- record the veterancy value of the unit
            cargoMass = cargoMass + unit:GetTotalMassCost()

            -- the engine will allegedly handle actually killing the unit, but misses some, so we'll
            -- explicitly kill our unit (with an instigator) to avoid units slipping through the cracks
            -- (and so the engine can properly update kill counts, both for score and unit kills)
            unit:Kill(instigator, damageType, excessDamageRatio)
        end

        if disperseVeterancy ~= false then
            self:VeterancyDispersal(cargoMass)
        else
            return cargoMass
        end
    end,

    --- Called when our air transport impacts
    --- Calls OnKilled on the cargo 
    ---@param self BaseTransport | Unit
    ImpactCargo = function(self)
        if self:BeenDestroyed() or not self.cargoCache then return end
        for _, unit in self.cargoCache or {} do
            if not unit:BeenDestroyed() then
                unit.DeathWeaponEnabled = false -- Units at this point have no weapons for some reason. Trying to fire one crashes the game.
                unit:OnKilled(self.killInstigator, self.killDamageType, self.killExcessDamageRatio)
            end
        end
    end
}

