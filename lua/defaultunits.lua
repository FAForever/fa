-- ****************************************************************************
-- **
-- **  File     :  /lua/defaultunits.lua
-- **  Author(s):  John Comes, Gordon Duclos
-- **
-- **  Summary  :  Default definitions of units
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local Unit = import('/lua/sim/Unit.lua').Unit
local Shield = import('shield.lua').Shield
local explosion = import('defaultexplosions.lua')
local Util = import('utilities.lua')
local EffectUtil = import('EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local EffectUtil = import('EffectUtilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local Buff = import('/lua/sim/Buff.lua')
local AdjacencyBuffs = import('/lua/sim/AdjacencyBuffs.lua')

local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread
local CreateAeonBuildBaseThread = EffectUtil.CreateAeonBuildBaseThread

local CreateScaledBoom = function(unit, overkill, bone)
    explosion.CreateDefaultHitExplosionAtBone(
        unit,
        bone or 0,
        explosion.CreateUnitExplosionEntity(unit, overkill).Spec.BoundingXZRadius
    )
end

-----------------------------------------------------------------
--  MISC UNITS
-----------------------------------------------------------------
DummyUnit = Class(Unit) {
    OnStopBeingBuilt = function(self,builder,layer)
        self:Destroy()
    end,
}

-----------------------------------------------------------------
--  STRUCTURE UNITS
-----------------------------------------------------------------
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

    OnStartBeingBuilt = function(self, builder, layer)
        Unit.OnStartBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint()
        if bp.Physics.FlattenSkirt and not self:HasTarmac() and bp.General.FactionName ~= "Seraphim" then
            if self.TarmacBag then
                self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            else
                self:CreateTarmac(true, true, true, false, false)
            end
        end
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        Unit.OnStopBeingBuilt(self,builder,layer)
        -- Whaa why can't we have sane inheritance chains :/
        if self:GetBlueprint().General.FactionName == "Seraphim" then
            self:CreateTarmac(true, true, true, false, false)
        end
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

    -- Refresh intel on a destroyed / upgraded unit by setting vision on the actual blip.
    -- The expired blip will actually be destroyed right after when the intel system notices it's no longer there
    RefreshIntel = function(self)
        local army = self:GetArmy()
        for i, brain in ArmyBrains do
            if army ~= i and not IsAlly(i, army) then
                local blip = self:GetBlip(i)

                if blip then
                    if not blip:IsSeenEver(i) and (blip:IsOnRadar(i) or blip:IsOnSonar(i)) then
                        -- Remove dead radar blip out of map so we don't reveal what's under it
                        blip:SetPosition(Vector(-100, 0, -100), true)
                    end

                    -- expired blip will disappear with this
                    blip:InitIntel(i, 'Vision', 2)
                    blip:EnableIntel('Vision')
                end
            end
        end
    end,

    DestroyUnit = function(self)
        self:RefreshIntel()
        Unit.DestroyUnit(self)
    end,

    -- Adding into OnDestroy the ability to destroy the tarmac but put a new one down that looks exactly like it but
    -- will time out over the time spec'd or 300 seconds.
    OnDestroy = function(self)
        Unit.OnDestroy(self)
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

---------------------------------------------------------------
--  FACTORY  UNITS
---------------------------------------------------------------
FactoryUnit = Class(StructureUnit) {
    OnCreate = function(self)
        -- Engymod addition: If a normal factory is created, we should check for research stations
        if EntityCategoryContains(categories.FACTORY, self) then
           self:updateBuildRestrictions()
        end

        StructureUnit.OnCreate(self)
        self.BuildingUnit = false
    end,

    DestroyUnitBeingBuilt = function(self)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() < 1 then
            if self.UnitBeingBuilt:GetFractionComplete() > 0.5 then
                self.UnitBeingBuilt:Kill()
            else
                self.UnitBeingBuilt:Destroy()
            end
        end
    end,

    OnDestroy = function(self)
        -- Figure out if we're a research station
        if EntityCategoryContains(categories.RESEARCH, self) then
            local aiBrain = self:GetAIBrain()
            local buildRestrictionVictims = aiBrain:GetListOfUnits(categories.FACTORY+categories.ENGINEER, false)

            for id, unit in buildRestrictionVictims do
                unit:updateBuildRestrictions()
            end
        end

        StructureUnit.OnDestroy(self)

        self.DestroyUnitBeingBuilt(self)
    end,

    OnPaused = function(self)
        --When factory is paused take some action
        self:StopUnitAmbientSound( 'ConstructLoop' )
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound( 'ConstructLoop' )
        end
        StructureUnit.OnUnpaused(self)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitMassStorage(self)
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
        local curMass = aiBrain:GetEconomyStoredRatio('MASS')
        if curEnergy > 0.11 and curMass > 0.11 then
            self:CreateBlinkingLights('Green')
            self.BlinkingLightsState = 'Green'
        else
            self:CreateBlinkingLights('Red')
            self.BlinkingLightsState = 'Red'
        end

        -- If we're a HQ, update build restrictions for all factories
        if EntityCategoryContains(categories.RESEARCH, self) then
            local buildRestrictionVictims = aiBrain:GetListOfUnits(categories.FACTORY + categories.ENGINEER, false)
            for id, unit in buildRestrictionVictims do
                unit:updateBuildRestrictions()
            end
        end

        StructureUnit.OnStopBeingBuilt(self,builder,layer)
    end,

    ChangeBlinkingLights = function(self, state)
        local bls = self.BlinkingLightsState
        if state == 'Yellow' then
            if bls == 'Green' then
                self:CreateBlinkingLights('Yellow')
                self.BlinkingLightsState = state
            end
        elseif state == 'Green' then
            if bls == 'Yellow' then
                self:CreateBlinkingLights('Green')
                self.BlinkingLightsState = state
            elseif bls == 'Red' then
                local aiBrain = GetArmyBrain(self:GetArmy())
                local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
                local curMass = aiBrain:GetEconomyStoredRatio('MASS')
                if curEnergy > 0.11 and curMass > 0.11 then
                    if self:GetNumBuildOrders(categories.ALLUNITS) == 0 then
                        self:CreateBlinkingLights('Green')
                        self.BlinkingLightsState = state
                    else
                        self:CreateBlinkingLights('Yellow')
                        self.BlinkingLightsState = 'Yellow'
                    end
                end
            end
        elseif state == 'Red' then
            self:CreateBlinkingLights('Red')
            self.BlinkingLightsState = state
        end
    end,

    OnMassStorageStateChange = function(self, newState)
        if newState == 'EconLowMassStore' then
            self:ChangeBlinkingLights('Red')
        else
            self:ChangeBlinkingLights('Green')
        end
    end,

    OnEnergyStorageStateChange = function(self, newState)
        if newState == 'EconLowEnergyStore' then
            self:ChangeBlinkingLights('Red')
        else
            self:ChangeBlinkingLights('Green')
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order )
        self:ChangeBlinkingLights('Yellow')
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order )
        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        end
        self.FactoryBuildFailed = false
    end,

    --- Introduce a rolloff delay, where defined.
    OnStopBuild = function(self, unitBeingBuilt, order )
        local bp = self:GetBlueprint()
        if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
            self:ForkThread(self.PauseThread, bp.General.RolloffDelay, unitBeingBuilt, order)
        else
            self:DoStopBuild(unitBeingBuilt, order)
        end
    end,

    --- Adds a pause between unit productions
    PauseThread = function(self, productionpause, unitBeingBuilt, order)
        self:StopBuildFx()
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)

        WaitSeconds(productionpause)

        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        self:DoStopBuild(unitBeingBuilt, order)
    end,

    DoStopBuild = function(self, unitBeingBuilt, order )
        StructureUnit.OnStopBuild(self, unitBeingBuilt, order )

        if not self.FactoryBuildFailed and not self.Dead then
            if not EntityCategoryContains(categories.AIR, unitBeingBuilt) then
                self:RollOffUnit()
            end
            self:StopBuildFx()
            self:ForkThread(self.FinishBuildThread, unitBeingBuilt, order )
        end
        self.BuildingUnit = false
    end,

    FinishBuildThread = function(self, unitBeingBuilt, order )
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim)
            self.Trash:Add(self.RollOffAnim)
            WaitTicks(1)
            WaitFor(self.RollOffAnim)
        end
        if unitBeingBuilt and not unitBeingBuilt.Dead then
            unitBeingBuilt:DetachFrom(true)
        end
        self:DetachAll(bp.Display.BuildAttachBone or 0)
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end
    end,

    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,

    OnFailedToBuild = function(self)
        self.FactoryBuildFailed = true
        StructureUnit.OnFailedToBuild(self)
        self:DestroyBuildRotator()
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    RollOffUnit = function(self)
        local spin, x, y, z = self:CalculateRollOffPoint()
        self.MoveCommand = IssueMove({self.UnitBeingBuilt}, Vector(x, y, z))
    end,

    CalculateRollOffPoint = function(self)
        local bp = self:GetBlueprint().Physics.RollOffPoints
        local px, py, pz = unpack(self:GetPosition())
        if not bp then return 0, px, py, pz end
        local vectorObj = self:GetRallyPoint()
        local bpKey = 1
        local distance, lowest = nil
        for k, v in bp do
            distance = VDist2(vectorObj[1], vectorObj[3], v.X + px, v.Z + pz)
            if not lowest or distance < lowest then
                bpKey = k
                lowest = distance
            end
        end
        local fx, fy, fz, spin
        local bpP = bp[bpKey]
        local unitBP = self.UnitBeingBuilt:GetBlueprint().Display.ForcedBuildSpin
        if unitBP then
            spin = unitBP
        else
            spin = bpP.UnitSpin
        end
        fx = bpP.X + px
        fy = bpP.Y + py
        fz = bpP.Z + pz
        return spin, fx, fy, fz
    end,

    StartBuildFx = function(self, unitBeingBuilt)

    end,

    StopBuildFx = function(self)

    end,

    PlayFxRollOff = function(self)
    end,

    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(-1)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    CreateBuildRotator = function(self)
        if not self.BuildBoneRotator then
            local spin = self:CalculateRollOffPoint()
            local bp = self:GetBlueprint().Display
            self.BuildBoneRotator = CreateRotator(self, bp.BuildAttachBone or 0, 'y', spin, 10000)
            self.Trash:Add(self.BuildBoneRotator)
        end
    end,

    DestroyBuildRotator = function(self)
        if self.BuildBoneRotator then
            self.BuildBoneRotator:Destroy()
            self.BuildBoneRotator = nil
        end
    end,

    RolloffBody = function(self)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayFxRollOff()
        -- Wait until unit has left the factory
        while not self.UnitBeingBuilt.Dead and self.MoveCommand and not IsCommandDone(self.MoveCommand) do
            WaitSeconds(0.5)
        end
        self.MoveCommand = nil
        self:PlayFxRollOffEnd()
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {

        Main = function(self)
            self:ChangeBlinkingLights('Green')
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
            self:DestroyBuildRotator()
        end,
    },

    BuildingState = State {

        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bp = self:GetBlueprint()
            local bone = bp.Display.BuildAttachBone or 0
            self:DetachAll(bone)
            unitBuilding:AttachBoneTo(-2, self, bone)
            self:CreateBuildRotator()
            self:StartBuildFx(unitBuilding)
        end,
    },


    RollingOffState = State {
        Main = function(self)
            self:RolloffBody()
        end,
    },
}


