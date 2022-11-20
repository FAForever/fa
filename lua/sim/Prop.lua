local PlayReclaimEndEffects = import("/lua/effectutilities.lua").PlayReclaimEndEffects

local minimumLabelMass = 10

-- upvalue globals for performance
local type = type
local Warp = Warp
local pcall = pcall
local GetTerrainHeight = GetTerrainHeight

-- upvalue moho functions for performance
local EntityMethods = moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntitySetHealth = EntityMethods.SetHealth
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntityAdjustHealth = EntityMethods.AdjustHealth
local EntityGetHealth = EntityMethods.GetHealth
local EntityGetMaxHealth = EntityMethods.GetMaxHealth
local EntityGetEntityId = EntityMethods.GetEntityId
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetPosition = EntityMethods.GetPosition
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntityGetFractionComplete = EntityMethods.GetFractionComplete
local EntitySetCollisionShape = EntityMethods.SetCollisionShape
local EntityGetBoneCount = EntityMethods.GetBoneCount
local EntityGetBoneName = EntityMethods.GetBoneName
local EntitySetAmbientSound = EntityMethods.SetAmbientSound

local UnitMethods = moho.unit_methods 
local UnitGetBuildRate = UnitMethods.GetBuildRate

-- upvalue trashbag functions for performance
-- local TrashBag = TrashBag
local TrashDestroy = TrashBag.Destroy

-- upvalue string functions for performance
local StringGsub = string.gsub

-- upvalue table functions for performance
local TableInsert = table.insert

