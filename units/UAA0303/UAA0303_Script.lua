#****************************************************************************
#**
#**  File     :  /cdimage/units/UAA0303/UAA0303_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Air Superiority Fighter Script
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local AAAAutocannonQuantumWeapon = import('/lua/aeonweapons.lua').AAAAutocannonQuantumWeapon

local blueprint = __blueprints['uaa0303']

-- cached from blueprint for performance
local MovementEffectBones = blueprint.Display.MovementEffects.Air.Effects[1].Bones
local ContrailEffectBones = blueprint.Display.MovementEffects.Air.Contrails.Bones 

local blueprintAudio = blueprint.Audio
local AudioSoundStartMove = blueprintAudio.StartMove
local AudioSoundStopMove = blueprintAudio.StopMove 
local AudioSoundLanding = blueprintAudio.Landing
local AudioAmbientMove = blueprintAudio.AmbientMove
local AudioLanding = blueprintAudio.Landing
local AudioThruster = blueprintAudio.Thruster
local AudioRefueling = blueprintAudio.Refueling
local AudioKilled = blueprintAudio.Killed
local AudioDestroyed = blueprintAudio.Destroyed
blueprintAudio = nil 

local TrailEmitter = '/effects/emitters/contrail_delayed_mist_01_emit.bp'

-- upvalue for performance
local CreateTrail = CreateTrail
local CreateAttachedEmitter = CreateAttachedEmitter

local TrashBag = TrashBag
local TrashBagAdd = TrashBag.Add 
local TrashBagDestroy = TrashBag.Destroy

local EntityGetBlueprint = _G.moho.entity_methods.GetBlueprint
local EntityGetArmy = _G.moho.entity_methods.GetArmy
local EntityPlaySound = _G.moho.entity_methods.PlaySound

local SyncMeta = import('/lua/sim/unit.lua').SyncMeta

-- keep track of total number of this unit type
local Count = 0