-------------------------------------------------------------
--  AIR FACTORY UNITS
-------------------------------------------------------------
AirFactoryUnit = Class(FactoryUnit) {
}

-------------------------------------------------------------
--  AIR STAGING PLATFORMS UNITS
-------------------------------------------------------------
AirStagingPlatformUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

-------------------------------------------------------------
-- ENERGY CREATION UNITS
-------------------------------------------------------------
ConcreteStructureUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}

-------------------------------------------------------------
--  ENERGY CREATION UNITS
-------------------------------------------------------------
EnergyCreationUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
}

-------------------------------------------------------------
--  ENERGY STORAGE UNITS
-------------------------------------------------------------
EnergyStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
        if curEnergy > 0.11 then
            self:CreateBlinkingLights('Yellow')
        else
            self:CreateBlinkingLights('Red')
        end
    end,

    OnEnergyStorageStateChange = function(self, newState)
        if newState == 'EconLowEnergyStore' then
            self:CreateBlinkingLights('Red')
        elseif newState == 'EconMidEnergyStore' then
            self:CreateBlinkingLights('Yellow')
        elseif newState == 'EconFullEnergyStore' then
            self:CreateBlinkingLights('Green')
        end
    end,

}

--------------------------------------------------------------
--  LAND FACTORY UNITS
--------------------------------------------------------------
LandFactoryUnit = Class(FactoryUnit) {}


