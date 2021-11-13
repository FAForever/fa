-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local EntityCategoryFilterDown = EntityCategoryFilterDown
local unit_methodsSetUnSelectable = moho.unit_methods.SetUnSelectable
local unit_methodsSetBlockCommandQueue = moho.unit_methods.SetBlockCommandQueue
local unit_methodsCanBuild = moho.unit_methods.CanBuild
local unit_methodsGetRallyPoint = moho.unit_methods.GetRallyPoint
local unit_methodsGetBlip = moho.unit_methods.GetBlip
local CreateAnimator = CreateAnimator
local unit_methodsGetGuards = moho.unit_methods.GetGuards
local tableInsert = table.insert
local unit_methodsIsPaused = moho.unit_methods.IsPaused
local unit_methodsRequestRefreshUI = moho.unit_methods.RequestRefreshUI
local unit_methodsSetBusy = moho.unit_methods.SetBusy
local unit_methodsDisableIntel = moho.unit_methods.DisableIntel
local unit_methodsGetFractionComplete = moho.unit_methods.GetFractionComplete
local CreateEconomyEvent = CreateEconomyEvent
local WaitFor = WaitFor
local CreateRotator = CreateRotator
local unit_methodsSetAccMult = moho.unit_methods.SetAccMult
local AnimationManipulatorSetAnimationFraction = moho.AnimationManipulator.SetAnimationFraction
local IsUnit = IsUnit
local aibrain_methodsGetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local unit_methodsGetGuardedUnit = moho.unit_methods.GetGuardedUnit
local unit_methodsGetHealth = moho.unit_methods.GetHealth
local unpack = unpack
local unit_methodsSetProductionActive = moho.unit_methods.SetProductionActive
local unit_methodsSetWorkProgress = moho.unit_methods.SetWorkProgress
local GetArmyBrain = GetArmyBrain
local pairs = pairs
local aibrain_methodsGetListOfUnits = moho.aibrain_methods.GetListOfUnits
local unit_methodsGetArmy = moho.unit_methods.GetArmy
local unit_methodsIsMoving = moho.unit_methods.IsMoving
local CreateAttachedEmitter = CreateAttachedEmitter
local DamageArea = DamageArea
local blip_methodsIsOnRadar = moho.blip_methods.IsOnRadar
local NotifyUpgrade = NotifyUpgrade
local unit_methodsSetTurnMult = moho.unit_methods.SetTurnMult
local GetMapSize = GetMapSize
local ipairs = ipairs
local aibrain_methodsGetEconomyStoredRatio = moho.aibrain_methods.GetEconomyStoredRatio
local unit_methodsSetIntelRadius = moho.unit_methods.SetIntelRadius
local unit_methodsRemoveCommandCap = moho.unit_methods.RemoveCommandCap
local mathAtan2 = math.atan2
local IssueMove = IssueMove
local mathCeil = math.ceil
local tableRemove = table.remove
local IEffectScaleEmitter = moho.IEffect.ScaleEmitter
local unit_methodsSetFocusEntity = moho.unit_methods.SetFocusEntity
local CreateDecal = CreateDecal
local unit_methodsBeenDestroyed = moho.unit_methods.BeenDestroyed
local Warp = Warp
local aibrain_methodsGetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local unit_methodsIsBeingBuilt = moho.unit_methods.IsBeingBuilt
local unit_methodsKill = moho.unit_methods.Kill
local WARN = WARN
local unit_methodsSetSpeedMult = moho.unit_methods.SetSpeedMult
local unit_methodsHideBone = moho.unit_methods.HideBone
local unit_methodsSetProductionPerSecondMass = moho.unit_methods.SetProductionPerSecondMass
local aibrain_methodsGetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
local unit_methodsGetConsumptionPerSecondMass = moho.unit_methods.GetConsumptionPerSecondMass
local unit_methodsGetProductionPerSecondMass = moho.unit_methods.GetProductionPerSecondMass
local unit_methodsSetFireState = moho.unit_methods.SetFireState
local unit_methodsGetPosition = moho.unit_methods.GetPosition
local unit_methodsGetNumBuildOrders = moho.unit_methods.GetNumBuildOrders
local stringSub = string.sub
local IsAlly = IsAlly
local unit_methodsSetImmobile = moho.unit_methods.SetImmobile
local VDist2Sq = VDist2Sq
local IssueStop = IssueStop
local ForkThread = ForkThread
local unit_methodsGetAIBrain = moho.unit_methods.GetAIBrain
local next = next
local unit_methodsDetachAll = moho.unit_methods.DetachAll
local tableEmpty = table.empty
local Vector = Vector
local IssueClearCommands = IssueClearCommands
local FlattenMapRect = FlattenMapRect
local unit_methodsSetConsumptionPerSecondMass = moho.unit_methods.SetConsumptionPerSecondMass
local tableGetn = table.getn
local mathFloor = math.floor
local unit_methodsAddCommandCap = moho.unit_methods.AddCommandCap
local aibrain_methodsGetEconomyStored = moho.aibrain_methods.GetEconomyStored
local GetGameTick = GetGameTick
local aibrain_methodsGiveResource = moho.aibrain_methods.GiveResource
local Random = Random
local blip_methodsIsSeenEver = moho.blip_methods.IsSeenEver
local unit_methodsIsUnitState = moho.unit_methods.IsUnitState
local unit_methodsGetConsumptionPerSecondEnergy = moho.unit_methods.GetConsumptionPerSecondEnergy
local IsCommandDone = IsCommandDone
local GetTerrainType = GetTerrainType
local tarmacsUp = import('/lua/tarmacs.lua')
local unit_methodsSetCapturable = moho.unit_methods.SetCapturable
local AnimationManipulatorSetRate = moho.AnimationManipulator.SetRate
local GetGameTimeSeconds = GetGameTimeSeconds
local RemoveEconomyEvent = RemoveEconomyEvent
local unit_methodsAddPingPongScroller = moho.unit_methods.AddPingPongScroller
local mathMin = math.min
local unit_methodsSetMesh = moho.unit_methods.SetMesh
local EntityCategoryContains = EntityCategoryContains
local unit_methodsCreateProjectileAtBone = moho.unit_methods.CreateProjectileAtBone
local unit_methodsCreateProjectile = moho.unit_methods.CreateProjectile
local unit_methodsGetBoneCount = moho.unit_methods.GetBoneCount
local unit_methodsDestroy = moho.unit_methods.Destroy
local IEffectOffsetEmitter = moho.IEffect.OffsetEmitter
local unit_methodsGetBlueprint = moho.unit_methods.GetBlueprint
local unit_methodsShowBone = moho.unit_methods.ShowBone
local unit_methodsGetFocusUnit = moho.unit_methods.GetFocusUnit
local KillThread = KillThread
local AnimationManipulatorPlayAnim = moho.AnimationManipulator.PlayAnim
local ParseEntityCategory = ParseEntityCategory
local unit_methodsSetReclaimable = moho.unit_methods.SetReclaimable
local VDist2 = VDist2
local unit_methodsGetCargo = moho.unit_methods.GetCargo

local Unit = import('/lua/sim/Unit.lua').Unit
local explosion = import('defaultexplosions.lua')
local EffectUtil = import('EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')
local AdjacencyBuffs = import('/lua/sim/AdjacencyBuffs.lua')
local FireState = import('/lua/game.lua').FireState
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

local teleportTime = {}

local CreateScaledBoom = function(unit, overkill, bone)
    explosion.CreateDefaultHitExplosionAtBone(
        unit,
        bone or 0,
        explosion.CreateUnitExplosionEntity(unit, overkill).Spec.BoundingXZRadius
)
end

-- allows us to skip ai-specific functionality
local GameHasAIs = ScenarioInfo.GameHasAIs

-- MISC UNITS
DummyUnit = Class(Unit) {
    OnStopBeingBuilt = function(self, builder, layer)
        unit_methodsDestroy(self)
    end,
}

-- compute once and store as upvalue for performance
local StructureUnitRotateTowardsEnemiesLand = categories.STRUCTURE + categories.LAND + categories.NAVAL
local StructureUnitRotateTowardsEnemiesArtillery = categories.ARTILLERY * (categories.TECH3 + categories.EXPERIMENTAL)
local StructureUnitOnStartBeingBuiltRotateBuildings = categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * (categories.DEFENSE + categories.ARTILLERY)