---@class Prop : moho.prop_methods
Prop = Class(moho.prop_methods) {

    IsProp = true,

    ---@param self Prop
    OnCreate = function(self)

        -- -- Caching

        self.Trash = TrashBag()
        self.EntityId = EntityGetEntityId(self)
        self.Blueprint = EntityGetBlueprint(self)
        self.CachePosition = EntityGetPosition(self)
        self.SyncData = { }

        -- -- Reclaim values

        -- used by typical props, wrecks have their own mechanism to set its value
        if not self.Blueprint.UnitWreckage then
            local economy = self.Blueprint.Economy

            -- set by some adaptive maps to influence how much a prop is worth
            local modifier = ScenarioInfo.Options.naturalReclaimModifier or 1

            self:SetMaxReclaimValues(
                economy.ReclaimTimeMultiplier or economy.ReclaimMassTimeMultiplier or economy.ReclaimEnergyTimeMultiplier or 1,
                (economy.ReclaimMassMax * modifier) or 0,
                (economy.ReclaimEnergyMax * modifier) or 0
            )
        end

        -- -- Terrain correction

        -- Find props that, for some reason, are below ground at their central bone
        local terrainAltitude = GetTerrainHeight(self.CachePosition[1], self.CachePosition[3])
        if self.CachePosition[2] < terrainAltitude then
            self.CachePosition[2] = terrainAltitude

            -- Warp the prop to the surface. We never want things hiding underground!
            Warp(self, self.CachePosition)
        end

        -- -- Set health and status

        local maxHealth = self.Blueprint.Defense.MaxHealth
        if maxHealth < 50 then
            maxHealth = 50
        end

        EntitySetMaxHealth(self, maxHealth)
        EntitySetHealth(self, self, maxHealth)
        self.CanTakeDamage = (not self.Blueprint.Categories.INVULNERABLE) or false
        self.CanBeKilled = true
    end,

    --- Adds a prop callback.
    -- @param self The prop itself.
    -- @param fn The function to call with the prop as its first argument and an optional second argument.
    -- @param type When the function should be called (OnKilled, OnReclaimed)
    AddPropCallback = function(self, fn, when)
        self.EventCallbacks = self.EventCallbacks or { }
        self.EventCallbacks[when] = self.EventCallbacks[when] or { }
        TableInsert(self.EventCallbacks[when], fn)
    end,

    --- Performs prop callbacks
    -- @param self The prop itself.
    -- @param when The callbacks to run.
    -- @param param An additional parameter to feed into the callbacks.
    DoPropCallbacks = function(self, when, param)
        if self.EventCallbacks then 
            local callbacks = self.EventCallbacks[when]
            if callbacks then
                for num, cb in callbacks do
                    cb(self, param)
                end
            end
        end
    end,

    --- Removes all prop callbacks with the same function reference.
    -- @param self The prop itself.
    -- @param fn The function to remove.
    RemoveCallback = function(self, fn)
        if self.EventCallbacks then 
            for k, v in self.EventCallbacks do
                if type(v) == "table" then
                    for kcb, vcb in v do
                        if vcb == fn then
                            v[kcb] = nil
                        end
                    end
                end
            end
        end
    end,

    --- Called by the engine when the prop is killed.
    -- @param instigator The entity that killed the prop.
    -- @param type The type of damage the entity did.
    -- @param excessDamageRatio The amount of overkill.
    OnKilled = function(self, instigator, type, excessDamageRatio)
        if not self.CanBeKilled then 
            return 
        end

        self:DoPropCallbacks('OnKilled')
        EntityDestroy(self)
    end,

    --- Called by the engine when the prop is reclaimed.
    -- @param entity The entity that reclaimed the prop.
    OnReclaimed = function(self, entity)
        self:DoPropCallbacks('OnReclaimed', entity)
        self:CreateReclaimEndEffects(entity)
        EntityDestroy(self)
    end,

    --- Constructs reclaim effects. Separate function for mod compatibility.
    -- @param target The entity that reclaimed the prop.
    CreateReclaimEndEffects = function(self, target)
        PlayReclaimEndEffects(target, self)
    end,

    --- Syncs the mass label to the UI.
    SyncMassLabel = function(self)

        -- check if prop has sufficient amount of reclaim to begin with
        if self.MaxMassReclaim < minimumLabelMass then
            return
        end

        -- check if prop has sufficient amount of reclaim left
        local mass = self.MaxMassReclaim * self.ReclaimLeft
        if mass < minimumLabelMass and not self.hasLabel then
            return
        end

        -- construct sync data
        local data = self.SyncData

        -- check if prop should receive sync data
        if not EntityBeenDestroyed(self) and mass >= minimumLabelMass then
            -- set the data
            data.mass = mass
            data.position = self.CachePosition
            self.hasLabel = true
        else
            -- prop is not worthy anymore
            data.mass = nil
            data.position = nil
            self.hasLabel = false
        end

        -- update the sync
        Sync.Reclaim[self.EntityId] = data
    end,

    --- Called by the engine when the prop is destroyed.
    OnDestroy = function(self)
        self.Dead = true
        self:UpdateReclaimLeft()
        TrashDestroy(self.Trash)
    end,

    --- Called by the engine when the prop receives damage.
    -- @param instigator The source of the damage.
    -- @param amount The amount of damage.
    -- @param direction The direction the damage is coming from.
    -- @param damageType The type of damage ('Normal', 'Fire', ...)
    OnDamage = function(self, instigator, amount, direction, damageType)

        -- only applies to trees
        if damageType == "TreeForce" or damageType == "TreeFire" then
            return
        end

        -- if we're immune then we're good
        if not self.CanTakeDamage then
            return
        end

        -- adjust our health
        local preHealth = EntityGetHealth(self)
        EntityAdjustHealth(self, instigator, -amount)
        local health = preHealth - amount 
        if health < 0 then
            health = 0 
        end 

        -- check if we're still alive
        if health <= 0 then
            if damageType == 'Reclaimed' then
                EntityDestroy(self)
            else
                -- Calculate the excess damage amount
                local excess = preHealth
                local maxHealth = EntityGetMaxHealth(self)
                if excess < 0 and maxHealth > 0 then
                    self:Kill(instigator, damageType, -excess / maxHealth)
                else 
                    self:Kill(instigator, damageType, 0.0)
                end
            end
        else
            self:UpdateReclaimLeft()
        end
    end,

    --- Called by the engine when the prop collides with a projectile.
    -- @param other The projectile we're colliding with.
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

    --- Mimics the engine behavior when calculating the reclaim value of a prop.
    UpdateReclaimLeft = function(self)
        if not self.Dead then
            local max = EntityGetMaxHealth(self)
            local health = EntityGetHealth(self)
            local ratio = (max and max > 0 and health / max) or 1

            -- we have to take into account if the wreck has been partly reclaimed by an engineer
            self.ReclaimLeft = ratio * EntityGetFractionComplete(self)
        end

        -- Notify UI about the mass change
        self:SyncMassLabel()
    end,

    --- Sets the collision box of the prop.
    -- @param shape The shape of the collider: 'Sphere', 'Box' or 'None'
    -- @param centerX The x-coordinate of the center of the sphere or of a point on the box
    -- @param centerY The x-coordinate of the center of the sphere or of a point on the box
    -- @param centerZ The x-coordinate of the center of the sphere or of a point on the box
    -- @param sizex The width of the box.
    -- @param sizey The height of the box.
    -- @param sizez The length of the box.
    -- @param radius The radius of the sphere.
    SetPropCollision = function(self, shape, centerx, centery, centerz, sizex, sizey, sizez, radius)

        -- only store this for wreckages, it is used to restore the collision box when armies are shared 
        -- upon death, see '/lua/simutils.lua' and then the function TransferUnfinishedUnitsAfterDeath.
        self.CollisionRadius = radius
        self.CollisionSizeX = sizex
        self.CollisionSizeY = sizey
        self.CollisionSizeZ = sizez
        self.CollisionCenterX = centerx
        self.CollisionCenterY = centery
        self.CollisionCenterZ = centerz
        self.CollisionShape = shape

        if radius and shape == 'Sphere' then
            EntitySetCollisionShape(self, shape, centerx, centery, centerz, radius)
        else
            EntitySetCollisionShape(self, shape, centerx, centery + sizey, centerz, sizex, sizey, sizez)
        end
    end,
    
    RevertCollisionShape = function(self)
        local x, y, z = self.CollisionCenterX, self.CollisionCenterY, self.CollisionCenterZ
        local radius = self.CollisionRadius
        local shape = self.CollisionShape
        if radius and shape == 'Sphere' then
            EntitySetCollisionShape(self, shape, x, y, z, radius)
        else
            local sizeX, sizeY, sizeZ = self.CollisionSizeX, self.CollisionSizeY, self.CollisionSizeZ
            EntitySetCollisionShape(self, shape, x, y + sizeY, z, sizeX, sizeY, sizeZ)
        end
    end;

    --- Computes how long it would take to reclaim this prop with the reclaimer.
    -- @param reclaimer The unit to compute the duration for.
    -- @return The time it takes and the amount of energy and mass reclaim.
    GetReclaimCosts = function(self, reclaimer)
        local maxValue = self.MaxMassReclaim
        if self.MaxEnergyReclaim > maxValue then
            maxValue = self.MaxEnergyReclaim
        end

        local time = self.TimeReclaim * (maxValue / UnitGetBuildRate(reclaimer))
        time = time / 10

        -- prevent division by 0 when the prop has no value
        if time < 0 then
            time = 0.0001
        end
        
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

        -- compute reclaim time of props
        local economy = self.Blueprint.Economy
        local time = 1
        if economy then
            time = economy.ReclaimTimeMultiplier or economy.ReclaimMassTimeMultiplier or economy.ReclaimEnergyTimeMultiplier or 1
        end

        -- compute directory prefix if it is not set
        if not dirprefix then
            -- default dirprefix to parent dir of our own blueprint
            -- trim ".../groups/blah_prop.bp" to just ".../"
            dirprefix = StringGsub(self.Blueprint.BlueprintId, "[^/]*/[^/]*$", "")
        end

        -- values used in the for loop
        local trimmedBoneName, blueprint, bone, ok, out

        -- contains the new props and the expected number of props
        local props = { }
        local count = EntityGetBoneCount(self) - 1

        -- compute information of new props
        local compensationMult = 2
        local time = time / count 
        local mass = (self.MaxMassReclaim * self.ReclaimLeft * compensationMult) / count
        local energy = (self.MaxEnergyReclaim * self.ReclaimLeft * compensationMult) / count
        for ibone = 1, count do

            -- get the bone name
            bone = EntityGetBoneName(self, ibone)

            -- determine prop name (removing _01, _02 from bone name)
            trimmedBoneName = StringGsub(bone, "_?[0-9]+$", "")
            blueprint = dirprefix .. trimmedBoneName .. "_prop.bp"

            -- attempt to make the prop
            ok, out = pcall(self.CreatePropAtBone, self, ibone, blueprint)
            if ok then 
                out:SetMaxReclaimValues(time, mass, energy)
                props[ibone] = out 
            else 
                WARN("Unable to split a prop: " .. self.Blueprint.BlueprintId .. " -> " .. blueprint)
                WARN(out)
            end
        end

        -- get rid of ourselves
        EntityDestroy(self)

        -- return the new props
        return props
    end,

    --- Plays a sound with the prop as source.
    -- @param sound The identifier in the prop blueprint.
    PlayPropSound = function(self, sound)
        local bp = self.Blueprint.Audio
        if bp and bp[sound] then
            self:PlaySound(bp[sound])
        end
    end,

    --- Plays an ambient sound with the prop as source. When the sound
    -- parameter is not provided the current ambient sound is removed.
    -- @param sound The identifier in the prop blueprint.
    PlayPropAmbientSound = function(self, sound)

        -- if there is no identifier then remove the ambient sound
        if sound == nil then
            EntitySetAmbientSound(self, nil, nil)

        -- if there is an identifier then see if it exists
        else
            local bp = self.Blueprint.Audio
            if bp and bp[sound] then
                EntitySetAmbientSound(self, bp[sound], nil)
            end
        end
    end,

    -- DEPRECATED --

    -- This should never be called - use the actual value.
    GetCachePosition = function(self)

        -- if not DeprecatedWarnings.GetCachePosition then 
        --     DeprecatedWarnings.GetCachePosition = true 
        --     SPEW("GetCachePosition is deprecated: use self.CachePosition instead")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        return self.CachePosition
    end,

    -- This should never be called - use the actual value. When set to false the prop can't take damage.
    SetCanTakeDamage = function(self, val)

        -- if not DeprecatedWarnings.SetCanTakeDamage then 
        --     DeprecatedWarnings.SetCanTakeDamage = true 
        --     SPEW("SetCanTakeDamage is deprecated: set self.CanTakeDamage instead")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.CanTakeDamage = val
    end,

    -- This should never be called - use the actual value. When set to false the prop can't be killed.
    SetCanBeKilled = function(self, val)

        -- if not DeprecatedWarnings.SetCanBeKilled then 
        --     DeprecatedWarnings.SetCanBeKilled = true 
        --     SPEW("SetCanBeKilled is deprecated: set self.SetCanBeKilled instead")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.CanBeKilled = val
    end,

    -- This should never be called - use the actual value. Retrieves whether the prop can be killed.
    CheckCanBeKilled = function(self, other)

        -- if not DeprecatedWarnings.CheckCanBeKilled then 
        --     DeprecatedWarnings.CheckCanBeKilled = true 
        --     SPEW("CheckCanBeKilled is deprecated: use self.CheckCanBeKilled instead")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        return self.CanBeKilled
    end,
}


-- imports kept for backwards compatibility with mods
local Entity = import("/lua/sim/entity.lua").Entity
local DeprecatedWarnings = { }
local TrashAdd = TrashBag.Add