--------------------------------------------------------------
-- MASS COLLECTION UNITS
--------------------------------------------------------------
MassCollectionUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:ApplyAdjacencyBuffs()
        self._productionActive = true
    end,

    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:RemoveAdjacencyBuffs()
        self._productionActive = false
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        local markers = ScenarioUtils.GetMarkers()
        local unitPosition = self:GetPosition()

        for k, v in pairs(markers) do
            if(v.type == 'MASS') then
                local massPosition = v.position
                if( (massPosition[1] < unitPosition[1] + 1) and (massPosition[1] > unitPosition[1] - 1) and
                    (massPosition[2] < unitPosition[2] + 1) and (massPosition[2] > unitPosition[2] - 1) and
                    (massPosition[3] < unitPosition[3] + 1) and (massPosition[3] > unitPosition[3] - 1)) then
                    self:SetProductionPerSecondMass(self:GetProductionPerSecondMass() * (v.amount / 100))
                    break
                end
            end
        end
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:AddCommandCap('RULEUCC_Stop')
        self.UpgradeWatcher = self:ForkThread(self.WatchUpgradeConsumption)
    end,

    OnStopBuild = function(self, unitbuilding, order)
        StructureUnit.OnStopBuild(self, unitbuilding, order)
        self:RemoveCommandCap('RULEUCC_Stop')
        if self.UpgradeWatcher then
            KillThread(self.UpgradeWatcher)
            self:SetConsumptionPerSecondMass(0)
            self:SetProductionPerSecondMass((self:GetBlueprint().Economy.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
        end
    end,
    -- band-aid on lack of multiple separate resource requests per unit...
    -- if mass econ is depleted, take all the mass generated and use it for the upgrade

    --Old WatchUpgradeConsumption replaced with this on, enabling mex to not use resources when paused
    WatchUpgradeConsumption = function(self)
        local bp = self:GetBlueprint()
        local massConsumption = self:GetConsumptionPerSecondMass()

        -- Fix for weird mex behaviour when upgrading with depleted resource stock or while paused [100]
        -- Replaced Gowerly's fix with this which is very much inspired by his code. My code looks much better and
        -- seems to work a little better aswell.

        local aiBrain = self:GetAIBrain()

        local CalcEnergyFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored( 'ENERGY' ) < self:GetConsumptionPerSecondEnergy() then
                fraction = math.min( 1, aiBrain:GetEconomyIncome('ENERGY') / aiBrain:GetEconomyRequested('ENERGY') )
            end
            return fraction
        end

        local CalcMassFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored( 'MASS' ) < self:GetConsumptionPerSecondMass() then
                fraction = math.min( 1, aiBrain:GetEconomyIncome('MASS') / aiBrain:GetEconomyRequested('MASS') )
            end
            return fraction
        end

        while not self.Dead do
            local massProduction = bp.Economy.ProductionPerSecondMass * (self.MassProdAdjMod or 1)
            if self:IsPaused() then
                -- paused mex upgrade (another bug here that caused paused upgrades to continue use resources)
                self:SetConsumptionPerSecondMass( 0 )
                self:SetProductionPerSecondMass( massProduction * CalcEnergyFraction() )
            elseif aiBrain:GetEconomyStored( 'MASS' ) < 1 then
                -- mex upgrade while out of mass (this is where the engine code has a bug)
                self:SetConsumptionPerSecondMass( massConsumption )
                self:SetProductionPerSecondMass( massProduction / CalcMassFraction() )
                -- to use Gowerly's words; the above division cancels the engine bug like matter and anti-matter.
                -- the engine seems to do the exact opposite of this division.
            else
                -- mex upgrade while enough mass (don't care about energy, that works fine)
                self:SetConsumptionPerSecondMass( massConsumption )
                self:SetProductionPerSecondMass( massProduction * CalcEnergyFraction() )
            end

            WaitTicks(1)
        end
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
    end,

    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound( 'ActiveLoop' )
    end,

    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound( 'ActiveLoop' )
    end,
}

--------------------------------------------------------------
--  MASS FABRICATION UNITS
--------------------------------------------------------------
MassFabricationUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
    end,

    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
        self:ApplyAdjacencyBuffs()
        self._productionActive = true
    end,

    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
        self:RemoveAdjacencyBuffs()
        self._productionActive = false
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
    end,

    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound( 'ActiveLoop' )
    end,

    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound( 'ActiveLoop' )
    end,
}

--------------------------------------------------------------
--  MASS STORAGE UNITS
--------------------------------------------------------------
MassStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitMassStorage(self)
        local curMass = aiBrain:GetEconomyStoredRatio('MASS')
        if curMass > 0.11 then
            self:CreateBlinkingLights('Yellow')
        else
            self:CreateBlinkingLights('Red')
        end
    end,

    OnMassStorageStateChange = function(self, newState)
        if newState == 'EconLowMassStore' then
            self:CreateBlinkingLights('Red')
        elseif newState == 'EconMidMassStore' then
            self:CreateBlinkingLights('Yellow')
        elseif newState == 'EconFullMassStore' then
            self:CreateBlinkingLights('Green')
        end
    end,
}

--------------------------------------------------------------
--  RADAR UNITS
--------------------------------------------------------------
RadarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        self:DestroyIdleEffects()
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Red')
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Green')
        self:CreateIdleEffects()
    end,
}


--------------------------------------------------------------
--  RADAR JAMMER UNITS
--------------------------------------------------------------
RadarJammerUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    -- Shut down intel while upgrading
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Construction', 'Jammer')
        self:DisableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    OnStopBuild = function(self, unitBeingBuilt)
        StructureUnit.OnStopBuild(self, unitBeingBuilt)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    OnFailedToBuild = function(self)
        StructureUnit.OnStopBuild(self)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        if self.IntelEffects and not self.IntelFxOn then
            self.IntelEffectsBag = {}
            self.CreateTerrainTypeEffects( self, self.IntelEffects, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag )
            self.IntelFxOn = true
        end
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        EffectUtil.CleanupEffectBag(self,'IntelEffectsBag')
        self.IntelFxOn = false
    end,
}

---------------------------------------------------------------
--  SONAR UNITS
---------------------------------------------------------------
SonarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self,builder,layer)
        StructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,

    CreateIdleEffects = function(self)
        StructureUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread( self.TimedIdleSonarEffects )
    end,

    TimedIdleSonarEffects = function( self )
        local layer = self:GetCurrentLayer()
        local army = self:GetArmy()
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects( 'FXIdle', layer, pos, vTypeGroup.Type, nil )

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            emit = CreateAttachedEmitter(self,vBone,army,vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds( 6.0 )
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        StructureUnit.DestroyIdleEffects(self)
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Red')
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        self:DestroyBlinkingLights()
        self:CreateBlinkingLights('Green')
    end,
}



--------------------------------------------------------------
-- SEA FACTORY UNITS
--------------------------------------------------------------
SeaFactoryUnit = Class(FactoryUnit) {
    -- Disable the default rocking behavior
    StartRocking = function(self)
    end,

    StopRocking = function(self)
    end,

    DestroyUnitBeingBuilt = function(self)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() < 1 then
            self.UnitBeingBuilt:Destroy()
        end
    end,
}



--------------------------------------------------------------
--  SHIELD STRCUTURE UNITS
--------------------------------------------------------------
ShieldStructureUnit = Class(StructureUnit) {

    UpgradingState = State(StructureUnit.UpgradingState) {
        Main = function(self)
            StructureUnit.UpgradingState.Main(self)
        end,

        OnFailedToBuild = function(self)
            StructureUnit.UpgradingState.OnFailedToBuild(self)
        end,
    }
}

--------------------------------------------------------------
--  TRANSPORT BEACON UNITS
--------------------------------------------------------------
TransportBeaconUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    --{'/effects/emitters/red_smoke_beacon_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    -- invincibility!  (the only way to kill a transport beacon is
    -- to kill the transport unit generating it)
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
    end,
}

--------------------------------------------------------------
--  WALL STRCUTURE UNITS
--------------------------------------------------------------
WallStructureUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
}

--------------------------------------------------------------
--  QUANTUM GATE UNITS
--------------------------------------------------------------
QuantumGateUnit = Class(FactoryUnit) {
    OnKilled = function(self, instigator, type, overkillRatio)
        self:StopUnitAmbientSound( 'ActiveLoop' )
        FactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

}

