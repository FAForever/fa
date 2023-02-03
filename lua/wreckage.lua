--****************************************************************************
--**
--**  File     : /lua/wreckage.lua
--**
--**  Summary  : Class for wreckage so it can get pushed around
--**
--**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import("/lua/sim/prop.lua").Prop

local CreateProp = CreateProp

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
local EntitySetOrientation = EntityMethods.SetOrientation
local EntityBeenDestroyed = EntityMethods.BeenDestroyed
local EntityGetFractionComplete = EntityMethods.GetFractionComplete
local EntitySetCollisionShape = EntityMethods.SetCollisionShape
local EntityGetBoneCount = EntityMethods.GetBoneCount
local EntityGetBoneName = EntityMethods.GetBoneName
local EntitySetAmbientSound = EntityMethods.SetAmbientSound

local EntityGetCollisionExtents = EntityMethods.GetCollisionExtents
local EntityGetOrientation = EntityMethods.GetOrientation
local EntitySetScale = EntityMethods.SetScale
local EntitySetMesh = EntityMethods.SetMesh


---@class Wreckage : Prop
Wreckage = Class(Prop) {

    OnCreate = function(self)

        -- -- Caching

        self.Trash = TrashBag()
        self.EntityId = EntityGetEntityId(self)
        self.Blueprint = EntityGetBlueprint(self)
        self.CachePosition = EntityGetPosition(self)
        self.SyncData = { }

        -- -- Set state

        self.IsWreckage = true
        self.CanTakeDamage = true 
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if self.CanTakeDamage then 
            self:DoTakeDamage(instigator, amount, vector, damageType)
        end
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        EntityAdjustHealth(self, instigator, -amount)
        local health = EntityGetHealth(self)

        if health <= 0 then
            self:DoPropCallbacks('OnKilled')
            EntityDestroy(self)
        else
            self:UpdateReclaimLeft()
        end
    end,

    OnCollisionCheck = function(self, other)
        return false
    end,

    --- Create and return an identical wreckage prop. Useful for replacing this one when something
    -- (a stupid engine bug) deleted it when we don't want it to.
    -- This function has the handle the case when *this* unit has already been destroyed. Notably,
    -- this means we have to calculate the health from the reclaim values, instead of going the
    -- other way.
    Clone = function(self)
        local clone = CreateWreckage(
            __blueprints[self.AssociatedBP], 
            self.CachePosition, 
            EntityGetOrientation(self), 
            self.MaxMassReclaim, 
            self.MaxEnergyReclaim, 
            self.TimeReclaim, 
            EntityGetCollisionExtents(self)
        )

        -- Figure out the health this wreck had before it was deleted. We can't use any native
        -- functions like GetHealth(), so we use the latest known value

        EntitySetHealth(clone, nil, clone:GetMaxHealth() * (self.ReclaimLeft or 1))
        clone:UpdateReclaimLeft()

        return clone
    end,

    Rebuild = function(self, units)
        local rebuilders = {}
        local assisters = {}
        local bpid = self.AssociatedBP

        for _, u in units do
            if u:CanBuild(bpid) then
                table.insert(rebuilders, u)
            else
                table.insert(assisters, u)
            end
        end

        if not rebuilders[1] then return end
        local pos = self:GetPosition()
        for _, u in rebuilders do
            IssueBuildMobile({u}, pos, bpid, {})
        end
        if assisters[1] then
            IssueGuard(assisters, pos)
        end
    end,
}

--- Create a wreckage prop.
function CreateWreckage(bp, position, orientation, mass, energy, time, deathHitBox)
    local wreck = bp.Wreckage
    local bpWreck = bp.Wreckage.Blueprint

    local prop = CreateProp(position, bpWreck)
    EntitySetOrientation(prop, orientation, true)
    EntitySetScale(prop, bp.Display.UniformScale)

    -- take the default center (cx, cy, cz) and size (sx, sy, sz)
    local cx, cy, cz, sx, sy, sz;
    cx = bp.CollisionOffsetX
    cy = bp.CollisionOffsetY
    cz = bp.CollisionOffsetZ
    sx = bp.SizeX
    sy = bp.SizeY
    sz = bp.SizeZ

    -- if a death animation is played the wreck hitbox may need some changes
    if deathHitBox then
        cx = deathHitBox.CollisionOffsetX or cx
        cy = deathHitBox.CollisionOffsetY or cy
        cz = deathHitBox.CollisionOffsetZ or cz
        sx = deathHitBox.SizeX or sx
        sy = deathHitBox.SizeY or sy
        sz = deathHitBox.SizeZ or sz
    end

    -- adjust the size, these dimensions are in both directions based on the center
    sx = sx * 0.5
    sy = sy * 0.5
    sz = sz * 0.5

    -- set health
    EntitySetMaxHealth(prop, bp.Defense.Health)
    EntitySetHealth(prop, nil, bp.Defense.Health * (bp.Wreckage.HealthMult or 1))

    -- set collision box and reclaim values, the latter depends on the health of the wreck
    prop:SetPropCollision('Box', cx, cy, cz, sx, sy, sz)
    prop:SetMaxReclaimValues(time, mass, energy)

    --FIXME: SetVizToNeurals('Intel') is correct here, so you can't see enemy wreckage appearing
    -- under the fog. However the engine has a bug with prop intel that makes the wreckage
    -- never appear at all, even when you drive up to it, so this is disabled for now.
    -- tested 2022-03-23: this works :)), but clashes with the reclaim labels that expects wrecks to be always visible
    -- prop:SetVizToNeutrals('Intel')

    if not bp.Wreckage.UseCustomMesh then
        EntitySetMesh(prop, bp.Display.MeshBlueprintWrecked)
    end

    -- This field cannot be renamed or the magical native code that detects rebuild bonuses breaks.
    prop.AssociatedBP = bp.Wreckage.IdHook or bp.BlueprintId

    return prop
end
