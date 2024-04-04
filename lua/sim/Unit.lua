-----------------------------------------------------------------
-- File      : /lua/unit.lua
-- Authors   : John Comes, David Tomandl, Gordon Duclos
-- Summary   : The Unit lua module
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Imports. Localise commonly used subfunctions for speed
local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtilities = import("/lua/effectutilities.lua")
local EnhancementCommon = import("/lua/enhancementcommon.lua")
local Explosion = import("/lua/defaultexplosions.lua")
local Game = import("/lua/game.lua")
local SimUtils = import("/lua/simutils.lua")
local utilities = import("/lua/utilities.lua")
local Wreckage = import("/lua/wreckage.lua")

local AntiArtilleryShield = import("/lua/shield.lua").AntiArtilleryShield
local PersonalBubble = import("/lua/shield.lua").PersonalBubble
local PersonalShield = import("/lua/shield.lua").PersonalShield
local Shield = import("/lua/shield.lua").Shield
local TransportShield = import("/lua/shield.lua").TransportShield
local Weapon = import("/lua/sim/weapon.lua").Weapon
local IntelComponent = import('/lua/defaultcomponents.lua').IntelComponent
local VeterancyComponent = import('/lua/defaultcomponents.lua').VeterancyComponent

local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy
local TrashEmpty = TrashBag.Empty

local armies = ListArmies()
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterAtBone = CreateEmitterAtBone
local IsAlly = IsAlly
local rawget = rawget

local UpdateAssistersConsumptionCats = categories.REPAIR - categories.INSIGNIFICANTUNIT     -- anything that repairs but insignificant things, such as drones

local DefaultTerrainType = GetTerrainType(-1, -1)

local GetNearestPlayablePoint = import("/lua/scenarioframework.lua").GetNearestPlayablePoint



--- Structures that are reused for performance reasons
--- Maps unit.techCategory to a number so we can do math on it for naval units


SyncMeta = {
    __index = function(t, key)
        local id = rawget(t, 'id')
        return UnitData[id].Data[key]
    end,

    __newindex = function(t, key, val)
         -- globals to locals
        local rawget = rawget
        local UnitData = UnitData

        local id = rawget(t, 'id')
        local army = rawget(t, 'army')
        local unitData = UnitData[id]
        if not unitData then
            unitData = {
                OwnerArmy = army,
                Data = {},
            }
            UnitData[id] = unitData
        end
        unitData.Data[key] = val

        local focus = GetFocusArmy()
        if army == focus or focus == -1 then -- Let observers get unit data
            local SyncUnitData = Sync.UnitData
            unitData = SyncUnitData[id]
            if not unitData then
                unitData = {}
                SyncUnitData[id] = unitData
            end
            unitData[key] = val
        end
    end,
}

---@class UnitCommand
---@field x number
---@field y number
---@field z number
---@field targetId? EntityId
---@field target? Entity
---@field commandType string 

---@class AIUnitProperties
---@field AIPlatoonReference AIPlatoon
---@field AIBaseManager LocationType
---@field ForkedEngineerTask? thread    # used by the engineer manager
---@field DesiresAssist? boolean         # used by the engineer manager
---@field NumAssistees? number           # used by the engineer manager
---@field MinNumAssistees? number
---@field BuilderManagerData? { EngineerManager: AIEngineerManager, LocationType: LocationType }
---@field UnitBeingAssist? Unit
---@field UnitBeingBuilt? Unit
---@field UnitBeingBuiltBehavior? thread
---@field Combat? boolean

local cUnit = moho.unit_methods
local cUnitGetBuildRate = cUnit.GetBuildRate