--------------------------------------------------------------
--  MOBILE UNITS
--------------------------------------------------------------
MobileUnit = Class(Unit) {
    TerrainType = nil,

    -- Added for engymod. After creating an enhancement, units must re-check their build restrictions
    CreateEnhancement = function(self, enh)
        Unit.CreateEnhancement(self, enh)
        self:updateBuildRestrictions()
    end,

    -- Added for engymod. When created, units must re-check their build restrictions
    OnCreate = function(self)
        Unit.OnCreate(self)
        self:updateBuildRestrictions()
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        --Add unit's threat to our influence map
        local threat = 5
        local decay = 0.1
        local currentLayer = self:GetCurrentLayer()
        if instigator then
            local unit = false
            if IsUnit(instigator) then
                unit = instigator
            elseif IsProjectile(instigator) or IsCollisionBeam(instigator) then
                unit = instigator.unit
            end

            if unit then
                local unitPos = unit:GetCachePosition()
                if EntityCategoryContains(categories.STRUCTURE, unit) then
                    decay = 0.01
                end

                if unitPos then
                    if currentLayer == 'Sub' then
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiSub')
                    elseif currentLayer == 'Air' then
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiAir')
                    else
                        threat = self:GetAIBrain():GetThreatAtPosition(unitPos, 0, true, 'AntiSurface')
                    end
                    threat = threat / 2
                end
            end
        end

        if currentLayer == 'Sub' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay*10, 'AntiSub')
        elseif currentLayer == 'Air' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay, 'AntiAir')
        elseif currentLayer == 'Water' then
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay*10, 'AntiSurface')
        else
            self:GetAIBrain():AssignThreatAtPosition(self:GetPosition(), threat, decay, 'AntiSurface')
        end

        Unit.OnKilled(self, instigator, type, overkillRatio)
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = self:GetBlueprint()
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            EffectUtil.CreateUEFUnitBeingBuiltEffects( self, builder, self.OnBeingBuiltEffectsBag )
        end
    end,

    CreateReclaimEffects = function(self, target)
        EffectUtil.PlayReclaimEffects( self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0}, self.ReclaimEffectsBag )
    end,

    CreateReclaimEndEffects = function(self, target)
        EffectUtil.PlayReclaimEndEffects(self, target)
    end,

    CreateCaptureEffects = function(self, target)
        EffectUtil.PlayCaptureEffects(self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0}, self.CaptureEffectsBag)
    end,

    -- Units with layer change effects (amphibious units like Megalith) need
    -- those changes applied when build ends, so we need to trigger the
    -- layer change event
    OnStopBeingBuilt = function(self,builder,layer)
       Unit.OnStopBeingBuilt(self,builder,layer)
       self:OnLayerChange(layer, 'None')
    end,

    OnTerrainTypeChange = function(self, new, old)
        self.TerrainType = new

        if self.MovementEffectsExist then
            self:DestroyMovementEffects()
            self:CreateMovementEffects( self.MovementEffectsBag, nil, new )
        end
    end,

    CreateTreads = function(self, treads)
        if treads.ScrollTreads then
            self:AddThreadScroller(1.0, treads.ScrollMultiplier or 0.2)
        end
        self.TreadThread = nil
        if treads.TreadMarks then
            local type = self:GetTTTreadType(self:GetPosition())
            if type ~= 'None' then
                self.TreadThread = self:ForkThread(self.CreateTreadsThread, treads.TreadMarks)
            end
        end
    end,

    CreateTreadsThread = function(self, treadsBP)
        local ux, uy, uz = self:GetUnitSizes()
        local wait
        local treads = {}
        local army = self:GetArmy()

        for _, t in treadsBP do
            local bones = t.Bones or t.BoneName or 0
            if type(bones) ~= 'table' then bones = {bones} end
            wait = math.max(0.1, math.min(wait or 1, t.TreadMarksInterval or 1))
            table.insert(treads, {texture=t.TreadMarks, x=t.TreadMarksSizeX, z=t.TreadMarksSizeZ, offset=t.TreadOffset, bones=bones or t.BoneName or 0, duration=t.TreadLifeTime or 10})
        end

        local heading, last_heading
        while self.CurrentLayer == 'Land' or self.CurrentLayer == 'Seabed' do
            heading = self:GetHeading()
            for _, t in treads do
                for _, bone in t.bones do
                    -- CreateSplatOnBone doesn't support unit heading unless bone == 0, that's why we need to do this
                    if bone ~= 0 then
                        local splat = CreateSplat(self:GetPosition(bone), heading, t.texture, t.x, t.z, 130, t.duration, army)
                    else
                        CreateSplatOnBone(self, t.offset, 0, t.texture, t.x, t.z, 130, t.duration, army)
                    end
                end
                --
            end

            WaitSeconds(last_heading and math.abs(last_heading - heading) < 0.05 and wait or wait*0.7)
            last_heading = heading
        end
    end,

    PlayLayerAmbientSound = function(self, type)
        return self:PlayUnitAmbientSound(type .. self.CurrentLayer) or self:PlayUnitAmbientSound(type)
    end,

    PlayLayerSound = function(self, type)
        return self:PlayUnitSound(type .. self.CurrentLayer) or self:PlayUnitSound(type)
    end,

    StopAmbientMoveSound = function(self)
        self:StopUnitAmbientSound( 'AmbientMove' )
        self:StopUnitAmbientSound( 'AmbientMoveWater' )
        self:StopUnitAmbientSound( 'AmbientMoveSub' )
        self:StopUnitAmbientSound( 'AmbientMoveLand' )
    end,

    OnLayerChange = function(self, new, old)
        self.CurrentLayer = new

        for i = 1, self:GetWeaponCount() do
            self:GetWeapon(i):SetValidTargetsForCurrentLayer(new)
        end

        if (old == 'Seabed' or old == 'None') and new == 'Land' then
            self:EnableIntel('Vision')
            self:DisableIntel('WaterVision')
        elseif (old == 'Land' or old == 'None') and new == 'Seabed' then
            self:EnableIntel('WaterVision')
        elseif (old == 'None') then
            self:EnableIntel('Vision')
        end

        if new == 'Land' or new == 'Water' then
            self:PlayLayerSound('Transition')
        end

        self:CreateLayerChangeEffects( new, old )
    end,

    OnMotionHorzEventChange = function(self, new, old)
        if self.Dead then
            return
        end

        local old_stop = old == 'Stopped' or old == 'Stopping'
        local new_stop = new == 'Stopped' or new == 'Stopping'

        if old_stop and not new_stop then
            -- Try the specialised sound, fall back to the general one.
            self:PlayLayerSound('StartMove')
            self:PlayLayerAmbientSound('AmbientMove')
        elseif new_stop then
            if not old_stop then
                -- Try the specialised sound, fall back to the general one.
                self:PlayLayerSound('StopMove')
            end
            self:StopAmbientMoveSound()
        end

        if self.MovementEffectsExist then
            self:UpdateMovementEffectsOnMotionEventChange(new, old)
        end

        if old == 'Stopped' then
            self:DoOnHorizontalStartMoveCallbacks()
        end

        for i = 1, self:GetWeaponCount() do
            local wep = self:GetWeapon(i)
            wep:OnMotionHorzEventChange(new, old)
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        self:CreateMotionChangeEffects(new,old)
    end,

    -- Called as planes whoosh round corners. No sounds were shipped for use with this and it was a
    -- cycle eater, so we killed it.
    OnMotionTurnEventChange = function() end,

    OnTerrainTypeChange = function(self, new, old) end,

    UpdateMovementEffectsOnMotionEventChange = function( self, new, old )

    end,

    GetTTTreadType = function( self, pos )
        local TerrainType = GetTerrainType( pos.x,pos.z )
        return TerrainType.Treads or 'None'
    end,

    CreateMovementEffects = function( self, EffectsBag, TypeSuffix, TerrainType )
        local layer = self.CurrentLayer
        local bpTable = self:GetBlueprint().Display.MovementEffects

        if bpTable[layer] then
            bpTable = bpTable[layer]
            local effectTypeGroups = bpTable.Effects

            if bpTable.Treads then
                self:CreateTreads( bpTable.Treads )
            else
                self:RemoveScroller()
            end

            if (not effectTypeGroups or (effectTypeGroups and (table.getn(effectTypeGroups) == 0))) then
                if not self.Footfalls and bpTable.Footfall then
                    LOG('*WARNING: No movement effect groups defined for unit ',repr(self:GetUnitId()),', Effect groups with bone lists must be defined to play movement effects. Add these to the Display.MovementEffects', layer, '.Effects table in unit blueprint. ' )
                end
                return false
            end

            if bpTable.CameraShake then
                self.CamShakeT1 = self:ForkThread(self.MovementCameraShakeThread, bpTable.CameraShake )
            end
            self:CreateTerrainTypeEffects( effectTypeGroups, 'FXMovement', layer, TypeSuffix, EffectsBag, TerrainType )
        end
    end,

    CreateLayerChangeEffects = function( self, new, old )
        local key = old..new
        local bpTable = self:GetBlueprint().Display.LayerChangeEffects[key]

        if bpTable then
            self:CreateTerrainTypeEffects( bpTable.Effects, 'FXLayerChange', key )
        end
    end,

    CreateMotionChangeEffects = function( self, new, old )
        local key = self.CurrentLayer .. old .. new
        local bpTable = self:GetBlueprint().Display.MotionChangeEffects[key]

        if bpTable then
            self:CreateTerrainTypeEffects( bpTable.Effects, 'FXMotionChange', key )
        end
    end,

    DestroyMovementEffects = function( self )
        local bpTable = self:GetBlueprint().Display.MovementEffects
        local layer = self.CurrentLayer

        EffectUtil.CleanupEffectBag(self,'MovementEffectsBag')

        --Clean up any camera shake going on.
        if self.CamShakeT1 then
            KillThread( self.CamShakeT1 )
            local shake = bpTable[layer].CameraShake
            if shake and shake.Radius and shake.MaxShakeEpicenter and shake.MinShakeAtRadius then
                self:ShakeCamera( shake.Radius, shake.MaxShakeEpicenter * 0.25, shake.MinShakeAtRadius * 0.25, 1 )
            end
        end

        --Clean up treads
        if self.TreadThread then
            KillThread(self.TreadThread)
            self.TreadThread = nil
        end

        if bpTable[layer].Treads.ScrollTreads then
            self:RemoveScroller()
        end
    end,

    DestroyTopSpeedEffects = function( self )
        EffectUtil.CleanupEffectBag(self,'TopSpeedEffectsBag')
    end,

    DestroyIdleEffects = function( self )
        EffectUtil.CleanupEffectBag(self,'IdleEffectsBag')
    end,

    UpdateBeamExhaust = function( self, motionState )
        local bpTable = self:GetBlueprint().Display.MovementEffects.BeamExhaust
        if not bpTable then
            return false
        end

        if motionState == 'Idle' then
            if self.BeamExhaustCruise  then
                self:DestroyBeamExhaust()
            end
            if self.BeamExhaustIdle and (table.getn(self.BeamExhaustEffectsBag) == 0) and (bpTable.Idle ~= false) then
                self:CreateBeamExhaust( bpTable, self.BeamExhaustIdle )
            end
        elseif motionState == 'Cruise' then
            if self.BeamExhaustIdle and self.BeamExhaustCruise then
                self:DestroyBeamExhaust()
            end
            if self.BeamExhaustCruise and (bpTable.Cruise ~= false) then
                self:CreateBeamExhaust( bpTable, self.BeamExhaustCruise )
            end
        elseif motionState == 'Landed' then
            if not bpTable.Landed then
                self:DestroyBeamExhaust()
            end
        end
    end,

    CreateBeamExhaust = function( self, bpTable, beamBP )
        local effectBones = bpTable.Bones
        if not effectBones or (effectBones and (table.getn(effectBones) == 0)) then
            LOG('*WARNING: No beam exhaust effect bones defined for unit ',repr(self:GetUnitId()),', Effect Bones must be defined to play beam exhaust effects. Add these to the Display.MovementEffects.BeamExhaust.Bones table in unit blueprint.' )
            return false
        end
        local army = self:GetArmy()
        for kb, vb in effectBones do
            table.insert( self.BeamExhaustEffectsBag, CreateBeamEmitterOnEntity(self, vb, army, beamBP ))
        end
    end,

    DestroyBeamExhaust = function( self )
        EffectUtil.CleanupEffectBag(self,'BeamExhaustEffectsBag')
    end,

    CreateContrails = function(self, tableData )
        local effectBones = tableData.Bones
        if not effectBones or (effectBones and (table.getn(effectBones) == 0)) then
            LOG('*WARNING: No contrail effect bones defined for unit ',repr(self:GetUnitId()),', Effect Bones must be defined to play contrail effects. Add these to the Display.MovementEffects.Air.Contrail.Bones table in unit blueprint. ' )
            return false
        end
        local army = self:GetArmy()
        local ZOffset = tableData.ZOffset or 0.0
        for ke, ve in self.ContrailEffects do
            for kb, vb in effectBones do
                table.insert(self.TopSpeedEffectsBag, CreateTrail(self,vb,army,ve):SetEmitterParam('POSITION_Z', ZOffset))
            end
        end
    end,

    MovementCameraShakeThread = function( self, camShake )
        local radius = camShake.Radius or 5.0
        local maxShakeEpicenter = camShake.MaxShakeEpicenter or 1.0
        local minShakeAtRadius = camShake.MinShakeAtRadius or 0.0
        local interval = camShake.Interval or 10.0
        if interval ~= 0.0 then
            while true do
                self:ShakeCamera( radius, maxShakeEpicenter, minShakeAtRadius, interval )
                WaitSeconds(interval)
            end
        end
    end,
}

