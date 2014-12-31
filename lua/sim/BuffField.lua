#****************************************************************************
#**
#**  File     :  /lua/sim/defaultbufffield.lua
#**  Author(s):  Brute51
#**
#**  Summary  :  Low level buff field class (version 3)
#**
#****************************************************************************
#**
#** READ DOCUMENTATION BEFORE USING THIS!!
#**
#****************************************************************************

local AIUtils = import('/lua/ai/aiutilities.lua')
local Buff = import('/lua/sim/Buff.lua')
local BuffDefinitions = import('/lua/sim/BuffDefinitions.lua')
local Entity = import('/lua/sim/Entity.lua').Entity

BuffFieldBlueprints = {
}

BuffField = Class(Entity) {

    # change these in an inheriting class if you want
    FieldVisualEmitter = '',   # the FX on the unit that carries the buff field

    # ----------------------------------------------------------------------------------------------------------
    # EVENTS

    OnCreated = function(self)    
        # fires when the field is initalised
        local bp = self:GetBlueprint()
        if bp.InitiallyEnabled then
            self:Enable()
        end
    end,

    OnEnabled = function(self)
        # fires when the field begins to work

        # show field FX
        if self.FieldVisualEmitter and type(self.FieldVisualEmitter) == 'string' and self.FieldVisualEmitter != '' then
            local Owner = self:GetOwner()
            if not Owner.BuffFieldEffectsBag then
                Owner.BuffFieldEffectsBag = {}
            end
            self.Emitter = CreateAttachedEmitter(Owner, 0, Owner:GetArmy(), self.FieldVisualEmitter)
            table.insert( Owner.BuffFieldEffectsBag, self.Emitter)
        end
    end,

    OnDisabled = function(self)
        # fires when the field stops working

        # remove field FX
        local Owner = self:GetOwner()
        if self.Emitter and Owner.BuffFieldEffectsBag then
            for k, v in Owner.BuffFieldEffectsBag do
                if v == self.Emitter then
                    v:Destroy()
                    table.remove(Owner.BuffFieldEffectsBag, k)
                    break
                end
            end
        end
    end,

    OnNewUnitsInFieldCheck = function(self)
        # fires when another check is done to find new units in range that aren't yet under the influence of the
        # field. This happens approximately every 4.9 seconds.
    end,

    OnPreUnitEntersField = function(self, unit)
        # fired before unit receives the buffs, but it will. Any data returned by this event function is used as an
        # argument for OnUnitEntersField, OnPreUnitLeavesField and OnUnitLeavesField
    end,

    OnUnitEntersField = function(self, unit, OnPreUnitEntersFieldData)
        # fired when a new unit begins being affected by the field. the unit argument contains the newly affected 
        # unit. The OnPreUnitEntersFieldData argument is the data (if any) returned by OnPreUnitEntersField. Any
        # data returned by this event function is used as an argument for OnPreUnitLeavesField and
        # OnUnitLeavesField
    end,

    OnPreUnitLeavesField = function(self, unit, OnPreUnitEntersFieldData, OnUnitEntersFieldData)
        # fired when a unit leaves the field, just before the field buffs are removed. The OnPreUnitEntersFieldData
        # argument is the data (if any) returned by OnPreUnitEntersField and the OnUnitEntersFieldData argument
        # is the data (if any) returned by OnUnitEntersField. Any data returned by this event function is used as 
        # an argument for OnUnitLeavesField.
    end,

    OnUnitLeavesField = function(self, unit, OnPreUnitEntersFieldData, OnUnitEntersFieldData, OnPreUnitLeavesField)
        # fired after a unit left the field and the field buffs have been removed. the last 3 arguments contain
        # data returned by the other events.
    end,

    # ----------------------------------------------------------------------------------------------------------
    # ACTUAL CODE (dont change anything)

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
        #LOG('Buffield: ['..repr(BuffFieldName)..'] OnCreate')

        local Owner = self:GetOwner()
        local bp = self:GetBlueprint()

        # verifying blueprint
        if not bp.Name or type(bp.Name) != 'string' or bp.Name == '' then WARN('BuffField: Invalid name or name not set!') end
        if type(bp.AffectsUnitCategories) == 'string' then bp.AffectsUnitCategories = ParseEntityCategory(bp.AffectsUnitCategories) end
        if type(bp.Buffs) == 'string' then bp.Buffs = { bp.Buffs } end
        if table.getn(bp.Buffs) < 1 then WARN('BuffField: [..repr(bp.Name)..] no buffs specified!') end

        for k, v in bp.Buffs do
            if not Buffs[v] then
                WARN('BuffField: [..repr(bp.Name)..] the field uses a buff that doesn\'t exist! '..repr(v))
                return
            end
        end
        if not bp.Radius or bp.Radius <= 0 then
            WARN('BuffField: [..repr(bp.Name)..] Invalid radius or radius not set!')
            return
        end

        # event stuff
        Entity.OnCreate(self)

        if bp.DisableInTransport then
            Owner:AddUnitCallback(self.DisableInTransport, 'OnAttachedToTransport')
            Owner:AddUnitCallback(self.EnableOutTransport, 'OnDetachedToTransport')
        end

        self:OnCreated()
    end,

    GetBlueprint = function(self)
        return BuffFieldBlueprints[self.Name]
    end,

    IsEnabled = function(self)
        return self.Enabled or false
    end,

    GetBuffs = function(self)
        return self:GetBlueprint().Buffs or nil
    end,

    GetOwner = function(self)
        return self.Owner
    end,

    Enable = function(self)
        #LOG('Buffield: ['..repr(self.Name)..'] enable')
        if not self:IsEnabled() then
            #LOG('Buffield: ['..repr(self.Name)..'] enabling buff field')
            local Owner = self:GetOwner()
            local bp = self:GetBlueprint()

            self.ThreadHandle = self.Owner:ForkThread(self.FieldThread, self)
            Owner:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            Owner:SetMaintenanceConsumptionActive()

            self.Enabled = true
            self:OnEnabled()
        end
    end,

    Disable = function(self)
        #LOG('Buffield: ['..repr(self.Name)..'] disable')
        if self:IsEnabled() then
            local Owner = self:GetOwner()
            Owner:SetMaintenanceConsumptionInactive()
            KillThread(self.ThreadHandle)
            self.Enabled = false
            self:OnDisabled()
        end
    end,

    # applies the buff to any unit in range each 5 seconds
    # Owner is the unit that carries the field. This is a bit weird to have it like this but its the result of
    # of the forkthread in the enable function.
    FieldThread = function(Owner, self)
        #LOG('Buffield: ['..repr(self.Name)..'] FieldThread')
        local bp = self:GetBlueprint()

        local function GetNearbyAffectableUnits()
            local units = {}
            local aiBrain = Owner:GetAIBrain()
            local pos = Owner:GetPosition()
            if bp.AffectsOwnUnits then
                units = table.merged(units, AIUtils.GetOwnUnitsAroundPoint(Owner:GetAIBrain(), bp.AffectsUnitCategories, pos, bp.Radius))
            end
            if bp.AffectsAllies then
                units = table.merged(units, aiBrain:GetUnitsAroundPoint( bp.AffectsUnitCategories, pos, bp.Radius, 'Ally' ))
                # civilians are not considered allies
            end
            if bp.AffectsVisibleEnemies then
                units = table.merged(units, aiBrain:GetUnitsAroundPoint( bp.AffectsUnitCategories, pos, bp.Radius, 'Enemy' ))
            end
            return units
        end

        while self:IsEnabled() and not Owner:IsDead() do
            #LOG('BuffField: ['..repr(self.Name)..'] check new units')
            local units = GetNearbyAffectableUnits()
            for k, unit in units do
                if unit == Owner and not bp.AffectsSelf then
                   continue
                end
                if not unit.HasBuffFieldThreadHandle[bp.Name] then
                    if type(unit.HasBuffFieldThreadHandle) != 'table' then
                        unit.HasBuffFieldThreadHandle = {}
                        unit.BuffFieldThreadHandle = {}
                    end
                    #LOG('BuffField: ['..repr(self.Name)..'] new unit')
                    unit.BuffFieldThreadHandle[bp.Name] = unit:ForkThread(self.UnitBuffFieldThread, Owner, self)
                    unit.HasBuffFieldThreadHandle[bp.Name] = true
                end
            end
            self:OnNewUnitsInFieldCheck()
            WaitSeconds(4.9) # this should be anything but 5 (of the other wait) to help spread the cpu load
        end
    end,

    # ============================================================================================

    # this will be run on the units affected by the field so self means the unit that is affected by the field

    UnitBuffFieldThread = function(self, instigator, BuffField)
        local bp = BuffField:GetBlueprint()
        local PreEnterData = BuffField:OnPreUnitEntersField(self)
        for _, buff in bp.Buffs do
            Buff.ApplyBuff(self, buff)
        end
        local EnterData = BuffField:OnUnitEntersField(self, PreEnterData)
        while not self:IsDead() and not instigator:IsDead() and BuffField:IsEnabled() do
            #LOG('BuffField: ['..repr(bp.Name)..'] unit thread check distance')
            dist = VDist3( self:GetPosition(), instigator:GetPosition() )
            if dist > bp.Radius then
                break # ideally we should check for another nearby buff field emitting unit but it doesn't really matter (no more than 5 sec anyway)
            end
            WaitSeconds(5)
        end
        local PreLeaveData = BuffField:OnPreUnitLeavesField(self, PreEnterData, EnterData)
        for _, buff in bp.Buffs do
            if Buff.HasBuff(self, buff) then
                Buff.RemoveBuff( self, buff)
            end
        end
        BuffField:OnUnitLeavesField(self, PreEnterData, EnterData, PreLeaveData)
        self.HasBuffFieldThreadHandle[bp.Name] = false
        #LOG('BuffField: ['..repr(bp.Name)..'] end unit thread')
    end,

    # ============================================================================================

    # these 2 are a bit weird. they are supposed to disable the enabled fields when on a transport and re-enable the
    # fields that were enabled and leave the disabled fields off.

    DisableInTransport = function(Owner, Transport)
        for k, field in Owner.BuffFields do
            if not field.DisabledForTransporting then
                local Enabled = field:IsEnabled()
                field.WasEnabledBeforeTransporting = Enabled
                if Enabled then
                    field:Disable()
                end
                field.DisabledForTransporting = true # to make sure the above is done once even if we have 2 fields or more
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


# this function is for registering new buff fields. Don't remove.
function BuffFieldBlueprint( bpData)
    if not bpData.Name then
        WARN('BuffFieldBlueprint: Encountered blueprint with no name, ignoring it.')
    elseif bpData.Merge then
        # Merging blueprints
        if not BuffFieldBlueprints[bpData.Name] then
            WARN('BuffFieldBlueprint: Trying to merge blueprint "'..bpData.Name..'" with a non-existing one.')
        else
            bpData.Merge = nil
            BuffFieldBlueprints[bpData.Name] = table.merged( BuffFieldBlueprints[bpData.Name], bpData )
        end
    else
        # Adding new blueprint if it doesn't exist yet
        BuffFieldBlueprints[bpData.Name] = bpData
    end
end