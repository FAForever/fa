-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Entity = import("/lua/sim/entity.lua").Entity
local Unit = import("/lua/sim/unit.lua").Unit
local explosion = import("/lua/defaultexplosions.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local TerrainUtils = import("/lua/sim/terrainutils.lua")
local Buff = import("/lua/sim/buff.lua")
local AdjacencyBuffs = import("/lua/sim/adjacencybuffs.lua")
local FireState = import("/lua/game.lua").FireState
local ScenarioFramework = import("/lua/scenarioframework.lua")
local Quaternion = import("/lua/shared/quaternions.lua").Quaternion

local MathAbs = math.abs

local FactionToTarmacIndex = {
    UEF = 1,
    AEON = 2,
    CYBRAN = 3,
    SERAPHIM = 4,
    NOMADS = 5,
}

local GetTarmac = import("/lua/tarmacs.lua").GetTarmacType
local TreadComponent = import("/lua/defaultcomponents.lua").TreadComponent


local RolloffUnitTable = { nil }
local RolloffPositionTable = { 0, 0, 0 }

-- allows us to skip ai-specific functionality
local GameHasAIs = ScenarioInfo.GameHasAIs

-- compute once and store as upvalue for performance
local StructureUnitRotateTowardsEnemiesLand = categories.STRUCTURE + categories.LAND + categories.NAVAL
local StructureUnitRotateTowardsEnemiesArtillery = categories.ARTILLERY * (categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL)
local StructureUnitOnStartBeingBuiltRotateBuildings = categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * (categories.DEFENSE + (categories.ARTILLERY - (categories.TECH3 + categories.EXPERIMENTAL)))

---@class StructureTarmacBag
---@field Decals TrashBag
---@field Orientation number
---@field CurrentBP UnitBlueprintTarmac
---@field Lifetime number
---@field OwnedByEntity EntityId

-- STRUCTURE UNITS
---@class StructureUnit : Unit
---@field AdjacentUnits? Unit[]
---@field TarmacBag StructureTarmacBag
StructureUnit = ClassUnit(Unit) {
    LandBuiltHiddenBones = {'Floatation'},
    MinConsumptionPerSecondEnergy = 1,
    MinWeaponRequiresEnergy = 0,

    -- Stucture unit specific damage effects and smoke
    FxDamage1 = {EffectTemplate.DamageStructureSmoke01, EffectTemplate.DamageStructureSparks01},
    FxDamage2 = {EffectTemplate.DamageStructureFireSmoke01, EffectTemplate.DamageStructureSparks01},
    FxDamage3 = {EffectTemplate.DamageStructureFire01, EffectTemplate.DamageStructureSparks01},

    ConsumptionActive = true,

    ---@param self StructureUnit
    OnCreate = function(self)
        Unit.OnCreate(self)
        self:HideLandBones()
        self.FxBlinkingLightsBag = { }

        local layer = self.Layer
        local blueprint = self.Blueprint
        local physicsBlueprint = blueprint.Physics
        local flatten = physicsBlueprint.FlattenSkirt
        local horizontalSkirt = physicsBlueprint.HorizontalSkirt
        if flatten then
            if horizontalSkirt then
                self:FlattenSkirtHorizontally()
            else
                self:FlattenSkirt()
            end
        end

        -- check for terrain orientation
        if not (
                physicsBlueprint.AltitudeToTerrain or
                physicsBlueprint.StandUpright or
                horizontalSkirt
            ) and (flatten or physicsBlueprint.AlwaysAlignToTerrain)
            and (layer == 'Land' or layer == 'Seabed')
        then
            -- rotate structure to match terrain gradient
            local a1, a2 = TerrainUtils.GetTerrainSlopeAnglesDegrees(
                self:GetPosition(),
                blueprint.Footprint.SizeX or physicsBlueprint.SkirtSizeX,
                blueprint.Footprint.SizeZ or physicsBlueprint.SkirtSizeZ
            )

            -- do not orientate structures that are on flat ground
            if a1 != 0 or a2 != 0 then
                -- quaternion magic incoming, be prepared! Note that the yaw axis is inverted, but then
                -- re-inverted again by multiplying it with the original orientation
                local quatSlope = Quaternion.fromAngle(0, 0 - a2,-1 * a1)
                local quatOrient = setmetatable(self:GetOrientation(), Quaternion)
                local quat = quatOrient * quatSlope
                self:SetOrientation(quat, true)

                -- technically obsolete, but as this is part of an integration we don't want to break
                -- the mod package that it originates from. Originates from the BrewLan mod suite
                self.TerrainSlope = {}
            end
        end

        -- create decal below structure
        if flatten and not self:HasTarmac() and blueprint.General.FactionName ~= "Seraphim" then
            if self.TarmacBag then
                self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            else
                self:CreateTarmac(true, true, true, false, false)
            end
        end
    end,

    --- Hides parts of a mesh that should be visible when the structure is made on water
    ---@param self StructureUnit
    HideLandBones = function(self)
        if self.LandBuiltHiddenBones and self.Layer == 'Land' then
            for _, v in self.LandBuiltHiddenBones do
                if self:IsValidBone(v) then
                    self:HideBone(v, true)
                end
            end
        end
    end,

    --- Rotates the structure towards the enemy, primarily used for point defenses
    ---@param self StructureUnit
    RotateTowardsEnemy = function(self)

        -- retrieve information we may need
        local bp = self.Blueprint
        local brain = self:GetAIBrain()
        local pos = self:GetPosition()

        -- determine default threat that aims at center of the map
        local x, z = GetMapSize()
        local target = {
            location = {0.5 * x, 0, 0.5 * z},
            distance = -1,
            threat = -1,
        }

        -- determine radius
        local radius = 40
        local weapons = self.Blueprint.Weapon
        if weapons then
            for k, weapon in weapons do
                if weapon.MaxRadius and weapon.MaxRadius > radius then
                    radius = 1.1 * weapon.MaxRadius
                end
            end
        end

        local cats = EntityCategoryContains(categories.ANTIAIR, self) and categories.AIR or (StructureUnitRotateTowardsEnemiesLand)
        local units = brain:GetUnitsAroundPoint(cats, pos, radius, 'Enemy')

        if units then
            for _, u in units do
                local blip = u:GetBlip(self.Army)
                if blip then

                    -- check if we've got it on radar and whether it is identified by army in question
                    local radar = blip:IsOnRadar(self.Army)
                    local identified = blip:IsSeenEver(self.Army)
                    if radar or identified then
                        local threat = (identified and u.Blueprint.Defense.SurfaceThreatLevel) or 1
                        if threat >= target.threat then
                            target.location = u:GetPosition()
                            target.threat = threat
                        end
                    end
                end
            end
        end

        -- get direction vector, atanify it for angle
        local rad = math.atan2(target.location[1] - pos[1], target.location[3] - pos[3])
        local degrees = rad * (180 / math.pi)

        if EntityCategoryContains(StructureUnitRotateTowardsEnemiesArtillery, self) then
            degrees = math.floor((degrees + 90) / 180) * 180
        end

        local rotator = CreateRotator(self, 0, 'y', degrees, nil, nil)
        rotator:SetPrecedence(1)
        self.Trash:Add(rotator)
    end,

    ---@param self StructureUnit
    ---@param builder Builder
    ---@param layer Layer
    OnStartBeingBuilt = function(self, builder, layer)
        Unit.OnStartBeingBuilt(self, builder, layer)

        -- rotate weaponry towards enemy
        if EntityCategoryContains(StructureUnitOnStartBeingBuiltRotateBuildings, self) then
            self:RotateTowardsEnemy()
        end
    end,

    ---@param self StructureUnit
    ---@param builder Builder
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        Unit.OnStopBeingBuilt(self, builder, layer)

        -- tarmac is made once seraphim animation is complete
        if self.Blueprint.General.FactionName == "Seraphim" then
            self:CreateTarmac(true, true, true, false, false)
        end

        self:PlayActiveAnimation()
    end,

    ---@param self StructureUnit
    FlattenSkirtHorizontally = function(self)
        local x0, z0, x1, z1 = self:GetSkirtRect()

        -- floor them
        x0 = x0 ^ 0
        z0 = z0 ^ 0

        -- ceil them
        x1 = 1 + (x1 ^ 0)
        z1 = 1 + (z1 ^ 0)

        -- compute average elevation and flatten
        local elevation = 0.25 * (
            GetTerrainHeight(x0, z0) +
            GetTerrainHeight(x1, z0) +
            GetTerrainHeight(x0, z1) +
            GetTerrainHeight(x1, z1)
        )

        FlattenMapRect(x0, z0, x1 - x0, z1 - z0, elevation)
    end,

    ---@param self StructureUnit
    FlattenSkirt = function(self)
        local x0, z0, x1, z1 = self:GetSkirtRect()

        -- floor them
        x0 = x0 ^ 0
        z0 = z0 ^ 0

        -- ceil them
        x1 = 1 + (x1 ^ 0)
        z1 = 1 + (z1 ^ 0)

        import('/lua/sim/TerrainUtils.lua').FlattenGradientMapRect(x0, z0, x1 - x0, z1 - z0)
    end,

    ---@param self StructureUnit
    ---@param albedo string
    ---@param normal string
    ---@param glow string
    ---@param orientation? number
    ---@param tarmac? UnitBlueprintTarmac
    ---@param lifeTime number
    ---@return boolean
    CreateTarmac = function(self, albedo, normal, glow, orientation, tarmac, lifeTime)
        self.Trash:Add(
            ForkThread(
                self.CreateTarmacThread,
                self,
                albedo,
                normal,
                glow, 
                orientation,
                tarmac,
                lifeTime
            )
        )
    end,

    ---@param self StructureUnit
    ---@param albedo string
    ---@param normal string
    ---@param glow string
    ---@param orientation? number
    ---@param tarmac? UnitBlueprintTarmac
    ---@param lifeTime number
    CreateTarmacThread = function(self, albedo, normal, glow, orientation, tarmac, lifeTime)
        -- hold up one tick to allow upgrades to pass the tarmac bag
        WaitTicks(1)

        -- upgrades pass the tarmac bag, in which case we take ownership and do nothing
        if self:HasTarmac() then
            self.TarmacBag.OwnedByEntity = self.EntityId
            return
        end

        -- no tarmacs underwater
        if self.Layer ~= 'Land' then
            return
        end

        -- bring into local scope for performance
        local CreateDecal = CreateDecal
        local GetTarmac = GetTarmac
        local TableEmpty = table.empty
        local TableRandom = table.random

        -- determine tarmac to place
        if not tarmac then
            local tarmacBlueprints = self.Blueprint.Display.Tarmacs
            if tarmacBlueprints and not TableEmpty(tarmacBlueprints) then
                tarmac = TableRandom(tarmacBlueprints)
            else
                return
            end
        end

        -- determine lod cutoff
        local meshBlueprint = self.Blueprint.Display.Mesh
        local cutoffOthers = meshBlueprint.LODs[1].LODCutoff
        local cutoffAlbedo = meshBlueprint.LODs[2].LODCutoff
        if not cutoffAlbedo then
            cutoffAlbedo = cutoffOthers
            cutoffOthers = 0.3 * cutoffOthers
        else
            cutoffOthers = 0.8 * cutoffOthers
        end

        -- reduce the LOD for performance
        cutoffAlbedo = 0.75 * cutoffAlbedo
        cutoffOthers = 0.75 * cutoffOthers

        -- determine orientation
        if not orientation then
            if tarmac.Orientations and not TableEmpty(tarmac.Orientations) then
                orientation = TableRandom(tarmac.Orientations)
                -- convert to radians
                orientation = (0.01745 * orientation)
            else
                orientation = 0
            end
        end

        -- determine size
        local w = tarmac.Width
        local l = tarmac.Length

        -- determine faction
        local factionIndex  = FactionToTarmacIndex[self.Blueprint.FactionCategory]

        -- determine terrain name for tarmacs based on terrain type
        local position = self:GetPosition()
        local terrain = GetTerrainType(position[1], position[3])
        local terrainName = ''
        if terrain then
            terrainName = terrain.Name
        end

        -- create a new bag
        self.TarmacBag = {
            Decals = TrashBag(),
            OwnedByEntity = self.EntityId,
            Orientation = orientation,
            CurrentBP = tarmac,
            Lifetime = cutoffOthers,
        }
        local bag = self.TarmacBag.Decals

        -- create albedo tarmac, note that it may have a 2nd texture for specular properties
        if albedo and tarmac.Albedo then
            local albedo2 = tarmac.Albedo2
            if albedo2 then
                albedo2 = albedo2 .. GetTarmac(factionIndex, terrain)
            end

            local handle = CreateDecal(
                position,
                orientation,
                tarmac.Albedo .. GetTarmac(factionIndex, terrainName),
                albedo2 or '',
                'Albedo',
                w,
                l,
                cutoffAlbedo, 
                lifeTime or 0,
                self.Army,
                0
            )

            bag:Add(handle)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(handle)
            end
        end

        -- create normals tarmac, note not the usual normals shader
        if normal and tarmac.Normal then
            local handle = CreateDecal(
                position,
                orientation,
                tarmac.Normal .. GetTarmac(factionIndex, terrainName),
                '',
                'Alpha Normals',
                w,
                l,
                cutoffOthers,
                lifeTime or 0,
                self.Army,
                0
            )

            bag:Add(handle)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(handle)
            end
        end

        -- create glow tarmacs, not used by the base game
        if glow and tarmac.Glow then
            local handle = CreateDecal(
                position,
                orientation,
                tarmac.Glow .. GetTarmac(factionIndex, terrainName),
                '',
                'Glow',
                w,
                l,
                cutoffOthers,
                lifeTime or 0,
                self.Army,
                0
            )

            bag:Add(handle)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(handle)
            end
        end
    end,

    ---@param self StructureUnit
    DestroyTarmac = function(self)
        -- no bag to clean up
        local bag = self.TarmacBag
        if not bag then
            return
        end

        -- not our responsibility to clean up
        if not bag.OwnedByEntity == self.EntityId then
            return
        end

        -- ok, clean the bag
        bag.Decals:Destroy()
    end,

    ---@param self StructureUnit
    HasTarmac = function(self)
        local bag = self.TarmacBag
        if not bag then
            return false
        end

        return not bag.Decals:Empty()
    end,

    ---@param self StructureUnit
    DestroyBlinkingLights = function(self)
        for _, v in self.FxBlinkingLightsBag do
            v:Destroy()
        end
        self.FxBlinkingLightsBag = { }
    end,

    ---@param self StructureUnit
    ---@param overkillRatio number
    CreateDestructionEffects = function(self, overkillRatio)
        if explosion.GetAverageBoundingXZRadius(self) < 1.0 then
            explosion.CreateScalableUnitExplosion(self)
        else
            explosion.CreateTimedStuctureUnitExplosion(self, self.DeathAnimManip)
            WaitSeconds(0.3)
            explosion.CreateScalableUnitExplosion(self)
        end
    end,

    -- Modified to use same upgrade logic as the ui. This adds more upgrade options via General.UpgradesFromBase blueprint option
    ---@param self StructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Check for death loop
        if not Unit.OnStartBuild(self, unitBeingBuilt, order) then
            return
        end
        self.UnitBeingBuilt = unitBeingBuilt

        local builderBp = self.Blueprint
        local targetBp = unitBeingBuilt.Blueprint
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

            -- Fix an oddly specific bug to structures with damaged shields:
            -- 1) let an engineer to assist the structure, repairing the damaged shield
            -- 2) upgrade the structure while the shield is being healed
            -- 3) engineer changes consumption target, but is in limbo - it consumes resources, but it doesn't repair the shield or help upgrade the structure

            -- Luckily, engineers do not heal damaged shields on their own. It usually only happens when an engineer was specifically told to assist the shield,
            -- therefore we add a check when we upgrade a structure that has a shield. For each guarding unit, check if this is the only command. If so,
            -- re-issue the guard command
            if self.MyShield then
                local guards = self:GetGuards()
                for k, guard in guards do
                    if table.getn(guard:GetCommandQueue()) == 1 then
                        IssueClearCommands({guard})
                        IssueGuard({guard}, self)
                    end
                end
            end
        end
    end,

    IdleState = State {
        Main = function(self)
        end,
    },

    UpgradingState = State {
        Main = function(self)
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()

            -- give ownership of tarmac bag
            local unitBuilding = self.UnitBeingBuilt
            if self.TarmacBag then
                local tarmacBag = self.TarmacBag
                tarmacBag.OwnedByEntity = unitBuilding.EntityId
                unitBuilding.TarmacBag = tarmacBag
            end

            local animation = self:GetUpgradeAnimation(self.UnitBeingBuilt)
            if animation then
                self.AnimatorUpgradeManip = CreateAnimator(self)
                self.Trash:Add(self.AnimatorUpgradeManip)
                local fractionOfComplete = 0
                self:StartUpgradeEffects(unitBuilding)
                self.AnimatorUpgradeManip:PlayAnim(animation, false):SetRate(0)

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

            if self.TarmacBag then
                self.TarmacBag.OwnedByEntity = self.EntityId
            end

            if self.AnimatorUpgradeManip then
                self.AnimatorUpgradeManip:Destroy()
            end

            self:PlayUnitSound('UpgradeFailed')
            self:PlayActiveAnimation()
            ChangeState(self, self.IdleState)
        end,
    },

    ---@param self StructureUnit
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        Unit.StartBeingBuiltEffects(self, builder, layer)
        local bp = self.Blueprint
        local FactionName = bp.General.FactionName

        if FactionName == 'UEF' then
            self:HideBone(0, true)
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

    ---@param self StructureUnit
    ---@param builder Unit
    ---@param layer Layer
    StopBeingBuiltEffects = function(self, builder, layer)
        local FactionName = self.Blueprint.General.FactionName
        if FactionName == 'UEF' and not self.BeingBuiltShowBoneTriggered then
            self:ShowBone(0, true)
            self:HideLandBones()
        end

        Unit.StopBeingBuiltEffects(self, builder, layer)
    end,

    ---comment
    ---@param self StructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order table
    StartBuildingEffects = function(self, unitBeingBuilt, order)
        Unit.StartBuildingEffects(self, unitBeingBuilt, order)
    end,

    ---@param self StructureUnit
    ---@param unitBeingBuilt Unit
    StopBuildingEffects = function(self, unitBeingBuilt)
        Unit.StopBuildingEffects(self, unitBeingBuilt)
    end,

    ---@param self StructureUnit
    ---@param unitBeingBuilt Unit
    StartUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:HideBone(0, true)
    end,

    ---@param self StructureUnit
    ---@param unitBeingBuilt Unit
    StopUpgradeEffects = function(self, unitBeingBuilt)
        unitBeingBuilt:ShowBone(0, true)
    end,

    ---@param self StructureUnit
    PlayActiveAnimation = function(self)
    end,

    ---@param self StructureUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        local scus = EntityCategoryFilterDown(categories.SUBCOMMANDER, self:GetGuards())
        if scus[1] then
            for _, u in scus do
                u:SetFocusEntity(self)
                self.Repairers[u.EntityId] = u
            end
        end

        Unit.OnKilled(self, instigator, type, overkillRatio)

        -- re-create tarmac bag, but with a life time
        local bag = self.TarmacBag
        local orient = bag.Orientation
        local currentBP = bag.CurrentBP
        local lifetime = bag.Lifetime
        self:DestroyTarmac()
        self:CreateTarmac(true, true, true, orient, currentBP, lifetime or 300)
    end,

    ---@param self StructureUnit
    ---@param wreckage Wreckage
    CheckRepairersForRebuild = function(self, wreckage)
        local units = {}
        for id, u in self.Repairers do
            if u:BeenDestroyed() then
                self.Repairers[id] = nil
            else
                local focus = u:GetFocusUnit()
                if focus == self and ((u:IsUnitState('Repairing') and not u:GetGuardedUnit()) or
                                      EntityCategoryContains(categories.SUBCOMMANDER, u)) then
                    table.insert(units, u)
                end
            end
        end

        if not units[1] then return end

        wreckage:Rebuild(units)
    end,

    ---@param self StructureUnit
    ---@param overkillRatio number
    ---@return Wreckage|nil
    CreateWreckage = function(self, overkillRatio)
        local wreckage = Unit.CreateWreckage(self, overkillRatio)
        if wreckage then
            self:CheckRepairersForRebuild(wreckage)
        end

        return wreckage
    end,

    -- Called by the engine when a structure is finished building for each adjacent unit
    ---@param self StructureUnit
    ---@param adjacentUnit StructureUnit
    ---@param triggerUnit StructureUnit
    OnAdjacentTo = function(self, adjacentUnit, triggerUnit)

        -- make sure we're both finished building
        if self:IsBeingBuilt() or adjacentUnit:IsBeingBuilt() then
            return
        end

        -- make sure we have adjacency buffs to apply
        local adjBuffs = self.Blueprint.Adjacency
        if not adjBuffs then
            return
        end

        -- keep track of who is adjacent to who
        self.AdjacentUnits = self.AdjacentUnits or { }
        adjacentUnit.AdjacentUnits = adjacentUnit.AdjacentUnits or { }

        self.AdjacentUnits[adjacentUnit.EntityId] = adjacentUnit
        adjacentUnit.AdjacentUnits[self.EntityId] = self

        -- apply the buffs
        local buffApplied = false
        if self.ConsumptionActive then
            for k, v in AdjacencyBuffs[adjBuffs] do
                buffApplied = true
                Buff.ApplyBuff(adjacentUnit, v, self)
            end
        end

        -- fix edge cases when buffs are applied
        if buffApplied then

            -- edge case for missile construction: the buff doesn't apply to the missile under construction
            if adjacentUnit.Blueprint.CategoriesHash["SILO"] then
                if adjacentUnit:IsUnitState('SiloBuildingAmmo') then
                    local autoModeEnabled = adjacentUnit.AutoModeEnabled or false
                    local progress = adjacentUnit:GetWorkProgress()
                    if progress < 0.99 then
                        adjacentUnit:StopSiloBuild()
                        IssueSiloBuildTactical({adjacentUnit})
                        adjacentUnit:GiveNukeSiloBlocks(progress)
                        LOG(autoModeEnabled)
                        adjacentUnit:SetAutoMode(autoModeEnabled)
                    end
                end
            end
        end
    
        -- refresh the UI
        self:RequestRefreshUI()
        adjacentUnit:RequestRefreshUI()
     end,

    -- Called by the engine when a structure is destroyed for each adjacent unit
    ---@param self StructureUnit
    ---@param adjacentUnit StructureUnit
    OnNotAdjacentTo = function(self, adjacentUnit)

        -- make sure we're both finished building
        if self:IsBeingBuilt() or adjacentUnit:IsBeingBuilt() then
            return
        end

        -- make sure we have buffs to remove
        local adjBuffs = self.Blueprint.Adjacency
        if not adjBuffs then
            return
        end

        -- remove the buffs
        local buffRemoved = false
        if adjBuffs and AdjacencyBuffs[adjBuffs] then
            for k, v in AdjacencyBuffs[adjBuffs] do
                if Buff.HasBuff(adjacentUnit, v) then
                    buffRemoved = true
                    Buff.RemoveBuff(adjacentUnit, v)
                end
            end
        end

        -- fix edge cases when buffs are removed
        if buffRemoved then

            -- edge case for missile construction: the buff doesn't apply to the missile under construction
            if adjacentUnit.Blueprint.CategoriesHash["SILO"] then
                if adjacentUnit:IsUnitState('SiloBuildingAmmo') then
                    local autoModeEnabled = adjacentUnit.AutoModeEnabled or false
                    local progress = adjacentUnit:GetWorkProgress()
                    if progress < 0.99 then
                        adjacentUnit:StopSiloBuild()
                        IssueSiloBuildTactical({adjacentUnit})
                        adjacentUnit:GiveNukeSiloBlocks(progress)
                        adjacentUnit:SetAutoMode(autoModeEnabled)
                    end
                end
            end
        end

        -- clean up effects
        self:DestroyAdjacentEffects(adjacentUnit)

        -- keep track of who is adjacent to who
        self.AdjacentUnits[adjacentUnit.EntityId] = nil
        adjacentUnit.AdjacentUnits[self.EntityId] = nil

        -- refresh the UI
        adjacentUnit:RequestRefreshUI()
        self:RequestRefreshUI()
    end,

    -- Add/Remove Adjacency Functionality
    -- Applies all appropriate buffs to all adjacent units
    ---@param self StructureUnit
    ApplyAdjacencyBuffs = function(self)
        local adjBuffs = self.Blueprint.Adjacency
        if not adjBuffs then return end

        -- There won't be any adjacentUnit if this is a producer just built...
        if self.AdjacentUnits then
            for k, adjacentUnit in self.AdjacentUnits do
                for k, v in AdjacencyBuffs[adjBuffs] do
                    Buff.ApplyBuff(adjacentUnit, v, self)
                    adjacentUnit:RequestRefreshUI()
                end
            end
            self:RequestRefreshUI()
        end
    end,

    -- Removes all appropriate buffs from all adjacent units
    ---@param self StructureUnit
    RemoveAdjacencyBuffs = function(self)
        local adjBuffs = self.Blueprint.Adjacency
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

    -- Add/Remove Adjacency Effects
    ---@param self StructureUnit
    ---@param adjacentUnit StructureUnit
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

    ---@param self StructureUnit
    ---@param adjacentUnit StructureUnit
    DestroyAdjacentEffects = function(self, adjacentUnit)
        if not self.AdjacencyBeamsBag then return end

        for k, v in self.AdjacencyBeamsBag do
            if v.Unit:BeenDestroyed() or v.Unit.Dead then
                v.Trash:Destroy()
                self.AdjacencyBeamsBag[k] = nil
            end
        end
    end,

    ---@param self StructureUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
	    -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep.Blueprint.Overcharge.structureDamage
        end
        Unit.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,

    ---@deprecated
    ---@param self StructureUnit
    ChangeBlinkingLights = function(self)
    end,

    ---@deprecated
    ---@param self StructureUnit
    CreateBlinkingLights = function(self)
    end,

    ---@deprecated
    ---@param self StructureUnit
    OnMassStorageStateChange = function(self, state)
    end,

    ---@deprecated
    ---@param self StructureUnit
    OnEnergyStorageStateChange = function(self, state)
    end,
}