--------------------------------------------------------------
--  WALKING LAND UNITS
--------------------------------------------------------------
WalkingLandUnit = Class(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    UpdateMovementEffectsOnMotionEventChange = function(self, new, old)
        if self.Detector then
            if new == 'Stopped' then
                self.Detector:Disable()
            elseif old == 'Stopped' then
                self.Detector:Enable()
            end
        end

        MobileUnit.UpdateMovementEffectsOnMotionEventChange()
    end,

    OnLayerChange = function(self, new, old)
        local footfall = self:GetBlueprint().Display.MovementEffects[new].Footfall
        if not self.Footfalls and footfall then
            self.Footfalls = self:CreateFootFallManipulators(footfall)
        end

        MobileUnit.OnLayerChange(self, new, old)
    end,

    OnMotionHorzEventChange = function(self, new, old)
        local display = self:GetBlueprint().Display

        if old == 'Stopped' then
            if not self.Animator then
                self.Animator = CreateAnimator(self, true)
            end
            if display.AnimationWalk then
                self.Animator:PlayAnim(display.AnimationWalk, true)
                self.Animator:SetRate(display.AnimationWalkRate or 1)
            end
        elseif new == 'Stopped' then
            -- only keep the animator around if we are dying and playing a death anim
            -- or if we have an idle anim
            if(self.IdleAnim and not self.Dead) then
                self.Animator:PlayAnim(self.IdleAnim, true)
            elseif(not self.DeathAnim or not self.Dead) then
                self.Animator:Destroy()
                self.Animator = false
            end
        end

        MobileUnit.OnMotionHorzEventChange(self, new, old)
    end,

    OnAnimCollision = function(self, bone, x, y, z)
        local layer = self.CurrentLayer
        local bpTable = self:GetBlueprint().Display.MovementEffects
        local footfall = bpTable[layer].Footfall

        if footfall then
            local effects = {}
            local scale = 1
            local offset = nil
            local army = self:GetArmy()
            local boneTable = nil

            if footfall.Damage then
                local bpDamage = footfall.Damage
                DamageArea(self, self:GetPosition(bone), bpDamage.Radius, bpDamage.Amount, bpDamage.Type, bpDamage.DamageFriendly )
            end

            if footfall.CameraShake then
                local shake = footfall.CameraShake
                self:ShakeCamera( shake.Radius, shake.MaxShakeEpicenter, shake.MinShakeAtRadius, shake.Interval )
            end

            for k, v in footfall.Bones do
                if bone == v.FootBone then
                    boneTable = v
                    bone = v.FootBone
                    scale = boneTable.Scale or 1
                    offset = bone.Offset
                    if v.Type then
                        effects = self.GetTerrainTypeEffects( 'FXMovement', layer, self:GetPosition(v.FootBone), v.Type )
                    end
                    break
                end
            end

            if boneTable.Tread and self:GetTTTreadType(self:GetPosition(bone)) ~= 'None' then
                CreateSplatOnBone(self, boneTable.Tread.TreadOffset, 0, boneTable.Tread.TreadMarks, boneTable.Tread.TreadMarksSizeX, boneTable.Tread.TreadMarksSizeZ, 100, boneTable.Tread.TreadLifeTime or 15, army )
                local treadOffsetX = boneTable.Tread.TreadOffset[1]
                if x and x > 0 then
                    if layer ~= 'Seabed' then
                    self:PlayUnitSound('FootFallLeft')
                    else
                        self:PlayUnitSound('FootFallLeftSeabed')
                    end
                elseif x and x < 0 then
                    if layer ~= 'Seabed' then
                    self:PlayUnitSound('FootFallRight')
                    else
                        self:PlayUnitSound('FootFallRightSeabed')
                    end
                end
            end

            for k, v in effects do
                CreateEmitterAtBone(self, bone, army, v):ScaleEmitter(scale):OffsetEmitter(offset.x or 0,offset.y or 0,offset.z or 0)
            end
        end
        if layer ~= 'Seabed' then
            self:PlayUnitSound('FootFallGeneric')
        else
            self:PlayUnitSound('FootFallGenericSeabed')
        end
    end,

    CreateFootFallManipulators = function( self, footfall )
        if not footfall.Bones or (footfall.Bones and (table.getn(footfall.Bones) == 0)) then
            LOG('*WARNING: No footfall bones defined for unit ',repr(self:GetUnitId()),', ', 'these must be defined to animation collision detector and foot plant controller' )
            return false
        end

        self.Detector = CreateCollisionDetector(self)
        self.Trash:Add(self.Detector)
        for k, v in footfall.Bones do
            self.Detector:WatchBone(v.FootBone)
            if v.FootBone and v.KneeBone and v.HipBone then
                CreateFootPlantController(self, v.FootBone, v.KneeBone, v.HipBone, v.StraightLegs or true, v.MaxFootFall or 0):SetPrecedence(10)
            end
        end
        return true
    end,
}

