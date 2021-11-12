-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0401/UEL0401_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  UEF Mobile Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local EntityMethods = _G.moho.entity_methods
local EntityMethodsAttachBoneTo = EntityMethods.AttachBoneTo
local EntityMethodsDetachAll = EntityMethods.DetachAll
local EntityMethodsDetachFrom = EntityMethods.DetachFrom
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local GlobalMethods = _G
local GlobalMethodsIssueMoveOffFactory = GlobalMethods.IssueMoveOffFactory

local UnitMethods = _G.moho.unit_methods
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsRestoreBuildRestrictions = UnitMethods.RestoreBuildRestrictions
local UnitMethodsSetBusy = UnitMethods.SetBusy
local UnitMethodsShowBone = UnitMethods.ShowBone
-- End of automatically upvalued moho functions

local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit
local WeaponsFile = import('/lua/terranweapons.lua')
local TDFGaussCannonWeapon = WeaponsFile.TDFLandGaussCannonWeapon
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon
local TAALinkedRailgun = WeaponsFile.TAALinkedRailgun
local TANTorpedoAngler = WeaponsFile.TANTorpedoAngler
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams

UEL0401 = Class(TMobileFactoryUnit)({
    FxDamageScale = 2.5,
    PrepareToBuildAnimRate = 5,
    BuildAttachBone = 'Build_Attachpoint',
    RollOffBones = {
        'Arm_Right03_Build_Emitter',
        'Arm_Left03_Build_Emitter',
    },

    Weapons = {
        RightTurret01 = Class(TDFGaussCannonWeapon)({}),
        RightTurret02 = Class(TDFGaussCannonWeapon)({}),
        LeftTurret01 = Class(TDFGaussCannonWeapon)({}),
        LeftTurret02 = Class(TDFGaussCannonWeapon)({}),
        RightRiotgun = Class(TDFRiotWeapon)({
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank,
        }),
        LeftRiotgun = Class(TDFRiotWeapon)({
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank,
        }),
        RightAAGun = Class(TAALinkedRailgun)({}),
        LeftAAGun = Class(TAALinkedRailgun)({}),
        Torpedo = Class(TANTorpedoAngler)({}),
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TMobileFactoryUnit.OnStopBeingBuilt(self, builder, layer)
        self.EffectsBag = {}
        self.PrepareToBuildManipulator = CreateAnimator(self)
        CAnimationManipulatorMethodsPlayAnim(self.PrepareToBuildManipulator, self:GetBlueprint().Display.AnimationBuild, false)
        CAnimationManipulatorMethodsSetRate(self.PrepareToBuildManipulator, 0)
        self.ReleaseEffectsBag = {}
        self.AttachmentSliderManip = CreateSlider(self, self.BuildAttachBone)
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        TMobileFactoryUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    -- This unit needs to not be allowed to build while underwater
    -- Additionally, if it goes underwater while building it needs to cancel the current order
    OnLayerChange = function(self, new, old)
        TMobileFactoryUnit.OnLayerChange(self, new, old)
        if new == 'Land' then
            UnitMethodsRestoreBuildRestrictions(self)
            EntityMethodsRequestRefreshUI(self)
        elseif new == 'Seabed' then
            self:AddBuildRestriction(categories.ALLUNITS)
            EntityMethodsRequestRefreshUI(self)
        end
    end,

    IdleState = State({
        OnStartBuild = function(self, unitBuilding, order)
            TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            CAnimationManipulatorMethodsSetRate(self.PrepareToBuildManipulator, self.PrepareToBuildAnimRate)
            ChangeState(self, self.BuildingState)
        end,

        Main = function(self)
            CAnimationManipulatorMethodsSetRate(self.PrepareToBuildManipulator, -self.PrepareToBuildAnimRate)
            EntityMethodsDetachAll(self, self.BuildAttachBone)
            UnitMethodsSetBusy(self, false)
        end,
    }),

    BuildingState = State({
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            CAnimationManipulatorMethodsSetRate(self.PrepareToBuildManipulator, self.PrepareToBuildAnimRate)
            local bone = self.BuildAttachBone
            EntityMethodsDetachAll(self, bone)
            if not self.UnitBeingBuilt.Dead then
                EntityMethodsAttachBoneTo(unitBuilding, -2, self, bone)
                local unitHeight = unitBuilding:GetBlueprint().SizeY
                self.AttachmentSliderManip:SetGoal(0, unitHeight, 0)
                self.AttachmentSliderManip:SetSpeed(-1)
                UnitMethodsHideBone(unitBuilding, 0, true)
            end
            WaitSeconds(3)
            UnitMethodsShowBone(unitBuilding, 0, true)
            WaitFor(self.PrepareToBuildManipulator)
            local unitBuilding = self.UnitBeingBuilt
            self.UnitDoneBeingBuilt = false
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            TMobileFactoryUnit.OnStopBuild(self, unitBeingBuilt)

            ChangeState(self, self.RollingOffState)
        end,
    }),

    RollingOffState = State({
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if not unitBuilding.Dead then
                UnitMethodsShowBone(unitBuilding, 0, true)
            end
            WaitFor(self.PrepareToBuildManipulator)
            WaitFor(self.AttachmentSliderManip)

            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(10)
            self.AttachmentSliderManip:SetGoal(0, 0, 17)
            WaitFor(self.AttachmentSliderManip)

            self.AttachmentSliderManip:SetGoal(0, -3, 17)
            WaitFor(self.AttachmentSliderManip)

            if not unitBuilding.Dead then
                EntityMethodsDetachFrom(unitBuilding, true)
                EntityMethodsDetachAll(self, self.BuildAttachBone)
                local worldPos = self:CalculateWorldPositionFromRelative({
                    0,
                    0,
                    -15,
                })
                GlobalMethodsIssueMoveOffFactory({
                    unitBuilding,
                }, worldPos)
            end

            self:DestroyRollOffEffects()
            ChangeState(self, self.IdleState)
        end,
    }),

    CreateRollOffEffects = function(self)
        local army = self.Army
        local unitB = self.UnitBeingBuilt
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = AttachBeamEntityToEntity(unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)

            fx = CreateEmitterAtBone(self, v, army, EffectTemplate.TTransportGlow01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,
})

TypeClass = UEL0401
