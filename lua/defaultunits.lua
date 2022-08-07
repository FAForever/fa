-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Entity = import('/lua/sim/Entity.lua').Entity
local Unit = import('/lua/sim/Unit.lua').Unit
local explosion = import('defaultexplosions.lua')
local EffectUtil = import('EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')
local AdjacencyBuffs = import('/lua/sim/AdjacencyBuffs.lua')
local FireState = import('/lua/game.lua').FireState
local ScenarioFramework = import('/lua/ScenarioFramework.lua')

-- allows us to skip ai-specific functionality
local GameHasAIs = ScenarioInfo.GameHasAIs

-- compute once and store as upvalue for performance
local StructureUnitRotateTowardsEnemiesLand = categories.STRUCTURE + categories.LAND + categories.NAVAL
local StructureUnitRotateTowardsEnemiesArtillery = categories.ARTILLERY * (categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL)
local StructureUnitOnStartBeingBuiltRotateBuildings = categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * (categories.DEFENSE + categories.ARTILLERY)

-- STRUCTURE UNITS
---@class StructureUnit : Unit
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
        self:HideLandBones()
        self.AdjacentUnits = {}
        self.FxBlinkingLightsBag = {}
        if self.Layer == 'Land' and self.Blueprint.Physics.FlattenSkirt then
            self:FlattenSkirt()
        end
    end,

    --- Hides parts of a mesh that should be visible when the structure is made on water
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

        -- retrieve units of certain type
        local radius = 2 * (bp.AI.GuardScanRadius or 50)
        local cats = EntityCategoryContains(categories.ANTIAIR, self) and categories.AIR or (StructureUnitRotateTowardsEnemiesLand)
        local units = brain:GetUnitsAroundPoint(cats, pos, radius, 'Enemy')

        -- for each unit found
        local threats = { }
        for _, u in units do

            -- find its blip
            local blip = u:GetBlip(self.Army)
            if blip then

                -- check if we've got it on radar and whether it is identified by army in question
                local radar = blip:IsOnRadar(self.Army)
                local identified = blip:IsSeenEver(self.Army)
                if radar or identified then

                    -- if we've identified the blip then we can use the threat of the unit, otherwise default to 1.
                    local threat = (identified and u.Blueprint.Defense.SurfaceThreatLevel) or 1

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
        local rad = math.atan2(target.location[1] - pos[1], target.location[3] - pos[3])
        local degrees = rad * (180 / math.pi)

        -- some buildings can only take 90 degree angles
        if EntityCategoryContains(StructureUnitRotateTowardsEnemiesArtillery, self) then
            degrees = math.floor((degrees + 45) / 90) * 90
        end

        self:SetRotation(degrees)
    end,

    OnStartBeingBuilt = function(self, builder, layer)
        Unit.OnStartBeingBuilt(self, builder, layer)

        if EntityCategoryContains(StructureUnitOnStartBeingBuiltRotateBuildings, self) then
            self:RotateTowardsEnemy()
        end

        local bp = self.Blueprint
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

        -- tarmac is made once seraphim animation is complete
        if self.Blueprint.General.FactionName == "Seraphim" then
            self:CreateTarmac(true, true, true, false, false)
        end

        self:PlayActiveAnimation()

        -- remove land bones if the structure has them
        self:HideLandBones()
    end,

    OnFailedToBeBuilt = function(self)
        Unit.OnFailedToBeBuilt(self)
        self:DestroyTarmac()
    end,

    FlattenSkirt = function(self)
        local x, y, z = self:GetPositionXYZ()
        local x0, z0, x1, z1 = self:GetSkirtRect()
        x0, z0, x1, z1 = math.floor(x0), math.floor(z0), math.ceil(x1), math.ceil(z1)
        FlattenMapRect(x0, z0, x1 - x0, z1 - z0, y)
    end,

    CreateTarmac = function(self, albedo, normal, glow, orientation, specTarmac, lifeTime)
        if self.Layer ~= 'Land' then return end
        local tarmac
        local bp = self.Blueprint.Display.Tarmacs
        if not specTarmac then
            if bp and not table.empty(bp) then
                local num = Random(1, table.getn(bp))
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

        local x, y, z = self:GetPositionXYZ()

        -- I'm disabling this for now since there are so many things wrong with it
        local orient = orientation
        if not orientation then
            if tarmac.Orientations and not table.empty(tarmac.Orientations) then
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
        local factionTable = {e = 1, a = 2, r = 3, s = 4}
        local faction  = factionTable[string.sub(self.UnitId, 2, 2)]
        if albedo and tarmac.Albedo then
            local albedo2 = tarmac.Albedo2
            if albedo2 then
                albedo2 = albedo2 .. GetTarmac(faction, terrain)
            end

            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Albedo .. GetTarmac(faction, terrainName) , albedo2 or '', 'Albedo', w, l, fadeout, lifeTime or 0, self.Army, 0)
            table.insert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end

        if normal and tarmac.Normal then
            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Normal .. GetTarmac(faction, terrainName), '', 'Alpha Normals', w, l, fadeout, lifeTime or 0, self.Army, 0)

            table.insert(self.TarmacBag.Decals, tarmacHndl)
            if tarmac.RemoveWhenDead then
                self.Trash:Add(tarmacHndl)
            end
        end

        if glow and tarmac.Glow then
            local tarmacHndl = CreateDecal(self:GetPosition(), orient, tarmac.Glow .. GetTarmac(faction, terrainName), '', 'Glow', w, l, fadeout, lifeTime or 0, self.Army, 0)

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
        return not table.empty(self.TarmacBag.Decals)
    end,

    DestroyBlinkingLights = function(self)
        for _, v in self.FxBlinkingLightsBag do
            v:Destroy()
        end
        self.FxBlinkingLightsBag = {}
    end,

    CreateDestructionEffects = function(self, overkillRatio)
        if explosion.GetAverageBoundingXZRadius(self) < 1.0 then
            explosion.CreateScalableUnitExplosion(self)
        else
            explosion.CreateTimedStuctureUnitExplosion(self)
            WaitSeconds(0.5)
            explosion.CreateScalableUnitExplosion(self)
        end
    end,

    -- Modified to use same upgrade logic as the ui. This adds more upgrade options via General.UpgradesFromBase blueprint option
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
        end
     end,

    IdleState = State {
        Main = function(self)
        end,
    },

    UpgradingState = State {
        Main = function(self)
            self:DestroyTarmac()
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()

            local animation = self:GetUpgradeAnimation(self.UnitBeingBuilt)
            if animation then

                local unitBuilding = self.UnitBeingBuilt
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

    StopBeingBuiltEffects = function(self, builder, layer)
        local FactionName = self.Blueprint.General.FactionName
        if FactionName == 'UEF' and not self.BeingBuiltShowBoneTriggered then
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

    OnKilled = function(self, instigator, type, overkillRatio)
        local scus = EntityCategoryFilterDown(categories.SUBCOMMANDER, self:GetGuards())
        if scus[1] then
            for _, u in scus do
                u:SetFocusEntity(self)
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
        if self:IsBeingBuilt() then return end
        if adjacentUnit:IsBeingBuilt() then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = self.Blueprint.Adjacency
        if not adjBuffs then return end

        -- Apply each buff needed to you and/or adjacent unit
        for k, v in AdjacencyBuffs[adjBuffs] do
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

    -- When we're not adjacent, try to remove all the possible bonuses
    OnNotAdjacentTo = function(self, adjacentUnit)
        if not self.AdjacentUnits then
            WARN("Precondition Failed: No AdjacentUnits registered for entity: " .. repr(self.GetEntityId))
            return
        end

        local adjBuffs = self.Blueprint.Adjacency

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
                table.remove(self.AdjacentUnits, k)
                adjacentUnit:RequestRefreshUI()
            end
        end
        self:RequestRefreshUI()
    end,

    -- Add/Remove Adjacency Functionality
    -- Applies all appropriate buffs to all adjacent units
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
            amount = wep.Blueprint.Overcharge.structureDamage
        end
        Unit.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,


    -- Deprecated functionality

    ChangeBlinkingLights = function(self)
        if not DeprecatedWarnings.ChangeBlinkingLights then 
            DeprecatedWarnings.ChangeBlinkingLights = true 
            WARN("ChangeBlinkingLights is deprecated.")
            WARN("Source: " .. repr(debug.getinfo(2)))
            WARN("Stacktrace:" .. repr(debug.traceback()))
        end
    end,

    CreateBlinkingLights = function(self)
        if not DeprecatedWarnings.CreateBlinkingLights then 
            DeprecatedWarnings.CreateBlinkingLights = true 
            WARN("CreateBlinkingLights is deprecated.")
            WARN("Source: " .. repr(debug.getinfo(2)))
            WARN("Stacktrace:" .. repr(debug.traceback()))
        end
    end,

    OnMassStorageStateChange = function(self, state)
        if not DeprecatedWarnings.OnMassStorageStateChange then 
            DeprecatedWarnings.OnMassStorageStateChange = true 
            WARN("OnMassStorageStateChange is deprecated.")
            WARN("Source: " .. repr(debug.getinfo(2)))
            WARN("Stacktrace:" .. repr(debug.traceback()))
        end
    end,

    OnEnergyStorageStateChange = function(self, state)
        if not DeprecatedWarnings.OnEnergyStorageStateChange then 
            DeprecatedWarnings.OnEnergyStorageStateChange = true 
            WARN("OnEnergyStorageStateChange is deprecated.")
            WARN("Source: " .. repr(debug.getinfo(2)))
            WARN("Stacktrace:" .. repr(debug.traceback()))
        end
    end,
}

