
local EffectTemplate = import("/lua/effecttemplates.lua")

local WalkingLandUnit = import("/lua/sim/units/walkinglandunit.lua").WalkingLandUnit

---@class CommandUnit : WalkingLandUnit
---@field BuildArmManipulator moho.AimManipulator
---@field BuildingUnit boolean
---@field UnitBeingBuilt? Unit
---@field UnitBuildOrder? string
---@field rightGunLabel string
CommandUnit = ClassUnit(WalkingLandUnit) {
    DeathThreadDestructionWaitTime = 2,

    ---@param self CommandUnit
    ---@param rightGunName string
    __init = function(self, rightGunName)
        self.rightGunLabel = rightGunName
    end,

    ---@param self CommandUnit
    OnCreate = function(self)
        WalkingLandUnit.OnCreate(self)

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
    end,

    ---@param self CommandUnit
    ResetRightArm = function(self)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, true)
        self:GetWeaponManipulatorByLabel(self.rightGunLabel):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self:SetImmobile(false)
    end,

    ---@param self CommandUnit
    OnFailedToBuild = function(self)
        WalkingLandUnit.OnFailedToBuild(self)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnStopCapture = function(self, target)
        WalkingLandUnit.OnStopCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnFailedCapture = function(self, target)
        WalkingLandUnit.OnFailedCapture(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    ---@param target Unit
    OnStopReclaim = function(self, target)
        WalkingLandUnit.OnStopReclaim(self, target)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()
    end,

    ---@param self CommandUnit
    OnPrepareArmToBuild = function(self)
        WalkingLandUnit.OnPrepareArmToBuild(self)
        if self:BeenDestroyed() then return end

        self:BuildManipulatorSetEnabled(true)
        self.BuildArmManipulator:SetPrecedence(20)
        self:SetWeaponEnabledByLabel(self.rightGunLabel, false)
        self.BuildArmManipulator:SetHeadingPitch(self:GetWeaponManipulatorByLabel(self.rightGunLabel):GetHeadingPitch())

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if self:IsMoving() then
            local navigator = self:GetNavigator()
            navigator:AbortMove()
        end
    end,

    ---@param self CommandUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        WalkingLandUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt

        if order ~= 'Upgrade' then
            self.BuildingUnit = true
        end

        -- Check if we're about to try and build something we shouldn't. This can only happen due to
        -- a native code bug in the SCU REBUILDER behaviour.
        -- FractionComplete is zero only if we're the initiating builder. Clearly, we want to allow
        -- assisting builds of other races, just not *starting* them.
        -- We skip the check if we're assisting another builder: it's up to them to have the ability
        -- to start this build, not us.
        if not self:GetGuardedUnit() and unitBeingBuilt:GetFractionComplete() == 0 and not self:CanBuild(unitBeingBuilt.Blueprint.BlueprintId) then
            IssueStop({self})
            IssueClearCommands({self})
            unitBeingBuilt:Destroy()
        end
    end,

    ---@param self CommandUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        WalkingLandUnit.OnStopBuild(self, unitBeingBuilt)
        if self:BeenDestroyed() then return end
        self:ResetRightArm()

        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    ---@param self CommandUnit
    OnPaused = function(self)
        WalkingLandUnit.OnPaused(self)
        if self.BuildingUnit then
            WalkingLandUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self CommandUnit
    OnUnpaused = function(self)
        if self.BuildingUnit then
            WalkingLandUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        WalkingLandUnit.OnUnpaused(self)
    end,

    ---@param self CommandUnit
    ---@param auto boolean
    SetAutoOvercharge = function(self, auto)
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        if wep.NeedsUpgrade then return end

        wep:SetAutoOvercharge(auto)
        self.Sync.AutoOvercharge = auto
    end,

    ---@param self CommandUnit
    ---@param bones string
    PlayCommanderWarpInEffect = function(self, bones)
        self:HideBone(0, true)
        self:SetUnSelectable(true)
        self:SetBusy(true)
        self:ForkThread(self.WarpInEffectThread, bones)
    end,

    ---@param self CommandUnit
    ---@param bones Bone[]
    WarpInEffectThread = function(self, bones)
        self:PlayUnitSound('CommanderArrival')
        self:CreateProjectile('/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(2.1)

        local bp = self.Blueprint
        local psm = bp.Display.WarpInEffect.PhaseShieldMesh
        if psm then
            self:SetMesh(psm, true)
        end

        self:ShowBone(0, true)
        self:SetUnSelectable(false)
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        for _, v in bones or bp.Display.WarpInEffect.HideBones do
            self:HideBone(v, true)
        end

        local totalBones = self:GetBoneCount() - 1
        for k, v in EffectTemplate.UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(self, bone, self.Army, v)
            end
        end

        if psm then
            WaitSeconds(6)
            self:SetMesh(bp.Display.MeshBlueprint, true)
        end
    end,

    -------------------------------------------------------------------------------------------
    -- TELEPORTING WITH DELAY
    -------------------------------------------------------------------------------------------

    ---@param self CommandUnit
    ---@param work any
    ---@return boolean
    OnWorkBegin = function(self, work)
        if WalkingLandUnit.OnWorkBegin(self, work) then

            -- Prevent consumption bug where two enhancements in a row prevents assisting units from
            -- updating their consumption costs based on the new build rate values.
            self:UpdateAssistersConsumption()

            -- Inform EnhanceTask that enhancement is not restricted
            return true
        end

        return false
    end,
}
