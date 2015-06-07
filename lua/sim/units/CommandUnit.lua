local WalkingLandUnit = import('/lua/sim/units/WalkingLandUnit.lua').WalkingLandUnit

--- Base class for commanders (ACU/SCU)
CommandUnit = Class(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch( self.BuildArmManipulator:GetHeadingPitch() )
    end,

    OnFailedToBuild = function(self)
        WalkingLandUnit.OnFailedToBuild(self)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnStopCapture = function(self, target)
        WalkingLandUnit.OnStopCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnFailedCapture = function(self, target)
        WalkingLandUnit.OnFailedCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnStopReclaim = function(self, target)
        WalkingLandUnit.OnStopReclaim(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    OnPrepareArmToBuild = function(self)
        WalkingLandUnit.OnPrepareArmToBuild(self)
        if self:BeenDestroyed() then return end

        self:BuildManipulatorSetEnabled(true)
        self.BuildArmManipulator:SetPrecedence(20)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, false)
        self.BuildArmManipulator:SetHeadingPitch(self:GetWeaponManipulatorByLabel(self.rightGunLabel):GetHeadingPitch())
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        WalkingLandUnit.OnStopBuild(self, unitBeingBuilt)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()

        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnPaused = function(self)
        WalkingLandUnit.OnPaused(self)
        if self.BuildingUnit then
            WalkingLandUnit.StopBuildingEffects(self, self:GetUnitBeingBuilt())
        end
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            WalkingLandUnit.StartBuildingEffects(self, self:GetUnitBeingBuilt(), self.UnitBuildOrder)
        end
        WalkingLandUnit.OnUnpaused(self)
    end
}