-- STRUCTURE UNITS
StructureUnit = Class(Unit) {
    LandBuiltHiddenBones = {'Floatation'},
    MinConsumptionPerSecondEnergy = 1,
    MinWeaponRequiresEnergy = 0,

    -- Stucture unit specific damage effects and smoke
    FxDamage1 = {EffectTemplate.DamageStructureSmoke01, EffectTemplate.DamageStructureSparks01},
    FxDamage2 = {EffectTemplate.DamageStructureFireSmoke01, EffectTemplate.DamageStructureSparks01},
    FxDamage3 = {EffectTemplate.DamageStructureFire01, EffectTemplate.DamageStructureSparks01},

    OnCreate = function(self)
        Unit.OnCreate(self)
        self.WeaponMod = {}
        self.FxBlinkingLightsBag = {}
        if self.Layer == 'Land' and unit_methodsGetBlueprint(self).Physics.FlattenSkirt then
            self:FlattenSkirt()
        end
    end,

    RotateTowardsEnemy = function(self)

        -- retrieve information we may need
        local bp = unit_methodsGetBlueprint(self)
        local brain = unit_methodsGetAIBrain(self)
        local pos = unit_methodsGetPosition(self)

        -- determine default threat that aims at center of the map
        local x, z = GetMapSize()
        local target = {
            location = {0.5 * x, 0, 0.5 * z},
            distance = -1,
            threat = -1,
        }

        -- retrieve units of certain type
        local radius = 2 * (bp.AI.GuardScanRadius or 50)
        local cats = EntityCategoryContains(categories.ANTIAIR, self) and categories.AIR or (StructureUnitRotateTowardsEnemiesLand)
        local units = aibrain_methodsGetUnitsAroundPoint(brain, cats, pos, radius, 'Enemy')

        -- for each unit found
        local threats = { }
        for _, u in units do

            -- find its blip
            local blip = unit_methodsGetBlip(u, self.Army)
            if blip then

                -- check if we've got it on radar and whether it is identified by army in question
                local radar = blip_methodsIsOnRadar(blip, self.Army)
                local identified = blip_methodsIsSeenEver(blip, self.Army)
                if radar or identified then

                    -- if we've identified the blip then we can use the threat of the unit, otherwise default to 1.
                    local threat = (identified and u:GetBlueprint().Defense.SurfaceThreatLevel) or 1

                    -- if this is more of a threat than what we have, compute distance
                    if threat >= target.threat then
                        local epos = u:GetPosition()
                        local distance = VDist2Sq(pos[1], pos[3], epos[1], epos[3])

                        -- if threat is bigger, then we don't need to compare distance
                        if threat > target.threat then 
                            target.location = epos
                            target.distance = distance
                            target.threat = threat
                        else 
                            -- threat is equal, therefore compare distance - closer wins
                            if distance < target.distance then 
                                target.location = epos
                                target.distance = distance
                                target.threat = threat
                            end
                        end
                    end
                end
            end
        end

        -- get direction vector, atanify it for angle
        local rad = mathAtan2(target.location[1] - pos[1], target.location[3] - pos[3])
        local degrees = rad * (180 / math.pi)

        -- some buildings can only take 90 degree angles
        if EntityCategoryContains(StructureUnitRotateTowardsEnemiesArtillery, self) then
            degrees = mathFloor((degrees + 45) / 90) * 90
        end

        self:SetRotation(degrees)
    end,

    OnStartBeingBuilt = function(self, builder, layer)
        if EntityCategoryContains(StructureUnitOnStartBeingBuiltRotateBuildings, self) then
            self:RotateTowardsEnemy()
        end

        Unit.OnStartBeingBuilt(self, builder, layer)
        local bp = unit_methodsGetBlueprint(self)
        if bp.Physics.FlattenSkirt and not self:HasTarmac() and bp.General.FactionName ~= "Seraphim" then
            if self.TarmacBag then
                self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            else
                self:CreateTarmac(true, true, true, false, false)
            end
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        Unit.OnStopBeingBuilt(self, builder, layer)
        -- Whaa why can't we have sane inheritance chains :/
        if unit_methodsGetBlueprint(self).General.FactionName == "Seraphim" then
            self:CreateTarmac(true, true, true, false, false)
        end
        self:PlayActiveAnimation()
    end,

    OnFailedToBeBuilt = function(self)
        Unit.OnFailedToBeBuilt(self)
        self:DestroyTarmac()
    end,

    FlattenSkirt = function(self)
        local x, y, z = unpack(self:GetCachePosition())
        local x0, z0, x1, z1 = self:GetSkirtRect()
        x0, z0, x1, z1 = mathFloor(x0), mathFloor(z0), mathCeil(x1), mathCeil(z1)
        FlattenMapRect(x0, z0, x1 - x0, z1 - z0, y)
    end,

    CreateTarmac = function(self, albedo, normal, glow, orientation, specTarmac, lifeTime)
        if self.Layer ~= 'Land' then return end
        local tarmac
        local bp = unit_methodsGetBlueprint(self).Display.Tarmacs
        if not specTarmac then
            if bp and not tableEmpty(bp) then
                local num = Random(1, tableGetn(bp))
                tarmac = bp[num]
            else
                return false
            end
        else
            tarmac = specTarmac
        end

        local w = tarmac.Width
        local l = tarmac.Length
        local fadeout = tarmac.FadeOut

        local x, y, z = unpack(unit_methodsGetPosition(self))

        -- I'm disabling this for now since there are so many things wrong with it
        local orient = orientation
        if not orientation then
            if tarmac.Orientations and not tableEmpty(tarmac.Orientations) then
                orient = tarmac.Orientations[Random(1, tableGetn(tarmac.Orientations))]
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

        local GetTarmac = tarmacsUp.GetTarmacType

        local terrain = GetTerrainType(x, z)
        local terrainName
        if terrain then
            terrainName = terrain.Name
        end

        -- Players and AI can build buildings outside of their faction. Get the *building's* faction to determine the correct tarrain-specific tarmac
        local factionTable = {e = 1, a = 2, r = 3, s = 4}
        local faction  = factionTable[stringSub(self.UnitId, 2, 2)]
        if albedo and tarmac.Albedo then
            local albedo2 = tarmac.Albedo2
            if albedo2 then
                albedo2 = albedo2 .. GetTarmac(faction, terrain)
            end

            local tarmacHndl = CreateDecal(unit_methodsGetPosition(self), orient, tarmac.Albedo .. GetTarmac(faction, terrainName) , albedo2 or '', 'Albedo', w, l, fadeout, lifeTime or 0, self.Army, 0)
            tableInsert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end

        if normal and tarmac.Normal then
            local tarmacHndl = CreateDecal(unit_methodsGetPosition(self), orient, tarmac.Normal .. GetTarmac(faction, terrainName), '', 'Alpha Normals', w, l, fadeout, lifeTime or 0, self.Army, 0)

            tableInsert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end

        if glow and tarmac.Glow then
            local tarmacHndl = CreateDecal(unit_methodsGetPosition(self), orient, tarmac.Glow .. GetTarmac(faction, terrainName), '', 'Glow', w, l, fadeout, lifeTime or 0, self.Army, 0)

            tableInsert(self.TarmacBag.Decals, tarmacHndl)
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
        return not tableEmpty(self.TarmacBag.Decals)
    end,

    OnMassStorageStateChange = function(self, state)
    end,

    OnEnergyStorageStateChange = function(self, state)
    end,

    CreateBlinkingLights = function(self, color)
        self:DestroyBlinkingLights()
        local bp = unit_methodsGetBlueprint(self)
        if bp.Display.BlinkingLights then
            local fxbp = bp.Display.BlinkingLightsFx[color]
            for _, v in bp.Display.BlinkingLights do
                if type(v) == 'table' then
                    local fx = CreateAttachedEmitter(self, v.BLBone, self.Army, fxbp)
                    IEffectOffsetEmitter(fx, v.BLOffsetX or 0, v.BLOffsetY or 0, v.BLOffsetZ or 0)
                    IEffectScaleEmitter(fx, v.BLScale or 1)
                    tableInsert(self.FxBlinkingLightsBag, fx)
                    self.Trash:Add(fx)
                end
            end
        end
    end,

    DestroyBlinkingLights = function(self)
        for _, v in self.FxBlinkingLightsBag do
            v:Destroy()
        end
        self.FxBlinkingLightsBag = {}
    end,

    CreateDestructionEffects = function(self, overkillRatio)
        if explosion.GetAverageBoundingXZRadius(self) < 1.0 then
            explosion.CreateScalableUnitExplosion(self, overkillRatio)
        else
            explosion.CreateTimedStuctureUnitExplosion(self)
            WaitSeconds(0.5)
            explosion.CreateScalableUnitExplosion(self, overkillRatio)
        end
    end,

    -- Modified to use same upgrade logic as the ui. This adds more upgrade options via General.UpgradesFromBase blueprint option
    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Check for death loop
        if not Unit.OnStartBuild(self, unitBeingBuilt, order) then
            return
        end
        self.UnitBeingBuilt = unitBeingBuilt

        local builderBp = unit_methodsGetBlueprint(self)
        local targetBp = unitBeingBuilt:GetBlueprint()
        local performUpgrade = false

        if targetBp.General.UpgradesFrom == builderBp.BlueprintId then
            performUpgrade = true
        elseif targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo then
            performUpgrade = true
        elseif targetBp.General.UpgradesFromBase ~= "none" then
            -- Try testing against the base
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
            local bp = unit_methodsGetBlueprint(self).Display
            self:DestroyTarmac()
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()
            if bp.AnimationUpgrade then
                local unitBuilding = self.UnitBeingBuilt
                self.AnimatorUpgradeManip = CreateAnimator(self)
                self.Trash:Add(self.AnimatorUpgradeManip)
                local fractionOfComplete = 0
                self:StartUpgradeEffects(unitBuilding)
                AnimationManipulatorPlayAnim(self.AnimatorUpgradeManip, bp.AnimationUpgrade, false):SetRate(0)

                while fractionOfComplete < 1 and not self.Dead do
                    fractionOfComplete = unitBuilding:GetFractionComplete()
                    AnimationManipulatorSetAnimationFraction(self.AnimatorUpgradeManip, fractionOfComplete)
                    WaitTicks(1)
                end

                if not self.Dead then
                    AnimationManipulatorSetRate(self.AnimatorUpgradeManip, 1)
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
                unit_methodsDestroy(self)
            end
        end,

        OnFailedToBuild = function(self)
            Unit.OnFailedToBuild(self)
            self:EnableDefaultToggleCaps()

            if self.AnimatorUpgradeManip then 
                self.AnimatorUpgradeManip:Destroy() 
            end
            
            self:PlayUnitSound('UpgradeFailed')
            self:PlayActiveAnimation()
            self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            ChangeState(self, self.IdleState)
        end,
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = unit_methodsGetBlueprint(self)
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            unit_methodsHideBone(self, 0, true)
            self.BeingBuiltShowBoneTriggered = false
            if bp.General.UpgradesFrom ~= builder.UnitId then
                self:ForkThread(EffectUtil.CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag)
            end
        elseif FactionName == 'Aeon' then
            if bp.General.UpgradesFrom ~= builder.UnitId then
                self:ForkThread(EffectUtil.CreateAeonBuildBaseThread, builder, self.OnBeingBuiltEffectsBag)
            end
        elseif FactionName == 'Seraphim' then
            if bp.General.UpgradesFrom ~= builder.UnitId then
                self:ForkThread(EffectUtil.CreateSeraphimBuildBaseThread, builder, self.OnBeingBuiltEffectsBag)
            end
        end
    end,

    StopBeingBuiltEffects = function(self, builder, layer)
        local FactionName = unit_methodsGetBlueprint(self).General.FactionName
        if FactionName == 'Aeon' then
            WaitSeconds(2.0)
        elseif FactionName == 'UEF' and not self.BeingBuiltShowBoneTriggered then
            unit_methodsShowBone(self, 0, true)
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
        unit_methodsHideBone(unitBeingBuilt, 0, true)
    end,

    StopUpgradeEffects = function(self, unitBeingBuilt)
        unit_methodsShowBone(unitBeingBuilt, 0, true)
    end,

    PlayActiveAnimation = function(self)

    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        local scus = EntityCategoryFilterDown(categories.SUBCOMMANDER, unit_methodsGetGuards(self))
        if scus[1] then
            for _, u in scus do
                unit_methodsSetFocusEntity(u, self)
                self.Repairers[u.EntityId] = u
            end
        end

        Unit.OnKilled(self, instigator, type, overkillRatio)
        -- Adding into OnKilled the ability to destroy the tarmac but put a new one down that looks exactly like it but
        -- will time out over the time spec'd or 300 seconds.
        local orient = self.TarmacBag.Orientation
        local currentBP = self.TarmacBag.CurrentBP
        self:DestroyTarmac()
        self:CreateTarmac(true, true, true, orient, currentBP, currentBP.DeathLifetime or 300)
    end,

    CheckRepairersForRebuild = function(self, wreckage)
        local units = {}
        for id, u in self.Repairers do
            if u:BeenDestroyed() then
                self.Repairers[id] = nil
            else
                local focus = unit_methodsGetFocusUnit(u)
                if focus == self and ((unit_methodsIsUnitState(u, 'Repairing') and not unit_methodsGetGuardedUnit(u)) or
                                      EntityCategoryContains(categories.SUBCOMMANDER, u)) then
                    tableInsert(units, u)
                end
            end
        end

        if not units[1] then return end

        wreckage:Rebuild(units)
    end,

    CreateWreckage = function(self, overkillRatio)
        local wreckage = Unit.CreateWreckage(self, overkillRatio)
        if wreckage then
            self:CheckRepairersForRebuild(wreckage)
        end

        return wreckage
    end,

    -- Adjacency
    -- When we're adjacent, try to apply all the possible bonuses
    OnAdjacentTo = function(self, adjacentUnit, triggerUnit) -- What is triggerUnit?
        if unit_methodsIsBeingBuilt(self) then return end
        if unit_methodsIsBeingBuilt(adjacentUnit) then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency
        if not adjBuffs then return end

        -- Apply each buff needed to you and/or adjacent unit
        for k, v in AdjacencyBuffs[adjBuffs] do
            Buff.ApplyBuff(adjacentUnit, v, self)
        end

        -- Keep track of adjacent units
        if not self.AdjacentUnits then
            self.AdjacentUnits = {}
        end
        tableInsert(self.AdjacentUnits, adjacentUnit)

        unit_methodsRequestRefreshUI(self)
        adjacentUnit:RequestRefreshUI()
     end,

    -- When we're not adjacent, try to remove all the possible bonuses
    OnNotAdjacentTo = function(self, adjacentUnit)
        if not self.AdjacentUnits then
            WARN("Precondition Failed: No AdjacentUnits registered for entity: " .. repr(self.GetEntityId))
            return
        end

        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency

        if adjBuffs and AdjacencyBuffs[adjBuffs] then
            for k, v in AdjacencyBuffs[adjBuffs] do
                if Buff.HasBuff(adjacentUnit, v) then
                    Buff.RemoveBuff(adjacentUnit, v)
                end
            end
        end
        self:DestroyAdjacentEffects()

        -- Keep track of units losing adjacent structures
        for k, u in self.AdjacentUnits do
            if u == adjacentUnit then
                tableRemove(self.AdjacentUnits, k)
                adjacentUnit:RequestRefreshUI()
            end
        end
        unit_methodsRequestRefreshUI(self)
    end,

    -- Add/Remove Adjacency Functionality
    -- Applies all appropriate buffs to all adjacent units
    ApplyAdjacencyBuffs = function(self)
        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency
        if not adjBuffs then return end

        -- There won't be any adjacentUnit if this is a producer just built...
        if self.AdjacentUnits then
            for k, adjacentUnit in self.AdjacentUnits do
                for k, v in AdjacencyBuffs[adjBuffs] do
                    Buff.ApplyBuff(adjacentUnit, v, self)
                    adjacentUnit:RequestRefreshUI()
                end
            end
            unit_methodsRequestRefreshUI(self)
        end
    end,

    -- Removes all appropriate buffs from all adjacent units
    RemoveAdjacencyBuffs = function(self)
        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency
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
            unit_methodsRequestRefreshUI(self)
        end
    end,

    -- Add/Remove Adjacency Effects
    CreateAdjacentEffect = function(self, adjacentUnit)
        -- Create trashbag to hold all these entities and beams
        if not self.AdjacencyBeamsBag then
            self.AdjacencyBeamsBag = {}
        end

        for k, v in self.AdjacencyBeamsBag do
            if v.Unit.EntityId == adjacentUnit.EntityId then
                return
            end
        end
        EffectUtil.CreateAdjacencyBeams(self, adjacentUnit, self.AdjacencyBeamsBag)
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

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
	    -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep:GetBlueprint().Overcharge.structureDamage
        end
        Unit.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,
}

