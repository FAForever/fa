
local Unit = import("/lua/sim/unit.lua").Unit
local explosion = import("/lua/defaultexplosions.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")
local TerrainUtils = import("/lua/sim/terrainutils.lua")
local Buff = import("/lua/sim/buff.lua")
local AdjacencyBuffs = import("/lua/sim/adjacencybuffs.lua")
local Quaternion = import("/lua/shared/quaternions.lua").Quaternion

local FactionToTarmacIndex = {
    UEF = 1,
    AEON = 2,
    CYBRAN = 3,
    SERAPHIM = 4,
    NOMADS = 5,
}

-- upvalue for performance
local Rect = Rect
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local FlattenMapRect = FlattenMapRect
local GetTerrainHeight = GetTerrainHeight
local GetReclaimablesInRect = GetReclaimablesInRect
local EntityCategoryContains = EntityCategoryContains
local CreateLightParticleIntel = CreateLightParticleIntel

local MathClamp = math.clamp
local MathMax = math.max
local MathFloor = math.floor
local MathCeil = math.ceil

local GetTarmac = import("/lua/tarmacs.lua").GetTarmacType

---@class StructureTarmacBag
---@field Decals TrashBag
---@field Orientation number
---@field CurrentBP UnitBlueprintTarmac
---@field Lifetime number
---@field OwnedByEntity EntityId

-- compute once and store as upvalue for performance
local StructureUnitRotateTowardsEnemiesLand = categories.STRUCTURE + categories.LAND + categories.NAVAL
local StructureUnitRotateTowardsEnemiesArtillery = categories.ARTILLERY * (categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL)
local StructureUnitOnStartBeingBuiltRotateBuildings = categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * (categories.DEFENSE + (categories.ARTILLERY - (categories.TECH3 + categories.EXPERIMENTAL)))

---@class StructureUnit : Unit
---@field AdjacentUnits? Unit[]
---@field TarmacBag StructureTarmacBag
---@field TerrainSlope table            # exists for backwards compatibility
---@field FxBlinkingLightsBag table     # exists for backwards compatibility
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
            degrees = MathFloor((degrees + 90) / 180) * 180
        end

        local rotator = CreateRotator(self, 0, 'y', degrees, nil, nil)
        rotator:SetPrecedence(1)
        self.Trash:Add(rotator)
    end,

    ---@param self StructureUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStartBeingBuilt = function(self, builder, layer)
        Unit.OnStartBeingBuilt(self, builder, layer)

        -- rotate weaponry towards enemy
        if EntityCategoryContains(StructureUnitOnStartBeingBuiltRotateBuildings, self) then
            self:RotateTowardsEnemy()
        end

        -- procedure to remove props that do not obstruct the building
        local blueprint = self.Blueprint
        if 
            -- do not apply for naval factories
            layer == 'Land' and

            -- do not apply to upgrades
            blueprint.General.UpgradesFrom != builder.Blueprint.BlueprintId
        then
            local CreateLightParticleIntel = CreateLightParticleIntel

            local army = self.Army
            local position = self:GetPosition()
            local blueprintPhysics = blueprint.Physics

            -- matches what we do for build effects
            local radius = MathMax(
                blueprintPhysics.MeshExtentsX or blueprint.SizeX or 0,
                blueprintPhysics.MeshExtentsY or blueprint.SizeY or 0,
                blueprintPhysics.MeshExtentsZ or blueprint.SizeZ or 0
            )

            -- create a flash when the structure starts
            CreateLightParticleIntel( self, -1, army, 2 * radius, 22, 'glow_03', 'ramp_antimatter_02' )

            -- includes units, need to filter those out
            local entities = GetReclaimablesInRect(Rect(
                position[1] - radius, position[3] - radius, position[1] + radius, position[3] + radius
            ))

            if entities then
                for k, prop in entities do
                    -- take out props that may linger around when building starts
                    if  prop.IsProp and
                        (not prop.Blueprint.CategoriesHash['OBSTRUCTSBUILDING'])  and
                        (not prop.Blueprint.CategoriesHash['INVULNERABLE'])
                    then
                        local center = prop:GetPosition()
                        local dx = position[1] - center[1]
                        local dz = position[3] - center[3]
                        local d = dx * dx + dz * dz
                        if d < radius * radius then
                            CreateLightParticleIntel(prop, -1, army, 2, 6, 'glow_02', 'ramp_flare_02')
                            prop:Destroy()
                        end
                    end
                end
            end
        end
    end,

    ---@param self StructureUnit
    ---@param builder Unit
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
        local size = ScenarioInfo.size
        local sx = size[1] - 1
        local sz = size[2] - 1

        -- floor and clamp them
        x0 = MathClamp(MathFloor(x0), 0, sx)
        z0 = MathClamp(MathFloor(z0), 0, sz)

        -- ceil and clamp them
        x1 = MathClamp(MathCeil(x1), 0, sx)
        z1 = MathClamp(MathCeil(z1), 0, sz)

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
        local size = ScenarioInfo.size
        local sx = size[1] - 1
        local sz = size[2] - 1

        -- floor and clamp them
        x0 = MathClamp(MathFloor(x0), 0, sx)
        z0 = MathClamp(MathFloor(z0), 0, sz)

        -- ceil and clamp them
        x1 = MathClamp(MathCeil(x1), 0, sx)
        z1 = MathClamp(MathCeil(z1), 0, sz)

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
                        IssueToUnitClearCommands(guard)
                        IssueGuard({guard}, self)
                    end
                end
            end
        end
    end,

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

    ---------------------------------------------------------------------------
    --#region Adjacency feature

    -- Called by the engine when a structure is finished building for each adjacent unit
    ---@param self StructureUnit
    ---@param adjacentUnit StructureUnit
    ---@param triggerUnit StructureUnit
    OnAdjacentTo = function(self, adjacentUnit, triggerUnit)

        -- make sure we're both finished building
        if self:IsBeingBuilt() or adjacentUnit:IsBeingBuilt() then
            return
        end

        -- keep track of who is adjacent to who
        self.AdjacentUnits = self.AdjacentUnits or { }
        adjacentUnit.AdjacentUnits = adjacentUnit.AdjacentUnits or { }

        self.AdjacentUnits[adjacentUnit.EntityId] = adjacentUnit
        adjacentUnit.AdjacentUnits[self.EntityId] = self

        -- make sure we have adjacency buffs to apply
        local adjBuffs = self.Blueprint.Adjacency
        if not adjBuffs then
            return
        end

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

        -- keep track of who is adjacent to who
        self.AdjacentUnits[adjacentUnit.EntityId] = nil
        adjacentUnit.AdjacentUnits[self.EntityId] = nil

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

    --#endregion

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

    ---------------------------------------------------------------------------
    --#region Deprecated functionality

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

    ---@param self StructureUnit
    DestroyBlinkingLights = function(self)
        for _, v in self.FxBlinkingLightsBag do
            v:Destroy()
        end
        self.FxBlinkingLightsBag = { }
    end,

    --#endregion

}