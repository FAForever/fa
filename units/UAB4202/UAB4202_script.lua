----****************************************************************************
----**
----**  File     :  /cdimage/units/UAB4202/UAB4202_script.lua
----**  Author(s):  David Tomandl
----**
----**  Summary  :  Aeon Shield Generator Script
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local AShieldStructureUnit = import("/lua/aeonunits.lua").AShieldStructureUnit
local ShieldEffectsComponent = import("/lua/defaultcomponents.lua").ShieldEffectsComponent
local CreateMercuryPoolOnBone = import("/lua/EffectUtilitiesAeon.lua").CreateMercuryPoolOnBone

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add

---@class UAB4202 : AShieldStructureUnit, ShieldEffectsComponent
---@field OrbManip1? moho.RotateManipulator
---@field OrbManip2? moho.RotateManipulator
---@field MercuryPool? Projectile # Upgrade effect
---@field MercuryPool2? Projectile # Upgrade effect
---@field ShieldEnabled? boolean # Used in logic for upgrade effect
UAB4202 = ClassUnit(AShieldStructureUnit, ShieldEffectsComponent) {

    ShieldEffectsScale = 0.75,
    ShieldEffectsBone = 'Effect',
    ShieldEffects = {
        '/effects/emitters/aeon_shield_generator_t2_01_emit.bp',
        '/effects/emitters/aeon_shield_generator_t2_02_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_03_emit.bp',
        '/effects/emitters/aeon_shield_generator_t3_04_emit.bp',
    },

    ---@param self UAB4202
    OnCreate = function(self)
        AShieldStructureUnit.OnCreate(self)
        ShieldEffectsComponent.OnCreate(self)
        self.ShieldEnabled = false
    end,

    ---@param self AShieldStructureUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function (self, builder, layer)
        AShieldStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local trash = self.Trash

        local orbManip1 = CreateRotator(self, 'Orb', '-x', nil, 0, 45, 45)
        TrashBagAdd(trash, orbManip1)
        self.OrbManip1 = orbManip1

        local orbManip2 = CreateRotator(self, 'Orb', 'z', nil, 0, 45, 45)
        TrashBagAdd(trash, orbManip2)
        self.OrbManip2 = orbManip2
    end,

    ---@param self UAB4202
    OnShieldEnabled = function(self)
        AShieldStructureUnit.OnShieldEnabled(self)
        ShieldEffectsComponent.OnShieldEnabled(self)
        for _, effect in self.ShieldEffectsBag do
            effect:OffsetEmitter(0, -2.2, 0)
        end

        local orbManip1 = self.OrbManip1
        if orbManip1 then
            -- Spin down very quickly since the rotator bugs out with the upgrade animation
            if self:IsUnitState('Upgrading') then
                orbManip1:SetSpinDown(true)
                orbManip1:SetTargetSpeed(9999)
            else
                orbManip1:SetSpinDown(false)
                orbManip1:SetTargetSpeed(45)
            end
        end

        local orbManip2 = self.OrbManip2
        if orbManip2 then
            -- Spin down very quickly since the rotator bugs out with the upgrade animation
            if self:IsUnitState('Upgrading') then
                orbManip2:SetSpinDown(true)
                orbManip2:SetTargetSpeed(9999)
            else
                orbManip2:SetSpinDown(false)
                orbManip2:SetTargetSpeed(45)
            end
        end

        self.ShieldEnabled = true
    end,

    ---@param self UAB4202
    OnShieldDisabled = function(self)
        AShieldStructureUnit.OnShieldDisabled(self)
        ShieldEffectsComponent.OnShieldDisabled(self)

        local orbManip1 = self.OrbManip1
        if orbManip1 then
            orbManip1:SetSpinDown(true)
        end

        local orbManip2 = self.OrbManip2
        if orbManip2 then
            orbManip2:SetSpinDown(true)
        end

        self.ShieldEnabled = false
    end,

    ---@param self UAB4202
    ---@param unitBeingBuilt Unit
    ---@param order BuildOrderType
    ---@return boolean
    OnStartBuild = function(self, unitBeingBuilt, order)
        if not AShieldStructureUnit.OnStartBuild(self, unitBeingBuilt, order) then return false end

        if order == "Upgrade" then
            self.MercuryPool = CreateMercuryPoolOnBone(self, self.Army, 'Pool', 1.5, 1.5, 1.5, 0.1)
            self.MercuryPool2 = CreateMercuryPoolOnBone(self, self.Army, 'Ramp2', 0.65, 0.65, 0.65, 0.1)

            -- Spin down very quickly since the rotator bugs out with the upgrade animation
            local orbManip1 = self.OrbManip1
            if orbManip1 then
                orbManip1:SetSpinDown(true)
                orbManip1:SetTargetSpeed(9999)
            end
            local orbManip2 = self.OrbManip2
            if orbManip2 then
                orbManip2:SetSpinDown(true)
                orbManip2:SetTargetSpeed(9999)
            end
        end

        return true
    end,

    ---@param self UAB4202
    ---@param unitBeingBuilt Unit
    ---@param order BuildOrderType
    OnStopBuild = function(self, unitBeingBuilt, order)
        AShieldStructureUnit.OnStopBuild(self, unitBeingBuilt, order)

        if order == "Upgrade" then
            self.MercuryPool:Destroy()
            self.MercuryPool2:Destroy()
            if self.ShieldEnabled then
                local orbManip1 = self.OrbManip1
                if orbManip1 then
                    orbManip1:SetSpinDown(false)
                    orbManip1:SetTargetSpeed(45)
                end
                local orbManip2 = self.OrbManip2
                if orbManip2 then
                    orbManip2:SetSpinDown(false)
                    orbManip2:SetTargetSpeed(45)
                end
            end
        end
    end,
}

TypeClass = UAB4202