-- FACTORY UNITS
FactoryUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- keeps track of what HQs are available
        if EntityCategoryContains(categories.RESEARCH, self) then

            -- is called when:
            -- - structure is being upgraded
            self:AddUnitCallback(
                function(self, unitBeingBuilt)
                    if EntityCategoryContains(categories.RESEARCH, self) then
                        unitBeingBuilt.UpgradedHQFromTech = self.techCategory
                    end
                end,
                "OnStartBuild"
            )

            -- is called when:
            --  - unit is built
            --  - unit is captured (for the new army)
            --  - unit is given (for the new army)
            self:AddUnitCallback(
                function(self) 
                    local brain = ArmyBrains[self.Army]

                    -- if we're an upgrade then remove the HQ we came from
                    if self.UpgradedHQFromTech then
                        brain:RemoveHQ(self.factionCategory, self.layerCategory, self.UpgradedHQFromTech)
                    end

                    -- update internal state
                    brain:AddHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = aibrain_methodsGetListOfUnits(brain, categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnStopBeingBuilt")

            -- is called when:
            --  - unit is killed
            self:AddUnitCallback(
                function(self) 
                    local brain = ArmyBrains[self.Army]

                    -- update internal state
                    brain:RemoveHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = aibrain_methodsGetListOfUnits(brain, categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnKilled")

            -- is called when:
            --  - unit is given (used for the old army)
            --  - unit is captured (used for the old army)
            self:AddUnitCallback(
                function(self, newUnit) 
                    local brain = ArmyBrains[self.Army]

                    -- update internal state
                    brain:RemoveHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = aibrain_methodsGetListOfUnits(brain, categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnGiven")

            -- is called when:
            --  - unit is reclaimed
            self:AddUnitCallback(
                function(self) 
                    local brain = ArmyBrains[self.Army]

                    -- update internal state
                    brain:RemoveHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = aibrain_methodsGetListOfUnits(brain, categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnReclaimed")
        end

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = unit_methodsGetBlueprint(self).General.BuildBones.BuildEffectBones
        self.BuildingUnit = false
        unit_methodsSetFireState(self, FireState.GROUND_FIRE)
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
        StructureUnit.OnDestroy(self)

        self.DestroyUnitBeingBuilt(self)
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)

        -- When factory is paused take some action
        if unit_methodsIsUnitState(self, 'Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if unit_methodsIsUnitState(self, 'Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            StructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)

        local aiBrain = GetArmyBrain(self.Army)
        aiBrain:ESRegisterUnitMassStorage(self)
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'ENERGY')
        local curMass = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'MASS')
        if curEnergy > 0.11 and curMass > 0.11 then
            self:CreateBlinkingLights('Green')
            self.BlinkingLightsState = 'Green'
        else
            self:CreateBlinkingLights('Red')
            self.BlinkingLightsState = 'Red'
        end
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
                local aiBrain = GetArmyBrain(self.Army)
                local curEnergy = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'ENERGY')
                local curMass = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'MASS')
                if curEnergy > 0.11 and curMass > 0.11 then
                    if unit_methodsGetNumBuildOrders(self, categories.ALLUNITS) == 0 then
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

    OnStartBuild = function(self, unitBeingBuilt, order)
        self:ChangeBlinkingLights('Yellow')
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        elseif unitBeingBuilt:GetBlueprint().CategoriesHash.RESEARCH then
            -- Removes assist command to prevent accidental cancellation when right-clicking on other factory
            unit_methodsRemoveCommandCap(self, 'RULEUCC_Guard')
            self.DisabledAssist = true
        end
        self.FactoryBuildFailed = false
    end,

    --- Introduce a rolloff delay, where defined.
    OnStopBuild = function(self, unitBeingBuilt, order)
        if self.DisabledAssist then
            unit_methodsAddCommandCap(self, 'RULEUCC_Guard')
            self.DisabledAssist = nil
        end
        local bp = unit_methodsGetBlueprint(self)
        if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
            self:ForkThread(self.PauseThread, bp.General.RolloffDelay, unitBeingBuilt, order)
        else
            self:DoStopBuild(unitBeingBuilt, order)
        end
    end,

    --- Adds a pause between unit productions
    PauseThread = function(self, productionpause, unitBeingBuilt, order)
        self:StopBuildFx()
        unit_methodsSetBusy(self, true)
        unit_methodsSetBlockCommandQueue(self, true)

        WaitSeconds(productionpause)

        unit_methodsSetBusy(self, false)
        unit_methodsSetBlockCommandQueue(self, false)
        self:DoStopBuild(unitBeingBuilt, order)
    end,

    DoStopBuild = function(self, unitBeingBuilt, order)
        StructureUnit.OnStopBuild(self, unitBeingBuilt, order)

        if not self.FactoryBuildFailed and not self.Dead then
            if not EntityCategoryContains(categories.AIR, unitBeingBuilt) then
                self:RollOffUnit()
            end
            self:StopBuildFx()
            self:ForkThread(self.FinishBuildThread, unitBeingBuilt, order)
        end
        self.BuildingUnit = false
    end,

    FinishBuildThread = function(self, unitBeingBuilt, order)
        unit_methodsSetBusy(self, true)
        unit_methodsSetBlockCommandQueue(self, true)
        local bp = unit_methodsGetBlueprint(self)
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
        unit_methodsDetachAll(self, bp.Display.BuildAttachBone or 0)
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            unit_methodsSetBusy(self, false)
            unit_methodsSetBlockCommandQueue(self, false)
        end
    end,

    CheckBuildRestriction = function(self, target_bp)
        -- Check basic build restrictions first (Unit.CheckBuildRestriction but we only go up one inheritance level)
        if not StructureUnit.CheckBuildRestriction(self, target_bp) then
            return false
        end
        -- Factories never build factories (this does not break Upgrades since CheckBuildRestriction is never called for Upgrades)
        -- Note: We check for the primary category, since e.g. AircraftCarriers have the FACTORY category.
        -- TODO: This is a hotfix for --1043, remove when engymod design is properly fixed
        return target_bp.General.Category ~= 'Factory'
    end,

    OnFailedToBuild = function(self)
        StructureUnit.OnFailedToBuild(self)
        self.FactoryBuildFailed = true
        self:DestroyBuildRotator()
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    RollOffUnit = function(self)
        local spin, x, y, z = self:CalculateRollOffPoint()
        self.MoveCommand = IssueMove({self.UnitBeingBuilt}, Vector(x, y, z))
    end,

    CalculateRollOffPoint = function(self)
        local bp = unit_methodsGetBlueprint(self).Physics.RollOffPoints
        local px, py, pz = unpack(unit_methodsGetPosition(self))

        if not bp then return 0, px, py, pz end

        local vectorObj = unit_methodsGetRallyPoint(self)

        if not vectorObj then return 0, px, py, pz end

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
            AnimationManipulatorSetRate(self.RollOffAnim, -1)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    CreateBuildRotator = function(self)
        if not self.BuildBoneRotator then
            local spin = self:CalculateRollOffPoint()
            local bp = unit_methodsGetBlueprint(self).Display
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
        unit_methodsSetBusy(self, true)
        unit_methodsSetBlockCommandQueue(self, true)
        self:PlayFxRollOff()

        -- Wait until unit has left the factory
        while not self.UnitBeingBuilt.Dead and self.MoveCommand and not IsCommandDone(self.MoveCommand) do
            WaitSeconds(0.5)
        end

        self.MoveCommand = nil
        self:PlayFxRollOffEnd()
        unit_methodsSetBusy(self, false)
        unit_methodsSetBlockCommandQueue(self, false)

        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            self:ChangeBlinkingLights('Green')
            unit_methodsSetBusy(self, false)
            unit_methodsSetBlockCommandQueue(self, false)
            self:DestroyBuildRotator()
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bp = unit_methodsGetBlueprint(self)
            local bone = bp.Display.BuildAttachBone or 0
            unit_methodsDetachAll(self, bone)
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

-- AIR FACTORY UNITS
AirFactoryUnit = Class(FactoryUnit) {}

-- AIR STAGING PLATFORMS UNITS
AirStagingPlatformUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

-- ENERGY CREATION UNITS
ConcreteStructureUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        unit_methodsDestroy(self)
    end
}

-- ENERGY CREATION UNITS
EnergyCreationUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
}

-- ENERGY STORAGE UNITS
EnergyStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        local aiBrain = GetArmyBrain(self.Army)
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'ENERGY')
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

