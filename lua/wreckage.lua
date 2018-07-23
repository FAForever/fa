--****************************************************************************
--**
--**  File     : /lua/wreckage.lua
--**
--**  Summary  : Class for wreckage so it can get pushed around
--**
--**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import('/lua/sim/Prop.lua').Prop

Wreckage = Class(Prop) {

    OnCreate = function(self)
        Prop.OnCreate(self)
        self.IsWreckage = true
        self.OrientationCache = self:GetOrientation()
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.CanTakeDamage then return end
        self:DoTakeDamage(instigator, amount, vector, damageType)
    end,

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

    OnCollisionCheck = function(self, other)
        if IsUnit(other) then
            return false
        else
            return true
        end
    end,

    --- Create and return an identical wreckage prop. Useful for replacing this one when something
    -- (a stupid engine bug) deleted it when we don't want it to.
    -- This function has the handle the case when *this* unit has already been destroyed. Notably,
    -- this means we have to calculate the health from the reclaim values, instead of going the
    -- other way.
    Clone = function(self)
        local clone = CreateWreckage(__blueprints[self.AssociatedBP], self.CachePosition, self.OrientationCache, self.MaxMassReclaim, self.MaxEnergyReclaim, self.TimeReclaim)

        -- Figure out the health this wreck had before it was deleted. We can't use any native
        -- functions like GetHealth(), so we use the latest known value

        clone:SetHealth(nil, clone:GetMaxHealth() * (self.ReclaimLeft or 1))
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
function CreateWreckage(bp, position, orientation, mass, energy, time, massRatio)
    local bpWreck = bp.Wreckage.Blueprint

    local prop = CreateProp(position, bpWreck)
    prop:SetOrientation(orientation, true)

    prop:SetScale(bp.Display.UniformScale)
    prop:SetPropCollision('Box', bp.CollisionOffsetX, bp.CollisionOffsetY, bp.CollisionOffsetZ, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)

    prop:SetMaxHealth(bp.Defense.Health)
    prop:SetHealth(nil, bp.Defense.Health * (massRatio or bp.Wreckage.HealthMult or 1))
    prop:SetMaxReclaimValues(time, mass, energy)

    --FIXME: SetVizToNeurals('Intel') is correct here, so you can't see enemy wreckage appearing
    -- under the fog. However the engine has a bug with prop intel that makes the wreckage
    -- never appear at all, even when you drive up to it, so this is disabled for now.
    --prop:SetVizToNeutrals('Intel')
    if not bp.Wreckage.UseCustomMesh then
        prop:SetMesh(bp.Display.MeshBlueprintWrecked)
    end

    -- This field cannot be renamed or the magical native code that detects rebuild bonuses breaks.
    prop.AssociatedBP = bp.BlueprintId

    return prop
end