--------------------------------------------------------------
--  SUB UNITS
--  These units typically float under the water and have wake when they move.
--------------------------------------------------------------
SubUnit = Class(MobileUnit) {
-- use default spark effect until underwater damaged states are made
    FxDamage1 = {EffectTemplate.DamageSparks01},
    FxDamage2 = {EffectTemplate.DamageSparks01},
    FxDamage3 = {EffectTemplate.DamageSparks01},

   -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,

    OnMotionVertEventChange = function( self, new, old )
        if self.Dead then
            return
        end

        MobileUnit.OnMotionVertEventChange(self, new, old)

        local layer = self.CurrentLayer

        --Surfacing and sinking, landing and take off idle effects
        if (new == 'Up' and old == 'Bottom') or
           (new == 'Down' and old == 'Top') then
            self:DestroyIdleEffects()
            if new == 'Up' and layer == 'Sub' then
                self:PlayUnitSound('SurfaceStart')
            end
            if new == 'Down' and layer == 'Water' then
                self:PlayUnitSound('SubmergeStart')
                if self.SurfaceAnimator then
                    self.SurfaceAnimator:SetRate(-1)
                end
            end
        end

        if (new == 'Top' and old == 'Up') or
           (new == 'Bottom' and old == 'Down') then
            self:CreateIdleEffects()
            if new == 'Bottom' and layer == 'Sub' then
                self:PlayUnitSound('SubmergeEnd')
            end
            if new == 'Top' and layer == 'Water' then
                self:PlayUnitSound('SurfaceEnd')
                local surfaceAnim = self:GetBlueprint().Display.AnimationSurface
                if not self.SurfaceAnimator and surfaceAnim then
                    self.SurfaceAnimator = CreateAnimator(self)
                end
                if surfaceAnim and self.SurfaceAnimator then
                    self.SurfaceAnimator:PlayAnim(surfaceAnim):SetRate(1)
                end
            end
        end
    end,
}