-- LAND FACTORY UNITS
LandFactoryUnit = Class(FactoryUnit) {}

-- MASS COLLECTION UNITS
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

    OnAdjacentTo = function(self, adjacentUnit, triggerUnit) -- What is triggerUnit?
        if unit_methodsIsBeingBuilt(self) then return end
        if unit_methodsIsBeingBuilt(adjacentUnit) then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency
        if not adjBuffs then return end

        -- Apply each buff needed to you and/or adjacent unit, only if turned on
        if self._productionActive then
            for k, v in AdjacencyBuffs[adjBuffs] do
                Buff.ApplyBuff(adjacentUnit, v, self)
            end
        end

        -- Keep track of adjacent units
        if not self.AdjacentUnits then
            self.AdjacentUnits = {}
        end
        tableInsert(self.AdjacentUnits, adjacentUnit)

        unit_methodsRequestRefreshUI(self)
        adjacentUnit:RequestRefreshUI()
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        local markers = ScenarioUtils.GetMarkers()
        local unitPosition = unit_methodsGetPosition(self)

        for _, v in pairs(markers) do
            if v.type == 'MASS' then
                local massPosition = v.position
                if (massPosition[1] < unitPosition[1] + 1) and (massPosition[1] > unitPosition[1] - 1) and
                    (massPosition[2] < unitPosition[2] + 1) and (massPosition[2] > unitPosition[2] - 1) and
                    (massPosition[3] < unitPosition[3] + 1) and (massPosition[3] > unitPosition[3] - 1) then
                    unit_methodsSetProductionPerSecondMass(self, unit_methodsGetProductionPerSecondMass(self) * (v.amount / 100))
                    break
                end
            end
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        unit_methodsAddCommandCap(self, 'RULEUCC_Stop')
        self.UpgradeWatcher = self:ForkThread(self.WatchUpgradeConsumption)
    end,

    OnStopBuild = function(self, unitbuilding, order)
        StructureUnit.OnStopBuild(self, unitbuilding, order)
        unit_methodsRemoveCommandCap(self, 'RULEUCC_Stop')
        if self.UpgradeWatcher then
            KillThread(self.UpgradeWatcher)
            unit_methodsSetConsumptionPerSecondMass(self, 0)
            unit_methodsSetProductionPerSecondMass(self, (unit_methodsGetBlueprint(self).Economy.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
        end
    end,

    -- Band-aid on lack of multiple separate resource requests per unit...
    -- If mass econ is depleted, take all the mass generated and use it for the upgrade
    -- Old WatchUpgradeConsumption replaced with this on, enabling mex to not use resources when paused
    WatchUpgradeConsumption = function(self)
        local bp = unit_methodsGetBlueprint(self)
        local massConsumption = unit_methodsGetConsumptionPerSecondMass(self)

        -- Fix for weird mex behaviour when upgrading with depleted resource stock or while paused [100]
        -- Replaced Gowerly's fix with this which is very much inspired by his code. My code looks much better and
        -- seems to work a little better aswell.
        local aiBrain = unit_methodsGetAIBrain(self)

        local CalcEnergyFraction = function()
            local fraction = 1
            if aibrain_methodsGetEconomyStored(aiBrain, 'ENERGY') < unit_methodsGetConsumptionPerSecondEnergy(self) then
                fraction = mathMin(1, aibrain_methodsGetEconomyIncome(aiBrain, 'ENERGY') / aibrain_methodsGetEconomyRequested(aiBrain, 'ENERGY'))
            end
            return fraction
        end

        local CalcMassFraction = function()
            local fraction = 1
            if aibrain_methodsGetEconomyStored(aiBrain, 'MASS') < unit_methodsGetConsumptionPerSecondMass(self) then
                fraction = mathMin(1, aibrain_methodsGetEconomyIncome(aiBrain, 'MASS') / aibrain_methodsGetEconomyRequested(aiBrain, 'MASS'))
            end
            return fraction
        end

        while not self.Dead do
            local massProduction = bp.Economy.ProductionPerSecondMass * (self.MassProdAdjMod or 1)
            if unit_methodsIsPaused(self) then
                -- Paused mex upgrade (another bug here that caused paused upgrades to continue use resources)
                unit_methodsSetConsumptionPerSecondMass(self, 0)
                unit_methodsSetProductionPerSecondMass(self, massProduction * CalcEnergyFraction())
            elseif aibrain_methodsGetEconomyStored(aiBrain, 'MASS') < 1 then
                -- Mex upgrade while out of mass (this is where the engine code has a bug)
                unit_methodsSetConsumptionPerSecondMass(self, massConsumption)
                unit_methodsSetProductionPerSecondMass(self, massProduction / CalcMassFraction())
                -- To use Gowerly's words; the above division cancels the engine bug like matter and anti-matter.
                -- The engine seems to do the exact opposite of this division.
            else
                -- Mex upgrade while enough mass (don't care about energy, that works fine)
                unit_methodsSetConsumptionPerSecondMass(self, massConsumption)
                unit_methodsSetProductionPerSecondMass(self, massProduction * CalcEnergyFraction())
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
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,
}

-- MASS FABRICATION UNITS
MassFabricationUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        unit_methodsSetProductionActive(self, true)
    end,

    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        unit_methodsSetProductionActive(self, true)
        self:ApplyAdjacencyBuffs()
        self._productionActive = true
    end,

    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        unit_methodsSetProductionActive(self, false)
        self:RemoveAdjacencyBuffs()
        self._productionActive = false
    end,

    OnAdjacentTo = function(self, adjacentUnit, triggerUnit) -- What is triggerUnit?
        if unit_methodsIsBeingBuilt(self) then return end
        if unit_methodsIsBeingBuilt(adjacentUnit) then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = unit_methodsGetBlueprint(self).Adjacency
        if not adjBuffs then return end

        -- Apply each buff needed to you and/or adjacent unit, only if turned on
        if self._productionActive then
            for _, v in AdjacencyBuffs[adjBuffs] do
                Buff.ApplyBuff(adjacentUnit, v, self)
            end
        end

        -- Keep track of adjacent units
        if not self.AdjacentUnits then
            self.AdjacentUnits = {}
        end
        tableInsert(self.AdjacentUnits, adjacentUnit)

        unit_methodsRequestRefreshUI(self)
        adjacentUnit:RequestRefreshUI()
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
    end,

    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,
}

-- MASS STORAGE UNITS
MassStorageUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        local aiBrain = GetArmyBrain(self.Army)
        aiBrain:ESRegisterUnitMassStorage(self)
        local curMass = aibrain_methodsGetEconomyStoredRatio(aiBrain, 'MASS')
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

-- RADAR UNITS
RadarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
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

-- RADAR JAMMER UNITS
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

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        if self.IntelEffects and not self.IntelFxOn then
            self.IntelEffectsBag = {}
            self.CreateTerrainTypeEffects(self, self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            self.IntelFxOn = true
        end
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        self.IntelFxOn = false
    end,
}

-- SONAR UNITS
SonarUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    CreateIdleEffects = function(self)
        StructureUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = unit_methodsGetPosition(self)

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            local emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                IEffectOffsetEmitter(emit, vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0, vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds(6.0)
            end
        end
    end,

    DestroyIdleEffects = function(self)
        StructureUnit.DestroyIdleEffects(self)
        if self.TimedSonarEffectsThread then
            self.TimedSonarEffectsThread:Destroy()
        end
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

-- SEA FACTORY UNITS
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

-- SHIELD STRCUTURE UNITS
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

-- TRANSPORT BEACON UNITS
TransportBeaconUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    -- Invincibility!  (the only way to kill a transport beacon is
    -- to kill the transport unit generating it)
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        unit_methodsSetCapturable(self, false)
        unit_methodsSetReclaimable(self, false)
    end,
}

-- WALL STRCUTURE UNITS
WallStructureUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
}

