local TableInsert = table.insert
local TableEmpty = table.empty
local EntityCategoryContains = EntityCategoryContains

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
    ---@param damageType? DamageType -- an override for when we have a transport inside another transports internal storage
    ---@param recursive? boolean -- if we're in a recursive call or not
    ---@return number? cargoMass -- The total mass value of the cargo
    KillCargo = function(self, instigator, damageType, recursive)
        -- If we're dead already, bail to avoid crashing
        if self.Dead then return 0 end

        local cargo = self:GetCargo()
        if TableEmpty(cargo) then return 0 end

        local cacheCargo = true
        local cargoDamageType

        -- We need to determine how to handle the cargo
        -- Units in internal storage are just killed/destroyed, and relevant numbers tallied up
        -- Units in external storage have anims, effects, etc. and OnImpact is called for them
        if damageType == "TransportDamage" or self:GetBlueprint().Transport.StorageSlots ~= 0 then
            cargoDamageType = "TransportDamage" -- This damage type makes sure we skip death effects for internal cargo
            cacheCargo = false
        else
            cargoDamageType = "Normal"
            self.cargoCache = {}
            self.killInstigator = instigator
        end

        -- Count our cargo's total veterancy value to disperse
        local cargoMass = 0

        for _, unit in cargo do

            -- If it's an external factory unit, just destroy it and continue
            if EntityCategoryContains(categories.EXTERNALFACTORYUNIT, unit) then
                unit:Destroy()
                continue
            end

            -- Kill the contents of a transport in a transport, however that happened
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then
                cargoMass = cargoMass + unit:KillCargo(instigator, cargoDamageType, true)
            end

            -- cache the cargo so we can impact it later (if needed)
            -- exception for command units, which explode immediately
            if not EntityCategoryContains(categories.COMMAND, unit) and cacheCargo then
                unit.killedInTransport = true
                TableInsert(self.cargoCache, unit)
            end

            -- record the veterancy value of the unit
            -- only take remaining health, so we don't double count
            cargoMass = cargoMass + unit:GetTotalMassCost() * (unit:GetHealth() / unit:GetMaxHealth())

            -- the engine will allegedly handle actually killing the unit, but misses some, so we'll
            -- explicitly kill our unit to avoid any slipping through the cracks
            -- (instigator allows engine to properly update kill counts, both for score and unit kills)
            unit:Kill(instigator, cargoDamageType, 0)
        end

        if recursive then
            return cargoMass
        else
            self:VeterancyDispersal(cargoMass)
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
                unit:OnKilled(self.killInstigator, "", 0)
            end
        end
    end
}

