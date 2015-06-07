local Unit = import('/lua/sim/Unit.lua').Unit
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')

--- Base class for structures.
StructureUnit = Class(Unit) {
    LandBuiltHiddenBones = {'Floatation'},
    MinConsumptionPerSecondEnergy = 1,
    MinWeaponRequiresEnergy = 0,

    -- Stucture unit specific damage effects and smoke
    FxDamage1 = { EffectTemplate.DamageStructureSmoke01, EffectTemplate.DamageStructureSparks01 },
    FxDamage2 = { EffectTemplate.DamageStructureFireSmoke01, EffectTemplate.DamageStructureSparks01 },
    FxDamage3 = { EffectTemplate.DamageStructureFire01, EffectTemplate.DamageStructureSparks01 },

    OnCreate = function(self)
        Unit.OnCreate(self)
        self.WeaponMod = {}
        self.FxBlinkingLightsBag = {}
        if self:GetCurrentLayer() == 'Land' and self:GetBlueprint().Physics.FlattenSkirt then
            self:FlattenSkirt()
            -- Units creating structure units tell unit to create the tarmac.
            -- This left here to help with F2 unit creation and testing.
            -- self:CreateTarmac(true, true, true, false, false)
        end
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        Unit.OnStopBeingBuilt(self,builder,layer)
        self:PlayActiveAnimation()
    end,

    OnFailedToBeBuilt = function(self)
        Unit.OnFailedToBeBuilt(self)
        self:DestroyTarmac()
    end,

    FlattenSkirt = function(self)
        local x, y, z = unpack(self:GetPosition())
        local x0,z0,x1,z1 = self:GetSkirtRect()
        x0,z0,x1,z1 = math.floor(x0),math.floor(z0),math.ceil(x1),math.ceil(z1)
        FlattenMapRect(x0, z0, x1-x0, z1-z0, y)
    end,

    CreateTarmac = function(self, albedo, normal, glow, orientation, specTarmac, lifeTime)
        if self:GetCurrentLayer() ~= 'Land' then return end
        local tarmac
        local bp = self:GetBlueprint().Display.Tarmacs
        if not specTarmac then
            if bp and table.getn(bp) > 0 then
                local num = Random(1, table.getn(bp))
                --LOG('*DEBUG: NUM + ', repr(num))
                tarmac = bp[num]
            else
                return false
            end
        else
            tarmac = specTarmac
        end

        local army = self:GetArmy()
        local w = tarmac.Width
        local l = tarmac.Length
        local fadeout = tarmac.FadeOut

        local x, y, z = unpack(self:GetPosition())

        -- I'm disabling this for now since there are so many things wrong with it.
        -- SetTerrainTypeRect(self.tarmacRect, {TypeCode= (aiBrain:GetFactionIndex() + 189) } )
        local orient = orientation
        if not orientation then
            if tarmac.Orientations and table.getn(tarmac.Orientations) > 0 then
                orient = tarmac.Orientations[Random(1, table.getn(tarmac.Orientations))]
                orient = (0.01745 * orient)
            else
                orient = 0
            end
        end

        if not self.TarmacBag then
            self.TarmacBag = {
                Decals = {},
                Orientation = orient,
                CurrentBP = tarmac,
            }
        end

        local GetTarmac = import('/lua/tarmacs.lua').GetTarmacType

        local terrain = GetTerrainType(x, z)
        local terrainName
        if terrain then
            terrainName = terrain.Name
        end
        -- Players and AI can build buildings outside of their faction. Get the *building's* faction to determine the correct tarrain-specific tarmac
        local factionTable = {e=1, a=2, r=3, s=4}
        local faction  = factionTable[string.sub(self:GetUnitId(),2,2)]

        if albedo and tarmac.Albedo then
            local albedo2 = tarmac.Albedo2
            if albedo2 then
                albedo2 = albedo2 .. GetTarmac(faction, terrain)
            end

            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Albedo .. GetTarmac(faction, terrainName) , albedo2 or '', 'Albedo', w, l, fadeout, lifeTime or 0, army, 0)
            table.insert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end
        if normal and tarmac.Normal then
            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Normal .. GetTarmac(faction, terrainName), '', 'Alpha Normals', w, l, fadeout, lifeTime or 0, army, 0)

            table.insert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end
        if glow and tarmac.Glow then
            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Glow .. GetTarmac(faction, terrainName), '', 'Glow', w, l, fadeout, lifeTime or 0, army, 0)

            table.insert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end
    end,

    DestroyTarmac = function(self)
        if not self.TarmacBag then return end
        for k, v in self.TarmacBag.Decals do
            v:Destroy()
        end

        self.TarmacBag.Orientation = nil
        self.TarmacBag.CurrentBP = nil
    end,

    HasTarmac = function(self)
        if not self.TarmacBag then return false end
        return (table.getn(self.TarmacBag.Decals) ~= 0)
    end,

    OnMassStorageStateChange = function(self, state)
    end,

    OnEnergyStorageStateChange = function(self, state)
    end,

    CreateBlinkingLights = function(self, color)
        self:DestroyBlinkingLights()
        local bp = self:GetBlueprint().Display.BlinkingLights
        local bpEmitters = self:GetBlueprint().Display.BlinkingLightsFx
        if bp then
            local fxbp = bpEmitters[color]
            for k, v in bp do
                if type(v) == 'table' then
                    local fx = CreateAttachedEmitter(self, v.BLBone, self:GetArmy(), fxbp)
                    fx:OffsetEmitter(v.BLOffsetX or 0, v.BLOffsetY or 0, v.BLOffsetZ or 0)
                    fx:ScaleEmitter(v.BLScale or 1)
                    table.insert(self.FxBlinkingLightsBag, fx)
                    self.Trash:Add(fx)
                end
            end
        end
    end,

    DestroyBlinkingLights = function(self)
        for k, v in self.FxBlinkingLightsBag do
            v:Destroy()
        end
        self.FxBlinkingLightsBag = {}
    end,

    CreateDestructionEffects = function( self, overKillRatio )
    -- LOG( bp.General.FactionName, ' ', bp.General.UnitType,' avg. bounding radius = ', explosion.GetAverageBoundingXZRadius( self ) )
    -- LOG( 'CurrentLayer ', self:GetCurrentLayer())

        if( explosion.GetAverageBoundingXZRadius( self ) < 1.0 ) then
            explosion.CreateScalableUnitExplosion( self, overKillRatio )
        else
            explosion.CreateTimedStuctureUnitExplosion( self )
            WaitSeconds( 0.5 )
            explosion.CreateScalableUnitExplosion( self, overKillRatio )
        end
    end,

    -- Modified to use same upgrade logic as the ui. This adds more upgrade options via General.UpgradesFromBase blueprint option
    OnStartBuild = function(self, unitBeingBuilt, order )
        Unit.OnStartBuild(self,unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt

        --LOG("structure onstartbuild")

        local builderBp = self:GetBlueprint()
        local targetBp = unitBeingBuilt:GetBlueprint()
        local performUpgrade = false

        if targetBp.General.UpgradesFrom == builderBp.BlueprintId then
            performUpgrade = true
        elseif targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo then
            performUpgrade = true
        elseif targetBp.General.UpgradesFromBase ~= "none" then
            -- try testing against the base
            if targetBp.General.UpgradesFromBase == builderBp.BlueprintId then
                performUpgrade = true
            elseif targetBp.General.UpgradesFromBase == builderBp.General.UpgradesFromBase then
                performUpgrade = true
            end
        end

        if performUpgrade and order == 'Upgrade' then
            ChangeState(self, self.UpgradingState)
        end
    end,

    IdleState = State {
        Main = function(self)
        end,
    },

    UpgradingState = State {
        Main = function(self)
            self:StopRocking()
            local bp = self:GetBlueprint().Display
            self:DestroyTarmac()
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()
            if bp.AnimationUpgrade then
                local unitBuilding = self.UnitBeingBuilt
                self.AnimatorUpgradeManip = CreateAnimator(self)
                self.Trash:Add(self.AnimatorUpgradeManip)
                local fractionOfComplete = 0
                self:StartUpgradeEffects(unitBuilding)
                self.AnimatorUpgradeManip:PlayAnim(bp.AnimationUpgrade, false):SetRate(0)

                while fractionOfComplete < 1 and not self.Dead do
                    fractionOfComplete = unitBuilding:GetFractionComplete()
                    self.AnimatorUpgradeManip:SetAnimationFraction(fractionOfComplete)
                    WaitTicks(1)
                end
                if not self.Dead then
                    self.AnimatorUpgradeManip:SetRate(1)
                end
            end
        end,

        OnStopBuild = function(self, unitBuilding)
            Unit.OnStopBuild(self, unitBuilding)
            self:EnableDefaultToggleCaps()

            if unitBuilding:GetFractionComplete() == 1 then
                NotifyUpgrade(self, unitBuilding)
                self:StopUpgradeEffects(unitBuilding)
                self:PlayUnitSound('UpgradeEnd')
                self:Destroy()
            end
        end,

        OnFailedToBuild = function(self)
            Unit.OnFailedToBuild(self)
            self:EnableDefaultToggleCaps()

            if self.AnimatorUpgradeManip then self.AnimatorUpgradeManip:Destroy() end

            if self:GetCurrentLayer() == 'Water' then
                self:StartRocking()
            end
            self:PlayUnitSound('UpgradeFailed')
            self:PlayActiveAnimation()
            self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            ChangeState(self, self.IdleState)
        end,
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = self:GetBlueprint()
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            self:HideBone(0, true)
            self.BeingBuiltShowBoneTriggered = false
            if bp.General.UpgradesFrom ~= builder:GetUnitId() then
                self:ForkThread( EffectUtil.CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag )
            end
        elseif FactionName == 'Aeon' then
            if bp.General.UpgradesFrom ~= builder:GetUnitId() then
                self:ForkThread( EffectUtil.CreateAeonBuildBaseThread, builder, self.OnBeingBuiltEffectsBag )
            end
        elseif FactionName == 'Cybran' then
        elseif FactionName == 'Seraphim' then
            if bp.General.UpgradesFrom ~= builder:GetUnitId() then
                self:ForkThread( EffectUtil.CreateSeraphimBuildBaseThread, builder, self.OnBeingBuiltEffectsBag )
            end
        end
    end,

    StopBeingBuiltEffects = function(self, builder, layer)
        local FactionName = self:GetBlueprint().General.FactionName
        if FactionName == 'Aeon' then
            WaitSeconds( 2.0 )
        elseif FactionName == 'UEF' and not self.BeingBuiltShowBoneTriggered then
            self:ShowBone(0, true)
            self:HideLandBones()
        end
        Unit.StopBeingBuiltEffects(self, builder, layer)
    end,

    StartBuildingEffects = function(self, unitBeingBuilt, order)
        Unit.StartBuildingEffects(self, unitBeingBuilt, order)
    end,

    StopBuildingEffects = function(self, unitBeingBuilt)
        Unit.StopBuildingEffects(self, unitBeingBuilt)
    end,

    StartUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:HideBone(0, true)
    end,

    StopUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:ShowBone(0, true)
    end,

    PlayActiveAnimation = function(self)

    end,

    -- Adding into OnKilled the ability to destroy the tarmac but put a new one down that looks exactly like it but
    -- will time out over the time spec'd or 300 seconds.
    OnKilled = function(self, instigator, type, overkillRatio)
        Unit.OnKilled(self, instigator, type, overkillRatio)
        local orient = self.TarmacBag.Orientation
        local currentBP = self.TarmacBag.CurrentBP
        self:DestroyTarmac()
        self:CreateTarmac(true, true, true, orient, currentBP, currentBP.DeathLifetime or 300)
    end,

    ----------------------------------------------------------------------------------------------
    --  Adjacency
    ----------------------------------------------------------------------------------------------

    -- When we're adjacent, try to apply all the possible bonuses
    OnAdjacentTo = function(self, adjacentUnit, triggerUnit)    -- What is triggerUnit?
        if self:IsBeingBuilt() then return end
        if adjacentUnit:IsBeingBuilt() then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = self:GetBlueprint().Adjacency
        if not adjBuffs then return end

        -- Apply each buff needed to you and/or adjacent unit
        for k,v in AdjacencyBuffs[adjBuffs] do
            Buff.ApplyBuff(adjacentUnit, v, self)
        end

        -- Keep track of adjacent units
        if not self.AdjacentUnits then
            self.AdjacentUnits = {}
        end
        table.insert(self.AdjacentUnits, adjacentUnit)

        self:RequestRefreshUI()
        adjacentUnit:RequestRefreshUI()
    end,

    --When we're not adjacent, try to remove all the possible bonuses
    OnNotAdjacentTo = function(self, adjacentUnit)
        if not self.AdjacentUnits then
            WARN("Precondition Failed: No AdjacentUnits registered for entity: " .. repr(self.GetEntityId))
            return
        end

        local adjBuffs = self:GetBlueprint().Adjacency

        if adjBuffs and AdjacencyBuffs[adjBuffs] then
            for k,v in AdjacencyBuffs[adjBuffs] do
                if Buff.HasBuff(adjacentUnit, v) then
                    Buff.RemoveBuff(adjacentUnit, v)
                end
            end
        end
        self:DestroyAdjacentEffects()

        -- Keep track of units losing adjacent structures
        for k,u in self.AdjacentUnits do
            if u == adjacentUnit then
                table.remove(self.AdjacentUnits, k)
                adjacentUnit:RequestRefreshUI()
            end
        end
        self:RequestRefreshUI()
    end,

    ------------------------------------
    --Add/Remove Adjacency Functionality
    ------------------------------------

    -- Applies all appropriate buffs to all adjacent units
    ApplyAdjacencyBuffs = function(self)
        local adjBuffs = self:GetBlueprint().Adjacency
        if not adjBuffs then return end

        -- There won't be any adjacentUnit if this is a producer just built...
        if self.AdjacentUnits then
            for k, adjacentUnit in self.AdjacentUnits do
                for k,v in AdjacencyBuffs[adjBuffs] do
                    Buff.ApplyBuff(adjacentUnit, v, self)
                    adjacentUnit:RequestRefreshUI()
                end
            end
            self:RequestRefreshUI()
        end
    end,

    -- Removes all appropriate buffs from all adjacent units
    RemoveAdjacencyBuffs = function(self)
        local adjBuffs = self:GetBlueprint().Adjacency
        if not adjBuffs then return end

        if self.AdjacentUnits then
            for k, adjacentUnit in self.AdjacentUnits do
                for key, v in AdjacencyBuffs[adjBuffs] do
                    if Buff.HasBuff(adjacentUnit, v) then
                        Buff.RemoveBuff(adjacentUnit, v, false, self)
                        adjacentUnit:RequestRefreshUI()
                    end
                end
            end
            self:RequestRefreshUI()
        end
    end,

    -------------------------------
    -- Add/Remove Adjacency Effects
    -------------------------------

    CreateAdjacentEffect = function(self, adjacentUnit)
    --Create trashbag to hold all these entities and beams
        if not self.AdjacencyBeamsBag then
            self.AdjacencyBeamsBag = {}
        end

        for k,v in self.AdjacencyBeamsBag do
            if v.Unit:GetEntityId() == adjacentUnit:GetEntityId() then
                return
            end
        end
        self:ForkThread( EffectUtil.CreateAdjacencyBeams, adjacentUnit, self.AdjacencyBeamsBag )
    end,

    DestroyAdjacentEffects = function(self, adjacentUnit)
        if not self.AdjacencyBeamsBag then return end

        for k, v in self.AdjacencyBeamsBag do
            if v.Unit:BeenDestroyed() or v.Unit.Dead then
                v.Trash:Destroy()
                self.AdjacencyBeamsBag[k] = nil
            end
        end
    end,
}
