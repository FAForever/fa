-----------------------------------------------------------------
-- File     :  /cdimage/units/URA0001/URA0001_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Builder bot units
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local EffectUtil = import('/lua/EffectUtilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')

-- upvalue globals for performance
local CreateBuilderArmController = CreateBuilderArmController

-- upvalue moho functions for performance
local BuilderArmManipulator = _G.moho.BuilderArmManipulator 
local BuilderArmManipulatorSetAimingArc = BuilderArmManipulator.SetAimingArc
local BuilderArmManipulatorSetPrecedence = BuilderArmManipulator.SetPrecedence
BuilderArmManipulator = nil 

local EntityFunctions = _G.moho.entity_methods 
local EntitySetCollisionShape = EntityFunctions.SetCollisionShape
EntityFunctions = nil

local UnitFunctions = _G.moho.unit_methods 
local UnitSetConsumptionActive = UnitFunctions.SetConsumptionActive
UnitFunctions = nil 

local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

URA0001 = Class(CAirUnit) {
    SpawnedBy = false,

    -- do not perform the logic of these functions                      
    OnMotionHorzEventChange = function(self, new, old) end,                     -- called a million times, keep it simple
    OnMotionVertEventChange = function(self, new, old) end,                 
    OnLayerChange = function(self, new, old) end,

    CreateBuildEffects = function(self, unitBeingBuilt, order) end,             -- do not make build effects (engineer / builder takes care of that)
    StartBuildingEffects = function(self, built, order) end,
    CreateBuildEffects = function(self, built, order) end,
    StopBuildingEffects = function(self, built) end,

    OnBuildProgress = function(self, unit, oldProg, newProg) end,               -- do not keep track of progress
    OnStopBuild = function(self, unitBeingBuilt) end,

    EnableUnitIntel = function(self, disabler, intel) end,                      -- do not bother doing intel
    DisableUnitIntel = function(self, disabler, intel) end,
    OnIntelEnabled = function(self) end,
    OnIntelDisabled = function(self) end,
    ShouldWatchIntel = function(self) end,
    IntelWatchThread = function(self) end,

    AddDetectedByHook = function(self, hook) end,                               -- do not bother keeping track of collision beams
    RemoveDetectedByHook = function(self, hook) end,
    OnDetectedBy = function(self, index) end,

    CreateWreckage = function (self, overkillRatio) end,                        -- don't make wreckage
    UpdateConsumptionValues = function(self) end,                               -- avoids junk in resource overlay
    ShouldUseVetSystem = function(self) return false end,                       -- never use vet
    OnStopBeingBuilt = function(self, builder, layer) end,                      -- do not perform this logic when being made
    OnStartRepair = function(self, unit) end,                                   -- do not run this logic
    OnKilled = function(self) end,                                              -- just fall out of the sky

    OnCollisionCheck = function(self, other, firingWeapon) return false end,    -- we never collide
    OnCollisionCheckWeapon = function(self, firingWeapon) return false end,

    OnPrepareArmToBuild = function(self) end,

    OnStartBuilderTracking = function(self) end,                                -- don't track anything
    OnStopBuilderTracking = function(self) end,

    DestroyUnit = function(self) end,                                           -- prevent misscalls
    DestroyAllTrashBags = function(self) end,

    OnStartSacrifice = function(self, target_unit) end,
    OnStopSacrifice = function(self, target_unit) end,

    -- only initialise what we need
    OnPreCreate = function(self) 
        self.Trash = TrashBag()
    end,             

    -- only initialise what we need
    OnCreate = function(self)
        -- make the drone aim for the target
        local BuildArmManipulator = CreateBuilderArmController(self, 'URA0003' , 'URA0003', 0)
        BuilderArmManipulatorSetAimingArc(BuildArmManipulator, -180, 180, 360, -90, 90, 360)
        BuilderArmManipulatorSetPrecedence(BuildArmManipulator, 5)
        TrashBagAdd(self.Trash, BuildArmManipulator)

        -- prevent drone from consuming anything and remove collision shape
        UnitSetConsumptionActive(self, false)

        -- self:SetCollisionShape('None')   -- this causes an engine crash after ~ 10 seconds
    end,

    -- short-cut when being destroyed
    OnDestroy = function(self) 
        self.Dead = true 
        self.Trash:Destroy()
        self.SpawnedBy.BuildBotsNext = self.SpawnedBy.BuildBotsNext - 1
    end,

    Kill = function(self)
        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        self:Destroy()
    end,

    -- prevent this type of operations
    OnStartCapture = function(self, target)
        IssueStop({self}) -- You can't capture!
    end,

    OnStartReclaim = function(self, target)
        IssueStop({self}) -- You can't reclaim!
    end,

    -- short cut - just get destroyed
    OnImpact = function(self, with)

        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        -- make it sound boom
        self:PlayUnitSound('Destroyed')

        -- make it gone
        self:Destroy()
    end,


}

TypeClass = URA0001
