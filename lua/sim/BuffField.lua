------------------------------------------------------
--  File     :  /lua/sim/defaultbufffield.lua
--  Author(s):  Brute51
--  Summary  :  Low level buff field class (version 3)
------------------------------------------------------

local aibrain_methodsGetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
local tableRemove = table.remove
local tableInsert = table.insert
local ParseEntityCategory = ParseEntityCategory
local ipairs = ipairs
local tableEmpty = table.empty
local next = next
local KillThread = KillThread
local entity_methodsGetBlueprint = moho.entity_methods.GetBlueprint
local tableMerged = table.merged
local type = type
local WARN = WARN
local tableSubtract = table.subtract

local Buff = import('/lua/sim/Buff.lua')
local Entity = import('/lua/sim/Entity.lua').Entity

BuffFieldBlueprints = {
}

BuffField = Class(Entity) {
    -- Change these in an inheriting class if you want
    FieldVisualEmitter = '', -- the FX on the unit that carries the buff field

    -- EVENTS
    OnCreated = function(self)
        -- Fires when the field is initalised
        local bp = entity_methodsGetBlueprint(self)
        if bp.InitiallyEnabled then
            self:Enable()
        end
    end,

    OnEnabled = function(self)
        -- Fires when the field begins to work
        -- Show field FX
        if self.FieldVisualEmitter and type(self.FieldVisualEmitter) == 'string' and self.FieldVisualEmitter ~= '' then
            local Owner = self:GetOwner()
            if not Owner.BuffFieldEffectsBag then
                Owner.BuffFieldEffectsBag = {}
            end
            self.Emitter = CreateAttachedEmitter(Owner, 0, Owner.Army, self.FieldVisualEmitter)
            tableInsert(Owner.BuffFieldEffectsBag, self.Emitter)
        end
    end,

    OnDisabled = function(self)
        -- Fires when the field stops working

        -- Remove field FX
        local Owner = self:GetOwner()
        if self.Emitter and Owner.BuffFieldEffectsBag then
            for k, v in Owner.BuffFieldEffectsBag do
                if v == self.Emitter then
                    v:Destroy()
                    tableRemove(Owner.BuffFieldEffectsBag, k)
                    break
                end
            end
        end
    end,

    -- ACTUAL CODE (dont change anything)
    __init = function(self, spec)
        Entity.__init(self, spec)
        self.Name = spec.Name or 'NoName'
        self.Owner = spec.Owner
        self.Enabled = false
        self.CreateFuncRan = false
        self.Emitter = false
        self.WasEnabledBeforeTransporting = false
        self.DisabledForTransporting = false
        self.ThreadHandle = false
    end,

    OnCreate = function(self)
        local Owner = self:GetOwner()
        local bp = entity_methodsGetBlueprint(self)

        -- Verifying blueprint
        if not bp.Name or type(bp.Name) ~= 'string' or bp.Name == '' then WARN('BuffField: Invalid name or name not set!') end
        if type(bp.AffectsUnitCategories) == 'string' then bp.AffectsUnitCategories = ParseEntityCategory(bp.AffectsUnitCategories) end
        if type(bp.Buffs) == 'string' then bp.Buffs = {bp.Buffs} end
        if tableEmpty(bp.Buffs) then WARN('BuffField: [..repr(bp.Name)..] no buffs specified!') end

        if not bp.Duration then
            WARN('BuffField: [..repr(bp.Name)..] Duration must be specified for a buff field buff.')
        end

        if not bp.Stacks ~= "REPLACE" then
            WARN('BuffField: [..repr(bp.Name)..] You almost certainly want buff fields to be Stack-type REPLACE.')
        end

        for _, v in bp.Buffs do
            if not Buffs[v] then
                WARN('BuffField: [..repr(bp.Name)..] the field uses a buff that doesn\'t exist! '..repr(v))
                return
            end
        end

        if not bp.Radius or bp.Radius <= 0 then
            WARN('BuffField: [..repr(bp.Name)..] Invalid radius or radius not set!')
            return
        end

        -- Set up the get-nearby-units function to include the units we care about.
        local aiBrain = Owner:GetAIBrain()
        local pos = Owner:GetPosition()
        local AffectsUnitCategories = bp.AffectsUnitCategories
        local Radius = bp.Radius

        if bp.AffectsOwnUnits and bp.AffectsAllies and bp.AffectsVisibleEnemies then
            -- Affect *all* the things!
            self.GetNearbyAffectableUnits = function()
                return aibrain_methodsGetUnitsAroundPoint(aiBrain, AffectsUnitCategories, pos, Radius)
            end
        elseif bp.AffectsOwnUnits and bp.AffectsAllies then
            -- All friendlies, no enemies.
            self.GetNearbyAffectableUnits = function()
                return aibrain_methodsGetUnitsAroundPoint(aiBrain, AffectsUnitCategories, pos, Radius, 'Ally')
            end
        elseif bp.AffectsOwnUnits and bp.AffectsVisibleEnemies then
            -- Self and enemies, not allies.
            self.GetNearbyAffectableUnits = function()
                return tableMerged(
                    aiBrain:GetOwnUnitsAroundPoint(AffectsUnitCategories, pos, Radius, 'Ally'),
                    aibrain_methodsGetUnitsAroundPoint(aiBrain, AffectsUnitCategories, pos, Radius, 'Enemy')
                )
            end
        elseif bp.AffectsOwnUnits then
            -- Own units only.
            self.GetNearbyAffectableUnits = function()
                return aiBrain:GetOwnUnitsAroundPoint(AffectsUnitCategories, pos, Radius)
            end
        elseif bp.AffectsVisibleEnemies then
            -- Enemies units only.
            self.GetNearbyAffectableUnits = function()
                return aibrain_methodsGetUnitsAroundPoint(aiBrain, AffectsUnitCategories, pos, Radius, 'Enemy')
            end
        elseif bp.AffectsAllies then
            -- Allies only. This wasn't supported before and is stupid anyway, but until we change
            -- the configuration so it's unrepresentable let's do it anyway...
            self.GetNearbyAffectableUnits = function()
                local mine = aiBrain:GetOwnUnitsAroundPoint(AffectsUnitCategories, pos, Radius, 'Enemy')
                local allied = aibrain_methodsGetUnitsAroundPoint(aiBrain, AffectsUnitCategories, pos, Radius, 'Ally')

                -- Subtract mine from allied and you get the allies only.
                return tableSubtract(allied, mine)
            end
        end

        -- Event stuff
        Entity.OnCreate(self)

        if bp.DisableInTransport then
            Owner:AddUnitCallback(self.DisableInTransport, 'OnAttachedToTransport')
            Owner:AddUnitCallback(self.EnableOutTransport, 'OnDetachedFromTransport')
        end

        self:OnCreated()
    end,

    GetBlueprint = function(self)
        return BuffFieldBlueprints[self.Name]
    end,

    IsEnabled = function(self)
        return self.Enabled
    end,

    GetBuffs = function(self)
        return entity_methodsGetBlueprint(self).Buffs or nil
    end,

    GetOwner = function(self)
        return self.Owner
    end,

    Enable = function(self)
        if not self:IsEnabled() then
            local Owner = self:GetOwner()
            local bp = entity_methodsGetBlueprint(self)

            self.ThreadHandle = self.Owner:ForkThread(self.FieldThread, self)
            Owner:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            Owner:SetMaintenanceConsumptionActive()

            self.Enabled = true
            self:OnEnabled()
        end
    end,

    Disable = function(self)
        if self:IsEnabled() then
            local Owner = self:GetOwner()
            Owner:SetMaintenanceConsumptionInactive()
            KillThread(self.ThreadHandle)
            self.Enabled = false
            self:OnDisabled()
        end
    end,

    -- Applies the buff to any unit in range each 5 seconds
    -- Owner is the unit that carries the field. This is a bit weird to have it like this but its the result of
    -- of the forkthread in the enable function.
    FieldThread = function(Owner, self)
        local bp = entity_methodsGetBlueprint(self)

        while not Owner.Dead do
            local units = self.GetNearbyAffectableUnits()
            for k, unit in units do
                if unit ~= Owner or bp.AffectsSelf then
                    for _, buff in bp.Buffs do
                        Buff.ApplyBuff(unit, buff)
                    end
                end
            end

            WaitSeconds(4.9) -- This should be anything but 5 (of the other wait) to help spread the cpu load
        end
    end,

    -- These 2 are a bit weird. they are supposed to disable the enabled fields when on a transport and re-enable the
    -- fields that were enabled and leave the disabled fields off.
    DisableInTransport = function(Owner, Transport)
        for k, field in Owner.BuffFields do
            if not field.DisabledForTransporting then
                local Enabled = field:IsEnabled()
                field.WasEnabledBeforeTransporting = Enabled
                if Enabled then
                    field:Disable()
                end
                field.DisabledForTransporting = true -- To make sure the above is done once even if we have 2 fields or more
            end
        end
    end,

    EnableOutTransport = function(Owner, Transport)
        for k, field in Owner.BuffFields do
            if field.DisabledForTransporting then
                if field.WasEnabledBeforeTransporting then
                    field:Enable()
                end
                field.DisabledForTransporting = false
            end
        end
    end,
}


-- This function is for registering new buff fields. Don't remove.
function BuffFieldBlueprint(bpData)
    if not bpData.Name then
        WARN('BuffFieldBlueprint: Encountered blueprint with no name, ignoring it.')
    elseif bpData.Merge then
        -- Merging blueprints
        if not BuffFieldBlueprints[bpData.Name] then
            WARN('BuffFieldBlueprint: Trying to merge blueprint "'..bpData.Name..'" with a non-existing one.')
        else
            bpData.Merge = nil
            BuffFieldBlueprints[bpData.Name] = tableMerged(BuffFieldBlueprints[bpData.Name], bpData)
        end
    else
        -- Adding new blueprint if it doesn't exist yet
        BuffFieldBlueprints[bpData.Name] = bpData
    end
end