--------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
AirUnit = Class(MobileUnit) {

    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp',},
    BeamExhaustCruise = '/effects/emitters/air_move_trail_beam_03_emit.bp',
    BeamExhaustIdle = '/effects/emitters/air_idle_trail_beam_01_emit.bp',

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DestructionExplosionWaitDelayMax = 0,
    DestroyNoFallRandomChance = 0.5,

    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        self.HasFuel = true
        self:AddPingPong()
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        MobileUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint()
        if bp.SizeSphere then
            self:SetCollisionShape(
                'Sphere',
                bp.CollisionSphereOffsetX or 0,
                bp.CollisionSphereOffsetY or 0,
                bp.CollisionSphereOffsetZ or 0,
                bp.SizeSphere
            )
        end
    end,

    AddPingPong = function(self)
        local bp = self:GetBlueprint()
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                and bp.Pong2 and bp.Pong2Speed then
                self:AddPingPongScroller(bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                                         bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        MobileUnit.OnMotionVertEventChange( self, new, old )
        local army = self:GetArmy()
        local set_vision

        if new == 'Down' or new == 'Hover' or new == 'Bottom' then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound('ActiveLoop')
            if new == 'Down' then
                self:PlayUnitSound('Landing')
            else
                self:PlayUnitSound('Landed')
                if new == 'Bottom' then
                    self:UpdateBeamExhaust('Landed')
                    -- While landed, planes can only see half as far
                    set_vision = (self:GetBlueprint().Intel.VisionRadius or 0) / 2
                end
            end
        elseif old == 'Bottom' or old == 'Down' then
            self:PlayUnitSound('TakeOff')
            -- Set the vision radius back to default
            if old == 'Bottom' then
                set_vision = self:GetBlueprint().Intel.VisionRadius or 0
                self:UpdateBeamExhaust('Cruise')
            end
        end

        if set_vision then self:SetIntelRadius('Vision', set_vision) end
    end,

    UpdateMovementEffectsOnMotionEventChange = function(self, new, old)
        local layer = self.CurrentLayer
        local bpMTable = self:GetBlueprint().Display.MovementEffects

        if old == 'TopSpeed' then
            --Destroy top speed contrails and exhaust effects
            self:DestroyTopSpeedEffects()
        end

        if new == 'TopSpeed' and self.HasFuel then
            if bpMTable[layer].Contrails and self.ContrailEffects then
                self:CreateContrails( bpMTable[layer].Contrails )
            end
            if bpMTable[layer].TopSpeedFX then
                self:CreateMovementEffects( self.TopSpeedEffectsBag, 'TopSpeed' )
            end
        end

        if (old == 'Stopped' and new ~= 'Stopping') or
           (old == 'Stopping' and new ~= 'Stopped') then
            self:DestroyIdleEffects()
            self:DestroyMovementEffects()
            self:CreateMovementEffects( self.MovementEffectsBag, nil )
            if bpMTable.BeamExhaust then
                self:UpdateBeamExhaust( 'Cruise' )
            end
        end

        if new == 'Stopped' then
            self:DestroyMovementEffects()
            self:DestroyIdleEffects()
            self:CreateIdleEffects()
            if bpMTable.BeamExhaust then
                self:UpdateBeamExhaust( 'Idle' )
            end
        end

        MobileUnit.UpdateMovementEffectsOnMotionEventChange(self, new, old)
    end,

    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- penalize movement for running out of fuel
        self:SetSpeedMult(0.35)     -- change the speed of the unit by this mult
        self:SetAccMult(0.25)       -- change the acceleration of the unit by this mult
        self:SetTurnMult(0.25)      -- change the turn ability of the unit by this mult
    end,

    OnGotFuel = function(self)
        self.HasFuel = true
        -- revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
    end,

    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    OnImpact = function(self, with, other)
        if self.DeathBounce then
            return
        end
        self.DeathBounce = true

        -- Damage the area we have impacted with.
        local bp = self:GetBlueprint()
        local i = 1
        local numWeapons = table.getn(bp.Weapon)

        for i, numWeapons in bp.Weapon do
            if(bp.Weapon[i].Label == 'DeathImpact') then
                DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                break
            end
        end

        if(with == 'Water') then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffects( self, self:GetArmy(), EffectTemplate.DefaultProjectileWaterImpact )
        end
        self:ForkThread(self.DeathThread, self.OverKillRatio )
    end,

    CreateUnitAirDestructionEffects = function( self, scale )
        local army = self:GetArmy()
        local scale = explosion.GetAverageBoundingXZRadius(self)
        explosion.CreateDefaultHitExplosion( self, scale)
        if(self.ShowUnitDestructionDebris) then
            explosion.CreateDebrisProjectiles(self, scale, {self:GetUnitSizes()})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    OnKilled = function(self, instigator, type, overkillRatio)
        local bp = self:GetBlueprint()

        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.
        if self.CurrentLayer == 'Air' and self:GetFractionComplete() == 1  then
            self.CreateUnitAirDestructionEffects( self, 1.0 )
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()
            if instigator and IsUnit(instigator) then
                instigator:OnKilledUnit(self)
            end
        else
            self.DeathBounce = 1
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,
}

--- Mixin transports (air, sea, space, whatever). Sellotape onto concrete transport base classes as
-- desired.
BaseTransport = Class() {
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:MarkWeaponsOnTransport(unit, true)
        if unit:ShieldIsOn() then
            unit:DisableShield()
            unit:DisableDefaultToggleCaps()
        end
        self:RequestRefreshUI()
        unit:OnAttachedToTransport(self, attachBone)
    end,

    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:MarkWeaponsOnTransport(unit, false)
        unit:EnableShield()
        unit:EnableDefaultToggleCaps()
        self:RequestRefreshUI()
        unit:TransportAnimation(-1)
        unit:OnDetachedToTransport(self)
    end,

    -- When one of our attached units gets killed, detach it
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    GetTransportClass = function(self)
        local bp = self:GetBlueprint().Transport
        return bp.TransportClass
    end,

    OnStartTransportLoading = function(self)
        -- We keep the aibrain up to date with the last transport to start loading so, among other
        -- things, we can determine which transport is being referenced during an OnTransportFull
        -- event (As this function is called immediately before that one).
        self:GetAIBrain().loadingTransport = self
    end,

    OnStopTransportLoading = function(...)
    end,

    DestroyedOnTransport = function(self)
    end,

    DetachCargo = function(self)
        local units = self:GetCargo()
        for k, v in units do
            v:DetachFrom()
        end
    end
}

--- Base class for air transports.
AirTransport = Class(AirUnit, BaseTransport) {
    OnKilled = function(self, instigator, type, overkillRatio)
        AirUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}

---------------------------------------------------------------
--  LAND UNITS
---------------------------------------------------------------
LandUnit = Class(MobileUnit) {}

-- -------------------------------------------------------------
--   CONSTRUCTION UNITS
-- -------------------------------------------------------------
ConstructionUnit = Class(MobileUnit) {
    OnCreate = function(self)
        MobileUnit.OnCreate(self)

        self.EffectsBag = {}
        if self:GetBlueprint().General.BuildBones then
            self:SetupBuildBones()
        end

        if self:GetBlueprint().Display.AnimationBuild then
            self.BuildingOpenAnim = self:GetBlueprint().Display.AnimationBuild
        end

        if self.BuildingOpenAnim then
            self.BuildingOpenAnimManip = CreateAnimator(self)
            self.BuildingOpenAnimManip:SetPrecedence(1)
            self.BuildingOpenAnimManip:PlayAnim(self.BuildingOpenAnim, false):SetRate(0)
            if self.BuildArmManipulator then
                self.BuildArmManipulator:Disable()
            end
        end
        self.BuildingUnit = false
    end,

    OnPaused = function(self)
        -- When factory is paused take some action
        self:StopUnitAmbientSound( 'ConstructLoop' )
        MobileUnit.OnPaused(self)
        if self.BuildingUnit then
            MobileUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound( 'ConstructLoop' )
            MobileUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        MobileUnit.OnUnpaused(self)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order )
        if unitBeingBuilt.WorkItem.Slot and unitBeingBuilt.WorkProgress == 0 then
            return
        else
            MobileUnit.OnStartBuild(self,unitBeingBuilt, order)
        end
        -- Fix up info on the unit id from the blueprint and see if it matches the 'UpgradeTo' field in the BP.
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
        if unitBeingBuilt:GetUnitId() == self:GetBlueprint().General.UpgradesTo and order == 'Upgrade' then
            self.Upgrading = true
            self.BuildingUnit = false
        end
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        MobileUnit.OnStopBuild(self,unitBeingBuilt)
        if self.Upgrading then
            NotifyUpgrade(self,unitBeingBuilt)
            self:Destroy()
        end
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil

        if self.BuildingOpenAnimManip and self.BuildArmManipulator then
            self.StoppedBuilding = true
        elseif self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(-1)
        end
        self.BuildingUnit = false
    end,

    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if (enable) then
                self.BuildArmManipulator:Enable()
            end
        end
    end,

    OnPrepareArmToBuild = function(self)
        MobileUnit.OnPrepareArmToBuild(self)

        -- LOG( 'OnPrepareArmToBuild' )
        if self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(self:GetBlueprint().Display.AnimationBuildRate or 1)
            if self.BuildArmManipulator then
                self.StoppedBuilding = false
                ForkThread( self.WaitForBuildAnimation, self, true )
            end
        end
    end,

    OnStopBuilderTracking = function(self)
        MobileUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self:GetBlueprint().Display.AnimationBuildRate or 1))
        end
    end,


    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,
}


