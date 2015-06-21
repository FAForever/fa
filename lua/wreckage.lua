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
        self:DoTakeDamage(instigator, amount, vector, damageType)
    end,

    --- Set the reclaim value of the prop to an appropriate fraction of its health.
    SetReclaimValuesByHealth = function(self)
        local healthRatio = self:GetHealth() / self:GetMaxHealth()

        self:SetReclaimValues(
            self.MaxReclaimTimeMult * healthRatio,
            self.MaxMassReclaim * healthRatio,
            self.MaxEnergyReclaim * healthRatio
        )
    end,

    --- Set the mass/energy value of this wreck when at full health, and the time coefficients
    -- that determine how quickly it can be reclaimed.
    -- These values are used to set te real reclaim values as fractions of the health as the wreck
    -- takes damage.
    SetMaxReclaimValues = function(self, time, mass, energy)
        self.MaxMassReclaim = mass
        self.MaxEnergyReclaim = energy
        self.MaxReclaimTimeMult = time
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health > 0 then
            self:SetReclaimValuesByHealth()
        elseif health <= 0 then
            self:Destroy()
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
        local clone = CreateWreckage(self.UnitBlueprint, self.CachePosition, self.OrientationCache, self.MassReclaim, self.EnergyReclaim, self.ReclaimTimeMassMult)

        -- Figure out the health this wreck had before it was deleted. We can't use any native
        -- functions like GetHealth(), so we work backwards what what we do have: the reclaim value.
        local healthFraction
        if self.MassReclaim > 0 then
            healthFraction = self.MassReclaim/self.MaxMassReclaim
        elseif self.EnergyReclaim then
            healthFraction = self.EnergyReclaim/self.MaxEnergyReclaim
        else
            -- This wreck had no value anyway. We don't care about recreating it.
            return
        end

        clone:SetHealth(nil, clone:GetMaxHealth() * healthFraction)
        clone:SetReclaimValuesByHealth()

        return clone
    end

}

--- Create a wreckage prop.
function CreateWreckage(bp, position, orientation, mass, energy, time)
    local bpWreck = bp.Wreckage.Blueprint

    local prop = CreateProp(position, bpWreck)
    prop:SetOrientation(orientation, true)

    prop:SetScale(bp.Display.UniformScale)
    prop:SetPropCollision('Box', bp.CollisionOffsetX, bp.CollisionOffsetY, bp.CollisionOffsetZ, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)

    prop:SetMaxHealth(bp.Defense.Health)
    prop:SetHealth(nil, bp.Defense.Health * (bp.Wreckage.HealthMult or 1))

    prop:SetMaxReclaimValues(time, mass, energy)
    prop:SetReclaimValuesByHealth()

    --FIXME: SetVizToNeurals('Intel') is correct here, so you can't see enemy wreckage appearing
    -- under the fog. However the engine has a bug with prop intel that makes the wreckage
    -- never appear at all, even when you drive up to it, so this is disabled for now.
    --prop:SetVizToNeutrals('Intel')
    if not bp.Wreckage.UseCustomMesh then
        prop:SetMesh(bp.Display.MeshBlueprintWrecked)
    end

    -- This field cannot be renamed or the magical native code that detects rebuild bonuses breaks.
    prop.AssociatedBP = bp.BlueprintId
    prop.UnitBlueprint = bp

    return prop
end