-- FACTORY UNITS
---@class FactoryUnit : StructureUnit
FactoryUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- if we're a support factory, make sure our build restrictions are correct
        if self.Cache.HashedCats["SUPPORTFACTORY"] then 
            self:UpdateBuildRestrictions()
        end
        
        -- if we're an HQ, enable all the additional logic
        if self.Cache.HashedCats["RESEARCH"] then

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
                    local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnStopBeingBuilt"
            )

            -- is called when:
            --  - unit is killed
            self:AddUnitCallback(
                function(self) 
                    local brain = ArmyBrains[self.Army]

                    -- update internal state
                    brain:RemoveHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnKilled"
            )

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
                    local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnGiven"
            )

            -- is called when:
            --  - unit is reclaimed
            self:AddUnitCallback(
                function(self) 
                    local brain = ArmyBrains[self.Army]

                    -- update internal state
                    brain:RemoveHQ(self.factionCategory, self.layerCategory, self.techCategory)
                    brain:SetHQSupportFactoryRestrictions(self.factionCategory, self.layerCategory)

                    -- update all units affected by this
                    local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
                    for id, unit in affected do
                        unit:UpdateBuildRestrictions()
                    end
                end, "OnReclaimed"
            )
        end

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        self.BuildingUnit = false
        self:SetFireState(FireState.GROUND_FIRE)
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
        if self:IsUnitState('Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            StructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        elseif unitBeingBuilt.Blueprint.CategoriesHash.RESEARCH then
            -- Removes assist command to prevent accidental cancellation when right-clicking on other factory
            self:RemoveCommandCap('RULEUCC_Guard')
            self.DisabledAssist = true
        end
        self.FactoryBuildFailed = false
    end,

    --- Introduce a rolloff delay, where defined.
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
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self.Blueprint
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
        local bp = self.Blueprint.Physics.RollOffPoints
        local px, py, pz = unpack(self:GetPosition())

        if not bp then return 0, px, py, pz end

        local vectorObj = self:GetRallyPoint()

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
        local unitBP = self.UnitBeingBuilt.Blueprint.Display.ForcedBuildSpin
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
            local bp = self.Blueprint.Display
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
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
            self:DestroyBuildRotator()
        end,
    },

    BuildingState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bp = self.Blueprint
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

