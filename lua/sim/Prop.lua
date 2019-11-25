------------------------------------------------------------------
--  File     :  /lua/sim/Prop.lua
--  Author(s):
--  Summary  :
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local EffectUtil = import('/lua/EffectUtilities.lua')

local minimumLabelMass = 10

Prop = Class(moho.prop_methods, Entity) {
    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self, spec)
    end,

    __post_init = function(self, spec)
    end,

    OnCreate = function(self)
        self.EventCallbacks = {
            OnKilled = {},
            OnReclaimed = {},
        }
        Entity.OnCreate(self)
        self.Trash = TrashBag()
        local bp = self:GetBlueprint()
        local economy = bp.Economy

        -- These values are used in world props like rocks / stones / trees
        local unitWreck = bp.UnitWreckage
        if not unitWreck then -- This function is called from Wreckage.lua, don't call twice
            local modifier = ScenarioInfo.Options.naturalReclaimModifier or 1 -- Set by some maps to reduce the value of starting non-wreck reclaim
            self:SetMaxReclaimValues(
                economy.ReclaimTimeMultiplier or economy.ReclaimMassTimeMultiplier or economy.ReclaimEnergyTimeMultiplier or 1,
                (economy.ReclaimMassMax * modifier) or 0,
                (economy.ReclaimEnergyMax * modifier) or 0
            )
        end

        -- Correct to terrain, just to be sure
        local pos = self:GetPosition()
        local terrainAltitude = GetTerrainHeight(pos[1], pos[3])
        if pos[2] < terrainAltitude then -- Find props that, for some reason, are below ground at their central bone
            pos[2] = terrainAltitude
            Warp(self, pos) -- Warp the prop to the surface. We never want things hiding underground!
        end

        self.CachePosition = pos

        local max = math.max(50, bp.Defense.MaxHealth)
        self:SetMaxHealth(max)
        self:SetHealth(self, max)
        self:SetCanTakeDamage(not EntityCategoryContains(categories.INVULNERABLE, self))
        self:SetCanBeKilled(true)
    end,

    AddPropCallback = function(self, fn, type)
        if not fn then
            error('*ERROR: Tried to add a callback type - ' .. type .. ' with a nil function')
            return
        end
        table.insert(self.EventCallbacks[type], fn)
    end,

    DoPropCallbacks = function(self, type, param)
        if self.EventCallbacks[type] then
            for num, cb in self.EventCallbacks[type] do
                cb(self, param)
            end
        end
    end,

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
        return self.CachePosition or self:GetPosition()
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

        Sync.Reclaim[self:GetEntityId()] = data
    end,

    OnDestroy = function(self)
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
