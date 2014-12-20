--****************************************************************************
--**
--**  File     :  /lua/sim/Prop.lua
--**  Author(s):
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
--
-- The base Prop lua class
--
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectUtil = import('/lua/EffectUtilities.lua')

--for CBFP:
local Game = import('/lua/game.lua')
local RebuildBonusCheckCallback = import('/lua/sim/RebuildBonusCallback.lua').RunRebuildBonusCallback



Prop = Class(moho.prop_methods, Entity) {

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self,spec)
    end,
    __post_init = function(self,spec)
    end,

    OnCreate = function(self)
        Entity.OnCreate(self)
        self.Trash = TrashBag()
        local bp = self:GetBlueprint().Economy
        self.MassReclaim = bp.ReclaimMassMax or 0
        self.EnergyReclaim = bp.ReclaimEnergyMax or 0
        self.ReclaimTimeMassMult = bp.ReclaimMassTimeMultiplier or 1
        self.ReclaimTimeEnergyMult = bp.ReclaimEnergyTimeMultiplier or 1
        self.MaxMassReclaim = bp.ReclaimMassMax or 0
        self.MaxEnergyReclaim = bp.ReclaimEnergyMax or 0
        self.CachePosition = self:GetPosition()

        local defense = self:GetBlueprint().Defense
        local maxHealth = 50
        if defense then
            maxHealth = math.max(maxHealth,defense.MaxHealth)
        end
        self:SetMaxHealth(maxHealth)
        self:SetHealth(self,maxHealth)
        if not EntityCategoryContains(categories.INVULNERABLE, self) then
            self:SetCanTakeDamage(true)
        else
            self:SetCanTakeDamage(false)
        end

        self:SetCanBeKilled(true)
    end,

    --Returns the cache position of the prop, since it doesn't move, it's a big optimization
    GetCachePosition = function(self)
        return self.CachePosition
    end,

    --Sets if the unit can take damage.  val = true means it can take damage.
    --val = false means it can't take damage
    SetCanTakeDamage = function(self, val)
        self.CanTakeDamage = val
    end,

    --Sets if the unit can be killed.  val = true means it can be killed.
    --val = false means it can't be killed
    SetCanBeKilled = function(self, val)
        self.CanBeKilled = val
    end,

    CheckCanBeKilled = function(self,other)
        return self.CanBeKilled
    end,

    OnKilled = function(self, instigator, type, exceessDamageRatio )
        if not self.CanBeKilled then return end
        self:Destroy()
    end,

    OnReclaimed = function(self, entity)
        self.CreateReclaimEndEffects( entity, self )
        self:Destroy()
    end,

    CreateReclaimEndEffects = function( self, target )
        EffectUtil.PlayReclaimEndEffects( self, target )
    end,

    Destroy = function(self)
        self.DestroyCalled = true
        Entity.Destroy(self)
    end,

    OnDestroy = function(self)
        if self.IsWreckage and not self.DestroyCalled then
            RebuildBonusCheckCallback(self:GetPosition(), self.AssociatedBP)
        end
        self.Trash:Destroy()
    end,

    OnDamage = function(self, instigator, amount, direction, damageType)
        if not self.CanTakeDamage then return end
        local preAdjHealth = self:GetHealth()
        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if( health <= 0 ) then
            if( damageType == 'Reclaimed' ) then
                self:Destroy()
            else
                local excessDamageRatio = 0.0
                -- Calculate the excess damage amount
                local excess = preAdjHealth - amount
                local maxHealth = self:GetMaxHealth()
                if(excess < 0 and maxHealth > 0) then
                    excessDamageRatio = -excess / maxHealth
                end
                self:Kill(instigator, damageType, excessDamageRatio)
            end
        end
    end,

    OnCollisionCheck = function(self, other)
        return true
    end,

    SetReclaimValues = function(self, masstimemult, energytimemult, mass, energy)
        self.MassReclaim = math.max( 0, mass )
        self.EnergyReclaim = math.max( 0, energy )
        self.ReclaimTimeMassMult = masstimemult
        self.ReclaimTimeEnergyMult = energytimemult
    end,

    SetMaxReclaimValues = function(self, masstimemult, energytimemult, mass, energy)
        self.MaxMassReclaim = math.max( 0, mass )
        self.MaxEnergyReclaim = math.max( 0, energy )
        self.ReclaimTimeMassMult = masstimemult
        self.ReclaimTimeEnergyMult = energytimemult
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
            self:SetCollisionShape(shape, centerx, centery, centerz, sizex, sizey, sizez, radius)
        else
            self:SetCollisionShape(shape, centerx, centery, centerz, sizex, sizey, sizez)
        end
    end,


    --Prop reclaiming
    -- time = the greater of either time to reclaim mass or energy
    -- time to reclaim mass or energy is defined as:
    -- Mass Time =  mass reclaim value / buildrate of thing reclaiming it * BP set mass mult
    -- Energy Time = energy reclaim value / buildrate of thing reclaiming it * BP set energy mult
    -- The time to reclaim is the highest of the two values above.
    GetReclaimCosts = function(self, reclaimer)
        local rbp = reclaimer:GetBlueprint()
        local mtime = self.ReclaimTimeMassMult * (self.MassReclaim / reclaimer:GetBuildRate() )
        local etime = self.ReclaimTimeEnergyMult * (self.EnergyReclaim / reclaimer:GetBuildRate() )
        local time = mtime
        if mtime < etime then
            time = etime
        end
        time = math.max( (time/10), 0.0001)  -- this should never be 0 or we'll divide by 0!
        return time, self.EnergyReclaim, self.MassReclaim
    end,



    --
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
    --
    SplitOnBonesByName = function(self, dirprefix)
        if not dirprefix then
            -- default dirprefix to parent dir of our own blueprint
            dirprefix = self:GetBlueprint().BlueprintId

            -- trim ".../groups/blah_prop.bp" to just ".../"
            dirprefix = string.gsub(dirprefix, "[^/]*/[^/]*$", "")
        end

        local newprops = {}

        for ibone=1, self:GetBoneCount()-1 do
            local bone = self:GetBoneName(ibone)

            -- construct name of replacement mesh from name of bone, trimming off optional _01 _02 etc
            local btrim = string.gsub(bone, "_?[0-9]+$", "")
            local newbp = dirprefix .. btrim .. "_prop.bp"

            local p = safecall("Creating prop", self.CreatePropAtBone, self, ibone, newbp)
            if p then
                table.insert(newprops, p)
            end
        end

        self:Destroy()
        return newprops
    end,


    PlayPropSound = function(self, sound)
        local bp = self:GetBlueprint().Audio
        if bp and bp[sound] then
            --LOG( 'Playing ', sound )
            self:PlaySound(bp[sound])
            return true
        end
        --LOG( 'Could not play ', sound )
        return false
    end,


    -- Play the specified ambient sound for the unit, and if it has
    -- AmbientRumble defined, play that too
    PlayPropAmbientSound = function(self, sound)
        if sound == nil then
            self:SetAmbientSound( nil, nil )
            return true
        else
            local bp = self:GetBlueprint().Audio
            if bp and bp[sound] then
                if bp.Audio['AmbientRumble'] then
                    self:SetAmbientSound( bp[sound], bp.Audio['AmbientRumble'] )
                else
                    self:SetAmbientSound( bp[sound], nil )
                end
                return true
            end
            return false
        end
    end,
}