---------------------------------------------------------------
--  SEA UNITS
--  These units typically float on the water and have wake when they move.
---------------------------------------------------------------

SeaUnit = Class(MobileUnit){
    DeathThreadDestructionWaitTime = 0,
    ShowUnitDestructionDebris = false,
    PlayEndestructionEffects = false,
    CollidedBones = 0,

    OnStopBeingBuilt = function(self,builder,layer)
        MobileUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

--- Base class for aircraft carriers.
AircraftCarrier = Class(SeaUnit, BaseTransport) {
    OnKilled = function(self, instigator, type, overkillRatio)
        SeaUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}

---------------------------------------------------------------
--  HOVERING LAND UNITS
---------------------------------------------------------------

HoverLandUnit = Class(MobileUnit) {
}

SlowHoverLandUnit = Class(HoverLandUnit) {
    OnLayerChange = function(self, new, old)
        HoverLandUnit.OnLayerChange(self, new, old)
        -- Slow these units down when they transition from land to water
        -- The mult is applied twice thanks to an engine bug, so careful when adjusting it
        -- Newspeed = oldspeed * mult * mult

        local mult = self:GetBlueprint().Physics.WaterSpeedMultiplier
        if new == 'Water' then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}

--- Base class for command units.
CommandUnit = Class(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch( self.BuildArmManipulator:GetHeadingPitch() )
    end,

    OnFailedToBuild = function(self)
        WalkingLandUnit.OnFailedToBuild(self)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnStopCapture = function(self, target)
        WalkingLandUnit.OnStopCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnFailedCapture = function(self, target)
        WalkingLandUnit.OnFailedCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnStopReclaim = function(self, target)
        WalkingLandUnit.OnStopReclaim(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnPrepareArmToBuild = function(self)
        WalkingLandUnit.OnPrepareArmToBuild(self)
        if self:BeenDestroyed() then return end

        self:BuildManipulatorSetEnabled(true)
        self.BuildArmManipulator:SetPrecedence(20)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, false)
        self.BuildArmManipulator:SetHeadingPitch(self:GetWeaponManipulatorByLabel(self.rightGunLabel):GetHeadingPitch())
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        WalkingLandUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt

        local bp = self:GetBlueprint()
        local isUpgrade = order == 'Upgrade'
        local showEffects = not isUpgrade or bp.Display.ShowBuildEffectsDuringUpgrade

        if not isUpgrade then
            self.BuildingUnit = true
        end

        if showEffects then
            self:StartBuildingEffects(unitBeingBuilt, order)
        end

        -- Check if we're about to try and build something we shouldn't. This can only happen due to
        -- a native code bug in the SCU REBUILDER behaviour.
        -- FractionComplete is zero only if we're the initiating builder. Clearly, we want to allow
        -- assisting builds of other races, just not *starting* them.
        -- We skip the check if we're assisting another builder: it's up to them to have the ability
        -- to start this build, not us.
        if not self:GetGuardedUnit() and unitBeingBuilt:GetFractionComplete() == 0 and not self:CanBuild(unitBeingBuilt:GetBlueprint().BlueprintId) then
            IssueStop({self})
            IssueClearCommands({self})
            unitBeingBuilt:Destroy()
        end
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        WalkingLandUnit.OnStopBuild(self, unitBeingBuilt)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()

        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnPaused = function(self)
        WalkingLandUnit.OnPaused(self)
        if self.BuildingUnit then
            WalkingLandUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            WalkingLandUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        WalkingLandUnit.OnUnpaused(self)
    end
}

ACUUnit = Class(CommandUnit) {
    -- The "commander under attack" warnings.
    CreateShield = function(self, bpShield)
        CommandUnit.CreateShield(self, bpShield)

        local aiBrain = self:GetAIBrain()

        -- Mutate the OnDamage function for this one very special shield.
        local oldApplyDamage = self.MyShield.ApplyDamage
        self.MyShield.ApplyDamage = function(...)
            oldApplyDamage(unpack(arg))
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        WalkingLandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = self:GetAIBrain()
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)

        --If there is a killer, and it's not me
        if instigator and instigator:GetArmy() ~= self:GetArmy() then
            local instigatorBrain = ArmyBrains[instigator:GetArmy()]
            if instigatorBrain and not instigatorBrain:IsDefeated() then
                instigatorBrain:AddArmyStat("FAFWin", 1)
            end
            --if we are teamkilled
            if IsAlly(self:GetArmy(), instigator:GetArmy()) then
                WARN('Teamkill detected')
                Sync.Teamkill = { killTime = GetGameTimeSeconds(), instigator = instigator:GetArmy(), victim = self:GetArmy() }
                WARN("Was teamkilled: army #" .. self:GetArmy())
                WARN("At time: " .. GetGameTimeSeconds())
                WARN("Killed by army #" .. instigator:GetArmy())
            end
        end

        --Score change, we send the score of all players
        for index, brain in ArmyBrains do
            if brain and not brain:IsDefeated() then
                local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                table.insert(Sync.GameResult, { index, result })
            end
        end
    end,

    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
    end,

    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
    end,

    GiveInitialResources = function(self)
        WaitTicks(2)
        self:GetAIBrain():GiveResource('Energy', self:GetBlueprint().Economy.StorageEnergy)
        self:GetAIBrain():GiveResource('Mass', self:GetBlueprint().Economy.StorageMass)
    end,
}

---------------------------------------------------------------
--  SHIELD HOVER UNITS
---------------------------------------------------------------
ShieldHoverLandUnit = Class(HoverLandUnit) {
}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
ShieldLandUnit = Class(LandUnit) {
}

---------------------------------------------------------------
--  SHIELD SEA UNITS
---------------------------------------------------------------
ShieldSeaUnit = Class(SeaUnit) {
}
