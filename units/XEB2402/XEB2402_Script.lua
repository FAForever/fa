-----------------------------------------------------------------
-- File     :  /cdimage/units/XEB2402/XEB2402_script.lua
-- Author(s):  Dru Staltman
-- Summary  :  UEF Sub Orbital Laser
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local TAirFactoryUnit = import('/lua/terranunits.lua').TAirFactoryUnit

XEB2402 = Class(TAirFactoryUnit) {   
    DeathThreadDestructionWaitTime = 8,

    OnStopBeingBuilt = function(self)
        TAirFactoryUnit.OnStopBeingBuilt(self)
        ChangeState(self, self.OpenState)
    end,

    OpenState = State() {
        Main = function(self)
            -- If the unit has arrived with a new player via capture, it will already have a Satellite in the wild
            if not self.Satellite then
                -- Play arm opening animation
                self.AnimManip = CreateAnimator(self)
                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca')
                self:PlayUnitSound('MoveArms')
                WaitFor(self.AnimManip)
                self.Trash:Add(self.AnimManip)

                -- Create Satellite, attach it to unit, play animation, release satellite
                local location = self:GetPosition('Attachpoint01')
                self.Satellite = CreateUnitHPR('XEA0002', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
                self.Trash:Add(self.Satellite)
                self.Satellite:AttachTo(self, 'Attachpoint01')
                self.haveOpenedOnce = true

                -- Create warning lights and other VFX
                local army = self:GetArmy()
                self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.06, -0.10, 1.90))
                self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.06, -0.10, 1.90))
                self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.08, -0.5, 1.60))
                self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.04, -0.5, 1.60))
                self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01', army, '/effects/emitters/structure_steam_ambient_01_emit.bp'):OffsetEmitter(0.7, -0.85, 0.35))
                self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01', army, '/effects/emitters/structure_steam_ambient_02_emit.bp'):OffsetEmitter(-0.7, -0.85, 0.35))
                self.Trash:Add(CreateAttachedEmitter(self,'ConstuctBeam01', army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter( 2.00 ))
                self.Trash:Add(CreateAttachedEmitter(self,'ConstuctBeam02', army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter( 2.00 ))

                -- Tell the satellite that we're its parent
                self.Satellite.Parent = self

                -- Play ejection animation
                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca')
                self:PlayUnitSound('LaunchSat')
                WaitFor(self.AnimManip)
                self.Trash:Add(CreateAttachedEmitter(self,'XEB2402',army, '/effects/emitters/uef_orbital_death_laser_launch_01_emit.bp'):OffsetEmitter(0.00, 0.00, 1.00))
                self.Trash:Add(CreateAttachedEmitter(self,'XEB2402',army, '/effects/emitters/uef_orbital_death_laser_launch_02_emit.bp'):OffsetEmitter(0.00, 2.00, 1.00))

                -- Release unit
                self.Satellite:DetachFrom()
                self.Satellite:Open()

                -- Reopen the cage and arms, to keep up the illusion
                WaitSeconds(1.5)
                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca')
                self.AnimManip:SetAnimationFraction(1) -- These animations are one-way, so set them to 'Complete' status, then play in reverse
                self.AnimManip:SetRate(-1)

                WaitFor(self.AnimManip)

                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca'):SetRate(-1)
                self.AnimManip:SetAnimationFraction(1)
                self.AnimManip:SetRate(-1)
                self:PlayUnitSound('MoveArms')
                WaitFor(self.AnimManip)
            end

            ChangeState(self, self.IdleState)
        end,
    },

    -- Override OnStartBuild to cancel any and all commands if we already have a Satellite
    OnStartBuild = function(self, unitBeingBuilt, order)
        if self.Satellite or not self.haveOpenedOnce then
            IssueStop({self})
            IssueClearCommands({self})
        else
            TAirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        end
    end,

    -- We shouldn't have a satellite here. If we do, something is very wrong. Kill it, and warn
    OnStopBuild = function(self, unitBeingBuilt)
        -- It's a bit of a hack, but what we do is destroy what we just built, cancel commands, and use the normal launch sequence
        self:StopBuildingEffects(unitBeingBuilt)
        unitBeingBuilt:Destroy()
        if not self.Satellite then
            IssueStop({self})
            ChangeState(self, self.OpenState)
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Satellite and not self.Satellite.Dead and not self.Satellite.IsDying then
            self.Satellite:Kill()
        end
        TAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnDestroy = function(self)
        if self.Satellite and not self.Satellite.Dead and not self.Satellite.IsDying then
            self.Satellite:Destroy()
        end
        TAirFactoryUnit.OnDestroy(self)
    end,

    OnCaptured = function(self, captor)
        if self and not self.Dead and captor and not captor.Dead and self:GetAIBrain() ~= captor:GetAIBrain() then
            local captorArmyIndex = captor:GetArmy()

            -- Disable unit cap for campaigns
            if ScenarioInfo.CampaignMode then
                SetIgnoreArmyUnitCap(captorArmyIndex, true)
            end

            -- Shift the two units to the new army and assign relationship
            local base = ChangeUnitArmy(self, captorArmyIndex)
            if self.Satellite and not self.Satellite.Dead then
                local sat = ChangeUnitArmy(self.Satellite, captorArmyIndex)
                sat.Parent = base
                base.Satellite = sat
            end

            -- Reapply unit cap checks
            local captorBrain = captor:GetAIBrain()
            if ScenarioInfo.CampaignMode and not captorBrain.IgnoreArmyCaps then
                SetIgnoreArmyUnitCap(captorArmyIndex, false)
            end
        end
    end,
}

TypeClass = XEB2402