-- FACTORY UNITS
---@class FactoryUnit : StructureUnit
---@field BuildingUnit boolean
---@field BuildBoneRotator moho.RotateManipulator
---@field BuildEffectBones string[]
FactoryUnit = ClassUnit(StructureUnit) {

    RollOffAnimationRate = 10,

    ---@param self FactoryUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- if we're a support factory, make sure our build restrictions are correct
        if self.Blueprint.CategoriesHash["SUPPORTFACTORY"] then
            self:UpdateBuildRestrictions()
        end

        -- Save build effect bones for faster access when creating build effects
        self.BuildBoneRotator = CreateRotator(self, self.Blueprint.Display.BuildAttachBone or 0, 'y', 0, 10000)
        self.BuildBoneRotator:SetPrecedence(1000)

        self.Trash:Add(self.BuildBoneRotator)
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        self.BuildingUnit = false
        self:SetFireState(FireState.GROUND_FIRE)
    end,

    ---@param self FactoryUnit
    ---@return string?
    ToSupportFactoryIdentifier = function(self)
        local hashedCategories = self.Blueprint.CategoriesHash
        local identifier = self.Blueprint.BlueprintId
        local faction = identifier:sub(2, 2)
        local layer = identifier:sub(7, 7)

        -- HQs can not upgrade to support factories
        if hashedCategories["RESEARCH"] then
            return nil
        end

        -- tech 1 factories can go tech 2 support factories if we have a tech 2 hq
        if  hashedCategories["TECH1"] and
            self.Brain:CountHQs(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, 'TECH2') > 0
        then
            return 'z' .. faction .. 'b950' .. layer
        end

        -- tech 2 support factories can go tech 3 support factories if we have a tech 3 hq
        if  hashedCategories["TECH2"] and
            hashedCategories["SUPPORTFACTORY"] and
            self.Brain:CountHQs(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, 'TECH3') > 0
        then
            return 'z' .. faction .. 'b960' .. layer
        end

        -- anything else can not upgrade
        return nil
    end,

    ---@param self FactoryUnit
    ToHQFactoryIdentifier = function(self)
        local hashedCategories = self.Blueprint.CategoriesHash
        local identifier = self.Blueprint.BlueprintId
        local faction = identifier:sub(1, 3)
        local layer = identifier:sub(7, 7)

        -- support factories can not upgrade to HQs
        if hashedCategories["SUPPORTFACTORY"] then
            return nil
        end

        -- tech 1 factories can always upgrade
        if hashedCategories["TECH1"] then
            return faction .. '020' .. layer
        end

        -- tech 2 factories can always upgrade
        if hashedCategories["TECH2"] and hashedCategories["RESEARCH"] then
            return faction .. '030'  .. layer
        end

        -- anything else can not upgrade
        return nil
    end,

    ---@param self FactoryUnit
    DestroyUnitBeingBuilt = function(self)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() < 1 then
            if self.UnitBeingBuilt:GetFractionComplete() > 0.5 then
                self.UnitBeingBuilt:Kill()
            else
                self.UnitBeingBuilt:Destroy()
            end
        end
    end,

    ---@param self FactoryUnit
    OnDestroy = function(self)
        StructureUnit.OnDestroy(self)

        if self.Blueprint.CategoriesHash["RESEARCH"] and self:GetFractionComplete() == 1.0 then

            -- update internal state
            self.Brain:RemoveHQ(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, self.Blueprint.TechCategory)
            self.Brain:SetHQSupportFactoryRestrictions(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory)

            -- update all units affected by this
            local affected = self.Brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
            for id, unit in affected do
                unit:UpdateBuildRestrictions()
            end
        end

        self:DestroyUnitBeingBuilt()
    end,

    ---@param self FactoryUnit
    OnPaused = function(self)
        StructureUnit.OnPaused(self)

        -- When factory is paused take some action
        if self:IsUnitState('Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self FactoryUnit
    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            StructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    OnStartBuild = function(self, unitBeingBuilt, order)
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order)

        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        elseif unitBeingBuilt.Blueprint.CategoriesHash["RESEARCH"] then
            -- Removes assist command to prevent accidental cancellation when right-clicking on other factory
            self:RemoveCommandCap('RULEUCC_Guard')
            self.DisabledAssist = true
        end
        self.FactoryBuildFailed = false
    end,

    --- Introduce a rolloff delay, where defined.
    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    OnStopBuild = function(self, unitBeingBuilt, order)
        if self.DisabledAssist then
            self:AddCommandCap('RULEUCC_Guard')
            self.DisabledAssist = nil
        end
        local bp = self.Blueprint
        if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
            self:ForkThread(self.PauseThread, bp.General.RolloffDelay, unitBeingBuilt, order)
        else
            self:DoStopBuild(unitBeingBuilt, order)
        end
    end,

    ---@param self FactoryUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)

        if self.Blueprint.CategoriesHash["RESEARCH"] then
            -- update internal state
            self.Brain:AddHQ(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, self.Blueprint.TechCategory)
            self.Brain:SetHQSupportFactoryRestrictions(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory)

            -- update all units affected by this
            local affected = self.Brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
            for _, unit in affected do
                unit:UpdateBuildRestrictions()
            end
        end
    end,

    --- Adds a pause between unit productions
    ---@param self FactoryUnit
    ---@param productionpause number
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    PauseThread = function(self, productionpause, unitBeingBuilt, order)
        self:StopBuildFx()
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)

        WaitSeconds(productionpause)

        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        self:DoStopBuild(unitBeingBuilt, order)
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
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

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self.Blueprint
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(self.RollOffAnimationRate)
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

    ---@param self FactoryUnit
    ---@param target_bp any
    ---@return boolean
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

    ---@param self FactoryUnit
    OnFailedToBuild = function(self)
        StructureUnit.OnFailedToBuild(self)
        self.FactoryBuildFailed = true
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    ---@param self FactoryUnit
    RollOffUnit = function(self)
        local spin, x, y, z = self:CalculateRollOffPoint()
        self.UnitBeingBuilt:SetRotation(spin)

        RolloffUnitTable[1] = self.UnitBeingBuilt
        RolloffPositionTable[1], RolloffPositionTable[2], RolloffPositionTable[3] = x, y, z
        IssueMove(RolloffUnitTable, RolloffPositionTable)
    end,

    ---@param self FactoryUnit
    CalculateRollOffPoint = function(self)
        local px, py, pz = self:GetPositionXYZ()

        -- check if we have roll of points set
        local rollOffPoints = self.Blueprint.Physics.RollOffPoints
        if not rollOffPoints then
            return 0, px, py, pz
        end

        -- find our rally point, or of the factory that we're assisting
        local rally = self:GetRallyPoint()
        local focus = self:GetGuardedUnit()
        while focus and focus != self do
            local next = focus:GetGuardedUnit()
            if next then
                focus = next
            else
                break
            end
        end

        if focus then
            rally = focus:GetRallyPoint()
        end

        -- check if we have a rally point set
        if not rally then
            return 0, px, py, pz
        end

        -- find nearest roll off point for rally point
        local nearestRollOffPoint = nil
        local d, dx, dz, lowest = 0, 0, 0, nil
        for k, rollOffPoint in rollOffPoints do
            dx = rally[1] - (px + rollOffPoint.X)
            dz = rally[3] - (pz + rollOffPoint.Z)
            d = dx * dx + dz * dz

            if not lowest or d < lowest then
                nearestRollOffPoint = rollOffPoint
                lowest = d
            end
        end

        -- determine return parameters
        local spin = self.UnitBeingBuilt.Blueprint.Display.ForcedBuildSpin or nearestRollOffPoint.UnitSpin
        local fx = nearestRollOffPoint.X + px
        local fy = nearestRollOffPoint.Y + py
        local fz = nearestRollOffPoint.Z + pz

        return spin, fx, fy, fz
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
    end,

    ---@param self FactoryUnit
    StopBuildFx = function(self)
    end,

    ---@param self FactoryUnit
    PlayFxRollOff = function(self)
    end,

    ---@param self FactoryUnit
    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(-1 * self.RollOffAnimationRate)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    ---@param self FactoryUnit
    RolloffBody = function(self)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayFxRollOff()

        -- find out when build pad is free again

        local size = 0.5 * self.UnitBeingBuilt.Blueprint.SizeX
        if size < self.UnitBeingBuilt.Blueprint.SizeZ then
            size = 0.5 * self.UnitBeingBuilt.Blueprint.SizeZ
        end

        size = size * size
        local unitPosition, dx, dz, d
        local buildPosition = self:GetPosition(self.Blueprint.Display.BuildAttachBone or 0)
        repeat
            unitPosition = self.UnitBeingBuilt:GetPosition()
            dx = buildPosition[1] - unitPosition[1]
            dz = buildPosition[3] - unitPosition[3]
            d = dx * dx + dz * dz
            WaitTicks(2)
        until IsDestroyed(self.UnitBeingBuilt) or d > size

        self:PlayFxRollOffEnd()
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        ChangeState(self, self.IdleState)
    end,

    ---@deprecated
    ---@param self FactoryUnit
    CreateBuildRotator = function(self)
    end,

    ---@deprecated
    ---@param self FactoryUnit
    DestroyBuildRotator = function(self)
    end,

    IdleState = State {
        ---@param self FactoryUnit
        Main = function(self)
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end,
    },

    BuildingState = State {
        ---@param self FactoryUnit
        Main = function(self)
            -- to help prevent a 1-tick rotation on most units
            local hasEnhancements = self.UnitBeingBuilt.Blueprint.Enhancements
            if not hasEnhancements then
                self.UnitBeingBuilt:HideBone(0, true)
            end

            local spin = self:CalculateRollOffPoint()
            self.BuildBoneRotator:SetGoal(spin)
            self.UnitBeingBuilt:AttachBoneTo(-2, self, self.Blueprint.Display.BuildAttachBone or 0)
            self:StartBuildFx(self.UnitBeingBuilt)

            -- prevents a 1-tick rotating visual 'glitch' of unit
            -- as it is being attached and the rotator is applied
            WaitTicks(3)
            if not hasEnhancements then
                self.UnitBeingBuilt:ShowBone(0, true)
            end
        end,
    },

    RollingOffState = State {
        ---@param self FactoryUnit
        Main = function(self)
            self:RolloffBody()
        end,
    },
}

