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

---@class Wreckage : Prop
Wreckage = Class(Prop) {

    IsWreckage = true,

    ---@param self Wreckage
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        self:DoTakeDamage(instigator, amount, vector, damageType)
    end,

    ---@param self Wreckage
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()

        if health <= 0 then
            self:DoPropCallbacks('OnKilled')
            self:Destroy()
        else
            self:UpdateReclaimLeft()
        end
    end,

    ---@param self Wreckage
    ---@param other Projectile
    ---@return boolean
    OnCollisionCheck = function(self, other)
        return false
    end,

    --- Create and return an identical wreckage prop. Useful for replacing this one when something
    -- (a stupid engine bug) deleted it when we don't want it to.
    -- This function has the handle the case when *this* unit has already been destroyed. Notably,
    -- this means we have to calculate the health from the reclaim values, instead of going the
    -- other way.
    ---@param self Wreckage
    ---@return Wreckage
    Clone = function(self)
        local clone = CreateWreckage(
            __blueprints[self.AssociatedBP],
            self.CachePosition,
            self:GetOrientation(),
            self.MaxMassReclaim,
            self.MaxEnergyReclaim,
            self.TimeReclaim,
            self:GetCollisionExtents()
        )

        -- Figure out the health this wreck had before it was deleted. We can't use any native
        -- functions like GetHealth(), so we use the latest known value

        clone:SetHealth(nil, clone:GetMaxHealth() * (self.ReclaimLeft or 1))
        clone:UpdateReclaimLeft()

        return clone
    end,

    ---@param self Wreckage
    ---@param units Unit[]
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
---@param bp PropBlueprint
---@param position Vector
---@param orientation Quaternion
---@param mass number
---@param energy number
---@param time number
---@param deathHitBox? table
---@return Prop
function CreateWreckage(bp, position, orientation, mass, energy, time, deathHitBox)
    local prop = CreateProp(position, bp.Wreckage.Blueprint)
    prop:SetOrientation(orientation, true)
    prop:SetScale(bp.Display.UniformScale)

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
    prop:SetMaxHealth(bp.Defense.Health * (bp.Wreckage.HealthMult or 1))
    prop:SetHealth(nil, bp.Defense.Health * (bp.Wreckage.HealthMult or 1))

    -- set collision box and reclaim values, the latter depends on the health of the wreck
    prop:SetPropCollision('Box', cx, cy, cz, sx, sy, sz)
    prop:SetMaxReclaimValues(time, mass, energy)

    --FIXME: SetVizToNeurals('Intel') is correct here, so you can't see enemy wreckage appearing
    -- under the fog. However the engine has a bug with prop intel that makes the wreckage
    -- never appear at all, even when you drive up to it, so this is disabled for now.
    -- tested 2022-03-23: this works :)), but clashes with the reclaim labels that expects wrecks to be always visible
    -- prop:SetVizToNeutrals('Intel')

    if not bp.Wreckage.UseCustomMesh then
        prop:SetMesh(bp.Display.MeshBlueprintWrecked, true)
    end

    -- This field cannot be renamed or the magical native code that detects rebuild bonuses breaks.
    prop.AssociatedBP = bp.Wreckage.IdHook or bp.BlueprintId

    return prop
end
