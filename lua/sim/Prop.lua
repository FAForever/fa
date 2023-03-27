
local PlayReclaimEndEffects = import("/lua/effectutilities.lua").PlayReclaimEndEffects
local GridReclaimInstance = import("/lua/AI/GridReclaim.lua").GridReclaimInstance

-- upvalue for performance
local type = type
local Warp = Warp
local pcall = pcall
local GetTerrainHeight = GetTerrainHeight
local StringGsub = string.gsub
local TableInsert = table.insert

---@alias PropCallbackTypes 'OnKilled' | 'OnReclaimed'

---@class Prop : moho.prop_methods
---@field Trash TrashBag
---@field EntityId number
---@field Blueprint PropBlueprint
---@field CachePosition Vector
---@field MaxMassReclaim number
---@field MaxEnergyReclaim number
---@field TimeReclaim number        # This is a multiplier and not the actual total time
---@field ReclaimLeft number
---@field SyncData? table
---@field Extents? table
Prop = Class(moho.prop_methods) {

    IsProp = true,

    ---@param self Prop
    OnCreate = function(self)

        -- caching
        self.Trash = TrashBag()
        self.EntityId = self:GetEntityId()
        self.Blueprint = self:GetBlueprint()
        self.CachePosition = self:GetPosition()

        -- set reclaim values
        local economy = self.Blueprint.Economy
        local modifier = ScenarioInfo.Options.naturalReclaimModifier or 1
        self:SetMaxReclaimValues(
            economy.ReclaimTimeMultiplier or 1,
            (economy.ReclaimMassMax * modifier),
            (economy.ReclaimEnergyMax * modifier)
        )

        -- terrain correction
        local terrainAltitude = GetTerrainHeight(self.CachePosition[1], self.CachePosition[3])
        if self.CachePosition[2] < terrainAltitude then
            self.CachePosition[2] = terrainAltitude

            -- Warp the prop to the surface. We never want things hiding underground!
            Warp(self, self.CachePosition)
        end

        -- set health
        local maxHealth = self.Blueprint.Defense.MaxHealth
        if maxHealth < 50 then
            maxHealth = 50
        end

        self:SetMaxHealth(maxHealth)
        self:SetHealth(self, maxHealth)

        -- track in reclaim grid

    end,

    ---@param self Prop 
    ---@param fn function 
    ---@param when PropCallbackTypes 
    AddPropCallback = function(self, fn, when)
        self.EventCallbacks = self.EventCallbacks or { }
        self.EventCallbacks[when] = self.EventCallbacks[when] or { }
        TableInsert(self.EventCallbacks[when], fn)
    end,

    ---@param self Prop
    ---@param when PropCallbackTypes
    ---@param param any
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

    ---@param self Prop
    ---@param fn function
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

    ---@param instigator Unit
    ---@param type DamageType
    ---@param excessDamageRatio number
    OnKilled = function(self, instigator, type, excessDamageRatio)
        self:DoPropCallbacks('OnKilled')
        self:Destroy()
    end,

    ---@param entity Unit
    OnReclaimed = function(self, entity)
        self:DoPropCallbacks('OnReclaimed', entity)
        self:CreateReclaimEndEffects(entity)
        self:Destroy()
    end,

    ---@param self Prop
    ---@param target Unit
    CreateReclaimEndEffects = function(self, target)
        PlayReclaimEndEffects(target, self)
    end,

    ---@param self Prop
    OnDestroy = function(self)
        self:CleanupUILabel()
        self.Trash:Destroy()

        -- keep track of reclaim
        if GridReclaimInstance then
            GridReclaimInstance:OnReclaimDestroyed(self)
        end
    end,

    ---@param self Prop
    ---@param instigator Unit
    ---@param amount number
    ---@param direction Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, direction, damageType)
        -- only applies to trees
        if damageType == "TreeForce" or damageType == "TreeFire" then
            return
        end

        -- adjust our health
        local preHealth = self:GetHealth()
        self:AdjustHealth(instigator, -amount)
        local health = preHealth - amount
        if health < 0 then
            health = 0
        end

        -- check if we're still alive
        if health <= 0 then
            if damageType == 'Reclaimed' then
                self:Destroy()
            else
                -- Calculate the excess damage amount
                local excess = preHealth
                local maxHealth = self:GetMaxHealth()
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

    --- Set the mass/energy value of this wreck when at full health, and the time coefficient
    --- that determine how quickly it can be reclaimed. These values are used to set the real reclaim 
    --- values as fractions of the health as the wreck takes damage.
    ---@param self Prop
    ---@param time number
    ---@param mass number
    ---@param energy number
    SetMaxReclaimValues = function(self, time, mass, energy)
        self.MaxMassReclaim = mass
        self.MaxEnergyReclaim = energy
        self.TimeReclaim = time
        self:UpdateReclaimLeft()

        if self.MaxMassReclaim * self.ReclaimLeft >= 10 then
            self:SetupUILabel()
        end
    end,

    --- Mimics the engine behavior when calculating the reclaim value of a prop
    ---@param self Prop
    UpdateReclaimLeft = function(self)
        if not self:BeenDestroyed() then
            local max = self:GetMaxHealth()
            local health = self:GetHealth()
            local ratio = (max and max > 0 and health / max) or 1

            -- we have to take into account if the wreck has been partly reclaimed by an engineer
            self.ReclaimLeft = ratio * self:GetFractionComplete()
            self:UpdateUILabel()
        else
            self.ReclaimLeft = 0
        end

        -- keep track of reclaim
        if GridReclaimInstance then
            GridReclaimInstance:OnReclaimUpdate(self)
        end
    end,

    --- Sets the collision box of the prop.
    ---@param self Prop
    ---@param shape 'Sphere' | 'Box' | 'None'
    ---@param centerx number The x-coordinate of the center of the sphere or of a point on the box
    ---@param centery number The Y-coordinate of the center of the sphere or of a point on the box
    ---@param centerz number The Z-coordinate of the center of the sphere or of a point on the box
    ---@param sizex number The width of the box.
    ---@param sizey number The height of the box.
    ---@param sizez number The length of the box.
    ---@param radius number The radius of the sphere.
    SetPropCollision = function(self, shape, centerx, centery, centerz, sizex, sizey, sizez, radius)
        if radius and shape == 'Sphere' then
            self:SetCollisionShape(shape, centerx, centery, centerz, radius)
        else
            self:SetCollisionShape(shape, centerx, centery + sizey, centerz, sizex, sizey, sizez)
        end
    end,

    ---@see prop.ApplyCachedCollisionExtents for applying the cached extents
    ---@param self Prop
    CacheAndRemoveCollisionExtents = function(self)
        self.Extents = self:GetCollisionExtents()
        self:SetCollisionShape('None')
    end,

    ---@see prop.CacheAndRemoveCollisionExtents for caching the extents
    ---@param self Prop
    ApplyCachedCollisionExtents = function(self)
        if self.Extents then
            local pos = self.CachePosition
            local min = self.Extents.Min
            local max = self.Extents.Max
            self.Extents = nil

            local x, y, z = min[1] - pos[1], min[2] - pos[2], min[3] - pos[3]
            local sx, sy, sz = 0.5 * (max[1] - min[1]), 0.5 * (max[2] - min[2]), 0.5 * (max[3] - min[3])

            self:SetCollisionShape("Box", x + sx, y + sy, z + sz, sx, sy, sz)
        end
    end,

    ---@param self Prop
    ---@param reclaimer Unit The unit to compute the duration for.
    ---@return number time it takes to reclaim
    ---@return number energy to reclaim
    ---@return number mass to reclaim
    GetReclaimCosts = function(self, reclaimer)
        local maxMass = self.MaxMassReclaim or 0
        local maxEnergy = self.MaxEnergyReclaim or  0
        local timeReclaim = self.TimeReclaim or 0
        local maxValue = maxMass
        if maxEnergy > maxValue then
            maxValue = maxEnergy
        end

        local time = (timeReclaim or 0) * (maxValue / reclaimer:GetBuildRate())
        time = time / 10

        -- prevent division by 0 when the prop has no value
        if time < 0 then
            time = 0.0001
        end

        return time, maxEnergy, maxMass
    end,

    --- Split this prop into multiple sub-props, placing one at each of our bone locations.
    --- The child prop names are taken from the names of the bones of this prop.
    ---
    --- If this prop has bones named
    ---           "one", "two", "two_01", "two_02"
    ---
    --- We will create props named
    ---           "../one_prop.bp", "../two_prop.bp", "../two_prop.bp", "../two_prop.bp"
    ---
    --- Note that the optional _01, _02, _03 ending to the bone name is stripped off.
    ---
    --- You can pass an optional 'dirprefix' arg saying where to look for the child props.
    --- If not given, it defaults to one directory up from this prop's blueprint location.
    ---@param self Prop
    ---@param dirprefix string
    ---@return table
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
        local count = self:GetBoneCount() - 1

        -- compute information of new props
        local compensationMult = 2
        local time = time / count 
        local mass = (self.MaxMassReclaim * self.ReclaimLeft * compensationMult) / count
        local energy = (self.MaxEnergyReclaim * self.ReclaimLeft * compensationMult) / count
        for ibone = 1, count do

            -- get the bone name
            bone = self:GetBoneName(ibone)

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

        self:Destroy()
        return props
    end,

    ---@param self Prop
    ---@param sound string The identifier in the prop blueprint.
    PlayPropSound = function(self, sound)
        local bp = self.Blueprint.Audio
        if bp and bp[sound] then
            self:PlaySound(bp[sound])
        end
    end,

    ---@param self Prop
    ---@param sound string
    PlayPropAmbientSound = function(self, sound)
        if sound == nil then
            self:SetAmbientSound(nil, nil)
        else
            local bp = self.Blueprint.Audio
            if bp and bp[sound] then
                self:SetAmbientSound(bp[sound], nil)
            end
        end
    end,

    ---@param self Prop
    SetupUILabel = function(self)
        if not self.SyncData then
            self.SyncData = {
                mass = self.MaxMassReclaim * (self.ReclaimLeft or 1),
                position = self.CachePosition
            }
            Sync.Reclaim[self.EntityId] = self.SyncData
        end
    end,

    ---@param self Prop
    CleanupUILabel = function(self)
        local data = self.SyncData
        if data then
            data.mass = nil
            data.position = nil
            Sync.Reclaim[self.EntityId] = false

            self.SyncData = nil
        end
    end,

    ---@param self Prop
    UpdateUILabel = function(self)
        local data = self.SyncData
        if data then
            local mass = self.MaxMassReclaim * self.ReclaimLeft
            if mass < 10 then
                self:CleanupUILabel()
                return
            end

            data.mass = mass
            Sync.Reclaim[self.EntityId] = data
        end
    end,

    ---@see use `prop.CachePosition` directly instead
    ---@deprecated
    ---@param self Prop
    ---@return Vector
    GetCachePosition = function(self)
        return self.CachePosition
    end,

    ---@see no alternative, value is no longer in use
    ---@deprecated
    ---@param self Prop
    ---@param val boolean
    SetCanTakeDamage = function(self, val)
        self.CanTakeDamage = val
    end,

    ---@see use `prop.CanBeKilled` directly instead
    ---@deprecated
    ---@param self Prop
    ---@param val any
    SetCanBeKilled = function(self, val)
        self.CanBeKilled = val
    end,

    ---@see compare with `prop.CanBeKilled` directly instead
    ---@deprecated
    ---@param self Prop
    ---@return boolean
    CheckCanBeKilled = function(self)
        return self.CanBeKilled
    end,
}

PropInvulnerable = Class(Prop) {
    OnDamage = function() end,
    OnKilled = function() end,
    SetupUILabel = function() end,
    CleanupUILabel = function() end,
    UpdateUILabel = function() end,
}

-- imports kept for backwards compatibility with mods
local Entity = import("/lua/sim/entity.lua").Entity