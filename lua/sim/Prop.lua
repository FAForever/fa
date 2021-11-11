------------------------------------------------------------------
--  File     :  /lua/sim/Prop.lua
--  Author(s):
--  Summary  :
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local EffectUtil = import('/lua/EffectUtilities.lua')

local minimumLabelMass = 10

-- upvalue globals for performance
local type = type
local Warp = Warp
local GetTerrainHeight = GetTerrainHeight

-- upvalue moho functions for performance
local EntityMethods = moho.entity_methods
local EntityGetEntityId = EntityMethods.GetEntityId
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetPosition = EntityMethods.GetPosition

-- upvalue trashbag functions for performance
local TrashBag = TrashBag

-- upvalue math functions for performance
local MathMax = math.max

-- upvalue table functions for performance
local TableInsert = table.insert

Prop = Class(moho.prop_methods, Entity) {

    -- override __init and __post_init to prevent creating an additional C++ object
    __init = function(self, spec)
    end,

    __post_init = function(self, spec)
    end,

    OnCreate = function(self)

        -- # Caching

        self.Trash = TrashBag()
        self.EntityId = EntityGetEntityId(self)
        self.Blueprint = EntityGetBlueprint(self)
        self.CachePosition = EntityGetPosition(self)
        self.MaxHealth = MathMax(50, self.Blueprint.Defense.MaxHealth)
        self.Health = self.MaxHealth
        
        self.EventCallbacks = { }

        -- # Reclaim values

        -- used by typical props, wrecks have their own mechanism to set its value
        if not self.Blueprint.UnitWreckage then 
            local economy = self.Blueprint.Economy

            -- set by some adaptive maps to influence how much a prop is worth
            local modifier = ScenarioInfo.Options.naturalReclaimModifier or 1 

            self.SetMaxReclaimValues(self,
                economy.ReclaimTimeMultiplier or economy.ReclaimMassTimeMultiplier or economy.ReclaimEnergyTimeMultiplier or 1,
                (economy.ReclaimMassMax * modifier) or 0,
                (economy.ReclaimEnergyMax * modifier) or 0
            )
        end

        -- # Terrain correction

        -- Find props that, for some reason, are below ground at their central bone
        local terrainAltitude = GetTerrainHeight(self.CachePosition[1], self.CachePosition[3])
        if self.CachePosition[2] < terrainAltitude then 
            self.CachePosition[2] = terrainAltitude

            -- Warp the prop to the surface. We never want things hiding underground!
            Warp(self, self.CachePosition) 
        end

        -- # Set health and status

        self.SetMaxHealth(self, self.MaxHealth)
        self.SetHealth(self, self, self.MaxHealth)
        self.CanTakeDamage = not EntityCategoryContains(categories.INVULNERABLE, self)
        self.CanBeKilled = true
    end,

    --- Adds a prop callback.
    -- @param self The prop itself.
    -- @param fn The function to call with the prop as its first argument and an optional second argument.
    -- @param type When the function should be called (OnKilled, OnReclaimed)
    AddPropCallback = function(self, fn, when)
        local callbacks = self.EventCallbacks[when] or { }
        self.EventCallbacks[when] = callbacks
        TableInsert(callbacks, fn)
    end,

    --- Performs prop callbacks
    -- @param self The prop itself.
    -- @param when The callbacks to run.
    -- @param param An additional parameter to feed into the callbacks.
    DoPropCallbacks = function(self, when, param)
        local callbacks = self.EventCallbacks[when]
        if callbacks then
            for num, cb in callbacks do
                cb(self, param)
            end
        end
    end,

    --- Removes all prop callbacks with the same function reference.
    -- @param self The prop itself.
    -- @param fn The function to remove.
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

    -- Returns the cache position of the prop, since it doesn't move, it's a big optimization
    GetCachePosition = function(self)
        return self.CachePosition
    end,

    -- Sets if the unit can take damage.  val = true means it can take damage.
    -- val = false means it can't take damage
    SetCanTakeDamage = function(self, val)
        self.CanTakeDamage = val
    end,

    -- Sets if the unit can be killed.  val = true means it can be killed.
    -- val = false means it can't be killed
    SetCanBeKilled = function(self, val)
        self.CanBeKilled = val
    end,

    CheckCanBeKilled = function(self, other)
        return self.CanBeKilled
    end,

    OnKilled = function(self, instigator, type, exceessDamageRatio)
        if not self.CanBeKilled then return end
        self:DoPropCallbacks('OnKilled')
        self:Destroy()
    end,

    OnReclaimed = function(self, entity)
        self:DoPropCallbacks('OnReclaimed', entity)
        self.CreateReclaimEndEffects(entity, self)
        self:Destroy()
    end,

    CreateReclaimEndEffects = function(self, target)
        EffectUtil.PlayReclaimEndEffects(self, target)
    end,

    Destroy = function(self)
        self.DestroyCalled = true
        Entity.Destroy(self)
    end,

    SyncMassLabel = function(self)
        if self.MaxMassReclaim < minimumLabelMass then
            -- The prop has never been applicable for labels, ignore it
            return
        end

        local mass = self.MaxMassReclaim * self.ReclaimLeft
        if mass < minimumLabelMass and not self.hasLabel then
            -- The prop doesn't have enough remaining mass and its label has already been removed
            return
        end

        local data = {}
        if not self:BeenDestroyed() and mass >= minimumLabelMass then
            -- The prop is still around and has enough mass, update the label
            data.mass = mass
            data.position = self:GetCachePosition()
            self.hasLabel = true
        else
            -- The prop is no longer applicable for labels, but has an existing label which needs to be removed
            self.hasLabel = false
        end

        Sync.Reclaim[self.EntityId] = data
    end,

    OnDestroy = function(self)
        self.Dead = true
        self:UpdateReclaimLeft()
        self.Trash:Destroy()
    end,

    OnDamage = function(self, instigator, amount, direction, damageType)
        if not self.CanTakeDamage then return end
        local preAdjHealth = self:GetHealth()
        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health <= 0 then
            if damageType == 'Reclaimed' then
                LOG("Reclaimed!")
                self:Destroy()
            else
                local excessDamageRatio = 0.0
                -- Calculate the excess damage amount
                local excess = preAdjHealth - amount
                local maxHealth = self:GetMaxHealth()
                if excess < 0 and maxHealth > 0 then
                    excessDamageRatio = -excess / maxHealth
                end
                self:Kill(instigator, damageType, excessDamageRatio)
            end
        else
            self:UpdateReclaimLeft()
        end
    end,

    OnCollisionCheck = function(self, other)
        return true
    end,

    --- Set the mass/energy value of this wreck when at full health, and the time coefficient
    -- that determine how quickly it can be reclaimed.
    -- These values are used to set the real reclaim values as fractions of the health as the wreck
    -- takes damage.
    SetMaxReclaimValues = function(self, time, mass, energy)
        self.MaxMassReclaim = mass
        self.MaxEnergyReclaim = energy
        self.TimeReclaim = time

        self:UpdateReclaimLeft()
    end,

    -- This function mimics the engine's behavior when calculating what value is left of a prop
    -- Called from OnDestroy, OnDamage, and OnCreate
    UpdateReclaimLeft = function(self)
        if not self:BeenDestroyed() then
            local max = self:GetMaxHealth()
            local ratio = (max and max > 0 and self:GetHealth() / max) or 1
            -- we have to take into account if the wreck has been partly reclaimed by an engineer
            self.ReclaimLeft = ratio * self:GetFractionComplete()
        end

        -- Notify UI about the mass change
        self:SyncMassLabel()
    end,

    SetPropCollision = function(self, shape, centerx, centery, centerz, sizex, sizey, sizez, radius)
        self.CollisionRadius = radius
        self.CollisionSizeX = sizex
        self.CollisionSizeY = sizey
        self.CollisionSizeZ = sizez
        self.CollisionCenterX = centerx
        self.CollisionCenterY = centery
        self.CollisionCenterZ = centerz
        self.CollisionShape = shape
        if radius and shape == 'Sphere' then
            self:SetCollisionShape(shape, centerx, centery, centerz, radius)
        else
            self:SetCollisionShape(shape, centerx, centery + sizey, centerz, sizex, sizey, sizez)
        end
    end,

    -- Prop reclaiming
    -- time = the greater of either time to reclaim mass or energy
    -- time to reclaim mass or energy is defined as:
    -- Mass Time =  mass reclaim value / buildrate of thing reclaiming it * BP set mass mult
    -- Energy Time = energy reclaim value / buildrate of thing reclaiming it * BP set energy mult
    -- The time to reclaim is the highest of the two values above.
    GetReclaimCosts = function(self, reclaimer)
        local time = self.TimeReclaim * (math.max(self.MaxMassReclaim, self.MaxEnergyReclaim) / reclaimer:GetBuildRate())
        time = math.max(time / 10, 0.0001)  -- this should never be 0 or we'll divide by 0!
        return time, self.MaxEnergyReclaim, self.MaxMassReclaim
    end,

    -- Split this prop into multiple sub-props, placing one at each of our bone locations.
    -- The child prop names are taken from the names of the bones of this prop.
    --
    -- If this prop has bones named
    --           "one", "two", "two_01", "two_02"
    --
    -- We will create props named
    --           "../one_prop.bp", "../two_prop.bp", "../two_prop.bp", "../two_prop.bp"
    --
    -- Note that the optional _01, _02, _03 ending to the bone name is stripped off.
    --
    -- You can pass an optional 'dirprefix' arg saying where to look for the child props.
    -- If not given, it defaults to one directory up from this prop's blueprint location.
    SplitOnBonesByName = function(self, dirprefix)
        local bp = self:GetBlueprint()

        if not dirprefix then
            -- default dirprefix to parent dir of our own blueprint
            -- trim ".../groups/blah_prop.bp" to just ".../"
            dirprefix = string.gsub(bp.BlueprintId, "[^/]*/[^/]*$", "")
        end

        local newprops = {}

        for ibone = 1, self:GetBoneCount() - 1 do
            local bone = self:GetBoneName(ibone)

            -- Construct name of replacement mesh from name of bone, trimming off optional _01 _02 etc
            local btrim = string.gsub(bone, "_?[0-9]+$", "")
            local newbp = dirprefix .. btrim .. "_prop.bp"
            local p = safecall("Creating prop", self.CreatePropAtBone, self, ibone, newbp)
            if p then
                table.insert(newprops, p)
            end
        end

        local n_props = table.getsize(newprops)
        if n_props == 0 then return end

        local time
        if bp.Economy then
            time = bp.economy.ReclaimTimeMultiplier or bp.economy.ReclaimMassTimeMultiplier or bp.economy.ReclaimEnergyTimeMultiplier or 1
        else
            time = 1
        end

        local compensationMult = 2 -- This mult is used to increase the value of split props to make up for reclaiming them being slower
        local perProp = {time = time / n_props, mass = (self.MaxMassReclaim * self.ReclaimLeft * compensationMult) / n_props, energy = (self.MaxEnergyReclaim * self.ReclaimLeft * compensationMult) / n_props}
        for _, p in newprops do
            p:SetMaxReclaimValues(perProp.time, perProp.mass, perProp.energy)
        end

        self:Destroy()
        return newprops
    end,

    PlayPropSound = function(self, sound)
        local bp = self:GetBlueprint().Audio
        if bp and bp[sound] then
            self:PlaySound(bp[sound])
            return true
        end

        return false
    end,

    -- Play the specified ambient sound for the unit, and if it has
    -- AmbientRumble defined, play that too
    PlayPropAmbientSound = function(self, sound)
        if sound == nil then
            self:SetAmbientSound(nil, nil)
            return true
        else
            local bp = self:GetBlueprint().Audio
            if bp and bp[sound] then
                if bp.Audio['AmbientRumble'] then
                    self:SetAmbientSound(bp[sound], bp.Audio['AmbientRumble'])
                else
                    self:SetAmbientSound(bp[sound], nil)
                end
                return true
            end

            return false
        end
    end,
}