-- QUANTUM GATE UNITS
QuantumGateUnit = Class(FactoryUnit) {
    OnKilled = function(self, instigator, type, overkillRatio)
        self:StopUnitAmbientSound('ActiveLoop')
        FactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

-- MOBILE UNITS
MobileUnit = Class(Unit) {
    -- Added for engymod. After creating an enhancement, units must re-check their build restrictions
    CreateEnhancement = function(self, enh)
        Unit.CreateEnhancement(self, enh)
    end,

    -- Added for engymod. When created, units must re-check their build restrictions
    OnCreate = function(self)
        Unit.OnCreate(self)
        unit_methodsSetFireState(self, FireState.GROUND_FIRE)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        -- This unit was in a transport and should create a wreck on crash
        if self.killedInTransport then
            self.killedInTransport = false
        else
            Unit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = unit_methodsGetBlueprint(self)
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            EffectUtil.CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
    end,

    StopBeingBuiltEffects = function(self, builder, layer)
        Unit.StopBeingBuiltEffects(self, builder, layer)
    end,

    StartBuildingEffects = function(self, unitBeingBuilt, order)
        Unit.StartBuildingEffects(self, unitBeingBuilt, order)
    end,

    StopBuildingEffects = function(self, unitBeingBuilt)
        Unit.StopBuildingEffects(self, unitBeingBuilt)
    end,

    CreateReclaimEffects = function(self, target)
        EffectUtil.PlayReclaimEffects(self, target, self.BuildEffectBones or {0, }, self.ReclaimEffectsBag)
    end,

    CreateReclaimEndEffects = function(self, target)
        EffectUtil.PlayReclaimEndEffects(self, target)
    end,

    CreateCaptureEffects = function(self, target)
        EffectUtil.PlayCaptureEffects(self, target, self.BuildEffectBones or {0, }, self.CaptureEffectsBag)
    end,

    -- Units with layer change effects (amphibious units like Megalith) need
    -- those changes applied when build ends, so we need to trigger the
    -- layer change event
    OnStopBeingBuilt = function(self, builder, layer)
       Unit.OnStopBeingBuilt(self, builder, layer)
       self:OnLayerChange(layer, 'None')
    end,

    OnLayerChange = function(self, new, old)
        Unit.OnLayerChange(self, new, old)

        -- Do this after the default function so the engine-bug guard in unit.lua works
        if self.transportDrop then
            self.transportDrop = nil
            unit_methodsSetImmobile(self, false)
        end
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        Unit.OnDetachedFromTransport(self, transport, bone)

         -- Set unit immobile to prevent it to accelerating in the air, cleared in OnLayerChange
        unit_methodsSetImmobile(self, true)
        self.transportDrop = true
    end,
}

-- WALKING LAND UNITS
WalkingLandUnit = Class(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    OnMotionHorzEventChange = function(self, new, old)
        MobileUnit.OnMotionHorzEventChange(self, new, old)

        if old == 'Stopped' then
            if not self.Animator then
                self.Animator = CreateAnimator(self, true)
            end

            local bpDisplay = unit_methodsGetBlueprint(self).Display
            if bpDisplay.AnimationWalk then
                AnimationManipulatorPlayAnim(self.Animator, bpDisplay.AnimationWalk, true)
                AnimationManipulatorSetRate(self.Animator, bpDisplay.AnimationWalkRate or 1)
            end
        elseif new == 'Stopped' then
            -- Only keep the animator around if we are dying and playing a death anim
            -- Or if we have an idle anim
            if self.IdleAnim and not self.Dead then
                AnimationManipulatorPlayAnim(self.Animator, self.IdleAnim, true)
            elseif not self.DeathAnim or not self.Dead then
                self.Animator:Destroy()
                self.Animator = false
            end
        end
    end,
}

-- SUB UNITS
-- These units typically float under the water and have wake when they move
SubUnit = Class(MobileUnit) {
    -- Use default spark effect until underwater damaged states are made
    FxDamage1 = {EffectTemplate.DamageSparks01},
    FxDamage2 = {EffectTemplate.DamageSparks01},
    FxDamage3 = {EffectTemplate.DamageSparks01},

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,
}

-- AIR UNITS
AirUnit = Class(MobileUnit) {
    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp', },
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

    AddPingPong = function(self)
        local bp = unit_methodsGetBlueprint(self)
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                and bp.Pong2 and bp.Pong2Speed then
                unit_methodsAddPingPongScroller(self, bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                                         bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    OnMotionVertEventChange = function(self, new, old)
        MobileUnit.OnMotionVertEventChange(self, new, old)

        if new == 'Down' then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Bottom' then
            -- While landed, planes can only see half as far
            local vis = unit_methodsGetBlueprint(self).Intel.VisionRadius / 2
            unit_methodsSetIntelRadius(self, 'Vision', vis)

            -- Turn off the ambient hover sound
            -- It will probably already be off, but there are some odd cases that
            -- make this a good idea to include here as well.
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Up' or (new == 'Top' and (old == 'Down' or old == 'Bottom')) then
            -- Set the vision radius back to default
            local bpVision = unit_methodsGetBlueprint(self).Intel.VisionRadius
            if bpVision then
                unit_methodsSetIntelRadius(self, 'Vision', bpVision)
            else
                unit_methodsSetIntelRadius(self, 'Vision', 0)
            end
        end
    end,

    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- Penalize movement for running out of fuel
        unit_methodsSetSpeedMult(self, 0.35) -- Change the speed of the unit by this mult
        unit_methodsSetAccMult(self, 0.25) -- Change the acceleration of the unit by this mult
        unit_methodsSetTurnMult(self, 0.25) -- Change the turn ability of the unit by this mult
    end,

    OnGotFuel = function(self)
        self.HasFuel = true
        -- Revert these values to the blueprint values
        unit_methodsSetSpeedMult(self, 1)
        unit_methodsSetAccMult(self, 1)
        unit_methodsSetTurnMult(self, 1)
    end,

    -- Planes need to crash. Called by engine or by ShieldCollider projectile on collision with ground or water
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        -- Immediately destroy units outside the map
        if not ScenarioFramework.IsUnitInPlayableArea(self) then
            unit_methodsDestroy(self)
        end

        -- Only call this code once
        self.GroundImpacted = true

        -- Damage the area we hit. For damage, use the value which may have been adjusted by a shield impact
        if not self.deathWep or not self.DeathCrashDamage then -- Bail if stuff is missing
            WARN('defaultunits.lua OnImpact: did not find a deathWep on the plane! Is the weapon defined in the blueprint? ' .. self.UnitId)
        elseif self.DeathCrashDamage > 0 then -- It was completely absorbed by a shield!
            local deathWep = self.deathWep -- Use a local copy for speed and easy reading
            DamageArea(self, unit_methodsGetPosition(self), deathWep.DamageRadius, self.DeathCrashDamage, deathWep.DamageType, deathWep.DamageFriendly)
        end

        if with == 'Water' then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffects(self, self.Army, EffectTemplate.DefaultProjectileWaterImpact)
            self.shallSink = true
            self.colliderProj:Destroy()
            self.colliderProj = nil
        end

        self:DisableUnitIntel('Killed')
        unit_methodsDisableIntel(self, 'Vision') -- Disable vision seperately, it's not handled in DisableUnitIntel
        self:ForkThread(self.DeathThread, self.OverKillRatio)
    end,

    -- ONLY works for Terrain, not Water
    OnAnimTerrainCollision = function(self, bone, x, y, z)
        self:OnImpact('Terrain')
    end,

    ShallSink = function(self)
        local layer = self.Layer
        local shallSink = (
            self.shallSink or -- Only the case when a bounced plane hits water. Overrides the fact that the layer is 'Air'
            ((layer == 'Water' or layer == 'Sub') and  -- In a layer for which sinking is meaningful
            not EntityCategoryContains(categories.STRUCTURE, self))  -- Exclude structures
        )
        return shallSink
    end,

    CreateUnitAirDestructionEffects = function(self, scale)
        local scale = explosion.GetAverageBoundingXZRadius(self)
        explosion.CreateDefaultHitExplosion(self, scale)

        if self.ShowUnitDestructionDebris then
            explosion.CreateDebrisProjectiles(self, scale, {self:GetUnitSizes()})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    OnKilled = function(self, instigator, type, overkillRatio)
        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.

        -- Additional stupidity: An idle transport, bot loaded and unloaded, counts as 'Land' layer so it would die with the wreck hovering.
        -- It also wouldn't call this code, and hence the cargo destruction. Awful!
        if unit_methodsGetFractionComplete(self) == 1 and (self.Layer == 'Air' or EntityCategoryContains(categories.TRANSPORTATION, self)) then
            self.CreateUnitAirDestructionEffects(self, 1.0)
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()

            -- Store our death weapon's damage on the unit so it can be edited remotely by the shield bouncer projectile
            local bp = unit_methodsGetBlueprint(self)
            local i = 1
            for i, numweapons in bp.Weapon do
                if bp.Weapon[i].Label == 'DeathImpact' then
                    self.deathWep = bp.Weapon[i]
                    break
                end
            end

            if not self.deathWep or self.deathWep == {} then
                WARN('An Air unit with no death weapon, or with incorrect label has died!!')
            else
                self.DeathCrashDamage = self.deathWep.Damage
            end

            -- Create a projectile we'll use to interact with Shields
            local proj = unit_methodsCreateProjectileAtBone(self, '/projectiles/ShieldCollider/ShieldCollider_proj.bp', 0)
            self.colliderProj = proj
            proj:Start(self, 0)
            self.Trash:Add(proj)

            if self.totalDamageTaken > 0 and not self.veterancyDispersed then
                self:VeterancyDispersal(not instigator or not IsUnit(instigator))
            end
        else
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,


    -- It's a modified copy of unit.OnCollisionCheck, this way we can get rid of unnecessary calls and double checks
    -- the only difference is the `elseif other.Nuke...` condition
    -- this can't be done in projectile.OnCollisionCheck because it's called after unit.OnCollisionCheck and then it's too late
    OnCollisionCheck = function(self, other, firingWeapon)
        if self.DisallowCollisions then
            return false
        end

        if EntityCategoryContains(categories.PROJECTILE, other) then
            if IsAlly(unit_methodsGetArmy(self), other:GetArmy()) then
                return other.CollideFriendly
            elseif other.Nuke and not unit_methodsGetBlueprint(self).CategoriesHash.EXPERIMENTAL then
                unit_methodsKill(self)
                return false
            end
        end

        -- Check for specific non-collisions
        local bp = other:GetBlueprint()
        if bp.DoNotCollideList then
            for _, v in pairs(bp.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end

        bp = unit_methodsGetBlueprint(self)
        if bp.DoNotCollideList then
            for _, v in pairs(bp.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), other) then
                    return false
                end
            end
        end
        return true
    end,
}

--- Mixin transports (air, sea, space, whatever). Sellotape onto concrete transport base classes as desired.
local slotsData = {}
BaseTransport = Class() {
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:RequestRefreshUI()

        for i = 1, self:GetBoneCount() do
            if self:GetBoneName(i) == attachBone then
                self.slots[i] = unit
                unit.attachmentBone = i
            end
        end

        unit:OnAttachedToTransport(self, attachBone)
    end,

    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:RequestRefreshUI()
        self.slots[unit.attachmentBone] = nil
        unit.attachmentBone = nil
        unit:OnDetachedFromTransport(self, attachBone)
    end,

    -- When one of our attached units gets killed, detach it
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    OnStartTransportLoading = function(self)
        -- We keep the aibrain up to date with the last transport to start loading so, among other
        -- things, we can determine which transport is being referenced during an OnTransportFull
        -- event (As this function is called immediately before that one).
        self.transData = {}
        self:GetAIBrain().loadingTransport = self
    end,

    OnStopTransportLoading = function(...)
    end,

    DestroyedOnTransport = function(self)
    end,

    -- Detaches cargo from a dying unit
    DetachCargo = function(self)
        if self.Dead then return end -- Bail out early from overkill damage when already dead to avoid crashing

        local cargo = unit_methodsGetCargo(self)
        for _, unit in cargo do
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then -- Kill the contents of a transport in a transport, however that happened
                for k, subUnit in unit_methodsGetCargo(unit) do
                    subUnit:Kill()
                end
            end
            unit:DetachFrom()
        end
    end,

    SaveCargoMass = function(self)
        local mass = 0
        for _, unit in unit_methodsGetCargo(self) do
            mass = mass + unit:GetVeterancyValue()
            unit.veterancyDispersed = true
        end
        self.cargoMass = mass
    end
}

--- Base class for air transports.
AirTransport = Class(AirUnit, BaseTransport) {
    OnTransportAborted = function(self)
    end,

    OnTransportOrdered = function(self)
    end,

    OnCreate = function(self)
        AirUnit.OnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    Kill = function(self, ...) -- Hook the engine 'Kill' command to flag cargo properly
         -- The arguments are (self, instigator, type, overkillRatio) but we can't just use normal arguments or AirUnit.Kill will complain if type is nil (which does happen)
        local instigator = arg[1]
        self:FlagCargo(not instigator or not IsUnit(instigator))
        AirUnit.Kill(self, unpack(arg))
    end,

    -- Override OnImpact to kill all cargo
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        self:KillCrashedCargo()
        AirUnit.OnImpact(self, with)
    end,

    OnStorageChange = function(self, loading)
        AirUnit.OnStorageChange(self, loading)
        for k, v in unit_methodsGetCargo(self) do
            v:OnStorageChange(loading)
        end
    end,

    -- Flags cargo that it's been killed while in a transport
    FlagCargo = function(self, suicide)
        if self.Dead then return end -- Bail out early from overkill damage when already dead to avoid crashing

        if not suicide then -- If the transport is self destructed, let its contents be self destructed separately
            self:SaveCargoMass()
        end
        self.cargo = {}
        local cargo = unit_methodsGetCargo(self)
        for _, unit in cargo or {} do
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then -- Kill the contents of a transport in a transport, however that happened
                local unitCargo = unit_methodsGetCargo(unit)
                for k, subUnit in unitCargo do
                    subUnit:Kill()
                end
            end
            if not EntityCategoryContains(categories.COMMAND, unit) then
                unit.killedInTransport = true
                tableInsert(self.cargo, unit)
            end
        end
    end,

    KillCrashedCargo = function(self)
        if unit_methodsBeenDestroyed(self) then return end

        for _, unit in self.cargo or {} do
            if not unit:BeenDestroyed() then
                unit.DeathWeaponEnabled = false -- Units at this point have no weapons for some reason. Trying to fire one crashes the game.
                unit:OnKilled(nil, '', 0)
            end
        end
    end,
}

-- LAND UNITS
LandUnit = Class(MobileUnit) {}

--  CONSTRUCTION UNITS
ConstructionUnit = Class(MobileUnit) {
    OnCreate = function(self)
        MobileUnit.OnCreate(self)

        local bp = unit_methodsGetBlueprint(self)

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = bp.General.BuildBones.BuildEffectBones

        self.EffectsBag = {}
        if bp.General.BuildBones then
            self:SetupBuildBones()
        end

        if bp.Display.AnimationBuild then
            self.BuildingOpenAnim = bp.Display.AnimationBuild
        end

        if self.BuildingOpenAnim then
            self.BuildingOpenAnimManip = CreateAnimator(self)
            self.BuildingOpenAnimManip:SetPrecedence(1)
            AnimationManipulatorPlayAnim(self.BuildingOpenAnimManip, self.BuildingOpenAnim, false):SetRate(0)
            if self.BuildArmManipulator then
                self.BuildArmManipulator:Disable()
            end
        end
        self.BuildingUnit = false
    end,

    OnPaused = function(self)
        -- When factory is paused take some action
        self:StopUnitAmbientSound('ConstructLoop')
        MobileUnit.OnPaused(self)
        if self.BuildingUnit then
            MobileUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound('ConstructLoop')
            MobileUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        MobileUnit.OnUnpaused(self)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        if unitBeingBuilt.WorkItem.Slot and unitBeingBuilt.WorkProgress == 0 then
            return
        else
            MobileUnit.OnStartBuild(self, unitBeingBuilt, order)
        end
        -- Fix up info on the unit id from the blueprint and see if it matches the 'UpgradeTo' field in the BP.
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
        if unitBeingBuilt.UnitId == unit_methodsGetBlueprint(self).General.UpgradesTo and order == 'Upgrade' then
            self.Upgrading = true
            self.BuildingUnit = false
        end
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        MobileUnit.OnStopBuild(self, unitBeingBuilt)
        if self.Upgrading then
            NotifyUpgrade(self, unitBeingBuilt)
            unit_methodsDestroy(self)
        end
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil

        if self.BuildingOpenAnimManip and self.BuildArmManipulator then
            self.StoppedBuilding = true
        elseif self.BuildingOpenAnimManip then
            AnimationManipulatorSetRate(self.BuildingOpenAnimManip, -1)
        end
        self.BuildingUnit = false

        unit_methodsSetImmobile(self, false)
    end,

    OnFailedToBuild = function(self)
        MobileUnit.OnFailedToBuild(self)
        unit_methodsSetImmobile(self, false)
    end,

    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if enable then
                self.BuildArmManipulator:Enable()
            end
        end
    end,

    OnPrepareArmToBuild = function(self)
        MobileUnit.OnPrepareArmToBuild(self)

        if self.BuildingOpenAnimManip then
            AnimationManipulatorSetRate(self.BuildingOpenAnimManip, unit_methodsGetBlueprint(self).Display.AnimationBuildRate or 1)
            if self.BuildArmManipulator then
                self.StoppedBuilding = false
                self:ForkThread(self.WaitForBuildAnimation, true)
            end
        end

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if unit_methodsIsMoving(self) then
            unit_methodsSetImmobile(self, true)
            self:ForkThread(function() WaitTicks(1) if not unit_methodsBeenDestroyed(self) then unit_methodsSetImmobile(self, false) end end)
        end
    end,

    OnStopBuilderTracking = function(self)
        MobileUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            AnimationManipulatorSetRate(self.BuildingOpenAnimManip, -(unit_methodsGetBlueprint(self).Display.AnimationBuildRate or 1))
            unit_methodsSetImmobile(self, false)
        end
    end,
}

-- SEA UNITS
-- These units typically float on the water and have wake when they move
SeaUnit = Class(MobileUnit){
    DeathThreadDestructionWaitTime = 0,
    ShowUnitDestructionDebris = false,
    PlayEndestructionEffects = false,
    CollidedBones = 0,

    OnStopBeingBuilt = function(self, builder, layer)
        MobileUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

--- Base class for aircraft carriers.
AircraftCarrier = Class(SeaUnit, BaseTransport) {
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SaveCargoMass()
        SeaUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}

-- HOVERING LAND UNITS
HoverLandUnit = Class(MobileUnit) {}

SlowHoverLandUnit = Class(HoverLandUnit) {
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        -- Slow these units down when they transition from land to water
        -- The mult is applied twice thanks to an engine bug, so careful when adjusting it
        -- Newspeed = oldspeed * mult * mult

        local mult = unit_methodsGetBlueprint(self).Physics.WaterSpeedMultiplier
        if new == 'Water' then
            unit_methodsSetSpeedMult(self, mult)
        else
            unit_methodsSetSpeedMult(self, 1)
        end
    end,
}

-- AMPHIBIOUS LAND UNITS
AmphibiousLandUnit = Class(MobileUnit) {}

SlowAmphibiousLandUnit = Class(AmphibiousLandUnit) {
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        local mult = unit_methodsGetBlueprint(self).Physics.WaterSpeedMultiplier
        if new == 'Seabed'  then
            unit_methodsSetSpeedMult(self, mult)
        else
            unit_methodsSetSpeedMult(self, 1)
        end
    end,
}

--- Base class for command units.
CommandUnit = Class(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    OnCreate = function(self)
        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = unit_methodsGetBlueprint(self).General.BuildBones.BuildEffectBones

        WalkingLandUnit.OnCreate(self)
    end,

    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        unit_methodsSetImmobile(self, false)
    end,

    OnFailedToBuild = function(self)
        WalkingLandUnit.OnFailedToBuild(self)
        if unit_methodsBeenDestroyed(self) then return end
        self:ResetRightArm()
    end,

    OnStopCapture = function(self, target)
        WalkingLandUnit.OnStopCapture(self, target)
        if unit_methodsBeenDestroyed(self) then return end
        self:ResetRightArm()
    end,

    OnFailedCapture = function(self, target)
        WalkingLandUnit.OnFailedCapture(self, target)
        if unit_methodsBeenDestroyed(self) then return end
        self:ResetRightArm()
    end,

    OnStopReclaim = function(self, target)
        WalkingLandUnit.OnStopReclaim(self, target)
        if unit_methodsBeenDestroyed(self) then return end
        self:ResetRightArm()
    end,

    OnPrepareArmToBuild = function(self)
        WalkingLandUnit.OnPrepareArmToBuild(self)
        if unit_methodsBeenDestroyed(self) then return end

        self:BuildManipulatorSetEnabled(true)
        self.BuildArmManipulator:SetPrecedence(20)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, false)
        self.BuildArmManipulator:SetHeadingPitch(self:GetWeaponManipulatorByLabel(self.rightGunLabel):GetHeadingPitch())

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if unit_methodsIsMoving(self) then
            unit_methodsSetImmobile(self, true)
            self:ForkThread(function() WaitTicks(1) if not unit_methodsBeenDestroyed(self) then unit_methodsSetImmobile(self, false) end end)
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        WalkingLandUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt

        if order ~= 'Upgrade' then
            self.BuildingUnit = true
        end

        -- Check if we're about to try and build something we shouldn't. This can only happen due to
        -- a native code bug in the SCU REBUILDER behaviour.
        -- FractionComplete is zero only if we're the initiating builder. Clearly, we want to allow
        -- assisting builds of other races, just not *starting* them.
        -- We skip the check if we're assisting another builder: it's up to them to have the ability
        -- to start this build, not us.
        if not unit_methodsGetGuardedUnit(self) and unitBeingBuilt:GetFractionComplete() == 0 and not unit_methodsCanBuild(self, unitBeingBuilt:GetBlueprint().BlueprintId) then
            IssueStop({self})
            IssueClearCommands({self})
            unitBeingBuilt:Destroy()
        end
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        WalkingLandUnit.OnStopBuild(self, unitBeingBuilt)
        if unit_methodsBeenDestroyed(self) then return end
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
    end,

    SetAutoOvercharge = function(self, auto)
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        if wep.NeedsUpgrade then return end

        wep:SetAutoOvercharge(auto)
        self.Sync.AutoOvercharge = auto
    end,

    PlayCommanderWarpInEffect = function(self, bones)
        unit_methodsHideBone(self, 0, true)
        unit_methodsSetUnSelectable(self, true)
        unit_methodsSetBusy(self, true)
        self:ForkThread(self.WarpInEffectThread, bones)
    end,

    WarpInEffectThread = function(self, bones)
        self:PlayUnitSound('CommanderArrival')
        unit_methodsCreateProjectile(self, '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(2.1)

        local bp = unit_methodsGetBlueprint(self)
        local psm = bp.Display.WarpInEffect.PhaseShieldMesh
        if psm then
            unit_methodsSetMesh(self, psm, true)
        end

        unit_methodsShowBone(self, 0, true)
        unit_methodsSetUnSelectable(self, false)
        unit_methodsSetBusy(self, false)
        unit_methodsSetBlockCommandQueue(self, false)

        for _, v in bones or bp.Display.WarpInEffect.HideBones do
            unit_methodsHideBone(self, v, true)
        end

        local totalBones = unit_methodsGetBoneCount(self) - 1
        for k, v in EffectTemplate.UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(self, bone, self.Army, v)
            end
        end

        if psm then
            WaitSeconds(6)
            unit_methodsSetMesh(self, bp.Display.MeshBlueprint, true)
        end
    end,

    -------------------------------------------------------------------------------------------
    -- TELEPORTING WITH DELAY
    -------------------------------------------------------------------------------------------
    InitiateTeleportThread = function(self, teleporter, location, orientation)
        self.UnitBeingTeleported = self
        unit_methodsSetImmobile(self, true)
        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        local bp = unit_methodsGetBlueprint(self)
        local bpEco = bp.Economy
        local teleDelay = bp.General.TeleportDelay
        local energyCost, time

        if bpEco then
            local mass = (bpEco.TeleportMassCost or bpEco.BuildCostMass or 1) * (bpEco.TeleportMassMod or 0.01)
            local energy = (bpEco.TeleportEnergyCost or bpEco.BuildCostEnergy or 1) * (bpEco.TeleportEnergyMod or 0.01)
            energyCost = mass + energy
            time = energyCost * (bpEco.TeleportTimeMod or 0.01)
        end

        if teleDelay then
            energyCostMod = (time + teleDelay) / time
            time = time + teleDelay
            energyCost = energyCost * energyCostMod

            self.TeleportDestChargeBag = nil
            self.TeleportCybranSphere = nil  -- this fixes some "...Game object has been destroyed" bugs in EffectUtilities.lua:TeleportChargingProgress

            self.TeleportDrain = CreateEconomyEvent(self, energyCost or 100, 0, time or 5, self.UpdateTeleportProgress)

            -- Create teleport charge effect + exit animation delay
            self:PlayTeleportChargeEffects(location, orientation, teleDelay)
            WaitFor(self.TeleportDrain)
        else
            self.TeleportDrain = CreateEconomyEvent(self, energyCost or 100, 0, time or 5, self.UpdateTeleportProgress)

            -- Create teleport charge effect
            self:PlayTeleportChargeEffects(location, orientation)
            WaitFor(self.TeleportDrain)
        end

        if self.TeleportDrain then
            RemoveEconomyEvent(self, self.TeleportDrain)
            self.TeleportDrain = nil
        end

        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        WaitSeconds(0.1)
        unit_methodsSetWorkProgress(self, 0.0)
        Warp(self, location, orientation)
        self:PlayTeleportInEffects()
        self:CleanupRemainingTeleportChargeEffects()
        teleportTime[self.EntityId] = GetGameTick()

        WaitSeconds(0.1) -- Perform cooldown Teleportation FX here

        -- Landing Sound
        self:StopUnitAmbientSound('TeleportLoop')
        self:PlayUnitSound('TeleportEnd')
        unit_methodsSetImmobile(self, false)
        self.UnitBeingTeleported = nil
        self.TeleportThread = nil
    end,
}

ACUUnit = Class(CommandUnit) {
    -- The "commander under attack" warnings.
    CreateShield = function(self, bpShield)
        CommandUnit.CreateShield(self, bpShield)

        local aiBrain = unit_methodsGetAIBrain(self)

        -- Mutate the OnDamage function for this one very special shield.
        local oldApplyDamage = self.MyShield.ApplyDamage
        self.MyShield.ApplyDamage = function(...)
            oldApplyDamage(unpack(arg))
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)

        self:SendNotifyMessage('completed', enh)
        unit_methodsSetImmobile(self, false)
    end,

    OnWorkBegin = function(self, work)
        local legalWork = CommandUnit.OnWorkBegin(self, work)
        if not legalWork then return end

        self:SendNotifyMessage('started', work)

        -- No need to do it for AI
        if unit_methodsGetAIBrain(self).BrainType == 'Human' then
            unit_methodsSetImmobile(self, true)
        end

        return true
    end,

    OnWorkFail = function(self, work)
        self:SendNotifyMessage('cancelled', work)
        unit_methodsSetImmobile(self, false)

        CommandUnit.OnWorkFail(self, work)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", unit_methodsGetHealth(self))
        self.WeaponEnabled = {}
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep:GetBlueprint().Overcharge.commandDamage
        end

        WalkingLandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = unit_methodsGetAIBrain(self)
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end

        if unit_methodsGetHealth(self) < ArmyBrains[self.Army]:GetUnitStat(self.UnitId, "lowest_health") then
            ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", unit_methodsGetHealth(self))
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)

        -- If there is a killer, and it's not me
        if instigator and instigator.Army ~= self.Army then
            local instigatorBrain = ArmyBrains[instigator.Army]

            Sync.EnforceRating = true
            WARN('ACU kill detected. Rating for ranked games is now enforced.')

            -- If we are teamkilled, filter out death explostions of allied units that were not coused by player's self destruct order
            -- Damage types:
            --     'DeathExplosion' - when normal unit is killed
            --     'Nuke' - when Paragon is killed
            --     'Deathnuke' - when ACU is killed
            if IsAlly(self.Army, instigator.Army) and not ((type == 'DeathExplosion' or type == 'Nuke' or type == 'Deathnuke') and not instigator.SelfDestructed) then
                WARN('Teamkill detected')
                Sync.Teamkill = {killTime = GetGameTimeSeconds(), instigator = instigator.Army, victim = self.Army}
            else
                ForkThread(function()
                    instigatorBrain:ReportScore()
                end)
            end
        end
        ArmyBrains[self.Army].CommanderKilledBy = (instigator or self).Army
    end,

    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)

        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)

        -- Ugly hack to re-initialise auto-OC once a task finishes
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        wep:SetAutoOvercharge(wep.AutoMode)
    end,

    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
    end,

    GiveInitialResources = function(self)
        WaitTicks(1)
        local bp = unit_methodsGetBlueprint(self)
        local aiBrain = unit_methodsGetAIBrain(self)
        aibrain_methodsGiveResource(aiBrain, 'Energy', bp.Economy.StorageEnergy)
        aibrain_methodsGiveResource(aiBrain, 'Mass', bp.Economy.StorageMass)
    end,

    BuildDisable = function(self)
        while unit_methodsIsUnitState(self, 'Building') or unit_methodsIsUnitState(self, 'Enhancing') or unit_methodsIsUnitState(self, 'Upgrading') or
                unit_methodsIsUnitState(self, 'Repairing') or unit_methodsIsUnitState(self, 'Reclaiming') do
            WaitSeconds(0.5)
        end

        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, true, true)
            end
        end
    end,

    -- Store weapon status on upgrade. Ignore default and OC, which are dealt with elsewhere
    SetWeaponEnabledByLabel = function(self, label, enable, lockOut)
        CommandUnit.SetWeaponEnabledByLabel(self, label, enable)

        -- Unless lockOut specified, updates the 'Permanent record' of whether a weapon is enabled. With it specified,
        -- the changing of the weapon on/off state is more... temporary. For example, when building something.
        if label ~= self.rightGunLabel and label ~= 'OverCharge' and label ~= 'AutoOverCharge' and not lockOut then
            self.WeaponEnabled[label] = enable
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        CommandUnit.OnStartBuild(self, unitBeingBuilt, order)

        -- Disable any active upgrade weapons
        local fork = false
        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, false, true)
                fork = true
            end
        end

        if fork then
            self:ForkThread(self.BuildDisable)
        end
    end,
}

-- SHIELD HOVER UNITS
ShieldHoverLandUnit = Class(HoverLandUnit) {}

-- SHIELD LAND UNITS
ShieldLandUnit = Class(LandUnit) {}

-- SHIELD SEA UNITS
ShieldSeaUnit = Class(SeaUnit) {}