UAA0303 = Class(AAirUnit) {
    Weapons = {
        AutoCannon1 = Class(AAAAutocannonQuantumWeapon) {},
    },

    --- Called before OnCreate, ensures some of the most fundamental properties are set.  
    OnPreCreate = function(self)
        
        -- allows this unit to be visible in the UI
        self.Sync = {}
        self.Sync.id = self:GetEntityId()
        self.Sync.army = self:GetArmy()
        setmetatable(self.Sync, SyncMeta)

        -- allows us to allocate all the trash at one location
        self.Trash = TrashBag()

        -- the corona doesn't have any of these
        -- todo: breaking change
        self.IntelDisables = {
            -- Radar = {NotInitialized = true},
            -- Sonar = {NotInitialized = true},
            -- Omni = {NotInitialized = true},
            -- RadarStealth = {NotInitialized = true},
            -- SonarStealth = {NotInitialized = true},
            -- RadarStealthField = {NotInitialized = true},
            -- SonarStealthField = {NotInitialized = true},
            -- Cloak = {NotInitialized = true},
            -- CloakField = {NotInitialized = true}, -- We really shouldn't use this. Cloak/Stealth fields are pretty busted
            -- Spoof = {NotInitialized = true},
            -- Jammer = {NotInitialized = true},
        }

        -- the corona doesn't support any of these
        -- todo: breaking change
        self.EventCallbacks = {
            -- OnKilled = {},
            -- OnUnitBuilt = {},
            -- OnStartBuild = {},
            -- OnReclaimed = {},
            -- OnStartReclaim = {},
            -- OnStopReclaim = {},
            -- OnStopBeingBuilt = {},
            -- OnHorizontalStartMove = {},
            -- OnCaptured = {},
            -- OnCapturedNewUnit = {},
            -- OnDamaged = {},
            -- OnStartCapture = {},
            -- OnStopCapture = {},
            -- OnFailedCapture = {},
            -- OnStartBeingCaptured = {},
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
        }
    end,

    OnCreate = function(self)

        -- retrieve it once, and only once!
        local blueprint = EntityGetBlueprint(self)   

        -- cache commonly used values from the engine
        -- self.Layer = self:GetCurrentLayer()      -- Not required: ironically OnLayerChange is called _before_ OnCreate is called!
        self.Army = EntityGetArmy(self)
        self.Blueprint = blueprint
        self.UnitId = blueprint.BlueprintId
        self.techCategory = blueprint.TechCategory
        self.layerCategory = blueprint.LayerCategory
        self.factionCategory = blueprint.FactionCategory

        -- cache sounds that are very common

        -- used to keep track of damage effects
        self.FxDamage1Amount = self.FxDamage1Amount or 2
        self.FxDamage2Amount = self.FxDamage2Amount or 2
        self.FxDamage3Amount = self.FxDamage3Amount or 2
        self.DamageEffectsBag = { {}, {}, {}, }

        self.AudioStartMove = blueprint.Audio.StartMove

        -- individual trashbags for effects
        self.MovementEffectsBag = TrashBag()
        self.TopSpeedEffectsBag = TrashBag()
        self.OnBeingBuiltEffectsBag = TrashBag()

        -- store targets and attackers for proper Stealth management
        self.Targets = {}
        self.WeaponTargets = {}
        self.WeaponAttackers = {}

        -- set up veterancy
        self.xp = 0
        self.Instigators = {}
        self.totalDamageTaken = 0

        -- set up buff logic
        self.Buffs = {
            BuffTable = {},
            Affects = {},
        }

        -- set up vision
        local visionRadius = blueprint.Intel.VisionRadius
        self:SetIntelRadius('Vision', visionRadius or 0)

        -- make sure we can take damage
        self:SetCanTakeDamage(true)
        self:SetCanBeKilled(true)

        -- still got some :)
        self.HasFuel = true

        -- not yet :)
        self.Dead = false
    end,

    --- Called whenever the jet changes between speed states. Possible states: Stopped, Stopping,
    -- CruiseSpeed, TopSpeed.
    OnMotionHorzEventChange = function(self, new, old)
        -- if we're a gooner then don't do anything
        if self.Dead then
            return
        end

        -- UPDATE SOUNDS --

        -- if we're starting to move
        if old == 'Stopped' or (old == 'Stopping' and new ~= 'Stopped') then 
            EntityPlaySound(self, AudioSoundStartMove)
        end

        -- if we're stopping to move
        if new == 'Stopping' and old ~= 'Stopped' then 
            EntityPlaySound(self, AudioSoundStopMove)
        end

        -- UPDATE EFFECTS -- 

        local army = self.Army 
        local trash = false 

        -- if we were at top speed, remove top speed effects
        if old == 'TopSpeed' then 
            TrashBagDestroy(self.TopSpeedEffectsBag)
        end

        -- if we get to top speed, add top speed effects
        if new == 'TopSpeed' and self.HasFuel then 
            trash = self.TopSpeedEffectsBag
            for k, effect in self.ContrailEffects do 
                for l, bone in ContrailEffectBones do
                    TrashBagAdd(
                        trash, 
                        CreateTrail(self, bone, army, effect)
                    )
                end
            end
        end

        -- if we stopped completely, remove all effects 
        if new == 'Stopped' then 
            TrashBagDestroy(self.TopSpeedEffectsBag)
            TrashBagDestroy(self.MovementEffectsBag)
        end

        -- if we're starting to move, add effects
        if old == 'Stopped' then 
            trash = self.MovementEffectsBag
            for k, bone in MovementEffectBones do 
                TrashBagAdd(
                    trash, 
                    CreateAttachedEmitter(self, bone, army, TrailEmitter)
                )
            end
        end
    end,

    --- Called when the layer changes (asf lands / starts flying)
    OnLayerChange = function(self, new, old)
        self.Layer = new 
    end,

    --- Called when the terrain type changes
    OnTerrainTypeChange = function(self, new, old)

    end,

    --- Called whenever the jet changes between height states. Possible states: Top, Up, Down, Bottom
    OnMotionVertEventChange = function(self, new, old)

        -- if we're a gooner then don't do anything
        if self.Dead then
            return
        end

        -- UPDATE SOUNDS --

        -- when landing
        if new == 'Down' then
            EntityPlaySound(self, AudioLanding)
        end
    end,

    OnCollisionCheck = function(self, other, firingWeapon)
        if self.DisallowCollisions then
            return false
        end

        if EntityCategoryContains(categories.PROJECTILE, other) then
            if IsAlly(self.Army, other:GetArmy()) then
                return other.CollideFriendly
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

        bp = self:GetBlueprint()
        if bp.DoNotCollideList then
            for _, v in pairs(bp.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), other) then
                    return false
                end
            end
        end
        return true
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        if self.DisallowCollisions then
            return false
        end

        -- Skip friendly collisions
        local weaponBP = firingWeapon:GetBlueprint()
        local collide = weaponBP.CollideFriendly
        if collide == false then
            if IsAlly(self.Army, firingWeapon.unit.Army) then
                return false
            end
        end

        -- Check for specific non-collisions
        if weaponBP.DoNotCollideList then
            for _, v in pairs(weaponBP.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end

        return true
    end,
}

TypeClass = UAA0303