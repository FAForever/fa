local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

---@class OverchargeWeapon : DefaultProjectileWeapon
OverchargeWeapon = ClassWeapon(DefaultProjectileWeapon) {
    NeedsUpgrade = false,
    AutoMode = false,
    AutoThread = nil,
    EnergyRequired = nil,

    ---@param self OverchargeWeapon
    ---@return boolean
    HasEnergy = function(self)
        return self.Brain:GetEconomyStored('ENERGY') >= self.EnergyRequired
    end,

    -- Can we use the OC weapon?
    ---@param self OverchargeWeapon
    ---@return boolean
    CanOvercharge = function(self)
        local unit = self.unit
        return not unit:IsOverchargePaused() and self:HasEnergy() and not
            self:UnitOccupied() and not
            unit:IsUnitState('Enhancing') and not
            unit:IsUnitState('Upgrading')
    end,

    ---@param self OverchargeWeapon
    StartEconomyDrain = function(self) -- OverchargeWeapon drains energy on impact
    end,

    -- Returns true if the unit is doing something that shouldn't allow any weapon fire
    ---@param self OverchargeWeapon
    ---@return boolean
    UnitOccupied = function(self)
        local unit = self.unit
        return (unit:IsUnitState('Upgrading') and not unit:IsUnitState('Enhancing')) or
            -- Don't let us shoot if we're upgrading, unless it's an enhancement task
            unit:IsUnitState('Building') or
            unit:IsUnitState('Repairing') or
            unit:IsUnitState('Reclaiming')
    end,

    -- The Overcharge cool-down function
    ---@param self OverchargeWeapon
    PauseOvercharge = function(self)
        local unit = self.unit
        if not unit:IsOverchargePaused() then
            unit:SetOverchargePaused(true)
            self:OnDisableWeapon()
            WaitSeconds(1 / self.Blueprint.RateOfFire)
            self.unit:SetOverchargePaused(false)
        end
    end,

    ---@param self OverchargeWeapon
    AutoEnable = function(self)
        while not self:CanOvercharge() do
            WaitSeconds(0.1)

        end

        if self.AutoMode then
            self:OnEnableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    ---@param auto boolean
    SetAutoOvercharge = function(self, auto)
        self.AutoMode = auto

        local autoThread = self.AutoThread
        if autoThread then
            KillThread(autoThread)
            self.AutoThread = nil
        end

        if self.AutoMode then
            self.AutoThread = self:ForkThread(self.AutoEnable)
        elseif self.enabled then
            self:OnDisableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    OnCreate = function(self)
        DefaultProjectileWeapon.OnCreate(self)
        self.EnergyRequired = self.Blueprint.EnergyRequired
        self:SetWeaponEnabled(false)
        local aimControl = self.AimControl
        aimControl:SetEnabled(false)
        aimControl:SetPrecedence(0)
        self.unit:SetOverchargePaused(false)
    end,

    ---@param self OverchargeWeapon
    OnGotTarget = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnGotTarget(self)
        else
            self:OnDisableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    OnFire = function(self)
        if self:CanOvercharge() then
            DefaultProjectileWeapon.OnFire(self)
        else
            self:OnDisableWeapon()
        end
    end,

    ---@param self OverchargeWeapon
    ---@return boolean
    IsEnabled = function(self)
        return self.enabled
    end,

    ---@param self OverchargeWeapon
    OnEnableWeapon = function(self)
        if self:BeenDestroyed() then return end
        DefaultProjectileWeapon.OnEnableWeapon(self)
        local unit = self.unit
        local weaponLabel = self.DesiredWeaponLabel
        local aimControl = self.AimControl
        self:SetWeaponEnabled(true)
        if self:CanOvercharge() then
            unit:SetWeaponEnabledByLabel(weaponLabel, false)
        end
        unit:BuildManipulatorSetEnabled(false)
        aimControl:SetEnabled(true)
        aimControl:SetPrecedence(20)
        unit.BuildArmManipulator:SetPrecedence(0)
        aimControl:SetHeadingPitch(unit:GetWeaponManipulatorByLabel(weaponLabel):GetHeadingPitch())
        self.enabled = true
    end,

    ---@param self OverchargeWeapon
    OnDisableWeapon = function(self)
        local unit = self.unit
        if unit:BeenDestroyed() then return end
        self:SetWeaponEnabled(false)
        local weaponLabel = self.DesiredWeaponLabel
        local aimControl = self.AimControl
        -- Only allow it to turn on the primary weapon if the unit is ready
        if not self:UnitOccupied() then
            unit:SetWeaponEnabledByLabel(weaponLabel, true)
        end

        unit:BuildManipulatorSetEnabled(false)
        aimControl:SetEnabled(false)
        aimControl:SetPrecedence(0)
        unit.BuildArmManipulator:SetPrecedence(0)
        unit:GetWeaponManipulatorByLabel(weaponLabel):SetHeadingPitch(aimControl:GetHeadingPitch())

        self.enabled = false

        if self.AutoMode then
            self.AutoThread = self:ForkThread(self.AutoEnable)
        end
    end,

    ---@param self OverchargeWeapon
    OnWeaponFired = function(self)
        DefaultProjectileWeapon.OnWeaponFired(self)
        self:ForkThread(self.PauseOvercharge)
    end,

    -- Weapon State Modifications
    IdleState = State(DefaultProjectileWeapon.IdleState) {
        OnGotTarget = function(self)
            if self:CanOvercharge() then
                DefaultProjectileWeapon.IdleState.OnGotTarget(self)
            else
                self:ForkThread(function()
                    while self.enabled and not self:CanOvercharge() do
                        WaitSeconds(0.1)
                    end

                    if self.enabled then
                        self:OnGotTarget()
                    end
                end)
            end
        end,

        OnFire = function(self)
            if self:CanOvercharge() then
                ChangeState(self, self.RackSalvoFiringState)
            else
                self:OnDisableWeapon()
            end
        end,
    },

    RackSalvoFireReadyState = State(DefaultProjectileWeapon.RackSalvoFireReadyState) {
        OnFire = function(self)
            if self:CanOvercharge() then
                DefaultProjectileWeapon.RackSalvoFireReadyState.OnFire(self)
            else
                self:OnDisableWeapon()
            end
        end,
    }
}