-- AIR FACTORY UNITS
---@class AirFactoryUnit : FactoryUnit
AirFactoryUnit = ClassUnit(FactoryUnit) {}

-- AIR STAGING PLATFORMS UNITS
---@class AirStagingPlatformUnit : StructureUnit
AirStagingPlatformUnit = ClassUnit(StructureUnit) { }

-- ENERGY CREATION UNITS
---@class ConcreteStructureUnit : StructureUnit
ConcreteStructureUnit = ClassUnit(StructureUnit) {
    ---@param self ConcreteStructureUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}

-- ENERGY CREATION UNITS
---@class EnergyCreationUnit : StructureUnit
EnergyCreationUnit = ClassUnit(StructureUnit) { }

-- ENERGY STORAGE UNITS
---@class EnergyStorageUnit : StructureUnit
EnergyStorageUnit = ClassUnit(StructureUnit) { }

-- LAND FACTORY UNITS
---@class LandFactoryUnit : FactoryUnit
LandFactoryUnit = ClassUnit(FactoryUnit) {}

-- MASS COLLECTION UNITS
---@class MassCollectionUnit : StructureUnit
MassCollectionUnit = ClassUnit(StructureUnit) {

    ---@param self MassCollectionUnit
    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true
    end,

    ---@param self MassCollectionUnit
    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false
    end,

    ---@param self MassCollectionUnit
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---comment
    ---@param self MassCollectionUnit
    ---@param unitbuilding MassCollectionUnit
    ---@param order boolean
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:AddCommandCap('RULEUCC_Stop')
        self.UpgradeWatcher = self:ForkThread(self.WatchUpgradeConsumption)
    end,

    ---@param self MassCollectionUnit
    ---@param unitbuilding MassCollectionUnit
    ---@param order boolean
    OnStopBuild = function(self, unitbuilding, order)
        StructureUnit.OnStopBuild(self, unitbuilding, order)
        self:RemoveCommandCap('RULEUCC_Stop')
        if self.UpgradeWatcher then
            KillThread(self.UpgradeWatcher)
            self:SetConsumptionPerSecondMass(0)
            self:SetProductionPerSecondMass((self.Blueprint.Economy.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
        end
    end,

    -- Band-aid on lack of multiple separate resource requests per unit...
    -- If mass econ is depleted, take all the mass generated and use it for the upgrade
    -- Old WatchUpgradeConsumption replaced with this on, enabling mex to not use resources when paused
    ---@param self MassCollectionUnit
    WatchUpgradeConsumption = function(self)
        local bp = self.Blueprint
        local massConsumption = self:GetConsumptionPerSecondMass()

        -- Fix for weird mex behaviour when upgrading with depleted resource stock or while paused [100]
        -- Replaced Gowerly's fix with this which is very much inspired by his code. My code looks much better and
        -- seems to work a little better aswell.
        local aiBrain = self:GetAIBrain()

        local CalcEnergyFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored('ENERGY') < self:GetConsumptionPerSecondEnergy() then
                fraction = math.min(1, aiBrain:GetEconomyIncome('ENERGY') / aiBrain:GetEconomyRequested('ENERGY'))
            end
            return fraction
        end

        local CalcMassFraction = function()
            local fraction = 1
            if aiBrain:GetEconomyStored('MASS') < self:GetConsumptionPerSecondMass() then
                fraction = math.min(1, aiBrain:GetEconomyIncome('MASS') / aiBrain:GetEconomyRequested('MASS'))
            end
            return fraction
        end

        while not self.Dead do
            local massProduction = bp.Economy.ProductionPerSecondMass * (self.MassProdAdjMod or 1)
            if self:IsPaused() then
                -- Paused mex upgrade (another bug here that caused paused upgrades to continue use resources)
                self:SetConsumptionPerSecondMass(0)
                self:SetProductionPerSecondMass(massProduction * CalcEnergyFraction())
            elseif aiBrain:GetEconomyStored('MASS') < 1 then
                -- Mex upgrade while out of mass (this is where the engine code has a bug)
                self:SetConsumptionPerSecondMass(massConsumption)
                self:SetProductionPerSecondMass(massProduction / CalcMassFraction())
                -- To use Gowerly's words; the above division cancels the engine bug like matter and anti-matter.
                -- The engine seems to do the exact opposite of this division.
            else
                -- Mex upgrade while enough mass (don't care about energy, that works fine)
                self:SetConsumptionPerSecondMass(massConsumption)
                self:SetProductionPerSecondMass(massProduction * CalcEnergyFraction())
            end

            WaitTicks(1)
        end
    end,

    ---@param self MassCollectionUnit
    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassCollectionUnit
    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,
}

-- MASS FABRICATION UNITS
---@class MassFabricationUnit : StructureUnit
MassFabricationUnit = ClassUnit(StructureUnit) {

    ---@param self MassFabricationUnit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 4 then
            -- no longer track us, we want to be disabled
            self.Brain:RemoveEnergyExcessUnit(self)

            -- immediately disable production
            self:OnProductionPaused()
        else
            StructureUnit.OnScriptBitSet(self, bit)
        end
    end,

    ---@param self MassFabricationUnit
    ---@param bit number
    OnScriptBitClear = function (self, bit)
        if bit == 4 then
            -- make brain track us to enable / disable accordingly
            self.Brain:AddDisabledEnergyExcessUnit(self)
        else
            StructureUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self MassFabricationUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)

        -- make brain track us to enable / disable accordingly
        self.Brain:AddEnabledEnergyExcessUnit(self)
    end,

    ---@param self MassFabricationUnit
    OnConsumptionActive = function(self)
        StructureUnit.OnConsumptionActive(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
        self:ApplyAdjacencyBuffs()
        self.ConsumptionActive = true
    end,

    ---@param self MassFabricationUnit
    OnConsumptionInActive = function(self)
        StructureUnit.OnConsumptionInActive(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
        self:RemoveAdjacencyBuffs()
        self.ConsumptionActive = false
    end,

    ---@param self MassFabricationUnit
    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassFabricationUnit
    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,

    ---@param self MassFabricationUnit
    OnExcessEnergy = function(self)
        self:OnProductionUnpaused()
    end,

    ---@param self MassFabricationUnit
    OnNoExcessEnergy = function(self)
        self:OnProductionPaused()
    end,

}

-- MASS STORAGE UNITS
---@class MassStorageUnit : StructureUnit
MassStorageUnit = ClassUnit(StructureUnit) { }

-- RADAR UNITS
---@class RadarUnit : StructureUnit
RadarUnit = ClassUnit(StructureUnit) {

    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = self
    end,

    ---@param self RadarUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnKilled = function (self, instigator, type, overkillRatio)
        StructureUnit.OnKilled(self, instigator, type, overkillRatio)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    OnDestroy = function (self)
        StructureUnit.OnDestroy(self)

        -- keep track of radars
        self.Brain.Radars[self.Blueprint.TechCategory][self.EntityId] = nil
    end,

    ---@param self RadarUnit
    OnIntelDisabled = function(self, intel)
        StructureUnit.OnIntelDisabled(self, intel)
        self:DestroyIdleEffects()
    end,

    ---@param self RadarUnit
    OnIntelEnabled = function(self, intel)
        StructureUnit.OnIntelEnabled(self, intel)
        self:CreateIdleEffects()
    end,
}

-- RADAR JAMMER UNITS
---@class RadarJammerUnit : StructureUnit
RadarJammerUnit = ClassUnit(StructureUnit) {

    -- Shut down intel while upgrading
    ---@param self RadarJammerUnit
    ---@param unitbuilding RadarJammerUnit
    ---@param order boolean
    OnStartBuild = function(self, unitbuilding, order)
        StructureUnit.OnStartBuild(self, unitbuilding, order)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Construction', 'Jammer')
        self:DisableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        StructureUnit.OnStopBuild(self, unitBeingBuilt)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    -- If we abort the upgrade, re-enable the intel
    ---@param self RadarJammerUnit
    OnFailedToBuild = function(self)
        StructureUnit.OnStopBuild(self)
        self:SetMaintenanceConsumptionActive()
        self:EnableUnitIntel('Construction', 'Jammer')
        self:EnableUnitIntel('Construction', 'RadarStealthField')
    end,

    ---@param self RadarJammerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self RadarJammerUnit
    OnIntelEnabled = function(self, intel)
        StructureUnit.OnIntelEnabled(self, intel)
        if self.IntelEffects and not self.IntelFxOn then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            self.IntelFxOn = true
        end
    end,

    ---@param self RadarJammerUnit
    OnIntelDisabled = function(self, intel)
        StructureUnit.OnIntelDisabled(self, intel)
        EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        self.IntelFxOn = false
    end,
}

-- SONAR UNITS
---@class SonarUnit : StructureUnit
SonarUnit = ClassUnit(StructureUnit) {

    ---@param self SonarUnit
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self SonarUnit
    CreateIdleEffects = function(self)
        StructureUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    ---@param self SonarUnit
    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            local emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0, vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                self:PlayUnitSound('Sonar')
                WaitSeconds(6.0)
            end
        end
    end,

    ---@param self SonarUnit
    DestroyIdleEffects = function(self)
        StructureUnit.DestroyIdleEffects(self)
        if self.TimedSonarEffectsThread then
            self.TimedSonarEffectsThread:Destroy()
        end
    end,
}

-- SEA FACTORY UNITS
---@class SeaFactoryUnit : FactoryUnit
SeaFactoryUnit = ClassUnit(FactoryUnit) {

    ---@param self SeaFactoryUnit
    DestroyUnitBeingBuilt = function(self)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() < 1 then
            self.UnitBeingBuilt:Destroy()
        end
    end,

    ---@param self SeaFactoryUnit
    CalculateRollOffPoint = function(self)
        -- backwards compatible, don't try and fix mods that rely on the old logic
        if not self.Blueprint.Physics.ComputeRollOffPoint then
            return FactoryUnit.CalculateRollOffPoint(self)
        end

        -- retrieve our position
        local px, py, pz = self:GetPositionXYZ()

        -- retrieve roll off points
        local bp = self.Blueprint.Physics.RollOffPoints
        if not bp then
            return 0, px, py, pz
        end

        -- retrieve rally point
        local rallyPoint = self:GetRallyPoint()
        if not rallyPoint then
            return 0, px, py, pz
        end

        -- find the attachpoint for the build location
        local bone = (self:IsValidBone('Attachpoint') and 'Attachpoint') or (self:IsValidBone('Attachpoint01') and 'Attachpoint01')
        local bx, by, bz = self:GetPositionXYZ(bone)
        local ropx = bx - px
        local modz = 1.0 + 0.1 * self.UnitBeingBuilt.Blueprint.SizeZ

        -- find the nearest roll off point
        local bpKey = 1
        local distance, lowest = nil
        for k, rolloffPoint in bp do

            local ropz = modz * rolloffPoint.Z
            distance = VDist2(rallyPoint[1], rallyPoint[3], ropx + px, ropz + pz)
            if not lowest or distance < lowest then
                bpKey = k
                lowest = distance
            end
        end

        -- finalize the computation
        local fx, fy, fz, spin
        local bpP = bp[bpKey]
        local unitBP = self.UnitBeingBuilt.Blueprint.Display.ForcedBuildSpin
        if unitBP then
            spin = unitBP
        else
            spin = bpP.UnitSpin
        end

        fx = ropx + px
        fy = bpP.Y + py
        fz = modz * bpP.Z + pz

        return spin, fx, fy, fz
    end,

}

-- SHIELD STRCUTURE UNITS
---@class ShieldStructureUnit : StructureUnit
ShieldStructureUnit = ClassUnit(StructureUnit) { }

-- TRANSPORT BEACON UNITS
---@class TransportBeaconUnit : StructureUnit
TransportBeaconUnit = ClassUnit(StructureUnit) {

    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    --- Invincibility!  (the only way to kill a transport beacon is
    --- to kill the transport unit generating it)
    ---@param self TransportBeaconUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    ---@param self TransportBeaconUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
    end,
}

-- WALL STRCUTURE UNITS
---@class WallStructureUnit : StructureUnit
WallStructureUnit = ClassUnit(StructureUnit) { }

-- QUANTUM GATE UNITS
---@class QuantumGateUnit : FactoryUnit
QuantumGateUnit = ClassUnit(FactoryUnit) { }

-- MOBILE UNITS
---@class MobileUnit : Unit, TreadComponent
MobileUnit = ClassUnit(Unit, TreadComponent) {

    ---@param self MobileUnit
    OnCreate = function(self)
        Unit.OnCreate(self)
        TreadComponent.OnCreate(self)

        self:SetFireState(FireState.GROUND_FIRE)

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

-- WALKING LAND UNITS
---@class WalkingLandUnit : MobileUnit
WalkingLandUnit = ClassUnit(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    ---comment
    ---@param self WalkingLandUnit
    ---@param spec any
    OnCreate = function(self, spec)
        MobileUnit.OnCreate(self, spec)

        local blueprint = self.Blueprint
        self.AnimationWalk = blueprint.Display.AnimationWalk
        self.AnimationWalkRate = blueprint.Display.AnimationWalkRate
    end,

    ---comment
    ---@param self WalkingLandUnit
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)
        MobileUnit.OnMotionHorzEventChange(self, new, old)

        if old == 'Stopped' then
            if not self.Animator then
                self.Animator = CreateAnimator(self, true)
            end

            if self.AnimationWalk then
                self.Animator:PlayAnim(self.AnimationWalk, true)
                self.Animator:SetRate(self.AnimationWalkRate or 1)
            end
        elseif new == 'Stopped' then
            -- Only keep the animator around if we are dying and playing a death anim
            -- Or if we have an idle anim
            if self.IdleAnim and not self.Dead then
                self.Animator:PlayAnim(self.IdleAnim, true)
            elseif not self.DeathAnim or not self.Dead then
                self.Animator:Destroy()
                self.Animator = false
            end
        end
    end,
}

-- SUB UNITS
-- These units typically float under the water and have wake when they move
---@class SubUnit : MobileUnit
SubUnit = ClassUnit(MobileUnit) {
    -- Use default spark effect until underwater damaged states are made
    FxDamage1 = { EffectTemplate.DamageSparks01 },
    FxDamage2 = { EffectTemplate.DamageSparks01 },
    FxDamage3 = { EffectTemplate.DamageSparks01 },

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,

    ---comment
    ---@param self SubUnit
    ---@param spec any
    OnCreate = function(self, spec)
        MobileUnit.OnCreate(self, spec)

        -- submarines do not make a sound by default, we want them to make sound so we use an entity as source instead
        self.SoundEntity = Entity()
        self.Trash:Add(self.SoundEntity)
        Warp(self.SoundEntity, self:GetPosition())
        self.SoundEntity:AttachTo(self,-1)
    end,
}

-- AIR UNITS
---@class AirUnit : MobileUnit
AirUnit = ClassUnit(MobileUnit) {
    -- Contrails
    ContrailEffects = {'/effects/emitters/contrail_polytrail_01_emit.bp', },
    BeamExhaustCruise = '/effects/emitters/air_move_trail_beam_03_emit.bp',
    BeamExhaustIdle = '/effects/emitters/air_idle_trail_beam_01_emit.bp',

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DestructionExplosionWaitDelayMax = 0,
    DestroyNoFallRandomChance = 0.5,

    ---@param self AirUnit
    OnCreate = function(self)
        MobileUnit.OnCreate(self)
        self.HasFuel = true
        self:AddPingPong()
    end,

    ---@param self AirUnit
    AddPingPong = function(self)
        local bp = self.Blueprint
        if bp.Display.PingPongScroller then
            bp = bp.Display.PingPongScroller
            if bp.Ping1 and bp.Ping1Speed and bp.Pong1 and bp.Pong1Speed and bp.Ping2 and bp.Ping2Speed
                and bp.Pong2 and bp.Pong2Speed then
                self:AddPingPongScroller(bp.Ping1, bp.Ping1Speed, bp.Pong1, bp.Pong1Speed,
                                         bp.Ping2, bp.Ping2Speed, bp.Pong2, bp.Pong2Speed)
            end
        end
    end,

    ---@param self AirUnit
    ---@param new string
    ---@param old string
    OnMotionVertEventChange = function(self, new, old)
        MobileUnit.OnMotionVertEventChange(self, new, old)

        if new == 'Down' then
            -- Turn off the ambient hover sound
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Bottom' then
            -- While landed, planes can only see half as far
            local vis = self.Blueprint.Intel.VisionRadius / 2
            self:SetIntelRadius('Vision', vis)

            -- Turn off the ambient hover sound
            -- It will probably already be off, but there are some odd cases that
            -- make this a good idea to include here as well.
            self:StopUnitAmbientSound('ActiveLoop')
        elseif new == 'Up' or (new == 'Top' and (old == 'Down' or old == 'Bottom')) then
            -- Set the vision radius back to default
            local bpVision = self.Blueprint.Intel.VisionRadius
            if bpVision then
                self:SetIntelRadius('Vision', bpVision)
            else
                self:SetIntelRadius('Vision', 0)
            end
        end
    end,

    ---@param self AirUnit
    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    ---@param self AirUnit
    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- Penalize movement for running out of fuel
        self:SetSpeedMult(0.35) -- Change the speed of the unit by this mult
        self:SetAccMult(0.25) -- Change the acceleration of the unit by this mult
        self:SetTurnMult(0.25) -- Change the turn ability of the unit by this mult
    end,

    ---@param self AirUnit
    OnGotFuel = function(self)
        self.HasFuel = true
        -- Revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
    end,

    -- Planes need to crash. Called by engine or by ShieldCollider projectile on collision with ground or water
    ---@param self AirUnit
    ---@param with string
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        -- Immediately destroy units outside the map
        if not ScenarioFramework.IsUnitInPlayableArea(self) then
            self:Destroy()
        end

        -- Only call this code once
        self.GroundImpacted = true

        -- Damage the area we hit. For damage, use the value which may have been adjusted by a shield impact
        if not self.deathWep or not self.DeathCrashDamage then -- Bail if stuff is missing
            WARN('defaultunits.lua OnImpact: did not find a deathWep on the plane! Is the weapon defined in the blueprint? ' .. self.UnitId)
        elseif self.DeathCrashDamage > 0 then -- It was completely absorbed by a shield!
            local deathWep = self.deathWep -- Use a local copy for speed and easy reading
            DamageArea(self, self:GetPosition(), deathWep.DamageRadius, self.DeathCrashDamage, deathWep.DamageType, deathWep.DamageFriendly)
            DamageArea(self, self:GetPosition(), deathWep.DamageRadius, 1, 'TreeForce', false)
        end

        if with == 'Water' then
            self:PlayUnitSound('AirUnitWaterImpact')
            EffectUtil.CreateEffectsOpti(self, self.Army, EffectTemplate.DefaultProjectileWaterImpact)
            self.shallSink = true
            self.colliderProj:Destroy()
            self.colliderProj = nil
        end

        self:DisableUnitIntel('Killed')
        self:DisableIntel('Vision') -- Disable vision seperately, it's not handled in DisableUnitIntel
        self:ForkThread(self.DeathThread, self.OverKillRatio)
    end,

    -- ONLY works for Terrain, not Water
    ---@param self AirUnit
    ---@param bone Bone
    ---@param x number
    ---@param y number
    ---@param z number
    OnAnimTerrainCollision = function(self, bone, x, y, z)
        self:OnImpact('Terrain')
    end,

    ---@param self AirUnit
    ShallSink = function(self)
        local layer = self.Layer
        local shallSink = (
            self.shallSink or -- Only the case when a bounced plane hits water. Overrides the fact that the layer is 'Air'
            ((layer == 'Water' or layer == 'Sub') and  -- In a layer for which sinking is meaningful
            not EntityCategoryContains(categories.STRUCTURE, self))  -- Exclude structures
        )
        return shallSink
    end,

    ---@param self AirUnit
    ---@param scale number
    CreateUnitAirDestructionEffects = function(self, scale)
        local scale = explosion.GetAverageBoundingXZRadius(self)
        local blueprint = self.Blueprint
        explosion.CreateDefaultHitExplosion(self, scale)

        if self.ShowUnitDestructionDebris then
            explosion.CreateDebrisProjectiles(self, scale, {blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    ---@param self AirUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.

        -- Additional stupidity: An idle transport, bot loaded and unloaded, counts as 'Land' layer so it would die with the wreck hovering.
        -- It also wouldn't call this code, and hence the cargo destruction. Awful!
        if self:GetFractionComplete() == 1 and (self.Layer == 'Air' or EntityCategoryContains(categories.TRANSPORTATION, self)) then
            self:CreateUnitAirDestructionEffects(1.0)
            self:DestroyTopSpeedEffects()
            self:DestroyBeamExhaust()
            self.OverKillRatio = overkillRatio
            self:PlayUnitSound('Killed')
            self:DoUnitCallbacks('OnKilled')
            self:DisableShield()

            -- Store our death weapon's damage on the unit so it can be edited remotely by the shield bouncer projectile
            local bp = self.Blueprint
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
            local proj = self:CreateProjectileAtBone('/projectiles/ShieldCollider/ShieldCollider_proj.bp', 0)
            self.colliderProj = proj
            proj:Start(self, 0)
            self.Trash:Add(proj)

            self:VeterancyDispersal()
        else
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,

    --- Called when a unit collides with a projectile to check if the collision is valid, allows
    -- ASF to be destroyed when they impact with strategic missiles
    ---@param self AirUnit The unit we're checking the collision for
    ---@param other Unit other The projectile we're checking the collision with
    ---@param firingWeapon Unit The weapon that the projectile originates from
    ---@return boolean
    OnCollisionCheck = function(self, other, firingWeapon)
        if self.DisallowCollisions then
            return false
        end

        -- allow regular air units to be destroyed by strategic missiles
        if other.Nuke and not self.Blueprint.CategoriesHash.EXPERIMENTAL then
            self:Kill()
            return false
        end

        return MobileUnit.OnCollisionCheck(self, other, firingWeapon)
    end,
}

--- Mixin transports (air, sea, space, whatever). Sellotape onto concrete transport base classes as desired.
local slotsData = {}
---@class BaseTransport
BaseTransport = ClassSimple {

    ---@param self BaseTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:RequestRefreshUI()

        for i = 1, self:GetBoneCount() do
            if self:GetBoneName(i) == attachBone then
                self.slots[i] = unit
                unit.attachmentBone = i
            end
        end
    end,

    ---@param self BaseTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:RequestRefreshUI()
        self.slots[unit.attachmentBone] = nil
        unit.attachmentBone = nil
    end,

    -- When one of our attached units gets killed, detach it
    ---@param self BaseTransport
    ---@param attached Unit
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    ---@param self BaseTransport
    OnStartTransportLoading = function(self)
        -- We keep the aibrain up to date with the last transport to start loading so, among other
        -- things, we can determine which transport is being referenced during an OnTransportFull
        -- event (As this function is called immediately before that one).
        self.transData = {}
        self:GetAIBrain().loadingTransport = self
    end,

    ---@param self BaseTransport
    OnStopTransportLoading = function(self)
    end,

    ---@param self BaseTransport
    DestroyedOnTransport = function(self)
    end,

    -- Detaches cargo from a dying unit
    ---@param self BaseTransport
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

    ---@param self BaseTransport
    SaveCargoMass = function(self)
        local mass = 0
        for _, unit in self:GetCargo() do
            mass = mass + unit:GetVeterancyValue()
            unit.veterancyDispersed = true
        end
        self.cargoMass = mass
    end
}

--- Base class for air transports.
---@class AirTransport: AirUnit, BaseTransport
AirTransport = ClassUnit(AirUnit, BaseTransport) {
    ---@param self AirTransport
    OnCreate = function(self)
        AirUnit.OnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        AirUnit.OnTransportAttach(self, attachBone, unit)
        BaseTransport.OnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        AirUnit.OnTransportDetach(self, attachBone, unit)
        BaseTransport.OnTransportDetach(self, attachBone, unit)
    end,

    OnAttachedKilled = function(self, attached)
        AirUnit.OnAttachedKilled(self, attached)
        BaseTransport.OnAttachedKilled(self, attached)
    end,

    ---@param self AirTransport
    OnStartTransportLoading = function(self)
        AirUnit.OnStartTransportLoading(self)
        BaseTransport.OnStartTransportLoading(self)
    end,

    ---@param self AirTransport
    OnStopTransportLoading = function(self)
        AirUnit.OnStopTransportLoading(self)
        BaseTransport.OnStopTransportLoading(self)
    end,

    ---@param self AirTransport
    DestroyedOnTransport = function(self)
        -- AirUnit.DestroyedOnTransport(self)
        BaseTransport.DestroyedOnTransport(self)
    end,

    ---@param self AirTransport
    ---@param ... any
    Kill = function(self, ...) -- Hook the engine 'Kill' command to flag cargo properly
         -- The arguments are (self, instigator, type, overkillRatio) but we can't just use normal arguments or AirUnit.Kill will complain if type is nil (which does happen)
        local instigator = arg[1]
        self:FlagCargo(not instigator or not IsUnit(instigator))
        AirUnit.Kill(self, unpack(arg))
    end,

    -- Override OnImpact to kill all cargo
    ---@param self AirTransport
    ---@param with AirTransport
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        self:KillCrashedCargo()
        AirUnit.OnImpact(self, with)
    end,

    ---@param self AirTransport
    ---@param loading boolean
    OnStorageChange = function(self, loading)
        AirUnit.OnStorageChange(self, loading)
        for k, v in self:GetCargo() do
            v:OnStorageChange(loading)
        end
    end,

    -- Flags cargo that it's been killed while in a transport
    ---@param self AirTransport
    ---@param suicide boolean
    FlagCargo = function(self, suicide)
        if self.Dead then return end -- Bail out early from overkill damage when already dead to avoid crashing

        if not suicide then -- If the transport is self destructed, let its contents be self destructed separately
            self:SaveCargoMass()
        end
        self.cargo = {}
        local cargo = self:GetCargo()
        for _, unit in cargo or {} do
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then -- Kill the contents of a transport in a transport, however that happened
                local unitCargo = unit:GetCargo()
                for k, subUnit in unitCargo do
                    subUnit:Kill()
                end
            end
            if not EntityCategoryContains(categories.COMMAND, unit) then
                unit.killedInTransport = true
                table.insert(self.cargo, unit)
            end
        end
    end,

    ---@param self BaseTransport
    KillCrashedCargo = function(self)
        if self:BeenDestroyed() then return end

        for _, unit in self.cargo or {} do
            if not unit:BeenDestroyed() then
                unit.DeathWeaponEnabled = false -- Units at this point have no weapons for some reason. Trying to fire one crashes the game.
                unit:OnKilled(nil, '', 0)
            end
        end
    end,
}

---@class LandUnit : MobileUnit
LandUnit = ClassUnit(MobileUnit) {}

--  CONSTRUCTION UNITS
---@class ConstructionUnit : MobileUnit
ConstructionUnit = ClassUnit(MobileUnit) {

    ---@param self ConstructionUnit
    OnCreate = function(self)
        MobileUnit.OnCreate(self)

        local bp = self.Blueprint

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = bp.General.BuildBones.BuildEffectBones
        
        if bp.General.BuildBones then
            self:SetupBuildBones()
        end

        if bp.Display.AnimationBuild then
            self.BuildingOpenAnim = bp.Display.AnimationBuild
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

    ---@param self ConstructionUnit
    OnPaused = function(self)
        -- When factory is paused take some action
        self:StopUnitAmbientSound('ConstructLoop')
        MobileUnit.OnPaused(self)
        if self.BuildingUnit then
            MobileUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self ConstructionUnit
    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound('ConstructLoop')
            MobileUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        MobileUnit.OnUnpaused(self)
    end,

    ---@param self ConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
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
        if unitBeingBuilt.UnitId == self.Blueprint.General.UpgradesTo and order == 'Upgrade' then
            self.Upgrading = true
            self.BuildingUnit = false
        end
    end,

    ---@param self ConstructionUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        MobileUnit.OnStopBuild(self, unitBeingBuilt)
        if self.Upgrading then
            NotifyUpgrade(self, unitBeingBuilt)
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

        self:SetImmobile(false)
    end,

    ---@param self ConstructionUnit
    OnFailedToBuild = function(self)
        MobileUnit.OnFailedToBuild(self)
        self:SetImmobile(false)
    end,

    ---@param self ConstructionUnit
    ---@param enable boolean
    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if enable then
                self.BuildArmManipulator:Enable()
            end
        end
    end,

    ---@param self ConstructionUnit
    OnPrepareArmToBuild = function(self)
        MobileUnit.OnPrepareArmToBuild(self)

        if self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(self.Blueprint.Display.AnimationBuildRate or 1)
            if self.BuildArmManipulator then
                self.StoppedBuilding = false
                self:ForkThread(self.WaitForBuildAnimation, true)
            end
        end

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if self:IsMoving() then
            local navigator = self:GetNavigator()
            navigator:AbortMove()
        end
    end,

    ---@param self ConstructionUnit
    OnStopBuilderTracking = function(self)
        MobileUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self.Blueprint.Display.AnimationBuildRate or 1))
        end
    end,
}

-- SEA UNITS
-- These units typically float on the water and have wake when they move
---@class SeaUnit : MobileUnit
SeaUnit = ClassUnit(MobileUnit){
    DeathThreadDestructionWaitTime = 0,
    ShowUnitDestructionDebris = false,
    PlayEndestructionEffects = false,
    CollidedBones = 0,

    ---@param self SeaUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        MobileUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

--- Base class for aircraft carriers.
---@class AircraftCarrier : SeaUnit, BaseTransport
AircraftCarrier = ClassUnit(SeaUnit, BaseTransport) {
    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        SeaUnit.OnTransportAttach(self, attachBone, unit)
        BaseTransport.OnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        SeaUnit.OnTransportDetach(self, attachBone, unit)
        BaseTransport.OnTransportDetach(self, attachBone, unit)
    end,

    OnAttachedKilled = function(self, attached)
        SeaUnit.OnAttachedKilled(self, attached)
        BaseTransport.OnAttachedKilled(self, attached)
    end,

    ---@param self AircraftCarrier
    OnStartTransportLoading = function(self)
        SeaUnit.OnStartTransportLoading(self)
        BaseTransport.OnStartTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    OnStopTransportLoading = function(self)
        SeaUnit.OnStopTransportLoading(self)
        BaseTransport.OnStopTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    DestroyedOnTransport = function(self)
        -- SeaUnit.DestroyedOnTransport(self)
        BaseTransport.DestroyedOnTransport(self)
    end,

    ---@param self AircraftCarrier
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SaveCargoMass()
        SeaUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}

-- HOVERING LAND UNITS
---@class HoverLandUnit : MobileUnit
HoverLandUnit = ClassUnit(MobileUnit) { }

---@class SlowHoverLandUnit : HoverLandUnit
SlowHoverLandUnit = ClassUnit(HoverLandUnit) {

    ---@param self SlowHoverLandUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        -- Slow these units down when they transition from land to water
        -- The mult is applied twice thanks to an engine bug, so careful when adjusting it
        -- Newspeed = oldspeed * mult * mult

        local mult = (self.Blueprint or self:GetBlueprint()).Physics.WaterSpeedMultiplier
        if new == 'Water' then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}

-- AMPHIBIOUS LAND UNITS
---@class AmphibiousLandUnit : MobileUnit
AmphibiousLandUnit = ClassUnit(MobileUnit) { }

---@class SlowAmphibiousLandUnit : AmphibiousLandUnit
SlowAmphibiousLandUnit = ClassUnit(AmphibiousLandUnit) {

    ---@param self SlowAmphibiousLandUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        local mult = (self.Blueprint or self:GetBlueprint()).Physics.WaterSpeedMultiplier
        if new == 'Seabed'  then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}

--- Base class for command units.
---@class CommandUnit : WalkingLandUnit
CommandUnit = ClassUnit(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    ---@param self CommandUnit
    ---@param rightGunName string
    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    ---@param self CommandUnit
    OnCreate = function(self)
        WalkingLandUnit.OnCreate(self)

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
    end,

    ---@param self CommandUnit
    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self:SetImmobile(false)
    end,

    ---@param self CommandUnit
    OnFailedToBuild = function(self)
        WalkingLandUnit.OnFailedToBuild(self)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnStopCapture = function(self, target)
        WalkingLandUnit.OnStopCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnFailedCapture = function(self, target)
        WalkingLandUnit.OnFailedCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnStopReclaim = function(self, target)
        WalkingLandUnit.OnStopReclaim(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    OnPrepareArmToBuild = function(self)
        WalkingLandUnit.OnPrepareArmToBuild(self)
        if self:BeenDestroyed() then return end

        self:BuildManipulatorSetEnabled(true)
        self.BuildArmManipulator:SetPrecedence(20)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, false)
        self.BuildArmManipulator:SetHeadingPitch(self:GetWeaponManipulatorByLabel(self.rightGunLabel):GetHeadingPitch())

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if self:IsMoving() then
            local navigator = self:GetNavigator()
            navigator:AbortMove()
        end
    end,

    ---@param self CommandUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
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
        if not self:GetGuardedUnit() and unitBeingBuilt:GetFractionComplete() == 0 and not self:CanBuild(unitBeingBuilt.Blueprint.BlueprintId) then
            IssueStop({self})
            IssueClearCommands({self})
            unitBeingBuilt:Destroy()
        end
    end,

    ---@param self CommandUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        WalkingLandUnit.OnStopBuild(self, unitBeingBuilt)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()

        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    ---@param self CommandUnit
    OnPaused = function(self)
        WalkingLandUnit.OnPaused(self)
        if self.BuildingUnit then
            WalkingLandUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self CommandUnit
    OnUnpaused = function(self)
        if self.BuildingUnit then
            WalkingLandUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        WalkingLandUnit.OnUnpaused(self)
    end,

    ---@param self CommandUnit
    ---@param auto boolean
    SetAutoOvercharge = function(self, auto)
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        if wep.NeedsUpgrade then return end

        wep:SetAutoOvercharge(auto)
        self.Sync.AutoOvercharge = auto
    end,

    ---@param self CommandUnit
    ---@param bones string
    PlayCommanderWarpInEffect = function(self, bones)
        self:HideBone(0, true)
        self:SetUnSelectable(true)
        self:SetBusy(true)
        self:ForkThread(self.WarpInEffectThread, bones)
    end,

    ---@param self CommandUnit
    ---@param bones Bone[]
    WarpInEffectThread = function(self, bones)
        self:PlayUnitSound('CommanderArrival')
        self:CreateProjectile('/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(2.1)

        local bp = self.Blueprint
        local psm = bp.Display.WarpInEffect.PhaseShieldMesh
        if psm then
            self:SetMesh(psm, true)
        end

        self:ShowBone(0, true)
        self:SetUnSelectable(false)
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        for _, v in bones or bp.Display.WarpInEffect.HideBones do
            self:HideBone(v, true)
        end

        local totalBones = self:GetBoneCount() - 1
        for k, v in EffectTemplate.UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(self, bone, self.Army, v)
            end
        end

        if psm then
            WaitSeconds(6)
            self:SetMesh(bp.Display.MeshBlueprint, true)
        end
    end,

    -------------------------------------------------------------------------------------------
    -- TELEPORTING WITH DELAY
    -------------------------------------------------------------------------------------------

    ---@param self CommandUnit
    ---@param work any
    ---@return boolean
    OnWorkBegin = function(self, work)
        if WalkingLandUnit.OnWorkBegin(self, work) then

            -- Prevent consumption bug where two enhancements in a row prevents assisting units from
            -- updating their consumption costs based on the new build rate values.
            self:UpdateAssistersConsumption()

            -- Inform EnhanceTask that enhancement is not restricted
            return true
        end
    end,
}

---@class ACUUnit : CommandUnit
ACUUnit = ClassUnit(CommandUnit) {
    -- The "commander under attack" warnings.
    ---@param self ACUUnit
    ---@param bpShield any
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

    ---@param self ACUUnit
    ---@param enh string
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)

        self:SendNotifyMessage('completed', enh)
        self:SetImmobile(false)
    end,

    ---@param self ACUUnit
    ---@param work string
    ---@return boolean
    OnWorkBegin = function(self, work)
        local legalWork = CommandUnit.OnWorkBegin(self, work)
        if not legalWork then return end

        self:SendNotifyMessage('started', work)

        -- No need to do it for AI
        self:SetImmobile(true)
        return true
    end,

    ---@param self ACUUnit
    ---@param work string
    OnWorkFail = function(self, work)
        self:SendNotifyMessage('cancelled', work)
        self:SetImmobile(false)

        CommandUnit.OnWorkFail(self, work)
    end,

    ---@param self ACUUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        self.WeaponEnabled = {}
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep.Blueprint.Overcharge.commandDamage
        end

        WalkingLandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = self:GetAIBrain()
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end

        if self:GetHealth() < ArmyBrains[self.Army]:GetUnitStat(self.UnitId, "lowest_health") then
            ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        end
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
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
            end

            -- prepare sync
            local sync = Sync
            local events = sync.Events or { }
            sync.Events = events
            local acuDestroyed = events.ACUDestroyed or { }
            events.ACUDestroyed = acuDestroyed

            -- sync the event
            table.insert(acuDestroyed, {
                Timestamp = GetGameTimeSeconds(),
                InstigatorArmy = instigator.Army,
                KilledArmy = self.Army
            })

        end
        ArmyBrains[self.Army].CommanderKilledBy = (instigator or self).Army
    end,

    ---@param self ACUUnit
    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)

        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)

        -- Ugly hack to re-initialise auto-OC once a task finishes
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        wep:SetAutoOvercharge(wep.AutoMode)
    end,

    ---@param self ACUUnit
    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
    end,

    ---@param self ACUUnit
    GiveInitialResources = function(self)
        WaitTicks(1)
        local bp = self.Blueprint
        local aiBrain = self:GetAIBrain()
        aiBrain:GiveResource('Energy', bp.Economy.StorageEnergy)
        aiBrain:GiveResource('Mass', bp.Economy.StorageMass)
    end,

    ---@param self ACUUnit
    BuildDisable = function(self)
        while self:IsUnitState('Building') or self:IsUnitState('Enhancing') or self:IsUnitState('Upgrading') or
                self:IsUnitState('Repairing') or self:IsUnitState('Reclaiming') do
            WaitSeconds(0.5)
        end

        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, true, true)
            end
        end
    end,

    -- Store weapon status on upgrade. Ignore default and OC, which are dealt with elsewhere
    ---@param self ACUUnit
    ---@param label string
    ---@param enable boolean
    ---@param lockOut boolean
    SetWeaponEnabledByLabel = function(self, label, enable, lockOut)
        CommandUnit.SetWeaponEnabledByLabel(self, label, enable)

        -- Unless lockOut specified, updates the 'Permanent record' of whether a weapon is enabled. With it specified,
        -- the changing of the weapon on/off state is more... temporary. For example, when building something.
        if label ~= self.rightGunLabel and label ~= 'OverCharge' and label ~= 'AutoOverCharge' and not lockOut then
            self.WeaponEnabled[label] = enable
        end
    end,

    ---@param self ACUUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
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
---@class ShieldHoverLandUnit : HoverLandUnit
ShieldHoverLandUnit = ClassUnit(HoverLandUnit) {}

-- SHIELD LAND UNITS
---@class ShieldLandUnit : LandUnit
ShieldLandUnit = ClassUnit(LandUnit) {}

-- SHIELD SEA UNITS
---@class ShieldSeaUnit : SeaUnit
ShieldSeaUnit = ClassUnit(SeaUnit) {}

---@class ExternalFactoryUnit : Unit
ExternalFactoryUnit = ClassUnit(Unit) {

    ---@param self ExternalFactoryUnit
    OnCreate = function(self)
        Unit.OnCreate(self)

        -- help us understand where this thing is
        self:ForkThread(function()
            while true do
                WaitTicks(1)
                DrawCircle(self:GetPosition(), 10, 'ffffff')
                end
            end
        )
    end,

    SetParent = function(self, parent)
        self.Parent = parent
    end,

    OnStartBuild = function(self, unitbuilding, order)
        Unit.OnStartBuild(self, unitbuilding, order)
        self.Parent:OnStartBuild(unitbuilding, order)
        self.UnitBeingBuilt = unitbuilding
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        Unit.OnStopBuild(self, unitBeingBuilt)
        self.Parent:OnStopBuild(unitBeingBuilt)
        self.UnitBeingBuilt = nil

        -- block building until our creator tells us to continue
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
    end,

    OnFailedToBuild = function(self)
        Unit.OnFailedToBuild(self)
        self.Parent:OnFailedToBuild()
        self.UnitBeingBuilt = nil

        -- block building until our creator tells us to continue
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
    end,

    CalculateRollOffPoint = function(self)
        return self.Parent:CalculateRollOffPoint()
    end,

    RolloffBody = function(self)
        self.Parent:RolloffBody()
    end,

    RollOffUnit = function(self)
        self.Parent:RollOffUnit()
    end,

    StartBuildFx = function(self, unitBeingBuilt)
        self.Parent:StartBuildFx(unitBeingBuilt)
    end,

    StopBuildFx = function(self)
        self.Parent:StopBuildFx()
    end,

    PlayFxRollOff = function(self)
        self.Parent:StopBuPlayFxRollOffildFx()
    end,

    PlayFxRollOffEnd = function(self)
        self.Parent:PlayFxRollOffEnd()
    end,

    IdleState = FactoryUnit.IdleState,
    BuildingState = FactoryUnit.BuildingState,
    RollingOffState = FactoryUnit.RollingOffState,
}