---@class Unit : moho.unit_methods, InternalObject, IntelComponent, VeterancyComponent, AIUnitProperties
---@field AIManagerIdentifier? string
---@field Repairers table<EntityId, Unit>
---@field Brain AIBrain
---@field buildBots? Unit[]
---@field Blueprint UnitBlueprint
---@field UnitName string
---@field BuildEffectsBag TrashBag
---@field BuildArmManipulator? moho.BuilderArmManipulator
---@field Trash TrashBag
---@field Layer Layer
---@field Army Army
---@field Dead? boolean
---@field UnitId UnitId
---@field EntityId EntityId
---@field EventCallbacks table<string, function[]>
---@field Buffs {Affects: table<BuffEffectName, BlueprintBuff.Effect>, buffTable: table<string, table>}
---@field EngineFlags? table<string, any>
---@field TerrainType TerrainType
---@field EngineCommandCap? table<string, boolean>
---@field UnitBeingBuilt Unit?
---@field UnitBuildOrder string
---@field MyShield Shield?
---@field EntityBeingReclaimed Unit | Prop | nil
---@field SoundEntity? Unit | Entity
---@field AutoModeEnabled? boolean
---@field OnBeingBuiltEffectsBag TrashBag
---@field IdleEffectsBag TrashBag
---@field SiloWeapon? Weapon
---@field SiloProjectile? ProjectileBlueprint
---@field ReclaimTimeMultiplier? number
---@field CaptureTimeMultiplier? number
---@field BaseName string
---@field CDRData table
---@field PlatoonData table
Unit = ClassUnit(moho.unit_methods, IntelComponent, VeterancyComponent) {

    IsUnit = true,
    Weapons = {},

    -- FX Damage tables. A random damage effect table of emitters is chosen out of this table
    FxDamage1 = {EffectTemplate.DamageSmoke01, EffectTemplate.DamageSparks01},
    FxDamage2 = {EffectTemplate.DamageFireSmoke01, EffectTemplate.DamageSparks01},
    FxDamage3 = {EffectTemplate.DamageFire01, EffectTemplate.DamageSparks01},

    -- Disables all collisions. This will be true for all units being constructed as upgrades
    DisallowCollisions = false,

    -- Destruction parameters
    PlayDestructionEffects = true,
    PlayEndAnimDestructionEffects = true,
    ShowUnitDestructionDebris = true,
    DestructionExplosionWaitDelayMin = 0,
    DestructionExplosionWaitDelayMax = 0.5,
    DeathThreadDestructionWaitTime = 0.1,
    DestructionPartsHighToss = {},
    DestructionPartsLowToss = {},
    DestructionPartsChassisToss = {},

    DisableIntelOfCargo = false,

    -- kept for backwards compatibility, these default to true
    CanTakeDamage = true,
    CanBeKilled = true,

    EnergyModifier = 0,
    MassModifier = 0,



    ---@param self Unit
    ---@return any
    GetSync = function(self)
        if not Sync.UnitData[self.EntityId] then
            Sync.UnitData[self.EntityId] = {}
        end
        return Sync.UnitData[self.EntityId]
    end,

    -- The original builder of this unit, set by OnStartBeingBuilt. Used for calculating differential
    -- upgrade costs, and tracking the original owner of a unit (for tracking gifting and so on)
    originalBuilder = nil,

    -------------------------------------------------------------------------------------------
    ---- INITIALIZATION
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    OnPreCreate = function(self)
        -- Each unit has a sync table to replicate values to the global sync table to be copied to the user layer at sync time.
        self.Sync = {}
        self.Sync.id = self:GetEntityId()
        self.Sync.army = self:GetArmy()
        setmetatable(self.Sync, SyncMeta)

        self.Trash = self.Trash or TrashBag()

        self.EventCallbacks = {
            -- OnKilled = {}, -- done
            -- OnUnitBuilt = {}, -- done
            -- OnStartBuild = {}, -- done
            -- OnReclaimed = {}, -- done
            -- OnStartReclaim = {}, -- done
            -- OnStopReclaim = {}, -- done
            -- OnStopBeingBuilt = {},
            -- OnCaptured = {},
            -- OnCapturedNewUnit = {},
            -- OnDamaged = {},
            -- OnStartCapture = {}, -- done
            -- OnStopCapture = {}, -- done
            -- OnFailedCapture = {}, -- done
            -- OnStartBeingCaptured = {}, -- done
            -- OnStopBeingCaptured = {},
            -- OnFailedBeingCaptured = {},
            -- OnFailedToBuild = {},
            -- OnVeteran = {},
            -- OnGiven = {},
            -- ProjectileDamaged = {},
            -- SpecialToggleEnableFunction = false,
            -- SpecialToggleDisableFunction = false,
            -- OnAttachedToTransport = {}, -- Returns self, transport, bone
            -- OnDetachedFromTransport = {}, -- Returns self, transport, bone

            -- OnTransportAttach = {}
            -- OnTransportDetach = {}
            -- OnTransportAborted = {}
            -- OnTransportOrdered = {}
            -- OnAttachedKilled = {}
            -- OnStartTransportLoading = {}
            -- OnStopTransportLoading = {}
        }
    end,

    ---@param self Unit
    OnCreate = function(self)
        local bp = self:GetBlueprint()

        -- cache often accessed values into inner table
        self.Blueprint = bp

        -- cache engine calls
        self.EntityId = self:GetEntityId()
        self.Army = self:GetArmy()
        self.UnitId = self:GetUnitId()
        self.Brain = self:GetAIBrain()

        -- used for rebuilding mechanic
        self.Repairers = {}

        -- used by almost all unit types
        self.OnBeingBuiltEffectsBag = TrashBag()
        self.IdleEffectsBag = TrashBag()

        -- Store weapon information for performance
        self.WeaponCount = self:GetWeaponCount() or 0
        self.WeaponInstances = { }
        for k = 1, self.WeaponCount do 
            local weapon = self:GetWeapon(k)
            self.WeaponInstances[weapon.Label] = weapon
            self.WeaponInstances[k] = weapon
        end

        -- Define Economic modifications
        local bpEcon = bp.Economy
        self:SetConsumptionPerSecondEnergy(bpEcon.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetConsumptionPerSecondMass(bpEcon.MaintenanceConsumptionPerSecondMass or 0)
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        self:SetProductionActive(true)

        self.Buffs = {
            BuffTable = {},
            Affects = {},
        }
        
        self:ShowPresetEnhancementBones()

        local bpDeathAnim = bp.Display.AnimationDeath
        if bpDeathAnim and not table.empty(bpDeathAnim) then
            self.PlayDeathAnimation = true
        end

        if self.Brain.CheatEnabled then
            import("/lua/ai/aiutilities.lua").ApplyCheatBuffs(self)
        end

        -- for syncing data to UI
        self:UpdateStat("HitpointsRegeneration", bp.Defense.RegenRate)
        self:UpdateStat("HitpointsRegeneration", bp.Defense.RegenRate)

        -- add support for keeping track of reclaim statistics
        if self.Blueprint.General.CommandCapsHash['RULEUCC_Reclaim'] then
            self.ReclaimedMass = 0
            self.ReclaimedEnergy = 0
            self:UpdateStat("ReclaimedMass", 0)
            self:UpdateStat("ReclaimedEnergy", 0)
        end

        -- add support for automated jamming reset
        if self.Blueprint.Intel.JammerBlips > 0 then
            self.Brain:TrackJammer(self)
            self.ResetJammer = -1
        end

        -- default to ground fire for structures, experimentals and (S)ACUs
        if EntityCategoryContains(categories.STRUCTURE + categories.EXPERIMENTAL + categories.COMMAND, self) then
            self:SetFireState(2)
        end

        -- Flags for scripts
        self.IsCivilian = armies[self.Army] == "NEUTRAL_CIVILIAN" or nil

        VeterancyComponent.OnCreate(self)
    end,

    -------------------------------------------------------------------------------------------
    ---- MISC FUNCTIONS
    -------------------------------------------------------------------------------------------
    -- Returns 4 numbers: skirt x0, skirt z0, skirt.x1, skirt.z1
    ---@param self Unit
    ---@return number x0
    ---@return number z0
    ---@return number x1
    ---@return number z1
    GetSkirtRect = function(self)
        local blueprint = self.Blueprint
        local physics = blueprint.Physics
        local footprint = blueprint.Footprint
        local x, _, z = self:GetPositionXYZ()
        local fx = x - footprint.SizeX * .5
        local fz = z - footprint.SizeZ * .5
        local sx = fx + physics.SkirtOffsetX
        local sz = fz + physics.SkirtOffsetZ

        return sx, sz, sx + blueprint.Physics.SkirtSizeX, sz + blueprint.Physics.SkirtSizeZ
    end,

    ---@param self Unit
    ---@param scalar number
    ---@return number X
    ---@return number Y
    ---@return number Z
    GetRandomOffset = function(self, scalar)
        local bp = self.Blueprint
        local sx, sy, sz = bp.SizeX, bp.SizeY, bp.SizeZ
        local heading = self:GetHeading()

        sx = sx * scalar
        sy = sy * scalar
        sz = sz * scalar

        local rx = Random() * sx - (sx * 0.5)
        local y  = Random() * sy + (bp.CollisionOffsetY or 0)
        local rz = Random() * sz - (sz * 0.5)

        local cosh = math.cos(heading)
        local sinh = math.sin(heading)

        local x = cosh * rx - sinh * rz
        local z = sinh * rx + cosh * rz

        return x, y, z
    end,

    ---@param self Unit
    ---@param fn function
    ---@param ... any
    ---@return thread | nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    ---@param self Unit
    ---@param priTable? UnparsedCategory[] | EntityCategory[]
    SetTargetPriorities = function(self, priTable)
        for i = 1, self.WeaponCount do
            self.WeaponInstances[i]:SetWeaponPriorities(priTable)
        end
    end,

    ---@param self Unit
    ---@param priTable? UnparsedCategory[] | EntityCategory[]
    SetLandTargetPriorities = function(self, priTable)
        for i = 1, self.WeaponCount do
            local wep = self.WeaponInstances[i]
            for onLayer, targetLayers in wep:GetBlueprint().FireTargetLayerCapsTable do
                if string.find(targetLayers, 'Land') then
                    wep:SetWeaponPriorities(priTable)
                    break
                end
            end
        end
    end,

    -- Updates build restrictions of any unit passed, used for support factories
    ---@param self Unit
    UpdateBuildRestrictions = function(self)

        -- retrieve info of factory
        local faction = self.Blueprint.FactionCategory
        local layer = self.Blueprint.LayerCategory
        local aiBrain = self:GetAIBrain()

        -- the pessimists we are, remove all the units!
        self:AddBuildRestriction((categories.TECH3 + categories.TECH2) * categories.MOBILE)

        -- if there is a specific T3 HQ - allow all t2 / t3 units of this type
        if aiBrain:CountHQs(faction, layer, "TECH3") > 0 then 
            self:RemoveBuildRestriction((categories.TECH3 + categories.TECH2) * categories.MOBILE)

        -- if there is some T3 HQ - allow t2 / t3 engineers
        elseif aiBrain:CountHQsAllLayers(faction, "TECH3") > 0 then 
            self:RemoveBuildRestriction((categories.TECH3 + categories.TECH2) * categories.MOBILE * categories.CONSTRUCTION)
        end 

        -- if there is a specific T2 HQ - allow all t2 units of this type
        if aiBrain:CountHQs(faction, layer, "TECH2") > 0 then 
            self:RemoveBuildRestriction(categories.TECH2 * categories.MOBILE)

        -- if there is some T2 HQ - allow t2 engineers
        elseif aiBrain:CountHQsAllLayers(faction, "TECH2") > 0 then 
            self:RemoveBuildRestriction(categories.TECH2 * categories.MOBILE * categories.CONSTRUCTION)
        end
    end,

    -------------------------------------------------------------------------------------------
    ---- TOGGLES
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 0 then -- Shield toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:EnableShield()
        elseif bit == 1 then -- Weapon toggle
            -- Amended in individual unit's script file
        elseif bit == 2 then -- Jamming toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit2', 'Jammer')
        elseif bit == 3 then -- Intel toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit3', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit3', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit3', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit3', 'SonarStealthField')
            self:DisableUnitIntel('ToggleBit3', 'Sonar')
            self:DisableUnitIntel('ToggleBit3', 'Omni')
            self:DisableUnitIntel('ToggleBit3', 'Cloak')
            self:DisableUnitIntel('ToggleBit3', 'CloakField') -- We really shouldn't use this. Cloak/Stealth fields are pretty busted
            self:DisableUnitIntel('ToggleBit3', 'Spoof')
            self:DisableUnitIntel('ToggleBit3', 'Jammer')
            self:DisableUnitIntel('ToggleBit3', 'Radar')
        elseif bit == 4 then -- Production toggle
            self:OnProductionPaused()
        elseif bit == 5 then -- Stealth toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit5', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit5', 'SonarStealthField')
        elseif bit == 6 then -- Generic pause toggle
            self:SetPaused(true)
        elseif bit == 7 then -- Special toggle
            self:EnableSpecialToggle()
        elseif bit == 8 then -- Cloak toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit8', 'Cloak')
        end

        if not self.MaintenanceConsumption then
            self.ToggledOff = true
        end
    end,

    ---@param self Unit
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 0 then -- Shield toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:DisableShield()
        elseif bit == 1 then -- Weapon toggle
        elseif bit == 2 then -- Jamming toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit2', 'Jammer')
        elseif bit == 3 then -- Intel toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit3', 'Radar')
            self:EnableUnitIntel('ToggleBit3', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit3', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit3', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit3', 'SonarStealthField')
            self:EnableUnitIntel('ToggleBit3', 'Sonar')
            self:EnableUnitIntel('ToggleBit3', 'Omni')
            self:EnableUnitIntel('ToggleBit3', 'Cloak')
            self:EnableUnitIntel('ToggleBit3', 'CloakField') -- We really shouldn't use this. Cloak/Stealth fields are pretty busted
            self:EnableUnitIntel('ToggleBit3', 'Spoof')
            self:EnableUnitIntel('ToggleBit3', 'Jammer')
        elseif bit == 4 then -- Production toggle
            self:OnProductionUnpaused()
        elseif bit == 5 then -- Stealth toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit5', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit5', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit5', 'SonarStealthField')
        elseif bit == 6 then -- Generic pause toggle
            self:SetPaused(false)
        elseif bit == 7 then -- Special toggle
            self:DisableSpecialToggle()
        elseif bit == 8 then -- Cloak toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit8', 'Cloak')
        end

        if self.MaintenanceConsumption then
            self.ToggledOff = false
        end
    end,

    ---@param self Unit
    OnPaused = function(self)

        if self:IsUnitState('Building') or self:IsUnitState('Upgrading') or self:IsUnitState('Repairing') then
            self:SetActiveConsumptionInactive()
            self:StopUnitAmbientSound('ConstructLoop')
        end

        -- When paused we reclaim at a speed of 0, with thanks to:
        -- - https://github.com/FAForever/FA-Binary-Patches/pull/19
        if self.EntityBeingReclaimed and (not IsDestroyed(self.EntityBeingReclaimed)) and IsProp(self.EntityBeingReclaimed) then
            self:StopReclaimEffects(self.EntityBeingReclaimed)
            self:StopUnitAmbientSound('ReclaimLoop')
            self:PlayUnitSound('StopReclaim')
        end

        -- for AI events
        self.Brain:OnUnitPaused(self)
    end,

    ---@param self Unit
    OnUnpaused = function(self)
        if self:IsUnitState('Building') or self:IsUnitState('Upgrading') or self:IsUnitState('Repairing') then
            self:SetActiveConsumptionActive()
            self:PlayUnitAmbientSound('ConstructLoop')
        end

        -- When paused we reclaim at a speed of 0, with thanks to:
        -- - https://github.com/FAForever/FA-Binary-Patches/pull/19
        if self.EntityBeingReclaimed and (not IsDestroyed(self.EntityBeingReclaimed)) and IsProp(self.EntityBeingReclaimed) then
            self:StartReclaimEffects(self.EntityBeingReclaimed)
            self:PlayUnitSound('StartReclaim')
            self:PlayUnitAmbientSound('ReclaimLoop')
        end

        -- for AI events
        self.Brain:OnUnitUnpaused(self)
    end,

    ---@param self Unit
    EnableSpecialToggle = function(self)
        if self.EventCallbacks.SpecialToggleEnableFunction then
            self.EventCallbacks.SpecialToggleEnableFunction(self)
        end
    end,

    ---@param self Unit
    DisableSpecialToggle = function(self)
        if self.EventCallbacks.SpecialToggleDisableFunction then
            self.EventCallbacks.SpecialToggleDisableFunction(self)
        end
    end,

    ---@param self Unit
    ---@param fn function
    AddSpecialToggleEnable = function(self, fn)
        if fn then
            self.EventCallbacks.SpecialToggleEnableFunction = fn
        end
    end,

    ---@param self Unit
    ---@param fn function
    AddSpecialToggleDisable = function(self, fn)
        if fn then
            self.EventCallbacks.SpecialToggleDisableFunction = fn
        end
    end,

    ---@param self Unit
    EnableDefaultToggleCaps = function(self)
        if self.ToggleCaps then
            for _, v in self.ToggleCaps do
                self:AddToggleCap(v)
            end
        end
    end,

    ---@param self Unit
    DisableDefaultToggleCaps = function(self)
        self.ToggleCaps = {}
        local capsCheckTable = {'RULEUTC_WeaponToggle', 'RULEUTC_ProductionToggle', 'RULEUTC_GenericToggle', 'RULEUTC_SpecialToggle'}
        for _, v in capsCheckTable do
            if self:TestToggleCaps(v) == true then
                table.insert(self.ToggleCaps, v)
            end
            self:RemoveToggleCap(v)
        end
    end,

    -------------------------------------------------------------------------------------------
    ---- MISC EVENTS
    -------------------------------------------------------------------------------------------

    ---@param self Unit
    ---@param target Unit
    OnStartCapture = function(self, target)
        self:DoUnitCallbacks('OnStartCapture', target)
        self:StartCaptureEffects(target)
        self:PlayUnitSound('StartCapture')
        self:PlayUnitAmbientSound('CaptureLoop')

        -- for AI events
        self.Brain:OnUnitStartCapture(self, target)
    end,

    ---@param self Unit
    ---@param target Unit
    OnStopCapture = function(self, target)
        self:DoUnitCallbacks('OnStopCapture', target)
        self:StopCaptureEffects(target)
        self:PlayUnitSound('StopCapture')
        self:StopUnitAmbientSound('CaptureLoop')

        -- for AI events
        self.Brain:OnUnitStopCapture(self, target)
    end,

    ---@param self Unit
    ---@param target Unit
    StartCaptureEffects = function(self, target)
        self.CaptureEffectsBag = self.CaptureEffectsBag or TrashBag()
        self.CaptureEffectsBag:Add(self:ForkThread(self.CreateCaptureEffects, target))
    end,

    ---@param self Unit
    ---@param target Unit
    CreateCaptureEffects = function(self, target)
        EffectUtilities.PlayCaptureEffects(self, target, self.BuildEffectBones or {0, }, self.CaptureEffectsBag)
    end,

    ---@param self Unit
    ---@param target Unit
    StopCaptureEffects = function(self, target)
        if self.CaptureEffectsBag then
            self.CaptureEffectsBag:Destroy()
        end
    end,

    ---@param self Unit
    ---@param target  Unit
    OnFailedCapture = function(self, target)
        self:DoUnitCallbacks('OnFailedCapture', target)
        self:StopCaptureEffects(target)
        self:StopUnitAmbientSound('CaptureLoop')
        self:PlayUnitSound('FailedCapture')

        -- for AI events
        self.Brain:OnUnitFailedCapture(self, target)
    end,

    ---@param self Unit
    ---@param captor Unit
    CheckCaptor = function(self, captor)
        if captor.Dead or captor:GetFocusUnit() ~= self then
            self:RemoveCaptor(captor)
        else
            local progress = captor:GetWorkProgress()
            if not self.CaptureProgress or progress > self.CaptureProgress then
                self.CaptureProgress = progress
            elseif progress < self.CaptureProgress then
                captor:SetWorkProgress(self.CaptureProgress)
            end
        end
    end,

    ---@param self Unit
    ---@param captor Unit
    AddCaptor = function(self, captor)
        if not self.Captors then
            self.Captors = {}
        end

        self.Captors[captor.EntityId] = captor

        if not self.CaptureThread then
            self.CaptureThread = self:ForkThread(function()
                local captors = self.Captors or {}
                while not table.empty(captors) do
                    for _, c in captors do
                        self:CheckCaptor(c)
                    end

                    WaitTicks(1)
                    captors = self.Captors or {}
                end
            end)
        end
    end,

    ---@param self Unit
    ResetCaptors = function(self)
        if self.CaptureThread then
            KillThread(self.CaptureThread)
        end
        self.Captors = {}
        self.CaptureThread = nil
        self.CaptureProgress = nil
    end,

    ---@param self Unit
    ---@param captor Unit
    RemoveCaptor = function(self, captor)
        self.Captors[captor.EntityId] = nil

        if table.empty(self.Captors) then
            self:ResetCaptors()
        end
    end,

    ---@param self Unit
    ---@param captor Unit
    OnStartBeingCaptured = function(self, captor)
        self:AddCaptor(captor)
        self:DoUnitCallbacks('OnStartBeingCaptured', captor)
        self:PlayUnitSound('StartBeingCaptured')

        -- for AI events
        self.Brain:OnUnitStartBeingCaptured(self, captor)
    end,

    ---@param self Unit
    ---@param captor Unit
    OnStopBeingCaptured = function(self, captor)
        self:RemoveCaptor(captor)
        self:DoUnitCallbacks('OnStopBeingCaptured', captor)
        self:PlayUnitSound('StopBeingCaptured')

        -- for AI events
        self.Brain:OnUnitStopBeingCaptured(self, captor)
    end,

    ---@param self Unit
    ---@param captor Unit
    OnFailedBeingCaptured = function(self, captor)
        self:RemoveCaptor(captor)
        self:DoUnitCallbacks('OnFailedBeingCaptured', captor)
        self:PlayUnitSound('FailedBeingCaptured')

        -- for AI events
        self.Brain:OnUnitFailedBeingCaptured(self, captor)
    end,

    ---@param self Unit
    ---@param reclaimer Unit
    OnReclaimed = function(self, reclaimer)
        self:DoUnitCallbacks('OnReclaimed', reclaimer)
        self.CreateReclaimEndEffects(reclaimer, self)
        self:Destroy()

        -- for AI events
        self.Brain:OnUnitReclaimed(self, reclaimer)
    end,

    ---@param self Unit
    ---@param unit Unit
    OnStartRepair = function(self, unit)
        unit.Repairers[self.EntityId] = self

        if unit.WorkItem ~= self.WorkItem then
            self:InheritWork(unit)
        end

        self:SetUnitState('Repairing', true)

        -- Force assist over repair when unit is assisting something
        if unit:GetFocusUnit() and unit:IsUnitState('Building') then
            self:ForkThread(function()
                self:CheckAssistFocus()
            end)
        end

        -- for AI events
        self.Brain:OnUnitStartRepair(self, unit)
    end,

    ---@param self Unit
    ---@param unit Unit
    OnStopRepair = function(self, unit)
        unit.Repairers[self.EntityId] = nil

        -- for AI events
        self.Brain:OnUnitStopRepair(self, unit)
    end,

    ---@param self Unit
    ---@param target Unit | Prop
    OnStartReclaim = function(self, target)
        -- When paused we reclaim at a speed of 0, with thanks to:
        -- - https://github.com/FAForever/FA-Binary-Patches/pull/19
        if not self:IsPaused() then
            self:StartReclaimEffects(target)
            self:PlayUnitSound('StartReclaim')
            self:PlayUnitAmbientSound('ReclaimLoop')
        end

        self.EntityBeingReclaimed = target
        self:SetUnitState('Reclaiming', true)
        self:SetFocusEntity(target)
        self:CheckAssistersFocus()
        self:DoUnitCallbacks('OnStartReclaim', target)

        -- Force me to move on to the guard properly when done
        local guard = self:GetGuardedUnit()
        if guard then
            IssueToUnitClearCommands(self)
            IssueReclaim({self}, target)
            IssueGuard({self}, guard)
        end

        -- add state to be able to show the amount reclaimed in the UI
        if target.IsProp then
            self.OnStartReclaimPropStartTick = GetGameTick() + 2

            local time, energy, mass = target:GetReclaimCosts(self)
            self.OnStartReclaimPropTicksRequired = 10 * time
            self.OnStartReclaimPropMass = mass
            self.OnStartReclaimPropEnergy = energy
        end

        -- awareness of event for AI
        self.Brain:OnUnitStartReclaim(self, target)
    end,

    --- Called when the unit stops reclaiming
    ---@param self Unit
    ---@param target Unit | Prop | nil      # is nil when the prop or unit is completely reclaimed
    OnStopReclaim = function(self, target)
        self:DoUnitCallbacks('OnStopReclaim', target)
        self:StopReclaimEffects(target)
        self:StopUnitAmbientSound('ReclaimLoop')
        self:PlayUnitSound('StopReclaim')
        self:SetUnitState('Reclaiming', false)
        self.EntityBeingReclaimed = nil

        if target.IsProp then
            target:UpdateReclaimLeft()
        end

        -- process the amount we reclaimed to show it in the UI
        if self.OnStartReclaimPropStartTick then
            local ticks = (GetGameTick() - self.OnStartReclaimPropStartTick)

            -- can end up negative if another engineer finishes reclaiming the prop between us starting to reclaim, and actually reclaiming
            if ticks > 0 then
                -- completely consumed this prop
                if ticks >= self.OnStartReclaimPropTicksRequired then
                    self.ReclaimedMass = self.ReclaimedMass + self.OnStartReclaimPropMass
                    self.ReclaimedEnergy = self.ReclaimedEnergy + self.OnStartReclaimPropEnergy
                    
                -- partially consumed the prop
                else
                    local fraction = ticks / self.OnStartReclaimPropTicksRequired
                    self.ReclaimedMass = self.ReclaimedMass + fraction * self.OnStartReclaimPropMass
                    self.ReclaimedEnergy = self.ReclaimedEnergy + fraction * self.OnStartReclaimPropEnergy
                end
            end

            -- update UI
            self:UpdateStat('ReclaimedMass', self.ReclaimedMass)
            self:UpdateStat('ReclaimedEnergy', self.ReclaimedEnergy)
        end

        -- reset reclaiming state
        self.OnStartReclaimPropStartTick = nil
        self.OnStartReclaimPropTicksRequired = nil
        self.OnStartReclaimPropMass = nil
        self.OnStartReclaimPropEnergy = nil

        -- awareness of event for AI
        self.Brain:OnUnitStopReclaim(self, target)
    end,

    ---@param self Unit
    ---@param target Unit | Prop
    StartReclaimEffects = function(self, target)
        self.ReclaimEffectsBag = self.ReclaimEffectsBag or TrashBag()
        self.ReclaimEffectsBag:Add(self:ForkThread(self.CreateReclaimEffects, target))
    end,

    ---@param self Unit
    ---@param target Unit | Prop
    CreateReclaimEffects = function(self, target)
        EffectUtilities.PlayReclaimEffects(self, target, self.BuildEffectBones or {0, }, self.ReclaimEffectsBag)
    end,

    ---@param self Unit
    ---@param target Unit | Prop
    CreateReclaimEndEffects = function(self, target)
        EffectUtilities.PlayReclaimEndEffects(self, target)
    end,

    ---@param self Unit
    ---@param target Unit | Prop
    StopReclaimEffects = function(self, target)
        if self.ReclaimEffectsBag then
            self.ReclaimEffectsBag:Destroy()
        end
    end,

    ---@param self Unit
    OnDecayed = function(self)
        self:Destroy()
    end,

    ---@param self Unit
    ---@param captor Unit
    OnCaptured = function(self, captor)
        if self and not self.Dead and captor and not captor.Dead and self:GetAIBrain() ~= captor:GetAIBrain() then
            if not self:IsCapturable() then
                self:Kill()
                return
            end

            -- Kill non-capturable things which are in a transport
            if EntityCategoryContains(categories.TRANSPORTATION, self) then
                local cargo = self:GetCargo()
                for _, v in cargo do
                    if not v.Dead and not v:IsCapturable() then
                        v:Kill()
                    end
                end
            end

            self:DoUnitCallbacks('OnCaptured', captor)
            local newUnitCallbacks = {}
            if self.EventCallbacks.OnCapturedNewUnit then
                newUnitCallbacks = self.EventCallbacks.OnCapturedNewUnit
            end

            local captorBrain = false

            -- Ignore army cap during unit transfer in Campaign
            if ScenarioInfo.CampaignMode then
                captorBrain = captor:GetAIBrain()
                SetIgnoreArmyUnitCap(captor.Army, true)
            end

            if ScenarioInfo.CampaignMode and not captorBrain.IgnoreArmyCaps then
                SetIgnoreArmyUnitCap(captor.Army, false)
            end

            -- Fix captured units not retaining their data
            self:ResetCaptors()
            local newUnits = SimUtils.TransferUnitsOwnership({self}, captor.Army, true) or {}

            -- The unit transfer function returns a table of units. Since we transferred 1 unit, the table contains 1 unit (The new unit).
            -- If table would have been nil (Set to {} above), was empty, or contains more than one, kill this sequence
            if table.empty(newUnits) or table.getn(newUnits) ~= 1 then
                return
            end

            local newUnit = newUnits[1]

            -- Because the old unit is lost we cannot call a member function for newUnit callbacks
            for _, cb in newUnitCallbacks do
                if cb then
                    cb(newUnit, captor)
                end
            end
        end
    end,

    ---@param self Unit
    ---@param newUnit Unit
    OnGiven = function(self, newUnit)
        newUnit:SendNotifyMessage('transferred')
        self:DoUnitCallbacks('OnGiven', newUnit)
    end,

    ---@param self Unit
    ---@param fn function
    AddOnGivenCallback = function(self, fn)
        self:AddUnitCallback(fn, 'OnGiven')
    end,

    -------------------------------------------------------------------------------------------
    -- ECONOMY
    -------------------------------------------------------------------------------------------

    -- We are splitting Consumption into two catagories:
    -- Maintenance -- for units that are usually "on": radar, mass extractors, etc.
    -- Active -- when upgrading, constructing, or something similar.
    --
    -- It will be possible for both or neither of these consumption methods to be
    -- in operation at the same time.  Here are the functions to turn them off and on.
    ---@param self Unit
    SetMaintenanceConsumptionActive = function(self)
        self.MaintenanceConsumption = true
        self:UpdateConsumptionValues()
    end,

    ---@param self Unit
    SetMaintenanceConsumptionInactive = function(self)
        self.MaintenanceConsumption = false
        self:UpdateConsumptionValues()
    end,

    ---@param self Unit
    SetActiveConsumptionActive = function(self)
        self.ActiveConsumption = true
        self:UpdateConsumptionValues()
    end,

    ---@param self Unit
    SetActiveConsumptionInactive = function(self)
        self.ActiveConsumption = false
        self:UpdateConsumptionValues()
    end,

    ---@param self Unit
    OnProductionPaused = function(self)
        self:SetMaintenanceConsumptionInactive()
        self:SetProductionActive(false)
    end,

    ---@param self Unit
    OnProductionUnpaused = function(self)
        self:SetMaintenanceConsumptionActive()
        self:SetProductionActive(true)
    end,

    ---@param self Unit
    ---@param time_mult number
    SetBuildTimeMultiplier = function(self, time_mult)
        self.BuildTimeMultiplier = time_mult
    end,

    ---@param self Unit
    ---@return integer
    GetMassBuildAdjMod = function(self)
        return self.MassBuildAdjMod or 1
    end,

    ---@param self Unit
    ---@return integer
    GetEnergyBuildAdjMod = function(self)
        return self.EnergyBuildAdjMod or 1
    end,

    ---@param self Unit
    GetEconomyBuildRate = function(self)
        return self:GetBuildRate()
    end,

    ---@param self Unit
    GetBuildRate = function(self)
        local buildrate = cUnitGetBuildRate(self)
        if buildrate < 0 then
            buildrate = 0.00001
        end

        return buildrate
    end,

    ---@param self Unit
    UpdateAssistersConsumption = function(self)
        local units = {}
        -- We need to check all the units assisting.
        for _, v in self:GetGuards() do
            if not v.Dead and (v:IsUnitState('Building') or v:IsUnitState('Repairing')) and not (EntityCategoryContains(categories.INSIGNIFICANTUNIT, v)) then
                table.insert(units, v)
            end
        end

        local workers = self:GetAIBrain():GetUnitsAroundPoint(UpdateAssistersConsumptionCats, self:GetPosition(), 50, 'Ally')
        for _, v in workers do
            if not v.Dead and v:IsUnitState('Repairing') and v:GetFocusUnit() == self then
                table.insert(units, v)
            end
        end

        for _, v in units do
            if not v.updatedConsumption then
                v.updatedConsumption = true -- Recursive protection
                v:UpdateConsumptionValues()
                v.updatedConsumption = false
            end
        end
    end,

    -- Called when we start building a unit, turn on/off, get/lose bonuses, or on
    -- any other change that might affect our build rate or resource use.
    ---@param self Unit
    UpdateConsumptionValues = function(self)
        local energy_rate = 0
        local mass_rate = 0

        if self.ActiveConsumption then
            local focus = self:GetFocusUnit()
            local time = 1
            local mass = 0
            local energy = 0
            local targetData
            local baseData
            local repairRatio = 0.75

            if focus then -- Always inherit work status of focus
                self:InheritWork(focus)
            end

            if self.WorkItem then -- Enhancement
                targetData = self.WorkItem
            elseif focus then -- Handling upgrades
                if self:IsUnitState('Upgrading') then
                    baseData = self.Blueprint.Economy -- Upgrading myself, subtract ev. baseCost
                elseif focus.originalBuilder and not focus.originalBuilder.Dead and focus.originalBuilder:IsUnitState('Upgrading') and focus.originalBuilder:GetFocusUnit() == focus then
                    baseData = focus.originalBuilder:GetBlueprint().Economy
                end

                if baseData then
                    targetData = focus:GetBlueprint().Economy
                end
            end

            if targetData then -- Upgrade/enhancement
                time, energy, mass = Game.GetConstructEconomyModel(self, targetData, baseData)
            elseif focus then -- Building/repairing something
                if focus:IsUnitState('SiloBuildingAmmo') then
                    local siloBuildRate = focus:GetBuildRate() or 1
                    time, energy, mass = focus:GetBuildCosts(focus.SiloProjectile)
                    energy = (energy / siloBuildRate) * (self:GetBuildRate() or 0)
                    mass = (mass / siloBuildRate) * (self:GetBuildRate() or 0)
                else
                    time, energy, mass = self:GetBuildCosts(focus:GetBlueprint())
                    if self:IsUnitState('Repairing') and focus.isFinishedUnit then
                        energy = energy * repairRatio
                        mass = mass * repairRatio
                    end
                end
            end

            energy = math.max(0, energy * (self.EnergyBuildAdjMod or 1))
            mass = math.max(0, mass * (self.MassBuildAdjMod or 1))
            energy_rate = energy / time
            mass_rate = mass / time
        end

        local myBlueprint = self.Blueprint
        if self.MaintenanceConsumption then
            local mai_energy = (self.EnergyMaintenanceConsumptionOverride or myBlueprint.Economy.MaintenanceConsumptionPerSecondEnergy)  or 0
            local mai_mass = myBlueprint.Economy.MaintenanceConsumptionPerSecondMass or 0

            -- Apply economic bonuses
            mai_energy = mai_energy * (100 + (self.EnergyModifier or 0)) * (self.EnergyMaintAdjMod or 1) * 0.01
            mai_mass = mai_mass * (100 + (self.MassModifier or 0)) * (self.MassMaintAdjMod or 1) * 0.01

            energy_rate = energy_rate + mai_energy
            mass_rate = mass_rate + mai_mass
        end

         -- Apply minimum rates
        energy_rate = math.max(energy_rate, myBlueprint.Economy.MinConsumptionPerSecondEnergy or 0)
        mass_rate = math.max(mass_rate, myBlueprint.Economy.MinConsumptionPerSecondMass or 0)

        self:SetConsumptionPerSecondEnergy(energy_rate)
        self:SetConsumptionPerSecondMass(mass_rate)
        self:SetConsumptionActive(energy_rate > 0 or mass_rate > 0)
    end,

    ---@param self Unit
    UpdateProductionValues = function(self)
        local bpEcon = self.Blueprint.Economy
        if not bpEcon then return end

        self:SetProductionPerSecondEnergy((bpEcon.ProductionPerSecondEnergy or 0) * (self.EnergyProdAdjMod or 1))
        self:SetProductionPerSecondMass((bpEcon.ProductionPerSecondMass or 0) * (self.MassProdAdjMod or 1))
    end,

    ---@param self Unit
    ---@param override number
    SetEnergyMaintenanceConsumptionOverride = function(self, override)
        self.EnergyMaintenanceConsumptionOverride = override or 0
    end,

    ---@param self Unit
    ---@param overRide number
    SetBuildRateOverride = function(self, overRide)
        self.BuildRateOverride = overRide
    end,

    ---@param self Unit
    ---@return number
    GetBuildRateOverride = function(self)
        return self.BuildRateOverride
    end,

    --- Adds up total build costs for the unit blueprint and active enhancements
    ---@param self Unit
    ---@return number mass
    ---@return number energy
    ---@return number time
    GetTotalResourceCosts = function(self)
        local bp = self.Blueprint
        local economy = bp.Economy
        local mass = economy.BuildCostMass or 0
        local energy = economy.BuildCostEnergy or 0
        local time = economy.BuildTime or 0
        local enhancements = bp.Enhancements
        if enhancements then
            local activeEnhancements = SimUnitEnhancements[self.EntityId]
            if activeEnhancements then
                -- add the costs of enhancements AND prerequisites
                for _, enhName in activeEnhancements do
                    repeat
                        local enh = enhancements[enhName]
                        mass = mass + (enh.BuildCostMass or 0)
                        energy = energy + (enh.BuildCostEnergy or 0)
                        time = time + (enh.BuildTime or 0)
                        enhName = enh.Prerequisite
                    until not enhName
                end

                -- subtract the costs of built-in enhancements
                local PresetEnhancements = bp.EnhancementPresetAssigned.Enhancements
                if PresetEnhancements then
                    for _, enhName in PresetEnhancements do
                        local enh = enhancements[enhName]
                        mass = mass - (enh.BuildCostMass or 0)
                        energy = energy - (enh.BuildCostEnergy or 0)
                        time = time - (enh.BuildTime or 0)
                    end
                end
            end
        end
        if time == 0 then
            time = 10
        end
        return mass, energy, time
    end;

    --- Adds up the total mass cost of this unit, including enhancements
    ---@param self Unit
    ---@return number
    GetTotalMassCost = function(self)
        return (self:GetTotalResourceCosts()) -- adjust to one return value
    end;

    --- Gets the change in progress a unit will have if it sacrifices into this one
    ---@overload fun(self: Unit, sacrificer: Unit): number
    --- Gets the change in progress a unit with `mass` and `energy` build costs will have, presuming
    --- a `SacrificeMassMult` and `SacrificeEnergyMult` of `1.0`. Premultiply the mass and energy values
    --- if this is not the case (as it usually is). 
    ---@param self Unit
    ---@param mass number
    ---@param energy number
    ---@return number
    CalculateSacrificeBonus = function(self, mass, energy)
        if type(mass) == "table" then
            local unit = mass
            local economy = unit.Blueprint.Economy
            mass, energy = unit:GetTotalResourceCosts()
            mass = mass * economy.SacrificeMassMult
            energy = energy * economy.SacrificeEnergyMult
        end
        local economy = self.Blueprint.Economy
        local buildMass = economy.BuildCostMass
        local buildEnergy = economy.BuildCostEnergy
        -- always comes within 5 ulps; probably what the underlying engine uses, with different rounding
        return math.min(mass / buildMass, energy / buildEnergy)
    end;

    -------------------------------------------------------------------------------------------
    -- DAMAGE
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)

        -- only applies to trees
        if damageType == "TreeForce" or damageType == "TreeFire" then 
            return 
        end

        if self.CanTakeDamage then
            self:DoOnDamagedCallbacks(instigator)

            -- Pass damage to an active personal shield, as personal shields no longer have collisions
            if self:GetShieldType() == 'Personal' and self:ShieldIsOn() and not self.MyShield.Charging then
                self.MyShield:ApplyDamage(instigator, amount, vector, damageType)
            else
                self:DoTakeDamage(instigator, amount, vector, damageType)
            end
        end
    end,

    ---@param self Unit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        VeterancyComponent.DoTakeDamage(self, instigator, amount, vector, damageType)

        local preAdjHealth = self:GetHealth()

        self:AdjustHealth(instigator, -amount)

        local health = self:GetHealth()
        if health < 1 then
            -- this if statement is an issue too
            if damageType == 'Reclaimed' then
                self:Destroy()
            else
                local excessDamageRatio = 0.0
                -- Calculate the excess damage amount
                local excess = preAdjHealth - amount
                local maxHealth = self:GetMaxHealth()
                if excess < 0 and maxHealth > 0 then
                    excessDamageRatio = -excess / maxHealth
                end

                if not EntityCategoryContains(categories.VOLATILE, self) then
                    self:SetReclaimable(false)
                end
                self:Kill(instigator, damageType, excessDamageRatio)
            end
        end
    end,

    --- Health values come in at fixed 25% intervals
    ---@param self Unit
    ---@param new number # 0.25 / 0.50 / 0.75 / 1.0
    ---@param old number # 0.25 / 0.50 / 0.75 / 1.0
    OnHealthChanged = function(self, new, old)
        self:ManageDamageEffects(new, old)

        -- inform the brain of the event
        self.Brain:OnUnitHealthChanged(self, new, old)
    end,

    ---@param self Unit
    ---@param newHealth number
    ---@param oldHealth number
    ManageDamageEffects = function(self, newHealth, oldHealth)

        if not self.DamageEffectsBag then
            self.DamageEffectsBag = {
                TrashBag(),
                TrashBag(),
                TrashBag(),
            }

            self.Trash:Add(self.DamageEffectsBag[1])
            self.Trash:Add(self.DamageEffectsBag[2])
            self.Trash:Add(self.DamageEffectsBag[3])
        end

        local damageEffectsBags = self.DamageEffectsBag
        if newHealth < oldHealth then
            local amount = self.Blueprint.SizeDamageEffects
            if oldHealth == 0.75 then
                for i = 1, amount do
                    self:PlayDamageEffect(self.FxDamage1, damageEffectsBags[1])
                end
            elseif oldHealth == 0.5 then
                for i = 1, amount do
                    self:PlayDamageEffect(self.FxDamage2, damageEffectsBags[2])
                end
            elseif oldHealth == 0.25 then
                for i = 1, amount do
                    self:PlayDamageEffect(self.FxDamage3, damageEffectsBags[3])
                end
            end
        else
            if newHealth <= 0.25 and newHealth > 0 then
                damageEffectsBags[3]:Destroy()
            elseif newHealth <= 0.5 and newHealth > 0.25 then
                damageEffectsBags[2]:Destroy()
            elseif newHealth <= 0.75 and newHealth > 0.5 then
                damageEffectsBags[1]:Destroy()
            elseif newHealth > 0.75 then
                self:DestroyAllDamageEffects()
            end
        end
    end,

    ---@param self Unit
    ---@param fxTable FileName[][]
    ---@param fxBag TrashBag
    PlayDamageEffect = function(self, fxTable, fxBag)
        -- cache for performance
        local TableGetn = table.getn
        local Random = Random
        local TableRandom = table.random

        -- retrieve an effect, which can be nil
        local effects = TableRandom(fxTable)
        if not effects then
            return
        end

        -- create the effects
        local blueprint = self.Blueprint
        local totalBones = self:GetBoneCount()
        local bone = Random(1, totalBones) - 1
        local bpDE = self.Blueprint.Display.DamageEffects
        for _, v in effects do
            local fx

            -- version where a unit has very few bones, and therefore we add a pre-defined offset
            if bpDE then
                local num = Random(1, TableGetn(bpDE))
                local bpFx = bpDE[num]
                fx = CreateAttachedEmitter(self, bpFx.Bone or 0, self.Army, v):ScaleEmitter(blueprint.SizeDamageEffectsScale):OffsetEmitter(bpFx.OffsetX or 0, bpFx.OffsetY or 0, bpFx.OffsetZ or 0)
            -- version where a unit has sufficient bones and we just use that
            else
                fx = CreateAttachedEmitter(self, bone, self.Army, v):ScaleEmitter(blueprint.SizeDamageEffectsScale)
            end

            fxBag:Add(fx)
        end
    end,

    ---@param self Unit
    DestroyAllDamageEffects = function(self)
        local damageEffectsBags = self.DamageEffectsBag
        if damageEffectsBags then
            damageEffectsBags[1]:Destroy()
            damageEffectsBags[2]:Destroy()
            damageEffectsBags[3]:Destroy()
        end
    end,

    -- On killed: this function plays when the unit takes a mortal hit. Plays death effects and spawns wreckage, dependant on overkill
    ---@param self Unit
    ---@param instigator Unit | Projectile
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)

        -- invulnerable little fella
        if not (self.CanBeKilled) then
            return
        end

        -- this flag is used to skip the need of `IsDestroyed`
        self.Dead = true

        local layer = self.Layer
        local bp = self.Blueprint
        local army = self.Army

        -- Units killed while being invisible because they're teleporting should show when they're killed
        if self.TeleportFx_IsInvisible then
            self:ShowBone(0, true)
            self:ShowEnhancementBones()
        end

        if layer == 'Water' and bp.Physics.MotionType == 'RULEUMT_Hover' then
            self:PlayUnitSound('HoverKilledOnWater')
        elseif layer == 'Land' and bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating' then
            -- Handle ships that can walk on land
            self:PlayUnitSound('AmphibiousFloatingKilledOnLand')
        else
            self:PlayUnitSound('Killed')
        end

        -- apply death animation on half built units (do not apply for ML and mega)
        local FractionThreshold = bp.General.FractionThreshold or 0.5
        if self.PlayDeathAnimation and self:GetFractionComplete() > FractionThreshold then
            self:ForkThread(self.PlayAnimationThread, 'AnimationDeath')
            self.DisallowCollisions = true
        end

        self:DoUnitCallbacks('OnKilled')
        if self.UnitBeingTeleported and not self.UnitBeingTeleported.Dead then
            self.UnitBeingTeleported:Destroy()
            self.UnitBeingTeleported = nil
        end

        if self.DeathWeaponEnabled ~= false then
            self:DoDeathWeapon()
        end

        -- veterancy computations should happen after triggering death weapons
        VeterancyComponent.VeterancyDispersal(self)

        self:DisableShield()
        self:DisableUnitIntel('Killed')
        self:ForkThread(self.DeathThread, overkillRatio , instigator)

        -- awareness for traitor game mode and game statistics
        ArmyBrains[army].LastUnitKilledBy = (instigator or self).Army
        ArmyBrains[army]:AddUnitStat(self.UnitId, "lost", 1)

        -- awareness of instigator that it killed a unit, but it can also be a projectile or nil
        if instigator and instigator.OnKilledUnit then
            instigator:OnKilledUnit(self)
        end

        self.Brain:OnUnitKilled(self, instigator, type, overkillRatio)
    end,

    ---@param self Unit
    ---@param unitKilled Unit
    ---@param experience number | nil
    OnKilledUnit = function (self, unitKilled, experience)
        ArmyBrains[self.Army]:AddUnitStat(unitKilled.UnitId, "kills", 1)
        
        if experience then
            VeterancyComponent.OnKilledUnit(self, unitKilled, experience)
        end
    end,

    ---@param self Unit
    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end

        local bp = self.Blueprint
        for _, v in bp.Weapon do
            if v.Label == 'DeathWeapon' then
                if v.FireOnDeath == true then
                    self:SetWeaponEnabledByLabel('DeathWeapon', true)
                    self.WeaponInstances['DeathWeapon']:Fire()
                else
                    self:ForkThread(self.DeathWeaponDamageThread, v.DamageRadius, v.Damage, v.DamageType, v.DamageFriendly)
                end
            end
        end
    end,

    --- Called when a unit collides with a projectile to check if the collision is valid
    ---@param self Unit The unit we're checking the collision for
    ---@param other Projectile The projectile we're checking the collision with
    ---@param firingWeapon Weapon The weapon that the projectile originates from
    ---@return boolean
    OnCollisionCheck = function(self, other, firingWeapon)
        -- bail out immediately
        if self.DisallowCollisions then
            return false
        end

        local selfArmy = self.Army
        local otherArmy = other.Army

        -- if we're allied, check if we allow allied collisions
        if selfArmy == otherArmy or IsAlly(selfArmy, otherArmy) then
            return other.CollideFriendly
        end

        return true
    end,

    --- Called when a unit collides with a collision beam to check if the collision is valid
    ---@param self Unit The unit we're checking the collision for
    ---@param firingWeapon Weapon The weapon the beam originates from that we're checking the collision with
    ---@return boolean
    OnCollisionCheckWeapon = function(self, firingWeapon)

       -- bail out immediately
        if self.DisallowCollisions then
            return false
        end

        local selfArmy = self.Army
        local otherArmy = firingWeapon.Army

        -- if we're allied, check if we allow allied collisions
        if selfArmy == otherArmy or IsAlly(selfArmy, otherArmy) then
            return firingWeapon.Blueprint.CollideFriendly
        end

        return true
    end,

    ---@param self Unit
    ---@param bp UnitBlueprintAnimationDeath[]
    ---@return UnitBlueprintAnimationDeath
    ChooseAnimBlock = function(self, bp)
        local totWeight = 0
        for _, v in bp do
            if v.Weight then
                totWeight = totWeight + v.Weight
            end
        end

        local val = 1
        local num = Random(0, totWeight)
        for _, v in bp do
            if v.Weight then
                val = val + v.Weight
            end
            if num < val then
                return v
            end
        end
    end,

    ---@param self Unit
    ---@param anim string
    ---@param rate number
    PlayAnimationThread = function(self, anim, rate)
        local bp = self.Blueprint.Display[anim]
        if bp then
            local animBlock = self:ChooseAnimBlock(bp)

            -- for determining wreckage offset after dying with an animation
            if anim == 'AnimationDeath' then
                self.DeathHitBox = animBlock.HitBox
            end

            if animBlock.Mesh then
                self:SetMesh(animBlock.Mesh)
            end
            if animBlock.Animation and (self:ShallSink() or not EntityCategoryContains(categories.NAVAL, self)) then
                local sinkAnim = CreateAnimator(self)
                self.DeathAnimManip = sinkAnim
                sinkAnim:PlayAnim(animBlock.Animation)
                rate = rate or 1
                if animBlock.AnimationRateMax and animBlock.AnimationRateMin then
                    rate = animBlock.AnimationRateMin + Random() * (animBlock.AnimationRateMax - animBlock.AnimationRateMin)
                end
                sinkAnim:SetRate(rate)
                self.Trash:Add(sinkAnim)
                WaitFor(sinkAnim)
                self.StopSink = true
            end
        end
    end,

    -- Create a unit's wrecked mesh blueprint from its regular mesh blueprint, by changing the shader and albedo
    ---@param self Unit
    ---@param overkillRatio number
    ---@return Wreckage | nil
    CreateWreckage = function (self, overkillRatio)
        if overkillRatio and overkillRatio > 1.0 then
            return
        end
        local bp = self.Blueprint
        local fractionComplete = self:GetFractionComplete()
        if fractionComplete < 0.5 or ((bp.TechCategory == 'EXPERIMENTAL' or bp.CategoriesHash["STRUCTURE"]) and fractionComplete < 1) then
            return
        end
        return self:CreateWreckageProp(overkillRatio)
    end,

    ---@param self Unit
    ---@param overkillRatio number
    ---@return Wreckage
    CreateWreckageProp = function(self, overkillRatio)
        local bp = self.Blueprint

        local wreck = bp.Wreckage.Blueprint
        if not wreck then
            return nil
        end

        local mass, energy = self:GetTotalResourceCosts()
        mass = mass * (bp.Wreckage.MassMult or 0)
        energy = energy * (bp.Wreckage.EnergyMult or 0)
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1)
        local pos = self:GetPosition()
        local wasOutside = false
        local layer = self.Layer

        -- Reduce the mass value based on the tech tier
        -- by default we reduce the mass value 2 times by 90% for a total of 81%
        local mass_tech_mult = 0.9
        local tech_category = bp.TechCategory

        -- We reduce the mass value based on tech category
        if tech_category == 'TECH1' then
            mass_tech_mult = 0.9
        elseif tech_category == 'TECH2' then
            mass_tech_mult = 0.8
        elseif tech_category == 'TECH3' then
            mass_tech_mult = 0.7
        elseif tech_category == 'EXPERIMENTAL' then
            mass_tech_mult = 0.6
        end
        
        mass = mass * mass_tech_mult

        -- Reduce the mass value of submerged wrecks
        if layer == 'Water' or layer == 'Sub' or layer == 'Seabed' then
            mass = mass * 0.6
            energy = energy * 0.6
        end

        -- Create potentially offmap wrecks on-map. Exclude campaign maps that may do weird scripted things.
        if self.Brain.BrainType == 'Human' and (not ScenarioInfo.CampaignMode) then
            pos, wasOutside = GetNearestPlayablePoint(pos)
        end

        local halfBuilt = self:GetFractionComplete() < 1

        -- Make sure air / naval wrecks stick to ground / seabottom, unless they're in a factory.
        if not halfBuilt and (layer == 'Air' or EntityCategoryContains(categories.NAVAL - categories.STRUCTURE, self)) then
            pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        end

        local overkillMultiplier = 1 - (overkillRatio or 1)
        mass = mass * overkillMultiplier * self:GetFractionComplete()
        energy = energy * overkillMultiplier * self:GetFractionComplete()
        time = time * overkillMultiplier

        -- Now we adjust the global multiplier. This is used for balance purposes to adjust global reclaim rate.
        local time  = time * 2

        local prop = Wreckage.CreateWreckage(bp, pos, self:GetOrientation(), mass, energy, time, self.DeathHitBox)

        -- Attempt to copy our animation pose to the prop. Only works if
        -- the mesh and skeletons are the same, but will not produce an error if not.
        if self.Tractored or (layer ~= 'Air' or (layer == "Air" and halfBuilt)) then
            TryCopyPose(self, prop, not wasOutside)
        end

        -- Create some ambient wreckage smoke
        if layer == 'Land' then
            Explosion.CreateWreckageEffects(self, prop)
        end

        return prop
    end,

    ---@param self Unit
    ---@param high number
    ---@param low number
    ---@param chassis any
    CreateUnitDestructionDebris = function(self, high, low, chassis)
        local HighDestructionParts = table.getn(self.DestructionPartsHighToss)
        local LowDestructionParts = table.getn(self.DestructionPartsLowToss)
        local ChassisDestructionParts = table.getn(self.DestructionPartsChassisToss)

        -- Limit the number of parts that we throw out
        local HighPartLimit = HighDestructionParts
        local LowPartLimit = LowDestructionParts
        local ChassisPartLimit = ChassisDestructionParts

        -- Create projectiles and accelerate them out and away from the unit
        if high and HighDestructionParts > 0 then
            HighPartLimit = Random(1, HighDestructionParts)
            for i = 1, HighPartLimit do
                self:ShowBone(self.DestructionPartsHighToss[i], false)
                local boneProj = self:CreateProjectileAtBone('/effects/entities/DebrisBoneAttachHigh01/DebrisBoneAttachHigh01_proj.bp', self.DestructionPartsHighToss[i])

                self:AttachBoneToEntityBone(self.DestructionPartsHighToss[i], boneProj, -1, false)
            end
        end

        if low and LowDestructionParts > 0 then
            LowPartLimit = Random(1, LowDestructionParts)
            for i = 1, LowPartLimit do
                self:ShowBone(self.DestructionPartsLowToss[i], false)
                local boneProj = self:CreateProjectileAtBone('/effects/entities/DebrisBoneAttachLow01/DebrisBoneAttachLow01_proj.bp', self.DestructionPartsLowToss[i])

                self:AttachBoneToEntityBone(self.DestructionPartsLowToss[i], boneProj, -1, false)
            end
        end

        if chassis and ChassisDestructionParts > 0 then
            ChassisPartLimit = Random(1, ChassisDestructionParts)
            for i = 1, Random(1, ChassisDestructionParts) do
                self:ShowBone(self.DestructionPartsChassisToss[i], false)
                local boneProj = self:CreateProjectileAtBone('/effects/entities/DebrisBoneAttachChassis01/DebrisBoneAttachChassis01_proj.bp', self.DestructionPartsChassisToss[i])

                self:AttachBoneToEntityBone(self.DestructionPartsChassisToss[i], boneProj, -1, false)
            end
        end
    end,

    ---@param self Unit
    ---@param overKillRatio number
    CreateDestructionEffects = function(self, overKillRatio)
        Explosion.CreateScalableUnitExplosion(self)
    end,

    ---@param self Unit
    ---@param damageRadius number
    ---@param damage number
    ---@param damageType DamageType
    ---@param damageFriendly boolean
    DeathWeaponDamageThread = function(self, damageRadius, damage, damageType, damageFriendly)
        WaitSeconds(0.1)
        DamageArea(self, self:GetPosition(), damageRadius or 1, damage or 1, damageType or 'Normal', damageFriendly or false)
        DamageArea(self, self:GetPosition(), damageRadius or 1, 1, 'TreeForce', false)
    end,

    ---@param self Unit
    SinkDestructionEffects = function(self)
        local blueprint = self.Blueprint
        local vol = blueprint.SizeVolume
        local numBones = self:GetBoneCount() - 1
        local pos = self:GetPosition()
        local surfaceHeight = GetSurfaceHeight(pos[1], pos[3])
        local i = 0

        while i < 1 do
            local randBone = utilities.GetRandomInt(0, numBones)
            local boneHeight = self:GetPosition(randBone)[2]
            local toSurface = surfaceHeight - boneHeight
            local y = toSurface
            local rx, ry, rz = self:GetRandomOffset(0.3)
            local rs = math.max(math.min(2.5, vol / 20), 0.5)
            local scale = utilities.GetRandomFloat(rs/2, rs)

            self:DestroyAllDamageEffects()
            if toSurface < 1 then
                CreateAttachedEmitter(self, randBone, self.Army, '/effects/emitters/destruction_water_sinking_ripples_01_emit.bp'):OffsetEmitter(rx, y, rz):ScaleEmitter(scale)
                CreateAttachedEmitter(self, randBone, self.Army, '/effects/emitters/destruction_water_sinking_wash_01_emit.bp'):OffsetEmitter(rx, y, rz):ScaleEmitter(scale)
            end

            if toSurface < 0 then
                Explosion.CreateDefaultHitExplosionAtBone(self, randBone, scale*1.5)
            else
                local lifetime = utilities.GetRandomInt(50, 200)

                if toSurface > 1 then
                    CreateEmitterAtBone(self, randBone, self.Army, '/effects/emitters/underwater_bubbles_01_emit.bp'):OffsetEmitter(rx, ry, rz)
                        :ScaleEmitter(scale)
                        :SetEmitterParam('LIFETIME', lifetime)

                    CreateAttachedEmitter(self, -1, self.Army, '/effects/emitters/destruction_underwater_sinking_wash_01_emit.bp'):OffsetEmitter(rx, ry, rz):ScaleEmitter(scale)
                end
                CreateEmitterAtBone(self, randBone, self.Army, '/effects/emitters/destruction_underwater_explosion_flash_01_emit.bp'):OffsetEmitter(rx, ry, rz):ScaleEmitter(scale)
                CreateEmitterAtBone(self, randBone, self.Army, '/effects/emitters/destruction_underwater_explosion_splash_01_emit.bp'):OffsetEmitter(rx, ry, rz):ScaleEmitter(scale)
            end
            local rd = utilities.GetRandomFloat(0.4, 1.0)
            WaitSeconds(i + rd)
            i = i + 0.3
        end
    end,

    ---@param self Unit
    ---@param callback fun(unit: Unit)
    StartSinking = function(self, callback)

        -- add flag to identify a unit died but is sinking before it is destroyed
        self.Sinking = true 

        local bp = self.Blueprint
        local scale = (((bp.SizeX or 0) + (bp.SizeZ or 0)) * 0.5)
        local bone = 0

        -- Create sinker projectile
        local proj = self:CreateProjectileAtBone('/projectiles/Sinker/Sinker_proj.bp', bone)

        -- Start the sinking after a delay of the given number of seconds, attaching to a given bone
        -- and entity.
        proj:Start(4 * math.max(2, math.min(7, scale)), self, bone, callback)
        self.Trash:Add(proj)
    end,

    ---@param self Unit
    SeabedWatcher = function(self)
        local pos = self:GetPosition()
        local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
        local watchBone = self.Blueprint.WatchBone or 0

        self.StopSink = false
        while not self.StopSink do
            WaitTicks(1)
            if self:GetPosition(watchBone)[2]-0.2 <= seafloor then
                self.StopSink = true
            end
        end
    end,

    ---@param self Unit
    ---@return boolean
    ShallSink = function(self)
        local layer = self.Layer
        local shallSink = (
            (layer == 'Water' or layer == 'Sub') and  -- In a layer for which sinking is meaningful
            not EntityCategoryContains(categories.STRUCTURE, self)  -- Exclude structures
        )
        return shallSink
    end,

    ---@param self Unit
    ---@param overkillRatio number
    ---@param instigator Unit
    DeathThread = function(self, overkillRatio, instigator)
        local isNaval = EntityCategoryContains(categories.NAVAL, self)
        local shallSink = self:ShallSink()
        WaitSeconds(utilities.GetRandomFloat(self.DestructionExplosionWaitDelayMin, self.DestructionExplosionWaitDelayMax))

        if not self.BagsDestroyed then
            self:DestroyAllBuildEffects()
            self:DestroyAllTrashBags()
            self.BagsDestroyed = true
        end

        -- Stop any motion sounds we may have
        self:StopUnitAmbientSound()

        -- BOOM!
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(overkillRatio)
        end

        -- Flying bits of metal and whatnot. More bits for more overkill.
        if self.ShowUnitDestructionDebris and overkillRatio then
            self:CreateUnitDestructionDebris(true, true, overkillRatio > 2)
        end

        if shallSink then
            self.DisallowCollisions = true

            -- Bubbles and stuff coming off the sinking wreck.
            self:ForkThread(self.SinkDestructionEffects)

            -- Avoid slightly ugly need to propagate this through callback hell...
            self.overkillRatio = overkillRatio

            if isNaval and self.Blueprint.Display.AnimationDeath then
                -- Waits for wreck to hit bottom or end of animation
                if self:GetFractionComplete() > 0.5 then
                    self:SeabedWatcher()
                else
                    self:DestroyUnit(overkillRatio)
                end
            else
                -- A non-naval unit or boat with no sinking animation dying over water needs to sink, but lacks an animation for it. Let's make one up.
                local this = self
                self:StartSinking(
                    function()
                        this:DestroyUnit(overkillRatio)
                    end
                )

                -- Wait for the sinking callback to actually destroy the unit.
                return
            end
        elseif self.DeathAnimManip then -- wait for non-sinking animations
            WaitFor(self.DeathAnimManip)
        end

        -- If we're not doing fancy sinking rubbish, just blow the damn thing up.
        self:DestroyUnit(overkillRatio)
    end,

    --- Called at the end of the destruction thread: create the wreckage and Destroy this unit.
    ---@param self Unit
    ---@param overkillRatio number
    DestroyUnit = function(self, overkillRatio)
        self:CreateWreckage(overkillRatio or self.overkillRatio)

        -- wait at least 1 tick before destroying unit
        WaitSeconds(math.max(0.1, self.DeathThreadDestructionWaitTime))

        -- do not play sound after sinking
        if not self.Sinking then 
            self:PlayUnitSound('Destroyed')
        end

        self:Destroy()
    end,

    ---@param self Unit
    DestroyAllBuildEffects = function(self)
        if self.BuildEffectsBag then
            self.BuildEffectsBag:Destroy()
        end
        if self.CaptureEffectsBag then
            self.CaptureEffectsBag:Destroy()
        end
        if self.ReclaimEffectsBag then
            self.ReclaimEffectsBag:Destroy()
        end
        if self.OnBeingBuiltEffectsBag then
            self.OnBeingBuiltEffectsBag:Destroy()
        end
        if self.UpgradeEffectsBag then
            self.UpgradeEffectsBag:Destroy()
        end
        if self.TeleportFxBag then
            self.TeleportFxBag:Destroy()
        end

        -- TODO: This really shouldn't be here...
        if self.buildBots then
            for _, bot in self.buildBots do
                if not bot:BeenDestroyed() then
                    bot.CanTakeDamage = true
                    bot.CanBeKilled = true

                    bot:Kill(nil, "Normal", 1)
                end
            end

            self.buildBots = nil
        end
    end,

    ---@param self Unit
    DestroyAllTrashBags = function(self)

        self.IdleEffectsBag:Destroy()
        self.OnBeingBuiltEffectsBag:Destroy()

        -- Some bags should really be managed by their classes, but
        -- for mod compatibility reasons we destroy those here too

        if self.ReleaseEffectsBag then
            for _, v in self.ReleaseEffectsBag do
                v:Destroy()
            end
        end

        if self.ShieldEffectsBag then 
            for k, v in self.ShieldEffectsBag do
                v:Destroy()
            end
        end

        if self.IntelEffectsBag then
            for _, v in self.IntelEffectsBag do
                v:Destroy()
            end
        end

        if self.TeleportDestChargeBag then
            for _, v in self.TeleportDestChargeBag do
                v:Destroy()
            end
        end

        if self.TeleportSoundChargeBag then
            for _, v in self.TeleportSoundChargeBag do
                v:Destroy()
            end
        end 

        if self.AdjacencyBeamsBag then
            for k, v in self.AdjacencyBeamsBag do
                v.Trash:Destroy()
                self.AdjacencyBeamsBag[k] = nil
            end
        end

        if self.DamageEffectsBag then
            for _, EffectsBag in self.DamageEffectsBag do
                for _, v in EffectsBag do
                    v:Destroy()
                end
            end
        end
    end,

    ---@param self Unit
    OnDestroy = function(self)
        self.Dead = true

        if self:GetFractionComplete() < 1 then
            self:SendNotifyMessage('cancelled')
        end

        -- Clear out our sync data
        UnitData[self.EntityId] = false
        Sync.UnitData[self.EntityId] = false

        -- Don't allow anyone to stuff anything else in the table
        self.Sync = false

        -- Let the user layer know this id is gone
        Sync.ReleaseIds[self.EntityId] = true

        -- Destroy everything added to the trash
        self.Trash:Destroy()

        -- Destroy all extra trashbags in case the DeathTread() has not already destroyed it (modded DeathThread etc.)
        if not self.BagsDestroyed then
            self:DestroyAllBuildEffects()
            self:DestroyAllTrashBags()
        end

        if self.TeleportDrain then
            RemoveEconomyEvent(self, self.TeleportDrain)
        end

        RemoveAllUnitEnhancements(self)

        -- remove all callbacks from the unit
        if self.EventCallbacks then
            self.EventCallbacks = nil
        end
        
        if self.Blueprint.Intel.JammerBlips > 0 then
            self.Brain:UntrackJammer(self)
        end
        
        -- for AI events
        self.Brain:OnUnitDestroy(self)

        ChangeState(self, self.DeadState)
    end,

    -- Generic function for showing a table of bones
    ---@param self Unit
    ---@param bones Bone List of bones
    ---@param children boolean True/False to show child bones
    ShowBones = function(self, bones, children)
        for _, v in bones do
            if self:IsValidBone(v) then
                self:ShowBone(v, children)
            else
                WARN('*WARNING: TRYING TO SHOW BONE ', repr(v), ' ON UNIT ', repr(self.UnitId), ' BUT IT DOES NOT EXIST IN THE MODEL. PLEASE CHECK YOUR SCRIPT IN THE BUILD PROGRESS BONES.')
            end
        end
    end,

    --- STRATEGIC LAUNCH DETECTED
    ---@param self Unit
    NukeCreatedAtUnit = function(self)
        if self:GetNukeSiloAmmoCount() <= 0 then
            return
        end

        local bp = self.Blueprint.Audio
        if bp then
            for num, aiBrain in ArmyBrains do
                local factionIndex = aiBrain:GetFactionIndex()

                if bp['NuclearLaunchDetected'] then
                    aiBrain:NuclearLaunchDetected(bp['NuclearLaunchDetected'])
                end
            end
        end
    end,

    ---@param self Unit
    ---@param enable boolean
    SetAllWeaponsEnabled = function(self, enable)
        for i = 1, self.WeaponCount do
            local wep = self.WeaponInstances[i]
            wep:SetWeaponEnabled(enable)
            wep:AimManipulatorSetEnabled(enable)
        end
    end,

    ---@param self Unit
    ---@param label string
    ---@param enable boolean
    SetWeaponEnabledByLabel = function(self, label, enable)

        local weapon = self:GetWeaponByLabel(label)
        if not weapon then 
            return 
        end

        if not enable then
            weapon:OnLostTarget()
        end

        weapon:SetWeaponEnabled(enable)
        weapon:AimManipulatorSetEnabled(enable)
    end,

    ---@param self Unit
    ---@param label string
    ---@return moho.AimManipulator | nil
    GetWeaponManipulatorByLabel = function(self, label)
        local weapon = self:GetWeaponByLabel(label)
        if weapon then 
            return weapon:GetAimManipulator()
        end
    end,

    ---@param self Unit
    ---@param label string
    ---@return Weapon | nil
    GetWeaponByLabel = function(self, label)

        -- if we're sinking then all death weapons should already have been applied
        if self.Sinking or self:BeenDestroyed() then 
            return nil
        end

        -- return the instanced weapon
        return self.WeaponInstances[label]
    end,

    ---@param self Unit
    ---@param label string
    ResetWeaponByLabel = function(self, label)
        local weapon = self:GetWeaponByLabel(label)
        if weapon then 
            weapon:ResetTarget()
        end
    end,

    ---@param self Unit
    ---@param enable boolean
    SetDeathWeaponEnabled = function(self, enable)
        self.DeathWeaponEnabled = enable
    end,

    ----------------------------------------------------------------------------------------------
    -- CONSTRUCTING - BEING BUILT
    ----------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param builder Unit
    ---@param oldProg number
    ---@param newProg number
    OnBeingBuiltProgress = function(self, builder, oldProg, newProg)
        self.Brain:OnUnitBeingBuiltProgress(self, builder, oldProg, newProg)
    end,

    ---@param self Unit
    ---@param angle number
    SetRotation = function(self, angle)
        local qx, qy, qz, qw = Explosion.QuatFromRotation(angle, 0, 1, 0)
        self:SetOrientation({qx, qy, qz, qw}, true)
    end,

    ---@param self Unit
    ---@param angle number
    Rotate = function(self, angle)
        local qx, qy, qz, qw = unpack(self:GetOrientation())
        local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
        local current_yaw = math.floor(math.abs(a) * (180 / math.pi) + 0.5)

        self:SetRotation(angle + current_yaw)
    end,

    ---@param self Unit
    ---@param tpos number
    RotateTowards = function(self, tpos)
        local pos = self:GetPosition()
        local rad = math.atan2(tpos[1] - pos[1], tpos[3] - pos[3])
        self:SetRotation(rad * (180 / math.pi))
    end,

    ---@param self Unit
    RotateTowardsMid = function(self)
        local x, y = GetMapSize()
        self:RotateTowards({x / 2, 0, y / 2})
    end,

    ---@param self Unit
    ---@param builder Unit
    ---@param layer string
    OnStartBeingBuilt = function(self, builder, layer)
        self:StartBeingBuiltEffects(builder, layer)

        local brain = self:GetAIBrain()
        if not table.empty(brain.UnitBuiltTriggerList) then
            for _, v in brain.UnitBuiltTriggerList do
                if EntityCategoryContains(v.Category, self) then
                    self:ForkThread(self.UnitBuiltPercentageCallbackThread, v.Percent, v.Callback)
                end
            end
        end

        self.originalBuilder = builder

        self:SendNotifyMessage('started')

        -- for AI events
        self.Brain:OnUnitStartBeingBuilt(self, builder, layer)
    end,

    ---@param self Unit
    ---@param percent number
    ---@param callback fun(unit: Unit)
    UnitBuiltPercentageCallbackThread = function(self, percent, callback)
        while not self.Dead and self:GetHealthPercent() < percent do
            WaitSeconds(1)
        end

        local aiBrain = self:GetAIBrain()
        for k, v in aiBrain.UnitBuiltTriggerList do
            if v.Callback == callback then
                callback(self)
                aiBrain.UnitBuiltTriggerList[k] = nil
            end
        end
    end,

    ---@param self Unit
    ---@param builder Unit
    ---@param layer Layer
    ---@return boolean
    OnStopBeingBuilt = function(self, builder, layer)
        if self.Dead or self:BeenDestroyed() then -- Sanity check, can prevent strange shield bugs and stuff
            self:Kill()
            return false
        end



        -- Create any idle effects on unit
        if TrashEmpty(self.IdleEffectsBag) then
            self:CreateIdleEffects()
        end

        IntelComponent.OnStopBeingBuilt(self, builder, layer)

        local bp = self.Blueprint
        local blueprintDisplay = bp.Display
        local blueprintDefense = bp.Defense
        self.isFinishedUnit = true

        self:ForkThread(self.StopBeingBuiltEffects, builder, layer)

        if self.Layer == 'Water' then
            local surfaceAnim = blueprintDisplay.AnimationSurface
            if not self.SurfaceAnimator and surfaceAnim then
                self.SurfaceAnimator = CreateAnimator(self)
            end
            if surfaceAnim and self.SurfaceAnimator then
                self.SurfaceAnimator:PlayAnim(surfaceAnim):SetRate(1)
            end
        end

        self:PlayUnitSound('DoneBeingBuilt')
        self:PlayUnitAmbientSound('ActiveLoop')

        if self.IsUpgrade and builder then
            -- Set correct hitpoints after upgrade
            local hpDamage = builder:GetMaxHealth() - builder:GetHealth() -- Current damage
            local damagePercent = hpDamage / self:GetMaxHealth() -- Resulting % with upgraded building
            local newHealthAmount = builder:GetMaxHealth() * (1 - damagePercent) -- HP for upgraded building
            builder:SetHealth(builder, newHealthAmount) -- Seems like the engine uses builder to determine new HP
            self.DisallowCollisions = false
            self.CanTakeDamage = true
            self:RevertCollisionShape()
            self.IsUpgrade = nil
        end

        -- Turn off land bones if this unit has them.
        self:DoUnitCallbacks('OnStopBeingBuilt')

        -- If we have a shield specified, create it.
        -- Blueprint registration always creates a dummy Shield entry:
        -- {
        --     ShieldSize = 0
        --     RegenAssistMult = 1
        -- }
        -- ... Which we must carefully ignore.
        local bpShield = blueprintDefense.Shield
        if bpShield.ShieldSize ~= 0 then
            self:CreateShield(bpShield)
        end

        -- Create spherical collisions if defined
        if bp.SizeSphere then
            self:SetCollisionShape(
                'Sphere',
                bp.CollisionSphereOffsetX or 0,
                bp.CollisionSphereOffsetY or 0,
                bp.CollisionSphereOffsetZ or 0,
                bp.SizeSphere
            )
        end

        if blueprintDisplay.AnimationPermOpen then
            self.PermOpenAnimManipulator = CreateAnimator(self):PlayAnim(blueprintDisplay.AnimationPermOpen)
            self.Trash:Add(self.PermOpenAnimManipulator)
        end

        -- Initialize movement effects subsystems, idle effects, beam exhaust, and footfall manipulators
        local movementEffects = blueprintDisplay.MovementEffects
        if movementEffects.Land or movementEffects.Air or movementEffects.Water or movementEffects.Sub or movementEffects.BeamExhaust then
            self.MovementEffectsExist = true
            if movementEffects.BeamExhaust and (movementEffects.BeamExhaust.Idle ~= false) then
                self:UpdateBeamExhaust('Idle')
            end
            if not self.Footfalls and movementEffects[layer].Footfall then
                self.Footfalls = self:CreateFootFallManipulators(movementEffects[layer].Footfall)
            end
        else
            self.MovementEffectsExist = false
        end

        ArmyBrains[self.Army]:AddUnitStat(self.UnitId, "built", 1)

        -- Prevent UI mods from violating game/scenario restrictions
        local id = self.UnitId
        local index = self.Army
        if not ScenarioInfo.CampaignMode and Game.IsRestricted(id, index) then
            WARN('Unit.OnStopBeingBuilt() Army ' ..index.. ' cannot create restricted unit: ' .. (bp.Description or id))
            if self ~= nil then self:Destroy() end

            return false -- Report failure of OnStopBeingBuilt
        end

        if bp.EnhancementPresetAssigned then
            self:ForkThread(self.CreatePresetEnhancementsThread)
        end

        -- Don't try sending a Notify message from here if we're an ACU
        if self.Blueprint.TechCategory ~= 'COMMAND' then
            self:SendNotifyMessage('completed')
        end

        -- for AI events
        self.Brain:OnUnitStopBeingBuilt(self, builder, layer)

        return true
    end,

    ---@param self Unit
    ---@param builder Unit
    ---@param layer string
    StartBeingBuiltEffects = function(self, builder, layer)
        local BuildMeshBp = self.Blueprint.Display.BuildMeshBlueprint
        if BuildMeshBp then
            self:SetMesh(BuildMeshBp, true)
        end
    end,

    ---@param self Unit
    ---@param builder Unit
    ---@param layer string
    StopBeingBuiltEffects = function(self, builder, layer)
        local bp = self.Blueprint.Display
        local useTerrainType = false
        if bp then
            if bp.TerrainMeshes then
                local bpTM = bp.TerrainMeshes
                local pos = self:GetPosition()
                local terrainType = GetTerrainType(pos[1], pos[3])
                if bpTM[terrainType.Style] then
                    self:SetMesh(bpTM[terrainType.Style], true)
                    useTerrainType = true
                end
            end
            if not useTerrainType then
                self:SetMesh(bp.MeshBlueprint, true)
            end
        end
        self.OnBeingBuiltEffectsBag:Destroy()
    end,

    ---@param self Unit
    OnFailedToBeBuilt = function(self)
        self:ForkThread(function()
            WaitTicks(1)
            self:Destroy()
        end)

        -- for AI events
        self.Brain:OnUnitFailedToBeBuilt(self)
    end,

    ---@param self Unit
    ---@param weapon Weapon
    OnSiloBuildStart = function(self, weapon)
        self.SiloWeapon = weapon
        self.SiloProjectile = weapon:GetProjectileBlueprint()

        -- for AI events
        self.Brain:OnUnitSiloBuildStart(self, weapon)
    end,

    ---@param self Unit
    ---@param weapon Weapon
    OnSiloBuildEnd = function(self, weapon)
        self.SiloWeapon = nil
        self.SiloProjectile = nil

        -- for AI events
        self.Brain:OnUnitSiloBuildEnd(self, weapon)
    end,

    -------------------------------------------------------------------------------------------
    -- UNIT ENHANCEMENT PRESETS
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ShowPresetEnhancementBones = function(self)
        -- Hide bones not involved in the preset enhancements.
        -- Useful during the build process to show the contours of the unit being built. Only visual.
        local bp = self.Blueprint
        if bp.Enhancements and (bp.CategoriesHash.USEBUILDPRESETS or bp.CategoriesHash.ISPREENHANCEDUNIT) then

            -- Create a blank slate: Hide all enhancement bones as specified in the unit BP
            for k, enh in bp.Enhancements do
                if enh.HideBones then
                    for _, bone in enh.HideBones do
                        self:HideBone(bone, true)
                    end
                end
            end

            -- For the barebone version we're done here. For the presets versions: show the bones of the enhancements we'll create later on
            if bp.EnhancementPresetAssigned then
                for _, v in bp.EnhancementPresetAssigned.Enhancements do
                    -- First show all relevant bones
                    if bp.Enhancements[v] and bp.Enhancements[v].ShowBones then
                        for _, bone in bp.Enhancements[v].ShowBones do
                            self:ShowBone(bone, true)
                        end
                    end

                    -- Now hide child bones of previously revealed bones, that should remain hidden
                    if bp.Enhancements[v] and bp.Enhancements[v].HideBones then
                        for _, bone in bp.Enhancements[v].HideBones do
                            self:HideBone(bone, true)
                        end
                    end
                end
            end
        end
    end,

    ---@param self Unit
    CreatePresetEnhancements = function(self)
        local bp = self.Blueprint
        if bp.Enhancements and bp.EnhancementPresetAssigned and bp.EnhancementPresetAssigned.Enhancements then
            for k, v in bp.EnhancementPresetAssigned.Enhancements do
                -- Enhancements may already have been created by SimUtils.TransferUnitsOwnership
                if not self:HasEnhancement(v) then
                    self:CreateEnhancement(v)
                end
            end
        end
    end,

    ---@param self Unit
    CreatePresetEnhancementsThread = function(self)
        -- Creating the preset enhancements on SCUs after they've been constructed. Delaying this by 1 tick to fix a problem where cloak and
        -- stealth enhancements work incorrectly.
        WaitTicks(1)
        if self and not self.Dead then
            self:CreatePresetEnhancements()
        end
    end,

    ---@param self Unit
    ShowEnhancementBones = function(self)
        -- Hide and show certain bones based on available enhancements
        local bp = self.Blueprint
        if bp.Enhancements then
            for _, enh in bp.Enhancements do
                if enh.HideBones then
                    for _, bone in enh.HideBones do
                        self:HideBone(bone, true)
                    end
                end
            end
            for k, enh in bp.Enhancements do
                if self:HasEnhancement(k) and enh.ShowBones then
                    for _, bone in enh.ShowBones do
                        self:ShowBone(bone, true)
                    end
                end
            end
        end
    end,

    ----------------------------------------------------------------------------------------------
    -- CONSTRUCTING - BUILDING - REPAIR
    ----------------------------------------------------------------------------------------------

    ---@param self Unit
    SetupBuildBones = function(self)
        local buildBones = self.Blueprint.General.BuildBones
        if  not buildBones or
            not buildBones.YawBone or
            not buildBones.PitchBone or
            not buildBones.AimBone
        then
            return
        end

        local buildArmManipulator = CreateBuilderArmController(self, buildBones.YawBone or 0 , buildBones.PitchBone or 0, buildBones.AimBone or 0)
        buildArmManipulator:SetAimingArc(-180, 180, 360, -90, 90, 360)
        buildArmManipulator:SetPrecedence(5)
        if self.BuildingOpenAnimManip and buildArmManipulator then
            buildArmManipulator:Disable()
        end

        self.BuildArmManipulator = buildArmManipulator
        self.Trash:Add(buildArmManipulator)
    end,

    ---@param self Unit
    ---@param enable boolean
    BuildManipulatorSetEnabled = function(self, enable)
        if IsDestroyed(self) then
            return
        end

        local buildArmManipulator = self.BuildArmManipulator
        if not buildArmManipulator then
            return
        end

        if enable then
            buildArmManipulator:Enable()
        else
            buildArmManipulator:Disable()
        end
    end,

    ---@param self Unit
    ---@param bp any unused
    ---@return number 
    GetRebuildBonus = function(self, bp)
        -- The engine intends to delete a wreck when our next build job starts. Remember this so we
        -- can regenerate the wreck if it's got the wrong one.
        self.EngineIsDeletingWreck = true

        return 0
    end,

    --- Look for a wreck of the thing we just started building at the same location. If there is
    -- one, give the rebuild bonus.
    ---@param self Unit
    ---@param unit Unit
    SetRebuildProgress = function(self, unit)
        local upos = unit:GetPosition()
        local props = GetReclaimablesInRect(Rect(upos[1], upos[3], upos[1], upos[3]))
        local wreckage = {}
        local bpid = unit.UnitId

        if EntityCategoryContains(categories.ENGINEER, self) then
            for _, p in props do
                local pos = p.CachePosition
                if p.IsWreckage and p.AssociatedBP == bpid and upos[1] == pos[1] and upos[3] == pos[3] then
                    local bp = unit:GetBlueprint()
                    local UnitMaxMassReclaim = bp.Economy.BuildCostMass * (bp.Wreckage.MassMult or 0)
                    if UnitMaxMassReclaim and UnitMaxMassReclaim > 0 then
                        local progress = (p.ReclaimLeft * p.MaxMassReclaim) / UnitMaxMassReclaim * 0.5
                        -- Set health according to how much is left of the wreck
                        unit:SetHealth(self, unit:GetMaxHealth() * progress)
                    end

                    -- Clear up wreck after rebuild bonus applied if engine won't
                    if not unit.EngineIsDeletingWreck then
                        p:Destroy()
                    end

                    return
                end
            end
        end

        if self.EngineIsDeletingWreck then
            -- Control reaches this point when:
            -- A structure build template was created atop a wreck of the same building type.
            -- The build template was then moved somewhere else.
            -- The build template was not moved back onto the wreck before construction started.

            -- This is a pretty hilariously rare case (in reality, it's probably only going to arise
            -- rarely, or when someone is trying to use the remote-wreck-deletion exploit).
            -- As such, I don't feel especially guilty doing the following. This approach means we
            -- don't have to waste a ton of memory keeping lists of wrecks of various sorts, we just
            -- do this one hideously expensive routine in the exceptionally rare circumstance that
            -- the badness happens.

            local x, y = GetMapSize()
            local reclaimables = GetReclaimablesInRect(0, 0, x, y)

            for _, r in reclaimables do
                if r.IsWreckage and r.AssociatedBP == bpid and r:BeenDestroyed() then
                    r:Clone()
                    return
                end
            end
        end
    end,

    --- This function is called when engineer A is assisting engineer B that is doing a task. It forces 
    --- the assisting unit to perform the same task as the unit it is assisting.
    ---@param self Unit
    CheckAssistFocus = function(self)

        --- Given engineer A that is assisting engineer B in doing some task. This function fixes the following situations:
        ---
        --- - (1) Engineer B is damaged. Engineer B starts the construction of a structure. Engineer A is repairing 
        --- engineer B instead of assisting with the structure
        ---
        --- - (2) Engineer B is building a structure. Engineer A is building the structure too. Engineer B switches to reclaiming 
        --- the same structure (before it is finished), but engineer A keeps on building the structure. This is a loop and the 
        --- structure will never cease to exist, the engineers are effectively stuck until the player intervenes

        if self.Dead or not (self and EntityCategoryContains(categories.ENGINEER, self)) then
            return
        end

        local guarded = self:GetGuardedUnit()
        if guarded and not (
            -- do not shift focus for dead or destroyed units
            guarded.Dead or
            IsDestroyed(guarded) or

            -- do not shift focus to the unit a factory is building
            (guarded:GetFractionComplete() >= 1.0 and EntityCategoryContains(categories.FACTORY, guarded)))
        then
            local focus = guarded:GetFocusUnit()
            if not focus then
                return
            end

            local cmd
            if guarded:IsUnitState('Reclaiming') then
                cmd = IssueReclaim
            elseif guarded:IsUnitState('Building') then
                cmd = IssueRepair
            end

            if cmd then
                IssueToUnitClearCommands(self)
                cmd({self}, focus)
                IssueGuard({self}, guarded)
            end
        end
    end,

    ---@param self Unit
    CheckAssistersFocus = function(self)
        for _, u in self:GetGuards() do
            if u:IsUnitState('Repairing') and not EntityCategoryContains(categories.INSIGNIFICANTUNIT, u) then
                u:CheckAssistFocus()
            end
        end
    end,

    ---@param self Unit
    ---@param built Unit
    ---@param order string
    ---@return boolean
    OnStartBuild = function(self, built, order)
        self.BuildEffectsBag = self.BuildEffectsBag or TrashBag()

        -- Prevent UI mods from violating game/scenario restrictions
        local id = built.UnitId
        local bp = built:GetBlueprint()
        local bpSelf = self.Blueprint
        if not ScenarioInfo.CampaignMode and Game.IsRestricted(id, self.Army) then
            WARN('Unit.OnStartBuild() Army ' ..self.Army.. ' cannot build restricted unit: ' .. (bp.Description or id))
            self:OnFailedToBuild() -- Don't use: self:OnStopBuild()
            IssueClearFactoryCommands({self})
            IssueToUnitClearCommands(self)
            return false -- Report failure of OnStartBuild
        end

        -- We just started a construction (and haven't just been tasked to work on a half-done
        -- project.)
        if built:GetHealth() == 1 then
            self:SetRebuildProgress(built)
            self.EngineIsDeletingWreck = nil
        end

        -- OnStartBuild() is called on paused engineers when they roll up to their next construction
        -- task. This is a native-code bug: it shouldn't be calling OnStartBuild at all in this case
        if self:IsPaused() then
            return true
        end

        if order == 'Repair' then
            self:OnStartRepair(built)
        elseif self:GetHealth() < self:GetMaxHealth() and not table.empty(self:GetGuards()) then
            -- Unit building something is damaged and has assisters, check their focus
            self:CheckAssistersFocus()
        end

        if order ~= 'Upgrade' or bpSelf.Display.ShowBuildEffectsDuringUpgrade then
            self:StartBuildingEffects(built, order)
        end

        self:SetActiveConsumptionActive()
        self:PlayUnitSound('Construct')
        self:PlayUnitAmbientSound('ConstructLoop')

        self:DoOnStartBuildCallbacks(built)

        if order == 'Upgrade' and bp.General.UpgradesFrom == self.UnitId then
            built.DisallowCollisions = true
            built.CanTakeDamage = false
            built:SetCollisionShape('None')
            built.IsUpgrade = true

            --Transfer flag
            self.TransferUpgradeProgress = true
            self.UpgradeBuildTime = bp.Economy.BuildTime
            self.UpgradesTo = bp.BlueprintId
        end

        self.Brain:OnUnitStartBuild(self, built, order)

        return true
    end,

    ---@param self Unit
    ---@param built Unit
    ---@param order string
    OnStopBuild = function(self, built, order)
        self:StopBuildingEffects(built)
        self:SetActiveConsumptionInactive()
        self:DoOnUnitBuiltCallbacks(built)
        self:StopUnitAmbientSound('ConstructLoop')
        self:PlayUnitSound('ConstructStop')
        self.TransferUpgradeProgress = nil

        if built.Repairers[self.EntityId] then
            self:OnStopRepair(self, built)
            built.Repairers[self.EntityId] = nil
        end

        -- for AI events
        self.Brain:OnUnitStopBuild(self, built, order)
    end,

    ---@param self Unit
    OnFailedToBuild = function(self)
        self:DoOnFailedToBuildCallbacks()
        self:StopUnitAmbientSound('ConstructLoop')
    end,

    ---@param self Unit
    OnPrepareArmToBuild = function(self)
    end,

    ---@param self Unit
    OnStartBuilderTracking = function(self)
    end,

    ---@param self Unit
    OnStopBuilderTracking = function(self)
    end,

    ---@param self Unit
    ---@param target Unit
    ---@param oldProg number
    ---@param newProg number
    OnBuildProgress = function(self, target, oldProg, newProg)
        self.Brain:OnUnitBuildProgress(self, target, oldProg, newProg)
    end,

    --- Called as this unit (with transport capabilities) attached another unit to itself
    ---@param self Unit
    ---@param attachBone Bone
    ---@param attachedUnit Unit
    OnTransportAttach = function(self, attachBone, attachedUnit)
        -- manual Lua callback for the unit
        attachedUnit:OnAttachedToTransport(self, attachBone)

        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnTransportAttach']
        if callbacks then
            for _, cb in callbacks do
                cb(self, attachBone, attachedUnit)
            end
        end

        -- for AI events
        self.Brain:OnUnitTransportAttach(self, attachBone, attachedUnit)
    end,

    --- Called by the engine when the infinite build is disabled
    ---@param self Unit
    OnStopRepeatQueue = function(self)
    end,

    --- Called by the engine when the infinite build is enabled
    ---@param self Unit
    OnStartRepeatQueue = function(self)
    end,

    --- Called by the engine when the unit is assigned a focus target. Behavior is a bit erradic
    OnAssignedFocusEntity = function(self)
    end,

    --- Called as this unit (with transport capabilities) deattached another unit from itself
    ---@param self Unit
    ---@param attachBone Bone
    ---@param detachedUnit Unit
    OnTransportDetach = function(self, attachBone, detachedUnit)
        -- manual Lua callback
        detachedUnit:OnDetachedFromTransport(self, attachBone) -- <-- this is what causes it to hang

        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnTransportDetach']
        if callbacks then
            for _, cb in callbacks do
                cb(self, attachBone, detachedUnit)
            end
        end

        -- for AI events
        self.Brain:OnUnitTransportDetach(self, attachBone, detachedUnit)
    end,

    --- Called as a unit (with transport capabilities) aborts the transport order
    ---@param self Unit
    OnTransportAborted = function(self)
        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnTransportAborted']
        if callbacks then
            for _, cb in callbacks do
                cb(self)
            end
        end

        self.Brain:OnUnitTransportAborted(self)
    end,

    --- Called as a unit (with transport capabilities) initiates the a transport order
    ---@param self Unit
    OnTransportOrdered = function(self)
        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnTransportOrdered']
        if callbacks then
            for _, cb in callbacks do
                cb(self)
            end
        end

        -- for AI events
        self.Brain:OnUnitTransportOrdered(self)
    end,

    --- Called as a unit is killed while being transported by a unit (with transport capabilities) of this platoon
    ---@param self Unit
    ---@param attached Unit
    OnAttachedKilled = function(self, attached)
        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnAttachedKilled']
        if callbacks then
            for _, cb in callbacks do
                cb(self, attached)
            end
        end

        -- for AI events
        self.Brain:OnUnitAttachedKilled(self, attached)
    end,
    
    --- Called as a unit (with transport capabilities) is ready to load in units
    ---@param self Unit
    OnStartTransportLoading = function(self)
        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnStartTransportLoading']
        if callbacks then
            for _, cb in callbacks do
                cb(self)
            end
        end

        -- for AI events
        self.Brain:OnUnitStartTransportLoading(self)
    end,

    --- Called as a unit (with transport capabilities) of this platoon is done loading in units
    ---@param self Unit
    OnStopTransportLoading = function(self)
        -- awareness of event for campaign scripts
        local callbacks = self.EventCallbacks['OnStopTransportLoading']
        if callbacks then
            for _, cb in callbacks do
                cb(self)
            end
        end

        -- for AI events
        self.Brain:OnUnitStopTransportLoading(self)
    end,

    ---@param self Unit
    ---@param built Unit
    ---@param order string
    StartBuildingEffects = function(self, built, order)
        local buildEffectsBag = self.BuildEffectsBag
        if buildEffectsBag then
            local thread = ForkThread(self.CreateBuildEffects, self, built, order)
            self.Trash:Add(thread)
            buildEffectsBag:Add(thread)
        end
    end,

    ---@param self Unit
    ---@param built Unit
    ---@param order string
    CreateBuildEffects = function(self, built, order)
    end,

    ---@param self Unit
    ---@param built Unit
    StopBuildingEffects = function(self, built)
        local buildEffectsBag = self.BuildEffectsBag
        if buildEffectsBag then
            buildEffectsBag:Destroy()
        end

        -- kept after --3355 for backwards compatibility with mods
        if self.buildBots then
            for _, b in self.buildBots do
                ChangeState(b, b.IdleState)
            end
        end
    end,

    ---@param self Unit
    ---@param targetUnit Unit
    OnStartSacrifice = function(self, targetUnit)
        self:SetUnitState("Sacrificing", true)
        EffectUtilities.PlaySacrificingEffects(self, targetUnit)
        self.SacrificeTargetUnit = targetUnit

        -- for AI events
        self.Brain:OnUnitStartSacrifice(self, targetUnit)
    end,

    ---@param self Unit
    ---@param targetUnit Unit
    OnStopSacrifice = function(self, targetUnit)
        self:SetUnitState("Sacrificing", false)
        EffectUtilities.PlaySacrificeEffects(self, targetUnit)
        self:SetDeathWeaponEnabled(false)
        self:Destroy()

        -- for AI events
        self.Brain:OnUnitStopSacrifice(self, targetUnit)
    end,

    -------------------------------------------------------------------------------------------
    -- GENERIC WORK
    -------------------------------------------------------------------------------------------

    ---@param self Unit
    ---@param target Unit
    InheritWork = function(self, target)
        self.WorkItem = target.WorkItem
        self.WorkItemBuildCostEnergy = target.WorkItemBuildCostEnergy
        self.WorkItemBuildCostMass = target.WorkItemBuildCostMass
        self.WorkItemBuildTime = target.WorkItemBuildTime
    end,

    ---@param self Unit
    ClearWork = function(self)
        self.WorkProgress = 0
        self.WorkItem = nil
        self.WorkItemBuildCostEnergy = nil
        self.WorkItemBuildCostMass = nil
        self.WorkItemBuildTime = nil
    end,

    ---@param self Unit
    ---@param work any
    ---@return boolean
    OnWorkBegin = function(self, work)
        local restrictions = EnhancementCommon.GetRestricted()
        if restrictions[work] then
            self:OnWorkFail(work)
            return false
        end

        local unitEnhancements = EnhancementCommon.GetEnhancements(self.EntityId)
        local tempEnhanceBp = self.Blueprint.Enhancements[work]
        if tempEnhanceBp.Prerequisite then
            if unitEnhancements[tempEnhanceBp.Slot] ~= tempEnhanceBp.Prerequisite then
                WARN('*WARNING: Ordered enhancement ['..(tempEnhanceBp.Name or 'nil')..'] does not have the proper prerequisite. Slot ['..(tempEnhanceBp.Slot or 'nil')..'] - Needed: ['..(unitEnhancements[tempEnhanceBp.Slot] or 'nil')..'] - Installed: ['..(tempEnhanceBp.Prerequisite or 'nil')..']')
                return false
            end
        elseif unitEnhancements[tempEnhanceBp.Slot] then
            WARN('*WARNING: Ordered enhancement ['..(tempEnhanceBp.Name or 'nil')..'] does not have the proper slot available. Slot ['..(tempEnhanceBp.Slot or 'nil')..'] has already ['..(unitEnhancements[tempEnhanceBp.Slot] or 'nil')..'] installed.')
            return false
        end


        self.WorkItem = tempEnhanceBp
        self.WorkItemBuildCostEnergy = tempEnhanceBp.BuildCostEnergy
        self.WorkItemBuildCostMass = tempEnhanceBp.BuildCostEnergy
        self.WorkItemBuildTime = tempEnhanceBp.BuildTime
        self.WorkProgress = 0

        self:PlayUnitSound('EnhanceStart')
        self:PlayUnitAmbientSound('EnhanceLoop')
        self:CreateEnhancementEffects(work)
        if not self:IsPaused() then
            self:SetActiveConsumptionActive()
        end

        ChangeState(self, self.WorkingState)

        -- for AI events
        self.Brain:OnUnitWorkBegin(self, work)

        -- Inform EnhanceTask that enhancement is not restricted
        return true
    end,

    ---@param self Unit
    ---@param work any
    OnWorkEnd = function(self, work)
        self:ClearWork()
        self:SetActiveConsumptionInactive()
        self:PlayUnitSound('EnhanceEnd')
        self:StopUnitAmbientSound('EnhanceLoop')
        self:CleanupEnhancementEffects()

        -- for AI events
        self.Brain:OnUnitWorkEnd(self, work)
    end,

    ---@param self Unit
    ---@param work any
    OnWorkFail = function(self, work)
        self:ClearWork()
        self:SetActiveConsumptionInactive()
        self:PlayUnitSound('EnhanceFail')
        self:StopUnitAmbientSound('EnhanceLoop')
        self:CleanupEnhancementEffects()

        -- for AI events
        self.Brain:OnUnitWorkFail(self, work)
    end,

    ---@alias DefaultWorkOrder "BeingBuilt" | "Enhancing" | "FactoryBuilding" | "None" | "Repairing" | "Upgrading"

    --- Returns the current default work order, which is something that an assisting unit would be
    --- able to directly do for the unit without inheriting work: constructing, enhancing, upgrading,
    --- factory building, repairing, or nothing (in that order).
    ---@param self Unit
    ---@return DefaultWorkOrder
    GetCurrentDefaultWorkOrder = function(self)
        if self:IsUnitState("BeingBuilt") then
            return "BeingBuilt"
        end
        if self:IsUnitState("Enhancing") then
            return "Enhancing"
        end
        if self:IsUnitState("Upgrading") then
            return "Upgrading"
        end
        if self:IsUnitState("Building") then
            return "FactoryBuilding"
        end
        if self:GetHealth() < self:GetMaxHealth() then
            return "Repairing"
        end
        return "None"
    end;

    --- Gets the amount of progress left for the current default work item--that is, something
    --- an assisting unit can directly do for the unit without inheriting work: constructing,
    --- enhancing, upgrading, factory building, and repairing (in that order).
    ---@param self Unit
    ---@return number totalProgressLeft
    GetCurrentDefaultWorkProgress = function(self)
        -- constructing
        local built = self:GetFractionComplete()
        if built < 1.0 then
            return built
        end

        --- enhancing, upgrading, building
        if self.WorkItem or self:IsUnitState("Upgrading") or self:IsUnitState("Building") then
            return self:GetWorkProgress()
        end

        --- default to repairing
        local health = self:GetHealth()
        local maxHealth = self:GetMaxHealth()
        if health == maxHealth then
            return 1.0
        end
        return health / maxHealth
    end;

    ---@param self Unit
    ---@param enh string
    ---@return boolean
    CreateEnhancement = function(self, enh)
        local bp = self.Blueprint.Enhancements[enh]
        if not bp then
            error('*ERROR: Got CreateEnhancement call with an enhancement that doesnt exist in the blueprint.', 2)
            return false
        end

        if bp.ShowBones then
            for _, v in bp.ShowBones do
                if self:IsValidBone(v) then
                    self:ShowBone(v, true)
                end
            end
        end

        if bp.HideBones then
            for _, v in bp.HideBones do
                if self:IsValidBone(v) then
                    self:HideBone(v, true)
                end
            end
        end

        AddUnitEnhancement(self, enh, bp.Slot or '')
        if bp.RemoveEnhancements then
            for _, v in bp.RemoveEnhancements do
                RemoveUnitEnhancement(self, v)
            end
        end

        self:RequestRefreshUI()
    end,

    ---@param self Unit
    ---@param enhancement string
    CreateEnhancementEffects = function(self, enhancement)
        local bp = self.Blueprint.Enhancements[enhancement]
        local effects = TrashBag()
        local scale = math.min(4, math.max(1, ((bp.BuildCostEnergy / bp.BuildTime) or 1) / 50))

        self.UpgradeEffectsBag = self.UpgradeEffectsBag or TrashBag()

        if bp.UpgradeEffectBones then
            for _, v in bp.UpgradeEffectBones do
                if self:IsValidBone(v) then
                    EffectUtilities.CreateEnhancementEffectAtBone(self, v, self.UpgradeEffectsBag)
                end
            end
        end

        if bp.UpgradeUnitAmbientBones then
            for _, v in bp.UpgradeUnitAmbientBones do
                if self:IsValidBone(v) then
                    EffectUtilities.CreateEnhancementUnitAmbient(self, v, self.UpgradeEffectsBag)
                end
            end
        end

        for _, e in effects do
            e:ScaleEmitter(scale)
            self.UpgradeEffectsBag:Add(e)
        end
    end,

    ---@param self Unit
    CleanupEnhancementEffects = function(self)
        if self.UpgradeEffectsBag.Destroy then self.UpgradeEffectsBag:Destroy() end
    end,

    ---@param self Unit
    ---@param enh string
    ---@return boolean
    HasEnhancement = function(self, enh)
        local unitEnh = SimUnitEnhancements[self.EntityId]
        if unitEnh then
            for k, v in unitEnh do
                if v == enh then
                    return true
                end
            end
        end

        return false
    end,

    -------------------------------------------------------------------------------------------
    -- LAYER EVENTS
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)

        -- this function is called _before_ OnCreate is called. 
        -- You can identify this original call by checking whether 'old' is set to 'None'.

        -- This function is called when:
        -- - A unit changes layer (heh)
        -- - For all units part of a transport, when the transport changes layer (e.g., land units can become 'Air')
        -- - When a jet lands, it changes to land (from Air)

        -- Store latest layer for performance, preventing .Layer engine calls.
        self.Layer = new 

        if old != 'None' then
            self:DestroyMovementEffects()
            self:CreateMovementEffects(self.MovementEffectsBag, nil)
        end

        -- Bail out early if dead. The engine calls this function AFTER entity:Destroy() has killed
        -- the C object. Any functions down this line which expect a live C object (self:CreateAnimator())
        -- for example, will throw an error.
        if self.Dead then return end

        -- set valid targets for weapons
        -- if old is defined as 'None' then OnCreate hasn't been called yet - do it the old way.
        if old ~= 'None' then 
            for i = 1, self.WeaponCount do
                self.WeaponInstances[i]:SetValidTargetsForCurrentLayer(new)
            end
        else 
            for i = 1, self:GetWeaponCount() do
                self:GetWeapon(i):SetValidTargetsForCurrentLayer(new)
            end
        end

        if (old == 'Seabed' or old == 'Water' or old == 'Sub' or old == 'None') and new == 'Land' then
            self:DisableIntel('WaterVision')
        elseif (old == 'Land' or old == 'None') and (new == 'Seabed' or new == 'Water' or new == 'Sub') then
            self:EnableIntel('WaterVision')
        end

        -- All units want normal vision!
        if old == 'None' then
            self:EnableIntel('Vision')
        end

        if new == 'Land' then
            self:PlayUnitSound('TransitionLand')
            self:PlayUnitAmbientSound('AmbientMoveLand')
        elseif new == 'Water' or new == 'Seabed' then
            self:PlayUnitSound('TransitionWater')
            self:PlayUnitAmbientSound('AmbientMoveWater')
        elseif new == 'Sub' then
            self:PlayUnitAmbientSound('AmbientMoveSub')
        end

        local movementEffects = self.Blueprint.Display.MovementEffects
        if not self.Footfalls and movementEffects[new].Footfall then
            self.Footfalls = self:CreateFootFallManipulators(movementEffects[new].Footfall)
        end
        self:CreateLayerChangeEffects(new, old)

        -- Trigger the re-worded stuff that used to be inherited, no longer because of the engine bug above.
        if self.LayerChangeTrigger then
            self:LayerChangeTrigger(new, old)
        end
    end,

    ---@param self Unit
    ---@param new string
    ---@param old string
    OnMotionHorzEventChange = function(self, new, old)

        -- we can't do anything if we're dead
        if self.Dead then
            return
        end

        local layer = self.Layer

        -- play sounds / events when we start moving
        if old == 'Stopped' then

            if not self:PlayUnitSound('StartMove' .. layer) then 
                self:PlayUnitSound('StartMove')
            end

            if not self:PlayUnitAmbientSound('AmbientMove' .. layer) then 
                self:PlayUnitAmbientSound('AmbientMove')
            end
        end

        -- play sounds / events when we stop moving
        if new == 'Stopping' then
            if not self:PlayUnitSound('StopMove' .. layer) then 
                self:PlayUnitSound('StopMove')
            end
            self:StopUnitAmbientSound()
        end

        -- update movement effects
        if self.MovementEffectsExist then
            self:UpdateMovementEffectsOnMotionEventChange(new, old)
        end

        -- update weapon capabilities
        for k = 1, self.WeaponCount do
            self.WeaponInstances[k]:OnMotionHorzEventChange(new, old)
        end
    end,

    ---@param self Unit
    ---@param new string
    ---@param old string
    OnMotionVertEventChange = function(self, new, old)
        if self.Dead then
            return
        end

        if new == 'Down' then
            -- Play the "landing" sound
            self:PlayUnitSound('Landing')
        elseif new == 'Bottom' or new == 'Hover' then
            -- Play the "landed" sound
            self:PlayUnitSound('Landed')
        elseif new == 'Up' or (new == 'Top' and (old == 'Down' or old == 'Bottom')) then
            -- Play the "takeoff" sound
            self:PlayUnitSound('TakeOff')
        end

        -- Adjust any beam exhaust
        if new == 'Bottom' then
            self:UpdateBeamExhaust('Landed')
        elseif old == 'Bottom' then
            self:UpdateBeamExhaust('Cruise')
        end

        -- Surfacing and sinking, landing and take off idle effects
        local layer = self.Layer
        if (new == 'Up' and old == 'Bottom') or (new == 'Down' and old == 'Top') then
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

        if (new == 'Top' and old == 'Up') or (new == 'Bottom' and old == 'Down') then
            self:CreateIdleEffects()

            if new == 'Bottom' and layer == 'Sub' then
                self:PlayUnitSound('SubmergeEnd')
            end
            if new == 'Top' and layer == 'Water' then
                self:PlayUnitSound('SurfaceEnd')
                local surfaceAnim = self.Blueprint.Display.AnimationSurface
                if not self.SurfaceAnimator and surfaceAnim then
                    self.SurfaceAnimator = CreateAnimator(self)
                end
                if surfaceAnim and self.SurfaceAnimator then
                    self.SurfaceAnimator:PlayAnim(surfaceAnim):SetRate(1)
                end
            end
        end
        self:CreateMotionChangeEffects(new, old)
    end,

    -- Called as planes whoosh round corners. No sounds were shipped for use with this and it was a
    -- cycle eater, so we killed it.
    OnMotionTurnEventChange = function() end,

    ---@param self Unit
    ---@param new string
    ---@param old string
    OnTerrainTypeChange = function(self, new, old)
        self.TerrainType = new
        if self.MovementEffectsExist then
            self:DestroyMovementEffects()
            self:CreateMovementEffects(self.MovementEffectsBag, nil, new)
        end
    end,

    ---@param self Unit
    ---@param bone Bone
    ---@param x number
    ---@param y number
    ---@param z number
    OnAnimCollision = function(self, bone, x, y, z)
        local layer = self.Layer
        local blueprintMovementEffects = self.Blueprint.Display.MovementEffects
        local movementEffects = blueprintMovementEffects and blueprintMovementEffects[layer] and blueprintMovementEffects[layer].Footfall

        if movementEffects then
            local effects = {}
            local scale = 1
            local offset
            local boneTable

            if movementEffects.Damage then
                local bpDamage = movementEffects.Damage
                DamageArea(self, self:GetPosition(bone), bpDamage.Radius, bpDamage.Amount, bpDamage.Type, bpDamage.DamageFriendly)
            end

            if movementEffects.CameraShake then
                local shake = movementEffects.CameraShake
                self:ShakeCamera(shake.Radius, shake.MaxShakeEpicenter, shake.MinShakeAtRadius, shake.Interval)
            end

            for _, v in movementEffects.Bones do
                if bone == v.FootBone then
                    boneTable = v
                    bone = v.FootBone
                    scale = boneTable.Scale or 1
                    offset = bone.Offset
                    if v.Type then
                        effects = self.GetTerrainTypeEffects('FXMovement', layer, self:GetPosition(v.FootBone), v.Type)
                    end

                    break
                end
            end

            if boneTable.Tread and self:GetTTTreadType(self:GetPosition(bone)) ~= 'None' then
                CreateSplatOnBone(self, boneTable.Tread.TreadOffset, 0, boneTable.Tread.TreadMarks, boneTable.Tread.TreadMarksSizeX, boneTable.Tread.TreadMarksSizeZ, 100, boneTable.Tread.TreadLifeTime or 4, self.Army)
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
                CreateEmitterAtBone(self, bone, self.Army, v):ScaleEmitter(scale):OffsetEmitter(offset.x or 0, offset.y or 0, offset.z or 0)
            end
        end

        if layer ~= 'Seabed' then
            self:PlayUnitSound('FootFallGeneric')
        else
            self:PlayUnitSound('FootFallGenericSeabed')
        end
    end,

    ---@param self Unit
    ---@param new Layer
    ---@param old Layer
    UpdateMovementEffectsOnMotionEventChange = function(self, new, old)
        if old == 'TopSpeed' then
            -- Destroy top speed contrails and exhaust effects
            self:DestroyTopSpeedEffects()
        end

        local layer = self.Layer
        local movementEffects = self.Blueprint.Display.MovementEffects
        local movementEffectsLayer = movementEffects[layer]
        if new == 'TopSpeed' and self.HasFuel then
            if movementEffectsLayer.Contrails and self.ContrailEffects then
                self:CreateContrails(movementEffectsLayer.Contrails)
            end
            if movementEffectsLayer.TopSpeedFX then
                self:CreateMovementEffects(self.TopSpeedEffectsBag, 'TopSpeed')
            end
        end

        if (old == 'Stopped' and new ~= 'Stopping') or (old == 'Stopping' and new ~= 'Stopped') then
            self:DestroyIdleEffects()
            self:DestroyMovementEffects()
            self:CreateMovementEffects(self.MovementEffectsBag, nil)
            if movementEffects.BeamExhaust then
                self:UpdateBeamExhaust('Cruise')
            end
            if self.Detector then
                self.Detector:Enable()
            end
        end

        if new == 'Stopped' then
            self:DestroyMovementEffects()
            self:DestroyIdleEffects()
            self:CreateIdleEffects()
            if movementEffects.BeamExhaust then
                self:UpdateBeamExhaust('Idle')
            end
            if self.Detector then
                self.Detector:Disable()
            end
        end
    end,

    ---@param fxType TerrainEffectType
    ---@param layer Layer
    ---@param pos Vector
    ---@param type? EffectType
    ---@param typeSuffix? string
    ---@return table
    GetTerrainTypeEffects = function(fxType, layer, pos, type, typeSuffix)
        -- Get terrain type mapped to local position
        if type then
            local terrainType = GetTerrainType(pos[1], pos[3])
            if typeSuffix then
                type = type .. typeSuffix
            end
            local terrainFx = terrainType[fxType][layer][type]

            if terrainFx then
                return terrainFx
            end
            -- If our current terrain type doesn't have the effects, try the default terrain type
        else
            -- only useful for impact effect types
            type = "Default"
            if typeSuffix then
                type = type .. typeSuffix
            end
        end

        return DefaultTerrainType[fxType][layer][type] or EmptyTable
    end,

    ---@overload fun(self: Unit, effectTypeGroups: UnitBlueprintEffect[], fxBlockType: "FXImpact", impactType: ImpactType, suffix?: string, bag?: TrashBag, terrainType?: TerrainType)
    ---@overload fun(self: Unit, effectTypeGroups: UnitBlueprintEffect[], fxBlockType: "FXMotionChange", motionChange: MotionChangeType, suffix?: string, bag?: TrashBag, terrainType?: TerrainType)
    ---@overload fun(self: Unit, effectTypeGroups: UnitBlueprintEffect[], fxBlockType: "FXLayerChange", layerChange: LayerChangeType, suffix?: string, bag?: TrashBag, terrainType?: TerrainType)
    ---
    ---@param self Unit
    ---@param effectTypeGroups UnitBlueprintEffect[]
    ---@param fxBlockType LayerTerrainEffectType
    ---@param layer Layer
    ---@param typeSuffix? string
    ---@param effectsBag? TrashBag
    ---@param terrainType? TerrainType
    CreateTerrainTypeEffects = function(self, effectTypeGroups, fxBlockType, layer, typeSuffix, effectsBag, terrainType)
        local effects, terrainFX, GetTerrainTypeEffects
        local pos = self:GetPosition()
        local army = self.Army
        if terrainType then
            terrainFX = terrainType[fxBlockType][layer]
        else
            GetTerrainTypeEffects = self.GetTerrainTypeEffects
        end

        for _, typeGroup in effectTypeGroups do
            local bones = typeGroup.Bones
            if table.empty(bones) then
                WARN('*WARNING: No effect bones defined for layer group ', repr(self.UnitId), ', Add these to a table in Display.[EffectGroup].', self.Layer, '.Effects {Bones ={}} in unit blueprint.')
                continue
            end

            if terrainType then
                effects = terrainFX[typeGroup.Type]
            else
                effects = GetTerrainTypeEffects(fxBlockType, layer, pos, typeGroup.Type, typeSuffix)
            end
            if table.empty(effects) then
                continue
            end

            local scale = typeGroup.Scale
            if scale == 1 then
                scale = nil
            end
            local offset = typeGroup.Offset
            local offsetX, offsetY, offsetZ
            if offset then
                offsetX, offsetY, offsetZ = offset[1] or 0, offset[2] or 0, offset[3] or 0
                if offsetX == 0 and offsetY == 0 and offsetZ == 0 then
                    offset = nil
                end
            end
            for _, bone in bones do
                for _, effect in effects do
                    local emitter = CreateAttachedEmitter(self, bone, army, effect)
                    if scale then
                        emitter:ScaleEmitter(scale)
                    end
                    if offset then
                        emitter:OffsetEmitter(offsetX, offsetY, offsetZ)
                    end
                    if effectsBag then
                        TrashAdd(effectsBag, emitter)
                    end
                end
            end
        end
    end,

    ---@param self Unit
    CreateIdleEffects = function(self)
        local layer = self.Layer
        local bpTable = self.Blueprint.Display.IdleEffects

        if bpTable[layer] and bpTable[layer].Effects then
            self:CreateTerrainTypeEffects(bpTable[layer].Effects, 'FXIdle',  layer, nil, self.IdleEffectsBag)
        end
    end,

    ---@param self Unit
    ---@param EffectsBag TrashBag
    ---@param TypeSuffix string
    ---@param TerrainType string
    ---@return boolean
    CreateMovementEffects = function(self, EffectsBag, TypeSuffix, TerrainType)
        local layer = self.Layer
        local bpTable = self.Blueprint.Display.MovementEffects

        if bpTable[layer] then
            bpTable = bpTable[layer]
            local effectTypeGroups = bpTable.Effects

            if not effectTypeGroups or (effectTypeGroups and (table.empty(effectTypeGroups))) then
                if not self.Footfalls and bpTable.Footfall then
                    WARN('*WARNING: No movement effect groups defined for unit ', repr(self.UnitId), ', Effect groups with bone lists must be defined to play movement effects. Add these to the Display.MovementEffects', layer, '.Effects table in unit blueprint. ')
                end
                return false
            end

            if bpTable.CameraShake then
                self.CamShakeT1 = self:ForkThread(self.MovementCameraShakeThread, bpTable.CameraShake)
            end

            self:CreateTerrainTypeEffects(effectTypeGroups, 'FXMovement', layer, TypeSuffix, EffectsBag, TerrainType)
        end
    end,

    ---@param self Unit
    ---@param new string
    ---@param old string
    CreateLayerChangeEffects = function(self, new, old)
        local key = old..new
        local bpTable = self.Blueprint.Display.LayerChangeEffects[key]

        if bpTable then
            self:CreateTerrainTypeEffects(bpTable.Effects, 'FXLayerChange', key)
        end
    end,

    ---@param self Unit
    ---@param new string
    ---@param old string
    CreateMotionChangeEffects = function(self, new, old)
        local key = self.Layer..old..new
        local bpTable = self.Blueprint.Display.MotionChangeEffects[key]

        if bpTable then
            self:CreateTerrainTypeEffects(bpTable.Effects, 'FXMotionChange', key)
        end
    end,

    ---@param self Unit
    DestroyMovementEffects = function(self)
        -- Destroy the stored movement effects
        if self.MovementEffectsBag then
            TrashDestroy(self.MovementEffectsBag)
        end

        -- Clean up any camera shake going on.
        local bpTable = self.Blueprint.Display.MovementEffects
        local layer = self.Layer
        if self.CamShakeT1 then
            KillThread(self.CamShakeT1)

            local shake = bpTable[layer].CameraShake
            if shake and shake.Radius and shake.MaxShakeEpicenter and shake.MinShakeAtRadius then
                self:ShakeCamera(shake.Radius, shake.MaxShakeEpicenter * 0.25, shake.MinShakeAtRadius * 0.25, 1)
            end
        end
    end,

    ---@param self Unit
    DestroyTopSpeedEffects = function(self)
        local topSpeedEffectsBag = self.TopSpeedEffectsBag
        if topSpeedEffectsBag then
            TrashDestroy(topSpeedEffectsBag)
        end
    end,

    ---@param self Unit
    DestroyIdleEffects = function(self)
        local idleEffectsBag = self.IdleEffectsBag
        if idleEffectsBag then
            TrashDestroy(idleEffectsBag)
        end
    end,

    ---@param self Unit
    ---@param motionState string
    ---@return boolean
    UpdateBeamExhaust = function(self, motionState)
        local beamExhaust = self.Blueprint.Display.MovementEffects.BeamExhaust

        if not beamExhaust then
            return false
        end

        if motionState == 'Idle' then
            if self.BeamExhaustCruise  then
                self:DestroyBeamExhaust()
            end
            if self.BeamExhaustIdle and TrashEmpty(self.BeamExhaustEffectsBag) and beamExhaust.Idle ~= false then
                self:CreateBeamExhaust(beamExhaust, self.BeamExhaustIdle)
            end
        elseif motionState == 'Cruise' then
            if self.BeamExhaustIdle and self.BeamExhaustCruise then
                self:DestroyBeamExhaust()
            end
            if self.BeamExhaustCruise and beamExhaust.Cruise ~= false then
                self:CreateBeamExhaust(beamExhaust, self.BeamExhaustCruise)
            end
        elseif motionState == 'Landed' then
            if not beamExhaust.Landed then
                self:DestroyBeamExhaust()
            end
        end
    end,

    ---@param self Unit
    ---@param bpTable UnitBlueprint
    ---@param beamBP WeaponBlueprint
    ---@return boolean
    CreateBeamExhaust = function(self, bpTable, beamBP)
        local effectBones = bpTable.Bones
        if not effectBones or (effectBones and table.empty(effectBones)) then
            WARN('*WARNING: No beam exhaust effect bones defined for unit ', repr(self.UnitId), ', Effect Bones must be defined to play beam exhaust effects. Add these to the Display.MovementEffects.BeamExhaust.Bones table in unit blueprint.')
            return false
        end
        for kb, vb in effectBones do
            TrashAdd(self.BeamExhaustEffectsBag, CreateBeamEmitterOnEntity(self, vb, self.Army, beamBP))
        end
    end,

    ---@param self Unit
    DestroyBeamExhaust = function(self)
        TrashDestroy(self.BeamExhaustEffectsBag)
    end,

    ---@param self Unit
    ---@param tableData table
    ---@return boolean
    CreateContrails = function(self, tableData)
        local effectBones = tableData.Bones
        if not effectBones or (effectBones and table.empty(effectBones)) then
            WARN('*WARNING: No contrail effect bones defined for unit ', repr(self.UnitId), ', Effect Bones must be defined to play contrail effects. Add these to the Display.MovementEffects.Air.Contrail.Bones table in unit blueprint. ')
            return false
        end
        local ZOffset = tableData.ZOffset or 0.0
        for ke, ve in self.ContrailEffects do
            for kb, vb in effectBones do
                TrashAdd(self.TopSpeedEffectsBag, CreateTrail(self, vb, self.Army, ve):SetEmitterParam('POSITION_Z', ZOffset))
            end
        end
    end,

    ---@param self Unit
    ---@param camShake any
    MovementCameraShakeThread = function(self, camShake)
        local radius = camShake.Radius or 5.0
        local maxShakeEpicenter = camShake.MaxShakeEpicenter or 1.0
        local minShakeAtRadius = camShake.MinShakeAtRadius or 0.0
        local interval = camShake.Interval or 10.0
        if interval ~= 0.0 then
            while true do
                self:ShakeCamera(radius, maxShakeEpicenter, minShakeAtRadius, interval)
                WaitSeconds(interval)
            end
        end
    end,

    ---@param self Unit
    ---@param footfall boolean
    ---@return boolean
    CreateFootFallManipulators = function(self, footfall)
        if not footfall.Bones or (footfall.Bones and (table.empty(footfall.Bones))) then
            WARN('*WARNING: No footfall bones defined for unit ', repr(self.UnitId), ', ', 'these must be defined to animation collision detector and foot plant controller')
            return false
        end

        self.Detector = CreateCollisionDetector(self)
        self.Trash:Add(self.Detector)
        for _, v in footfall.Bones do
            self.Detector:WatchBone(v.FootBone)
            if v.FootBone and v.KneeBone and v.HipBone then
                CreateFootPlantController(self, v.FootBone, v.KneeBone, v.HipBone, v.StraightLegs or true, v.MaxFootFall or 0):SetPrecedence(10)
            end
        end

        return true
    end,

    ---@param self Unit
    ---@param label string
    ---@return Weapon
    GetWeaponClass = function(self, label)
        return self.Weapons[label] or Weapon
    end,

    -- Return the total time in seconds, cost in energy, and cost in mass to build the given target type.
    ---@param self Unit
    ---@param target_bp UnitBlueprint
    ---@return number
    GetBuildCosts = function(self, target_bp)
        return Game.GetConstructEconomyModel(self, target_bp.Economy)
    end,

    ---@param self Unit
    ---@param time_mult number
    SetReclaimTimeMultiplier = function(self, time_mult)
        self.ReclaimTimeMultiplier = time_mult
    end,

    --- Returns the duration, energy cost, and mass cost to reclaim the given
    --- target when it has full health. The engine then factors in the
    --- progression.
    ---
    --- Is called each tick to recompute the costs.
    ---@param self Unit
    ---@param target Unit | Prop
    ---@return number time      # time in seconds
    ---@return number energy    # only applies to props
    ---@return number mass      # only applies to props
    GetReclaimCosts = function(self, target)
        if target.IsProp then
            return target:GetReclaimCosts(self)
        end

        if target.IsUnit then
            local buildrate = self:GetBuildRate()
            local reclaimTimeMultiplier = self.ReclaimTimeMultiplier or 1
            local targetBlueprintEconomy = target.Blueprint.Economy
            local buildEnergyCosts = targetBlueprintEconomy.BuildCostEnergy
            local buildMassCosts = targetBlueprintEconomy.BuildCostMass

            -- find largest build cost value, this is always energy? :)
            local costs = buildEnergyCosts
            if buildMassCosts > buildEnergyCosts then
                costs = buildMassCosts
            end

            duration = (0.1 * costs * reclaimTimeMultiplier) / buildrate
            if duration < 0 then
                duration = 1
            end

            -- for units the energy and mass fields are ignored but they do need to exist or the engine burps
            return duration, 0, 0
        end

        return 0, 0, 0
    end,

    --- Multiplies the time it takes to capture a unit, defaults to 1.0. Often
    --- used by campaign events.
    ---@param self Unit
    ---@param captureTimeMultiplier number
    SetCaptureTimeMultiplier = function(self, captureTimeMultiplier)
        self.CaptureTimeMultiplier = captureTimeMultiplier
    end,

    --- Return the total time in seconds, cost in energy, and cost in mass to 
    --- capture the given target. The function is called for all attached units 
    --- to the target, the results are combined by the engine.
    ---@param self Unit
    ---@param target Unit
    ---@return number time      # time in seconds
    ---@return number energy
    ---@return number zero
    GetCaptureCosts = function(self, target)
        -- if the target is not a unit then we ignore it
        if not target.IsUnit then
            return 0, 0, 0
        end

        -- if the target is not fully built then we ignore it, applies to factories
        if target:GetFractionComplete() < 1.0 then
            return 0, 0, 0
        end

        -- compute capture costs
        local targetBlueprintEconomy = target.Blueprint.Economy
        local time = ((targetBlueprintEconomy.BuildTime or 10) / self:GetBuildRate()) / 2
        local energy = targetBlueprintEconomy.BuildCostEnergy or 100
        time = time * (self.CaptureTimeMultiplier or 1)
        if time < 0 then
            time = 1
        end

        return time, energy, 0
    end,

    ---@param self Unit
    ---@return number
    GetHealthPercent = function(self)
        local health = self:GetHealth()
        local maxHealth = self.Blueprint.Defense.MaxHealth
        return health / maxHealth
    end,

    ---@param self Unit
    ---@param bone Bone
    ---@return boolean
    ValidateBone = function(self, bone)
        if self:IsValidBone(bone) then
            return true
        end
        error('*ERROR: Trying to use the bone, ' .. bone .. ' on unit ' .. self.UnitId .. ' and it does not exist in the model.', 2)

        return false
    end,

    ---@param self Unit
    ---@param target_bp UnitBlueprint
    ---@return boolean
    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,

    -------------------------------------------------------------------------------------------
    -- Sound
    -------------------------------------------------------------------------------------------

    --- Plays a sound using the unit as a source. Returns true if successful, false otherwise
    ---@param self Unit A unit
    ---@param sound string A string identifier that represents the sound to be played.
    ---@return boolean
    PlayUnitSound = function(self, sound)
        local audio = self.Blueprint.Audio[sound]
        if not audio then 
            return false
        end

        (self.SoundEntity or self):PlaySound(audio)
        return true
    end,

    --- Plays an ambient sound using the unit as a source. Returns true if successful, false otherwise
    ---@param self Unit
    ---@param sound string
    ---@return boolean
    PlayUnitAmbientSound = function(self, sound)
        local audio = self.Blueprint.Audio[sound]
        if not audio then 
            return false
        end

        (self.SoundEntity or self):SetAmbientSound(audio, nil)
        return true 
    end,

    --- Stops playing the ambient sound that is currently being played.
    ---@param self Unit
    ---@return boolean
    StopUnitAmbientSound = function(self)
        (self.SoundEntity or self):SetAmbientSound(nil, nil)
        return true
    end,

    -------------------------------------------------------------------------------------------
    -- UNIT CALLBACKS
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param fn function
    ---@param type string
    AddUnitCallback = function(self, fn, type)
        self.EventCallbacks[type] = self.EventCallbacks[type] or { }
        table.insert(self.EventCallbacks[type], fn)
    end,

    ---@param self Unit
    ---@param type string
    ---@param param any
    DoUnitCallbacks = function(self, type, param)
        if self.EventCallbacks[type] then
            for num, cb in self.EventCallbacks[type] do
                cb(self, param)
            end
        end
    end,

    --- Adds a callback for the `OnTransportAttach` event
    ---@param self Unit
    ---@param fn fun(transport: Unit, attachBone: Bone,  attachedUnit: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnTransportAttachCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnTransportAttach'] or { }
        self.EventCallbacks['OnTransportAttach'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnTransportDetach` event
    ---@param self Unit
    ---@param fn fun(transport: Unit, attachBone: Bone,  deattachedUnit: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnTransportDetachCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnTransportDetach'] or { }
        self.EventCallbacks['OnTransportDetach'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnTransportOrdered` event
    ---@param self Unit
    ---@param fn fun(transport: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnTransportOrderedCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnTransportOrdered'] or { }
        self.EventCallbacks['OnTransportOrdered'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnTransportAborted` event
    ---@param self Unit
    ---@param fn fun(transport: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnTransportAbortedCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnTransportAborted'] or { }
        self.EventCallbacks['OnTransportAborted'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnAttachedKilled` event
    ---@param self Unit
    ---@param fn fun(transport: Unit, killedUnit: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnAttachedKilledCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnAttachedKilled'] or { }
        self.EventCallbacks['OnAttachedKilled'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnStartTransportLoading` event
    ---@param self Unit
    ---@param fn fun(transport: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnStartTransportLoadingCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnStartTransportLoading'] or { }
        self.EventCallbacks['OnStartTransportLoading'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    --- Adds a callback for the `OnStopTransportLoading` event
    ---@param self Unit
    ---@param fn fun(transport: Unit)
    ---@param id string | nil       # if provided, stores the function using the identifier as key
    AddOnStopTransportLoadingCallback = function(self, fn, id)
        local callbacks = self.EventCallbacks['OnStopTransportLoading'] or { }
        self.EventCallbacks['OnStopTransportLoading'] = callbacks

        if id then
            callbacks[id] = fn
        else
            table.insert(callbacks, fn)
        end
    end,

    ---@param self Unit
    ---@param fn function
    AddProjectileDamagedCallback = function(self, fn)
        self:AddUnitCallback(fn, "ProjectileDamaged")
    end,

    ---@param self Unit
    ---@param cbOldUnit Unit
    ---@param cbNewUnit Unit
    AddOnCapturedCallback = function(self, cbOldUnit, cbNewUnit)
        if cbOldUnit then
            self:AddUnitCallback(cbOldUnit, 'OnCaptured')
        end
        if cbNewUnit then
            self:AddUnitCallback(cbNewUnit, 'OnCapturedNewUnit')
        end
    end,

    --- Add a callback to be invoked when this unit starts building another. The unit being built is
    --- passed as a parameter to the callback function.
    ---@param self Unit
    ---@param fn function
    AddOnStartBuildCallback = function(self, fn)
        self:AddUnitCallback(fn, "OnStartBuild")
    end,

    ---@param self Unit
    ---@param unit Unit
    DoOnStartBuildCallbacks = function(self, unit)
        self:DoUnitCallbacks("OnStartBuild", unit)
    end,

    ---@param self Unit
    DoOnFailedToBuildCallbacks = function(self)
        self:DoUnitCallbacks("OnFailedToBuild")
    end,

    ---@param self Unit
    ---@param fn function
    ---@param category EntityCategory
    AddOnUnitBuiltCallback = function(self, fn, category)
        self.EventCallbacks.OnUnitBuilt = self.EventCallbacks.OnUnitBuilt or { }
        table.insert(self.EventCallbacks['OnUnitBuilt'], {category=category, cb=fn})
    end,

    ---@param self Unit
    ---@param unit Unit
    DoOnUnitBuiltCallbacks = function(self, unit)
        if self.EventCallbacks.OnUnitBuilt then 
            for _, v in self.EventCallbacks.OnUnitBuilt do
                if unit and not unit.Dead and EntityCategoryContains(v.category, unit) then
                    v.cb(self, unit)
                end
            end
        end
    end,

    ---@param self Unit
    ---@param fn function
    RemoveCallback = function(self, fn)
        for k, v in self.EventCallbacks do
            if type(v) == "table" then
                for kcb, vcb in v do
                    if vcb == fn then
                        v[kcb] = nil
                    end
                end
            end
        end
    end,

    ---@param self Unit
    ---@param fn function
    ---@param amount number
    ---@param repeatNum number
    AddOnDamagedCallback = function(self, fn, amount, repeatNum)
        local num = amount or -1
        repeatNum = repeatNum or 1
        self.EventCallbacks.OnDamaged = self.EventCallbacks.OnDamaged or { }
        table.insert(self.EventCallbacks.OnDamaged, {Func = fn, Amount=num, Called=0, Repeat = repeatNum})
    end,

    ---@param self Unit
    ---@param instigator Unit
    DoOnDamagedCallbacks = function(self, instigator)
        if self.EventCallbacks.OnDamaged then
            for num, callback in self.EventCallbacks.OnDamaged do
                if (callback.Called < callback.Repeat or callback.Repeat == -1) and (callback.Amount == -1 or (1 - self:GetHealthPercent() > callback.Amount)) then
                    callback.Called = callback.Called + 1
                    callback.Func(self, instigator)
                end
            end
        end
    end,

    -------------------------------------------------------------------------------------------
    -- STATES
    -------------------------------------------------------------------------------------------
    IdleState = State {
        Main = function(self)
        end,
    },

    DeadState = State {
        Main = function(self)
        end,
    },

    WorkingState = State {
        Main = function(self)
        end,

        OnWorkEnd = function(self, work)
            self:ClearWork()
            self:SetActiveConsumptionInactive()
            AddUnitEnhancement(self, work)
            self:CleanupEnhancementEffects(work)
            self:CreateEnhancement(work)
            self:PlayUnitSound('EnhanceEnd')
            self:StopUnitAmbientSound('EnhanceLoop')
            self:EnableDefaultToggleCaps()
            ChangeState(self, self.IdleState)
        end,
    },

    -------------------------------------------------------------------------------------------
    -- BUFFS
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param buffTable BlueprintBuff[]
    ---@param PosEntity Vector
    AddBuff = function(self, buffTable, PosEntity)
        local bt = buffTable.BuffType
        if not bt then
            error('*ERROR: Tried to add a unit buff in unit.lua but got no buff table.  Wierd.', 1)
            return
        end

        -- When adding debuffs we have to make sure that we check for permissions
        local category = buffTable.TargetAllow and ParseEntityCategory(buffTable.TargetAllow) or categories.ALLUNITS
        if buffTable.TargetDisallow then
            category = category - ParseEntityCategory(buffTable.TargetDisallow)
        end

        if bt == 'STUN' then
            local targets
            if buffTable.Radius and buffTable.Radius > 0 then
                -- If the radius is bigger than 0 then we will use the unit as the center of the stun blast
                targets = utilities.GetTrueEnemyUnitsInSphere(self, PosEntity or self:GetPosition(), buffTable.Radius, category)
            else
                -- The buff will be applied to the unit only
                if EntityCategoryContains(category, self) then
                    targets = {self}
                end
            end

            -- Exclude things currently flying around
            for _, target in targets or {} do
                if target.Layer ~= 'Air' then
                    target:SetStunned(buffTable.Duration or 1)
                end
            end
        elseif bt == 'MAXHEALTH' then
            self:SetMaxHealth(self:GetMaxHealth() + (buffTable.Value or 0))
        elseif bt == 'HEALTH' then
            self:AdjustHealth(self, buffTable.Value or 0)
        elseif bt == 'SPEEDMULT' then
            self:SetSpeedMult(buffTable.Value or 0)
        elseif bt == 'MAXFUEL' then
            self:SetFuelUseTime(buffTable.Value or 0)
        elseif bt == 'FUELRATIO' then
            self:SetFuelRatio(buffTable.Value or 0)
        elseif bt == 'HEALTHREGENRATE' then
            self:SetRegenRate(buffTable.Value or 0)
        end
    end,

    ---@param self Unit
    ---@param buffTable BlueprintBuff[]
    ---@param weapon Weapon
    AddWeaponBuff = function(self, buffTable, weapon)
        local bt = buffTable.BuffType
        if not bt then
            error('*ERROR: Tried to add a weapon buff in unit.lua but got no buff table.  Wierd.', 1)
            return
        end

        if bt == 'RATEOFFIRE' then
            weapon:ChangeRateOfFire(buffTable.Value or 1)
        elseif bt == 'TURRETYAWSPEED' then
            weapon:SetTurretYawSpeed(buffTable.Value or 0)
        elseif bt == 'TURRETPITCHSPEED' then
            weapon:SetTurretPitchSpeed(buffTable.Value or 0)
        elseif bt == 'DAMAGE' then
            weapon:AddDamageMod(buffTable.Value or 0)
        elseif bt == 'MAXRADIUS' then
            weapon:ChangeMaxRadius(buffTable.Value or weapon:GetBlueprint().MaxRadius)
        elseif bt == 'FIRINGRANDOMNESS' then
            weapon:SetFiringRandomness(buffTable.Value or 0)
        else
            self:AddBuff(buffTable)
        end
    end,

    ---@param self Unit
    ---@param value number
    SetRegen = function(self, value)
        self:SetRegenRate(value)
        self:UpdateStat("HitpointsRegeneration", value)
    end,

    -------------------------------------------------------------------------------------------
    -- SHIELDS
    -------------------------------------------------------------------------------------------
    ---@param self Unit
    ---@param bpShield UnitBlueprintDefenseShield 
    CreateShield = function(self, bpShield)
        -- Copy the shield template so we don't alter the blueprint table.
        local bpShield = table.deepcopy(bpShield)
        self:DestroyShield()

        if bpShield.PersonalShield then
            self.MyShield = PersonalShield(bpShield, self)
        elseif bpShield.AntiArtilleryShield then
            self.MyShield = AntiArtilleryShield(bpShield, self)
        elseif bpShield.PersonalBubble then
            self.MyShield = PersonalBubble(bpShield, self)
        elseif bpShield.TransportShield then
            self.MyShield = TransportShield(bpShield, self)
        else
            self.MyShield = Shield(bpShield, self)
        end

        self:SetFocusEntity(self.MyShield)
        self.Trash:Add(self.MyShield)
    end,

    ---@param self Unit
    EnableShield = function(self)
        self:SetScriptBit('RULEUTC_ShieldToggle', true)
        if self.MyShield then
            self.MyShield:TurnOn()
        end
    end,

    ---@param self Unit
    DisableShield = function(self)
        self:SetScriptBit('RULEUTC_ShieldToggle', false)
        if self.MyShield then
            self.MyShield:TurnOff()
        end
    end,

    ---@param self Unit
    DestroyShield = function(self)
        if self.MyShield then
            self:ClearFocusEntity()
            self.MyShield:Destroy()
            self.MyShield = nil
        end
    end,

    ---@param self Unit
    ---@return boolean
    ShieldIsOn = function(self)
        if self.MyShield then
            return self.MyShield:IsOn()
        end
    end,

    ---@param self Unit
    ---@return string
    GetShieldType = function(self)
        if self.MyShield then
            return self.MyShield.ShieldType or 'Unknown'
        end
        return 'None'
    end,

    ---@param self Unit
    ---@param instigator Unit
    ---@param spillingUnit Unit
    ---@param damage number
    ---@param type string
    OnAdjacentBubbleShieldDamageSpillOver = function(self, instigator, spillingUnit, damage, type)
        if self.MyShield then
            self.MyShield:OnAdjacentBubbleShieldDamageSpillOver(instigator, spillingUnit, damage, type)
        end
    end,

    -------------------------------------------------------------------------------------------
    -- TRANSPORTING
    -------------------------------------------------------------------------------------------

    ---@param self Unit
    ---@return integer
    GetTransportClass = function(self)
        return self.Blueprint.Transport.TransportClass or 1
    end,

    ---@param self Unit
    ---@param transport Unit
    ---@param bone Bone
    OnStartTransportBeamUp = function(self, transport, bone)
        self.TransportBeamEffectsBag = self.TransportBeamEffectsBag or TrashBag()

        local slot = transport.slots[bone]
        if slot then
            self:GetAIBrain():OnTransportFull()
            IssueToUnitClearCommands(self)
            return
        end

        self:DestroyIdleEffects()
        self:DestroyMovementEffects()

        TrashAdd(self.TransportBeamEffectsBag, AttachBeamEntityToEntity(self, -1, transport, bone, self.Army, EffectTemplate.TTransportBeam01))
        TrashAdd(self.TransportBeamEffectsBag, AttachBeamEntityToEntity(transport, bone, self, -1, self.Army, EffectTemplate.TTransportBeam02))
        TrashAdd(self.TransportBeamEffectsBag, CreateEmitterAtBone(transport, bone, self.Army, EffectTemplate.TTransportGlow01))

        self:TransportAnimation()

        -- for AI events
        self.Brain:OnUnitStartTransportBeamUp(self, transport, bone)
    end,

    ---@param self Unit
    OnStopTransportBeamUp = function(self)
        self:DestroyIdleEffects()
        self:DestroyMovementEffects()
        TrashDestroy(self.TransportBeamEffectsBag)

        -- Reset weapons to ensure torso centres and unit survives drop
        for i = 1, self.WeaponCount do
            self.WeaponInstances[i]:ResetTarget()
        end

        -- for AI events
        self.Brain:OnUnitStoptransportBeamUp(self)
    end,

    ---@param self Unit
    ---@param bool boolean
    MarkWeaponsOnTransport = function(self, bool)
        for i = 1, self.WeaponCount do
            self.WeaponInstances[i]:SetOnTransport(bool)
        end
    end,

    ---@param self Unit
    ---@param loading boolean
    OnStorageChange = function(self, loading)
        self:MarkWeaponsOnTransport(loading)

        if loading then
            self:HideBone(0, true)
        else
            self:ShowBone(0, true)
        end

        self.CanTakeDamage = not loading
        self:SetDoNotTarget(loading)
        self:SetReclaimable(not loading)
        self:SetCapturable(not loading)
    end,

    --- Called from the perspective of the unit that is added to the storage of another unit
    ---@param self Unit
    ---@param carrier Unit
    OnAddToStorage = function(self, carrier)
        self:OnStorageChange(true)

        if carrier.DisableIntelOfCargo and (not IsDestroyed(self)) then
            self:DisableUnitIntel('Cargo')
            if self.MaintenanceConsumption then
                self:SetMaintenanceConsumptionInactive()
                self.EnableConsumptionWhenRemovedFromStorage = true
            end

            -- look at additional layer of storage / cargo (looking at you, Stinger)
            if EntityCategoryContains(categories.TRANSPORTATION, self) then
                for _, attached in self:GetCargo() do
                    attached:DisableUnitIntel('Cargo')
                    if attached.MaintenanceConsumption then
                        attached:SetMaintenanceConsumptionInactive()
                        attached.EnableConsumptionWhenRemovedFromStorage = true
                    end
                end
            end
        end

        -- for AI events
        self.Brain:OnUnitAddToStorage(self, carrier)
    end,

    --- Called from the perspective of the unit that is removed from the storage of another unit
    ---@param self Unit
    ---@param carrier Unit
    OnRemoveFromStorage = function(self, carrier)
        self:OnStorageChange(false)

        if carrier.DisableIntelOfCargo and (not IsDestroyed(self)) then
            self:EnableUnitIntel('Cargo')
            if self.EnableConsumptionWhenRemovedFromStorage then
                self:SetMaintenanceConsumptionActive()
                self.EnableConsumptionWhenRemovedFromStorage = nil
            end

            -- look at additional layer of storage / cargo (looking at you, Stinger)
            if EntityCategoryContains(categories.TRANSPORTATION, self) then
                for _, attached in self:GetCargo() do
                    attached:EnableUnitIntel('Cargo')
                    if attached.EnableConsumptionWhenRemovedFromStorage then
                        attached:SetMaintenanceConsumptionActive()
                        attached.EnableConsumptionWhenRemovedFromStorage = nil
                    end
                end
            end
        end

        -- for AI events
        self.Brain:OnUnitRemoveFromStorage(self, carrier)
    end,

    -- Animation when being dropped from a transport.
    ---@param self Unit
    ---@param rate number
    TransportAnimation = function(self, rate)
        self:ForkThread(self.TransportAnimationThread, rate)
    end,

    ---@param self Unit
    ---@param rate number
    TransportAnimationThread = function(self, rate)
        local bp = self.Blueprint.Display
        local animbp
        rate = rate or 1

        if rate < 0 and bp.TransportDropAnimation then
            animbp = bp.TransportDropAnimation
            rate = bp.TransportDropAnimationSpeed or -rate
        else
            animbp = bp.TransportAnimation
            rate = bp.TransportAnimationSpeed or rate
        end

        WaitSeconds(.5)
        if animbp then
            local animBlock = self:ChooseAnimBlock(animbp)
            if animBlock.Animation then
                if not self.TransAnimation then
                    self.TransAnimation = CreateAnimator(self)
                    self.Trash:Add(self.TransAnimation)
                end
                self.TransAnimation:PlayAnim(animBlock.Animation)
                self.TransAnimation:SetRate(rate)
                WaitFor(self.TransAnimation)
            end
        end
    end,

    -------------------------------------------------------------------------------------------
    -- TELEPORTING
    -------------------------------------------------------------------------------------------

    ---@param self Unit
    ---@param teleporter any
    ---@param location Vector
    ---@param orientation Quaternion
    OnTeleportUnit = function(self, teleporter, location, orientation)

        -- prevent cheats (teleporting while not having the upgrade)
        if not self:TestCommandCaps('RULEUCC_Teleport') then
            return
        end

        -- prevent cheats (teleport off map)
        if location[1] < 1 or location[1] > ScenarioInfo.PlayableArea[3] - 1 then
            return
        end

        -- prevent cheats (teleport off map)
        if location[3] < 1 or location[3] > ScenarioInfo.PlayableArea[4] - 1 then
            return
        end

        if self.TeleportDrain then
            RemoveEconomyEvent(self, self.TeleportDrain)
            self.TeleportDrain = nil
        end

        if self.TeleportThread then
            KillThread(self.TeleportThread)
            self.TeleportThread = nil
        end

        self:CleanupTeleportChargeEffects()
        self.TeleportThread = self:ForkThread(self.InitiateTeleportThread, teleporter, location, orientation)

        -- for AI events
        self.Brain:OnUnitTeleportUnit(self, teleporter, location, orientation)
    end,

    ---@param self Unit
    OnFailedTeleport = function(self)
        if self.TeleportDrain then
            RemoveEconomyEvent(self, self.TeleportDrain)
            self.TeleportDrain = nil
        end

        if self.TeleportThread then
            KillThread(self.TeleportThread)
            self.TeleportThread = nil
        end

        self:StopUnitAmbientSound('TeleportLoop')
        self:CleanupTeleportChargeEffects()
        self:CleanupRemainingTeleportChargeEffects()
        self:SetWorkProgress(0.0)
        self:SetImmobile(false)
        self.UnitBeingTeleported = nil

        -- for AI events
        self.Brain:OnUnitFailedTeleport(self)
    end,

    ---@param self Unit
    ---@param teleporter any
    ---@param location Vector
    ---@param orientation Quaternion
    InitiateTeleportThread = function(self, teleporter, location, orientation)
        self.UnitBeingTeleported = self
        self:SetImmobile(true)
        self:PlayUnitSound('TeleportStart')
        self:PlayUnitAmbientSound('TeleportLoop')

        local energyCost, time, teleDelay = import('/lua/shared/teleport.lua').TeleportCostFunction(self, location)

        if teleDelay then
            self.TeleportDestChargeBag = nil
            self.TeleportCybranSphere = nil  -- this fixes some "...Game object has been destroyed" bugs in EffectUtilities.lua:TeleportChargingProgress
        end

        self.TeleportDrain = CreateEconomyEvent(self, energyCost or 100, 0, time or 5, self.UpdateTeleportProgress)

        -- Create teleport charge effect + exit animation delay
        self:PlayTeleportChargeEffects(location, orientation, teleDelay)
        WaitFor(self.TeleportDrain)

        if self.TeleportDrain then
            RemoveEconomyEvent(self, self.TeleportDrain)
            self.TeleportDrain = nil
        end

        self:PlayTeleportOutEffects()
        self:CleanupTeleportChargeEffects()
        WaitSeconds(0.1)

        -- prevent cheats (teleporting after transport, teleporting without having the enhancement)
        if self:IsUnitState('Teleporting') and self:TestCommandCaps('RULEUCC_Teleport') then
            Warp(self, location, orientation)
            self:PlayTeleportInEffects()
        else
            IssueToUnitClearCommands(self)
        end

        self:SetWorkProgress(0.0)
        self:CleanupRemainingTeleportChargeEffects()

        -- Perform cooldown Teleportation FX here
        WaitSeconds(0.1)

        -- Landing Sound
        self:StopUnitAmbientSound('TeleportLoop')
        self:PlayUnitSound('TeleportEnd')
        self:SetImmobile(false)
        self.UnitBeingTeleported = nil
        self.TeleportThread = nil
    end,

    ---@param self Unit
    ---@param progress number
    UpdateTeleportProgress = function(self, progress)
        self:SetWorkProgress(progress)
        EffectUtilities.TeleportChargingProgress(self, progress)
    end,

    ---@param self Unit
    ---@param location Vector
    ---@param orientation Quaternion
    ---@param teleDelay? number
    PlayTeleportChargeEffects = function(self, location, orientation, teleDelay)
        self.TeleportFxBag = self.TeleportFxBag or TrashBag()
        EffectUtilities.PlayTeleportChargingEffects(self, location, self.TeleportFxBag, teleDelay)
    end,

    ---@param self Unit
    CleanupTeleportChargeEffects = function(self)
        self.TeleportFxBag = self.TeleportFxBag or TrashBag()
        EffectUtilities.DestroyTeleportChargingEffects(self, self.TeleportFxBag)
    end,

    ---@param self Unit
    CleanupRemainingTeleportChargeEffects = function(self)
        self.TeleportFxBag = self.TeleportFxBag or TrashBag()
        EffectUtilities.DestroyRemainingTeleportChargingEffects(self, self.TeleportFxBag)
    end,

    ---@param self Unit
    PlayTeleportOutEffects = function(self)
        self.TeleportFxBag = self.TeleportFxBag or TrashBag()
        EffectUtilities.PlayTeleportOutEffects(self, self.TeleportFxBag)
    end,

    ---@param self Unit
    PlayTeleportInEffects = function(self)
        self.TeleportFxBag = self.TeleportFxBag or TrashBag()
        EffectUtilities.PlayTeleportInEffects(self, self.TeleportFxBag)
    end,

    ---@param self Unit
    ---@param transport Unit
    ---@param bone Bone
    OnAttachedToTransport = function(self, transport, bone)
        self:MarkWeaponsOnTransport(true)
        if self:ShieldIsOn() or self.MyShield.Charging then

            local shield = self.MyShield
            if shield and not (shield.SkipAttachmentCheck or shield.RemainEnabledWhenAttached) then
                self:DisableShield()
            end

            self:DisableDefaultToggleCaps()

        end
        self:DoUnitCallbacks('OnAttachedToTransport', transport, bone)

        -- for AI events
        self.Brain:OnUnitAttachedToTransport(self, transport, bone)
    end,

    ---@param self Unit
    ---@param transport Unit
    ---@param bone Bone
    OnDetachedFromTransport = function(self, transport, bone)
        self.Trash:Add(ForkThread(self.OnDetachedFromTransportThread, self, transport, bone))
        self:MarkWeaponsOnTransport(false)
        self:EnableShield()
        self:EnableDefaultToggleCaps()
        self:TransportAnimation(-1)
        self:DoUnitCallbacks('OnDetachedFromTransport', transport, bone)

        -- for AI events
        self.Brain:OnUnitDetachedFromTransport(self, transport, bone)
    end,

    OnDetachedFromTransportThread = function(self, transport, bone)
        if IsDestroyed(transport) then
            self:Destroy()
        end
    end,


    --- Called by the engine when the auto construction mode (usually for missiles) is turned on
    ---@param self Unit
    OnAutoModeOn = function(self)
        self.AutoModeEnabled = true
    end,

    --- Called by the engine when the auto construction mode (usually for missiles) is turned off
    ---@param self Unit
    OnAutoModeOff = function(self)
        self.AutoModeEnabled = false
    end,

    --- Called by the engine when a ferry point is set for this unit
    ---@param self Unit
    OnFerryPointSet = function(self)
    end,

    -- Utility Functions
    ---@param self Unit
    ---@param trigger any
    ---@param source any
    SendNotifyMessage = function(self, trigger, source)
        local focusArmy = GetFocusArmy()
        if focusArmy == -1 or focusArmy == self.Army then
            local id
            local unitType
            local category

            if not source then
                local bp = self.Blueprint
                if bp.CategoriesHash.RESEARCH then
                    unitType = string.lower('research' .. self.Blueprint.LayerCategory .. self.Blueprint.TechCategory)
                    category = 'tech'
                elseif EntityCategoryContains(categories.NUKE * categories.STRUCTURE - categories.EXPERIMENTAL, self) then -- Ensure to exclude Yolona Oss, which gets its own message
                    unitType = 'nuke'
                    category = 'other'
                elseif EntityCategoryContains(categories.TECH3 * categories.STRUCTURE * categories.ARTILLERY, self) then
                    unitType = 'arty'
                    category = 'other'
                elseif self.Blueprint.TechCategory == 'EXPERIMENTAL' then
                    unitType = bp.BlueprintId
                    category = 'experimentals'
                else
                    return
                end
            else -- We are being called from the Enhancements chain (ACUs)
                id = self.EntityId
                category = string.lower(self.Blueprint.FactionCategory)
            end

            if trigger == 'transferred' then
                if not Sync.EnhanceMessage then return end
                for index, msg in Sync.EnhanceMessage do
                    if msg.source == (source or unitType) and msg.trigger == 'completed' and msg.category == category and msg.id == id then
                        table.remove(Sync.EnhanceMessage, index)
                        break
                    end
                end
            else
                if not Sync.EnhanceMessage then Sync.EnhanceMessage = {} end
                local message = {source = source or unitType, trigger = trigger, category = category, id = id, army = self.Army}
                table.insert(Sync.EnhanceMessage, message)
            end
        end
    end,

    ---@param self Unit
    ---@param count number
    GiveNukeSiloAmmo = function(self, count)
        cUnit.GiveNukeSiloAmmo(self, count)
    end,

    ---@param self Unit
    ---@param fraction number
    GiveNukeSiloBlocks = function(self, fraction)
        if fraction < 0 or fraction > 1 then
            return
        end

        local buildRate = self.Blueprint.Economy.BuildRate
        if not buildRate then
            return
        end

        local buildTime = self:GetWeapon(1):GetProjectileBlueprint().Economy.BuildTime
        if not buildTime then
            return
        end

        local total = 10 * (buildTime / buildRate)
        local blocks = math.ceil(fraction * total)
        cUnit.GiveNukeSiloAmmo(self, blocks, true)
    end,

    --- Updates a statistic that you can retrieve on the UI side using `userunit:GetStat`. See `unit:UpdateStat` for an alternative
    ---@deprecated
    ---@param self Unit
    ---@param key string
    ---@param value number
    SetStat = function(self, key, value)
        self:UpdateStat(key, value)
    end,

    --- Updates a statistic that you can retrieve on the UI side using `userunit:GetStat`.
    --- Relies on an assembly patch to be functional, without it this setup causes the game to crash.
    ---@param self Unit
    ---@param key string
    ---@param value number
    UpdateStat = function(self, key, value)
        -- With thanks to 4z0t the `SetStat` function no longer hard-crashes when the value doesn't exist. Instead, it returns 'true' 
        -- when the stat doesn't exist. If it doesn't exist then we can use `GetStat` to initialize it. This makes no sense, therefore
        -- we have this new function to hide the magic
        local needsSetup = cUnit.SetStat(self, key, value)
        if needsSetup then
            cUnit.GetStat(self, key, value)
            cUnit.SetStat(self, key, value)
        end
    end,

    ---@param self Unit
    ---@return UnitCommand[]
    GetCommandQueue = function(self)
        local queue = cUnit.GetCommandQueue(self)
        if queue then
            for k, order in queue do
                if order.targetId then
                    local target = GetEntityById(order.targetId)
                    if target and IsEntity(target) then
                        order.target = target
                        -- take position of the entity, used to sort the units
                        order.x, order.y, order.z = moho.entity_methods.GetPositionXYZ(target)
                    end
                end
            end
        end

        return queue
    end,

    --- Stuns the unit, if it isn't set to be immune by the flag unit.ImmuneToStun
    ---@param self Unit A reference to the unit itself, automatically set when you use the ':' notation
    ---@param duration number Stun duration in seconds
    SetStunned = function(self, duration)
        if not self.ImmuneToStun then
            cUnit.SetStunned(self, duration)
        end
    end,

    --- Determines whether or not this unit is actively consuming resources. There is an engine bug
    --- that allows you to gain free resources by reverting the resources of the last tick to the
    --- user when it is called with 'false' while the consumption is already set to 'false'
    ---@param self Unit A reference to the unit itself, automatically set when you use the ':' notation
    ---@param flag boolean A flag to determine whether our consumption should be active
    SetConsumptionActive = function(self, flag)
        local engineFlags = self.EngineFlags
        if not engineFlags then
            engineFlags = { }
            self.EngineFlags = engineFlags
        end

        if engineFlags['SetConsumptionActive'] ~= flag then
            cUnit.SetConsumptionActive(self, flag)
            engineFlags['SetConsumptionActive'] = flag
        end
    end,

    --- A work around because the engine function `TestCommandCaps` does not appear to be functional. Is
    --- in particular used to prevent cheats related to teleportation. Stores the added command capabilities
    --- in a table called `EngineCommandCap`, in the unit table.
    ---@param self Unit
    ---@param capName CommandCap
    AddCommandCap = function(self, capName)
        if not self.EngineCommandCap then
            self.EngineCommandCap = { }
        end

        self.EngineCommandCap[capName] = true
        cUnit.AddCommandCap(self, capName)
    end,

    --- A work around because the engine function `TestCommandCaps` does not appear to be functional. Is
    --- in particular used to prevent cheats related to teleportation.
    ---@param self Unit
    ---@param capName CommandCap
    RemoveCommandCap = function(self, capName)
        if self.EngineCommandCap then
            self.EngineCommandCap[capName] = nil
        end

        cUnit.RemoveCommandCap(self, capName)
    end,

    --- A work around because the engine function `TestCommandCaps` does not appear to be functional. Is
    --- in particular used to prevent cheats related to teleportation.
    ---@param self Unit
    ---@param capName CommandCap
    TestCommandCaps = function(self, capName)
        return (self.EngineCommandCap and self.EngineCommandCap[capName]) or cUnit.TestCommandCaps(self, capName)
    end,


    --- Determines the upgrade animation to use. Allows you to manage units (by hooking) that can upgrade to
    --- more than just one unit type, as an example tech 1 factories that can become HQs or
    --- support factories.
    ---@param self Unit A reference to the unit itself, automatically set when you use the ':' notation
    ---@param unitBeingBuilt Unit A flag to determine whether our consumption should be active
    GetUpgradeAnimation = function(self, unitBeingBuilt)
        local display = self.Blueprint.Display
        if display.AnimationUpgradeTable and display.AnimationUpgradeTable[unitBeingBuilt.Blueprint.BlueprintId] then
            return display.AnimationUpgradeTable[unitBeingBuilt.Blueprint.BlueprintId]
        end

        return display.AnimationUpgrade
    end,

    --- Called when a missile launched by this unit is intercepted
    ---@param self Unit
    ---@param target Vector
    ---@param defense Unit Requires an `IsDestroyed` check as the defense may have been destroyed when the missile is intercepted
    ---@param position Vector Location where the missile got intercepted
    OnMissileIntercepted = function(self, target, defense, position)
        -- try and run callbacks
        if self.EventCallbacks['OnMissileIntercepted'] then
            for k, callback in self.EventCallbacks['OnMissileIntercepted'] do
                local ok, msg = pcall(callback, target, defense, position)
                if not ok then
                    WARN("OnMissileIntercepted callback triggered an error:")
                    WARN(msg)
                end
            end
        end

        self.Brain:OnUnitMissileIntercepted(self, target, defense, position)
    end,


    --- Called when a missile launched by this unit hits a shield
    ---@param self Unit
    ---@param target Vector
    ---@param shield Unit  Requires an `IsDestroyed` check when using as the shield may have been destroyed when the missile impacts
    ---@param position Vector Location where the missile hit the shield
    OnMissileImpactShield = function(self, target, shield, position)
        -- try and run callbacks
        if self.EventCallbacks['OnMissileImpactShield'] then
            for k, callback in self.EventCallbacks['OnMissileImpactShield'] do
                local ok, msg = pcall(callback, target, shield, position)
                if not ok then
                    WARN("OnMissileImpactShield callback triggered an error:")
                    WARN(msg)
                end
            end
        end

        self.Brain:OnUnitMissileImpactShield(self, target, shield, position)
    end,

    --- Called when a missile launched by this unit hits the terrain, note that this can be the same location as the target
    ---@param self Unit
    ---@param target Vector 
    ---@param position Vector Location where the missile hit the terrain
    OnMissileImpactTerrain = function(self, target, position)
        -- try and run callbacks
        if self.EventCallbacks['OnMissileImpactTerrain'] then
            for k, callback in self.EventCallbacks['OnMissileImpactTerrain'] do
                local ok, msg = pcall(callback, self, target, position)
                if not ok then
                    WARN("OnMissileImpactTerrain callback triggered an error:")
                    WARN(msg)
                end
            end
        end

        -- for AI events
        self.Brain:OnUnitMissileImpactTerrain(self, target, position)
    end,

    --- Add a callback when a missile launched by this unit is intercepted
    ---@param self Unit
    ---@param callback function<Vector, Unit, Vector>
    AddMissileInterceptedCallback = function(self, callback)
        self.EventCallbacks['OnMissileIntercepted'] = self.EventCallbacks['OnMissileIntercepted'] or { }
        table.insert(self.EventCallbacks['OnMissileIntercepted'], callback)
    end,

    --- Add a callback when a missile launched by this unit hits a shield
    ---@param self Unit
    ---@param callback function<Vector, Unit, Vector>
    AddMissileImpactShieldCallback = function(self, callback)
        self.EventCallbacks['OnMissileImpactShield'] = self.EventCallbacks['OnMissileImpactShield'] or { }
        table.insert(self.EventCallbacks['OnMissileImpactShield'], callback)
    end,

    --- Add a callback when a missile launched by this unit hits the terrain, note that this can be the same location as the target
    ---@param self Unit
    ---@param callback function<Vector, Vector>
    AddMissileImpactTerrainCallback = function(self, callback)
        self.EventCallbacks['OnMissileImpactTerrain'] = self.EventCallbacks['OnMissileImpactTerrain'] or { }
        table.insert(self.EventCallbacks['OnMissileImpactTerrain'], callback)
    end,

    --- Various callback-like functions

    -- Called when the C function unit.SetConsumptionActive is called
    ---@param self Unit
    OnConsumptionActive = function(self)
        -- for AI events
        self.Brain:OnUnitConsumptionActive(self)
    end,

    ---@param self Unit
    OnConsumptionInActive = function(self) 
        -- for AI events
        self.Brain:OnUnitConsumptionInActive(self)
    end,

    -- Called when the C function unit.SetProductionActive is called
    OnProductionActive = function(self)
        -- for AI events
        self.Brain:OnUnitProductionActive(self)
    end,

    OnProductionInActive = function(self)
        -- for AI events
        self.Brain:OnUnitProductionInActive(self)
    end,

    -- Called by the shield class 
    ---@param self Unit
    OnShieldEnabled = function(self) 
        -- for AI events
        self.Brain:OnUnitShieldEnabled(self)
    end,

    ---@param self Unit
    OnShieldDisabled = function(self) 
        -- for AI events
        self.Brain:OnUnitShieldDisabled(self)
    end,

    -- Called by the brain when the unit registered itself
    ---@param self Unit
    OnNoExcessEnergy = function(self) end,

    ---@param self Unit
    OnExcessEnergy = function(self) end,

    -- Called by the weapon class, these are expensive!
    ---@param self Unit
    ---@param Weapon Weapon
    OnGotTarget = function(self, Weapon) end,

    ---@param self Unit
    ---@param Weapon Weapon
    OnLostTarget = function(self, Weapon) end,

    --- called when the unit
    ---@param self Unit
    OnNukeArmed = function(self)
        -- for AI events
        self.Brain:OnUnitNukeArmed(self)
    end,

    ---@param self Unit
    OnNukeLaunched = function(self)
        -- for AI events
        self.Brain:OnUnitNukeLaunched(self)
    end,

    -- Unknown when these are called
    ---@param self Unit
    OnActive = function(self) end,
    ---@param self Unit
    OnInActive = function(self) end,

    ---@param self Unit
    ---@param location number
    OnSpecialAction = function(self, location) end,

    ---@param self Unit
    ---@param index integer
    OnDamageBy = function(self, index) end,

    --- Deprecated functionality

    ---@param self Unit
    ---@param pos Vector
    ---@return TerrainTreadType
    GetTTTreadType = function(self, pos)
        local terrainType = GetTerrainType(pos[1], pos[3])
        return terrainType.Treads or 'None'
    end,

    ---@deprecated
    ---@param self Unit
    ---@param fn function
    AddOnHorizontalStartMoveCallback = function(self, fn)
    end,

    --- Allows the unit to rock from side to side. Useful when the unit is on water. Is not used
    -- in practice, nor by this repository or by any of the commonly played mod packs.
    ---@param self Unit
    ---@deprecated
    StartRocking = function(self)

        local bp = self.Blueprint.Display
        local speed = bp.MaxRockSpeed
        if (not self.RockManip) and (not self.Dead) and speed and speed > 0 then 

            -- clear it so that GC can take it, if it exists
            if self.StopRockThread then 
                KillThread(self.StopRockThread)
                self.StopRockThread = nil 
            end

            self.StartRockThread = self:ForkThread(self.RockingThread, speed)
        end
    end,

    --- Stops the unit to rock from side to side. Useful when the unit is on water. Is not used
    -- in practice, nor by this repository or by any of the commonly played mod packs.
    ---@param self Unit
    ---@deprecated
    StopRocking = function(self)

        if self.StartRockThread then
            -- clear it so that GC can take it
            KillThread(self.StartRockThread)
            self.StartRockThread = nil

            local bp = self.Blueprint.Display
            local speed = bp.MaxRockSpeed

            self.StopRockThread = self:ForkThread(self.EndRockingThread, speed)
        end
    end,

    --- Rocking thread to move a unit when it is on the water.
    ---@param self Unit
    ---@param speed number
    ---@deprecated
    RockingThread = function(self, speed)

        -- default value
        speed = speed or 1.5

        self.RockManip = CreateRotator(self, 0, 'z', nil, 0, speed * 0.2, speed * 0.6)
        self.Trash:Add(self.RockManip)
        self.RockManip:SetPrecedence(0)

        while true do
            WaitFor(self.RockManip)

            if self.Dead then break end -- Abort if the unit died

            self.RockManip:SetTargetSpeed(-speed) 
            WaitFor(self.RockManip)

            if self.Dead then break end -- Abort if the unit died

            self.RockManip:SetTargetSpeed(speed)
        end
    end,


    --- Stopping of the rocking thread, allowing it to gracefully end instead of suddenly
    --- warping to the original position.
    ---@deprecated
    ---@param self Unit
    ---@param speed number
    EndRockingThread = function(self, speed)
        if self.RockManip then

            -- default value
            speed = speed or 1.5

            self.RockManip:SetGoal(0)
            self.RockManip:SetSpeed(speed / 4)
            WaitFor(self.RockManip)

            if self.RockManip then
                self.RockManip:Destroy()
                self.RockManip = nil
            end
        end
    end,

    ---@deprecated
    ---@param self Unit
    updateBuildRestrictions = function(self)
        self:UpdateBuildRestrictions()
    end,

    ---@deprecated
    ---@param aiBrain AIBrain
    ---@param category EntityCategory
    FindHQType = function(aiBrain, category)
    end,

    ---@deprecated
    ---@param self Unit
    SetDead = function(self)
        self.Dead = true
    end,

    ---@deprecated
    ---@param self Unit
    ---@return boolean
    IsDead = function(self)
        return self.Dead
    end,

    ---@deprecated
    ---@param self Unit
    ---@return Vector
    GetCachePosition = function(self)
        return self:GetPosition()
    end,
    
    ---@deprecated
    ---@param self Unit
    ---@return number
    GetFootPrintSize = function(self)
        return self.FootPrintSize
    end,
    
    ---@deprecated
    ---@param self Unit
    ---@return number sizeX
    ---@return number sizeY
    ---@return number sizeZ
    GetUnitSizes = function(self)
        local blueprint = self.Blueprint
        return blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ
    end,

    ---@deprecated
    ---@param self Unit
    ---@param val number
    SetCanTakeDamage = function(self, val)
        self.CanTakeDamage = val
    end,

    ---@deprecated
    ---@param self Unit
    ---@return boolean
    CheckCanTakeDamage = function(self)
        return self.CanTakeDamage
    end,

    ---@deprecated
    ---@param self Unit
    ---@param other any
    ---@return boolean
    CheckCanBeKilled = function(self, other)
        return self.CanBeKilled
    end,

    ---@deprecated
    ---@param self Unit
    ---@param val number
    SetCanBeKilled = function(self, val)
        self.CanBeKilled = val
    end,

    ---@deprecated
    ---@param self Unit
    ---@return boolean
    GetUnitBeingBuilt = function(self)
        return self.UnitBeingBuilt
    end,

}

-- upvalued moho functions for performance
local EntityGetArmy = _G.moho.entity_methods.GetArmy
local EntityGetEntityId = _G.moho.entity_methods.GetEntityId

local UnitGetCurrentLayer = _G.moho.unit_methods.GetCurrentLayer
local UnitGetUnitId = _G.moho.unit_methods.GetUnitId

---@class DummyUnit : moho.unit_methods
---@field EntityId EntityId
---@field Army Army
---@field Layer Layer
---@field Blueprint UnitBlueprint
DummyUnit = ClassDummyUnit(moho.unit_methods) {

    IsUnit = true,

    ---@param self DummyUnit
    OnCreate = function(self)
        -- cache unique values into inner table
        self.EntityId = EntityGetEntityId(self)
        self.UnitId = UnitGetUnitId(self)
        self.Army = EntityGetArmy(self)
        self.Layer = UnitGetCurrentLayer(self)

        -- cache often accessed values into inner table
        self.Blueprint = self:GetBlueprint()
    end,

    --- Typically called by functions
    ---@param self DummyUnit
    CheckAssistFocus = function(self) end,

    ---@param self DummyUnit
    UpdateAssistersConsumption = function (self) end,

    --- Plays a sound using the unit as a source. Returns true if successful, false otherwise
    ---@param self DummyUnit A unit
    ---@param sound string A string identifier that represents the sound to be played.
    ---@return boolean
    PlayUnitSound = function(self, sound)
        local audio = self.Blueprint.Audio[sound]
        if not audio then
            return false
        end

        self:PlaySound(audio)
        return true
    end,
}

-- Backwards compatibility with mods

-- As we try to improve the performance of the base game we do
-- our best to keep compatible with (unmaintained) mods. This is
-- our approach to that when we remove values of the unit table
-- to preserve more memory: the moment we detect a sim mod we 
-- add back in the fields that mods rely on.

if next(__active_mods) then

    SPEW("Sim mod detected - adding in missing fields to unit class to improve compatibility")

    local oldUnit = Unit
    Unit = Class(oldUnit) {
        ---@param self Unit
        OnCreate = function(self)
            oldUnit.OnCreate(self)

            -- in case recent mods use these values
            self.factionCategory = self.Blueprint.FactionCategory
            self.layerCategory = self.Blueprint.LayerCategory
            self.factionCategory = self.Blueprint.FactionCategory

            -- in case mods have a mobile unit inherit from a structure
            self.MovementEffectsBag = TrashBag()
            self.TopSpeedEffectsBag = TrashBag()
            self.BeamExhaustEffectsBag = TrashBag()
            self.IdleEffectsBag = TrashBag()

            -- a lot of mods edit this table manually for some reason
            self.IntelDisables = {
                Radar = {NotInitialized = true},
                Sonar = {NotInitialized = true},
                Omni = {NotInitialized = true},
                RadarStealth = {NotInitialized = true},
                SonarStealth = {NotInitialized = true},
                RadarStealthField = {NotInitialized = true},
                SonarStealthField = {NotInitialized = true},
                Cloak = {NotInitialized = true},
                CloakField = {NotInitialized = true},
                Spoof = {NotInitialized = true},
                Jammer = {NotInitialized = true},
            }
            
            -- in case recent mods use these values
            self.MovementEffects = self.Blueprint.Display.MovementEffects
            self.Audio = self.Blueprint.Audio
        end,

        DestroyAllTrashBags = function(self)
            oldUnit.DestroyAllTrashBags(self)

            self.MovementEffectsBag:Destroy()
            self.TopSpeedEffectsBag:Destroy()
            self.BeamExhaustEffectsBag:Destroy()
            self.IdleEffectsBag:Destroy()
    
            if self.TransportBeamEffectsBag then
                self.TransportBeamEffectsBag:Destroy()
            end

            if self.AmbientExhaustEffectsBag then
                for _, v in self.AmbientExhaustEffectsBag do
                    v:Destroy()
                end
            end

            if self.EffectsBag then
                for _, v in self.EffectsBag do
                    v:Destroy()
                end
            end

            if self.OmniEffectsBag then
                for k, v in self.OmniEffectsBag do
                    v:Destroy()
                end
            end
        end,
    }
end