-- AIR FACTORY UNITS
---@class AirFactoryUnit : FactoryUnit
AirFactoryUnit = Class(FactoryUnit) {}

-- AIR STAGING PLATFORMS UNITS
---@class AirStagingPlatformUnit : StructureUnit
AirStagingPlatformUnit = Class(StructureUnit) { }

-- ENERGY CREATION UNITS
---@class ConcreteStructureUnit : StructureUnit
ConcreteStructureUnit = Class(StructureUnit) {
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:Destroy()
    end
}

-- ENERGY CREATION UNITS
---@class EnergyCreationUnit : StructureUnit
EnergyCreationUnit = Class(StructureUnit) { }

-- ENERGY STORAGE UNITS
---@class EnergyStorageUnit : StructureUnit
EnergyStorageUnit = Class(StructureUnit) { }

-- LAND FACTORY UNITS
---@class LandFactoryUnit : FactoryUnit
LandFactoryUnit = Class(FactoryUnit) {}

-- MASS COLLECTION UNITS
---@class MassCollectionUnit : StructureUnit
MassCollectionUnit = Class(StructureUnit) {

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
        if self:IsBeingBuilt() then return end
        if adjacentUnit:IsBeingBuilt() then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = self.Blueprint.Adjacency
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
        table.insert(self.AdjacentUnits, adjacentUnit)

        self:RequestRefreshUI()
        adjacentUnit:RequestRefreshUI()
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
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
            self:SetProductionPerSecondMass((self.Blueprint.Economy.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
        end
    end,

    -- Band-aid on lack of multiple separate resource requests per unit...
    -- If mass econ is depleted, take all the mass generated and use it for the upgrade
    -- Old WatchUpgradeConsumption replaced with this on, enabling mex to not use resources when paused
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
---@class MassFabricationUnit : StructureUnit
MassFabricationUnit = Class(StructureUnit) {

    ---@param self MassFabricationUnit
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
    OnScriptBitClear = function (self, bit)
        if bit == 4 then 
            -- make brain track us to enable / disable accordingly
            self.Brain:AddDisabledEnergyExcessUnit(self)
        else 
            StructureUnit.OnScriptBitClear(self, bit)
        end
    end,

    ---@param self MassFabricationUnit
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)

        -- make brain track us to enable / disable accordingly
        self.Brain:AddEnabledEnergyExcessUnit(self)
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

    OnAdjacentTo = function(self, adjacentUnit, triggerUnit) -- What is triggerUnit?
        if self:IsBeingBuilt() then return end
        if adjacentUnit:IsBeingBuilt() then return end

        -- Does the unit have any adjacency buffs to use?
        local adjBuffs = self.Blueprint.Adjacency
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
        table.insert(self.AdjacentUnits, adjacentUnit)

        self:RequestRefreshUI()
        adjacentUnit:RequestRefreshUI()
    end,

    OnProductionPaused = function(self)
        StructureUnit.OnProductionPaused(self)
        self:StopUnitAmbientSound('ActiveLoop')
    end,

    OnProductionUnpaused = function(self)
        StructureUnit.OnProductionUnpaused(self)
        self:PlayUnitAmbientSound('ActiveLoop')
    end,

    OnExcessEnergy = function(self)
        self:OnProductionUnpaused()
    end,

    OnNoExcessEnergy = function(self)
        self:OnProductionPaused()
    end,

}

-- MASS STORAGE UNITS
---@class MassStorageUnit : StructureUnit
MassStorageUnit = Class(StructureUnit) { }

-- RADAR UNITS
---@class RadarUnit : StructureUnit
RadarUnit = Class(StructureUnit) {

    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,

    OnIntelDisabled = function(self)
        StructureUnit.OnIntelDisabled(self)
        self:DestroyIdleEffects()
    end,

    OnIntelEnabled = function(self)
        StructureUnit.OnIntelEnabled(self)
        self:CreateIdleEffects()
    end,
}

-- RADAR JAMMER UNITS
---@class RadarJammerUnit : StructureUnit
RadarJammerUnit = Class(StructureUnit) {

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
---@class SonarUnit : StructureUnit
SonarUnit = Class(StructureUnit) {

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

    DestroyIdleEffects = function(self)
        StructureUnit.DestroyIdleEffects(self)
        if self.TimedSonarEffectsThread then
            self.TimedSonarEffectsThread:Destroy()
        end
    end,
}

-- SEA FACTORY UNITS
---@class SeaFactoryUnit : FactoryUnit
SeaFactoryUnit = Class(FactoryUnit) {
    DestroyUnitBeingBuilt = function(self)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() < 1 then
            self.UnitBeingBuilt:Destroy()
        end
    end,

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
ShieldStructureUnit = Class(StructureUnit) { }

-- TRANSPORT BEACON UNITS
---@class TransportBeaconUnit : StructureUnit
TransportBeaconUnit = Class(StructureUnit) {

    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    -- Invincibility!  (the only way to kill a transport beacon is
    -- to kill the transport unit generating it)
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
    end,
}

-- WALL STRCUTURE UNITS
---@class WallStructureUnit : StructureUnit
WallStructureUnit = Class(StructureUnit) { }

-- QUANTUM GATE UNITS
---@class QuantumGateUnit : FactoryUnit
QuantumGateUnit = Class(FactoryUnit) { }

-- MOBILE UNITS
---@class MobileUnit : Unit
MobileUnit = Class(Unit) {

    -- Added for engymod. When created, units must re-check their build restrictions
    OnCreate = function(self)
        Unit.OnCreate(self)
        self:SetFireState(FireState.GROUND_FIRE)
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
        if self.factionCategory == 'UEF' then
            EffectUtil.CreateUEFUnitBeingBuiltEffects(self, builder, self.OnBeingBuiltEffectsBag)
        end
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
            self:SetImmobile(false)
        end
    end,

    OnDetachedFromTransport = function(self, transport, bone)
        Unit.OnDetachedFromTransport(self, transport, bone)

         -- Set unit immobile to prevent it to accelerating in the air, cleared in OnLayerChange
        self:SetImmobile(true)
        self.transportDrop = true
    end,
}

-- WALKING LAND UNITS
---@class WalkingLandUnit : MobileUnit
WalkingLandUnit = Class(MobileUnit) {
    WalkingAnim = nil,
    WalkingAnimRate = 1,
    IdleAnim = false,
    IdleAnimRate = 1,
    DeathAnim = false,
    DisabledBones = {},

    OnCreate = function(self, spec)
        MobileUnit.OnCreate(self, spec)

        local blueprint = self.Blueprint
        self.AnimationWalk = blueprint.Display.AnimationWalk
        self.AnimationWalkRate = blueprint.Display.AnimationWalkRate
    end,

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
SubUnit = Class(MobileUnit) {
    -- Use default spark effect until underwater damaged states are made
    FxDamage1 = { EffectTemplate.DamageSparks01 },
    FxDamage2 = { EffectTemplate.DamageSparks01 },
    FxDamage3 = { EffectTemplate.DamageSparks01 },

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,

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

    OnStartRefueling = function(self)
        self:PlayUnitSound('Refueling')
    end,

    OnRunOutOfFuel = function(self)
        self.HasFuel = false
        self:DestroyTopSpeedEffects()

        -- Penalize movement for running out of fuel
        self:SetSpeedMult(0.35) -- Change the speed of the unit by this mult
        self:SetAccMult(0.25) -- Change the acceleration of the unit by this mult
        self:SetTurnMult(0.25) -- Change the turn ability of the unit by this mult
    end,

    OnGotFuel = function(self)
        self.HasFuel = true
        -- Revert these values to the blueprint values
        self:SetSpeedMult(1)
        self:SetAccMult(1)
        self:SetTurnMult(1)
    end,

    -- Planes need to crash. Called by engine or by ShieldCollider projectile on collision with ground or water
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
        local size = self.Size
        explosion.CreateDefaultHitExplosion(self, scale)

        if self.ShowUnitDestructionDebris then
            explosion.CreateDebrisProjectiles(self, scale, {size.SizeX, size.SizeY, size.SizeZ})
        end
    end,

    --- Called when the unit is killed, but before it falls out of the sky and blows up.
    OnKilled = function(self, instigator, type, overkillRatio)
        -- A completed, flying plane expects an OnImpact event due to air crash.
        -- An incomplete unit in the factory still reports as being in layer "Air", so needs this
        -- stupid check.

        -- Additional stupidity: An idle transport, bot loaded and unloaded, counts as 'Land' layer so it would die with the wreck hovering.
        -- It also wouldn't call this code, and hence the cargo destruction. Awful!
        if self:GetFractionComplete() == 1 and (self.Layer == 'Air' or EntityCategoryContains(categories.TRANSPORTATION, self)) then
            self.CreateUnitAirDestructionEffects(self, 1.0)
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

            if self.totalDamageTaken > 0 and not self.veterancyDispersed then
                self:VeterancyDispersal(not instigator or not IsUnit(instigator))
            end
        else
            MobileUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,


    --- Called when a unit collides with a projectile to check if the collision is valid, allows
    -- ASF to be destroyed when they impact with strategic missiles
    -- @param self The unit we're checking the collision for
    -- @param other The projectile we're checking the collision with
    -- @param firingWeapon The weapon that the projectile originates from
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
---@class BaseTransport : AirUnit
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
        for k, v in self:GetCargo() do
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

-- LAND UNITS
---@class LandUnit : MobileUnit
LandUnit = Class(MobileUnit) {}

--  CONSTRUCTION UNITS
---@class ConstructionUnit : MobileUnit
ConstructionUnit = Class(MobileUnit) {
    OnCreate = function(self)
        MobileUnit.OnCreate(self)

        local bp = self.Blueprint

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
            self.BuildingOpenAnimManip:PlayAnim(self.BuildingOpenAnim, false):SetRate(0)
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
        if unitBeingBuilt.UnitId == self.Blueprint.General.UpgradesTo and order == 'Upgrade' then
            self.Upgrading = true
            self.BuildingUnit = false
        end
    end,

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

    OnFailedToBuild = function(self)
        MobileUnit.OnFailedToBuild(self)
        self:SetImmobile(false)
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
            self:SetImmobile(true)
            self:ForkThread(function() WaitTicks(1) if not self:BeenDestroyed() then self:SetImmobile(false) end end)
        end
    end,

    OnStopBuilderTracking = function(self)
        MobileUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self.Blueprint.Display.AnimationBuildRate or 1))
            self:SetImmobile(false)
        end
    end,
}

-- SEA UNITS
-- These units typically float on the water and have wake when they move
---@class SeaUnit : MobileUnit
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
---@class AircraftCarrier : SeaUnit
AircraftCarrier = Class(SeaUnit, BaseTransport) {
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SaveCargoMass()
        SeaUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}

-- HOVERING LAND UNITS
---@class HoverLandUnit : MobileUnit
HoverLandUnit = Class(MobileUnit) { }

---@class SlowHoverLandUnit : HoverLandUnit
SlowHoverLandUnit = Class(HoverLandUnit) {
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
AmphibiousLandUnit = Class(MobileUnit) { }

---@class SlowAmphibiousLandUnit : AmphibiousLandUnit
SlowAmphibiousLandUnit = Class(AmphibiousLandUnit) {
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
CommandUnit = Class(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    OnCreate = function(self)
        WalkingLandUnit.OnCreate(self)

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
    end,

    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self:SetImmobile(false)
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

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if self:IsMoving() then
            self:SetImmobile(true)
            self:ForkThread(function() WaitTicks(1) if not self:BeenDestroyed() then self:SetImmobile(false) end end)
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
        if not self:GetGuardedUnit() and unitBeingBuilt:GetFractionComplete() == 0 and not self:CanBuild(unitBeingBuilt.Blueprint.BlueprintId) then
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
    end,

    SetAutoOvercharge = function(self, auto)
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        if wep.NeedsUpgrade then return end

        wep:SetAutoOvercharge(auto)
        self.Sync.AutoOvercharge = auto
    end,

    PlayCommanderWarpInEffect = function(self, bones)
        self:HideBone(0, true)
        self:SetUnSelectable(true)
        self:SetBusy(true)
        self:ForkThread(self.WarpInEffectThread, bones)
    end,

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
    InitiateTeleportThread = function(self, teleporter, location, orientation)
        self.UnitBeingTeleported = self
        self:SetImmobile(true)
        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        local bp = self.Blueprint
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
        self:SetWorkProgress(0.0)
        Warp(self, location, orientation)
        self:PlayTeleportInEffects()
        self:CleanupRemainingTeleportChargeEffects()

        WaitSeconds(0.1) -- Perform cooldown Teleportation FX here

        -- Landing Sound
        self:StopUnitAmbientSound('TeleportLoop')
        self:PlayUnitSound('TeleportEnd')
        self:SetImmobile(false)
        self.UnitBeingTeleported = nil
        self.TeleportThread = nil
    end,

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

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)

        self:SendNotifyMessage('completed', enh)
        self:SetImmobile(false)
    end,

    OnWorkBegin = function(self, work)
        local legalWork = CommandUnit.OnWorkBegin(self, work)
        if not legalWork then return end

        self:SendNotifyMessage('started', work)

        -- No need to do it for AI
        if self:GetAIBrain().BrainType == 'Human' then
            self:SetImmobile(true)
        end

        return true
    end,

    OnWorkFail = function(self, work)
        self:SendNotifyMessage('cancelled', work)
        self:SetImmobile(false)

        CommandUnit.OnWorkFail(self, work)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        self.WeaponEnabled = {}
    end,

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
        local bp = self.Blueprint
        local aiBrain = self:GetAIBrain()
        aiBrain:GiveResource('Energy', bp.Economy.StorageEnergy)
        aiBrain:GiveResource('Mass', bp.Economy.StorageMass)
    end,

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
---@class ShieldHoverLandUnit : HoverLandUnit
ShieldHoverLandUnit = Class(HoverLandUnit) {}

-- SHIELD LAND UNITS
---@class ShieldLandUnit : LandUnit
ShieldLandUnit = Class(LandUnit) {}

-- SHIELD SEA UNITS
---@class ShieldSeaUnit : SeaUnit
ShieldSeaUnit = Class(SeaUnit) {}
