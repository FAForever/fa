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
    Clone = function(self)
        local clone = GetWreckageForBlueprint(self.AssociatedBP, self:GetPosition(), self:GetOrientation(), self.MassReclaim, self.EnergyReclaim, self.ReclaimTimeMassMult)
        clone:SetHealth(self:GetHealth())
        clone:SetReclaimValuesByHealth()

        return clone
    end

}

function CreateWreckage(bp, position, orientation, mass, energy, time)
    local bpWreck = bp.Wreckage.Blueprint

    local prop = CreateProp(position, bpWreck)
    prop:SetScale(bp.Display.UniformScale)
    prop:SetOrientation(orientation, true)
    prop:SetPropCollision('Box', bp.CollisionOffsetX, bp.CollisionOffsetY, bp.CollisionOffsetZ, bp.SizeX* 0.5, bp.SizeY* 0.5, bp.SizeZ * 0.5)

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

    prop.AssociatedBP = bp.BlueprintId

    return prop
end
