-----------------------------------------------------------------
-- File     :  /cdimage/units/XEB2402/XEB2402_script.lua
-- Author(s):  Dru Staltman
-- Summary  :  UEF Sub Orbital Laser
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local TAirFactoryUnit = import("/lua/terranunits.lua").TAirFactoryUnit

---@class XEB2402 : TAirFactoryUnit
XEB2402 = ClassUnit(TAirFactoryUnit) {

    OnStopBeingBuilt = function(self)
        TAirFactoryUnit.OnStopBeingBuilt(self)
        ChangeState(self, self.OpenState)
    end,

    OpenState = State() {
        Retract = function(self)
            -- Retract cage
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca')
            self.AnimManip:SetAnimationFraction(1)
            self.AnimManip:SetRate(-1)
            WaitFor(self.AnimManip)

            -- Retract Arms
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca'):SetRate(-1)
            self.AnimManip:SetAnimationFraction(1)
            self.AnimManip:SetRate(-1)
            self:PlayUnitSound('MoveArms')
            WaitFor(self.AnimManip)
        end,

        Extend = function(self)
            -- Extend Arms
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca'):SetRate(-1)
            self.AnimManip:SetAnimationFraction(0)
            self.AnimManip:SetRate(1)
            self:PlayUnitSound('MoveArms')
            WaitFor(self.AnimManip)

            -- Make a satellite and launch
            self:CreateSatellite()

            -- Extend cage
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca')
            self.AnimManip:SetAnimationFraction(0)
            self.AnimManip:SetRate(1)
            WaitFor(self.AnimManip)
        end,

        CreateSatellite = function(self)
            -- Create Satellite, attach it to unit, play animation, release satellite
            local location = self:GetPosition('Attachpoint01')

            if self.newSatellite then
                self.Satellite = self.newSatellite
                self.newSatellite = nil
            else
                self.Satellite = CreateUnitHPR('XEA0002', self.Army, location[1], location[2], location[3], 0, 0, 0)
                self.Satellite:AttachTo(self, 'Attachpoint01')
            end

            -- Create warning lights and other VFX
            local army = self.Army
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.06, -0.10, 1.90))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.06, -0.10, 1.90))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.08, -0.5, 1.60))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04', army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.04, -0.5, 1.60))
            self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01', army, '/effects/emitters/structure_steam_ambient_01_emit.bp'):OffsetEmitter(0.7, -0.85, 0.35))
            self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01', army, '/effects/emitters/structure_steam_ambient_02_emit.bp'):OffsetEmitter(-0.7, -0.85, 0.35))
            self.Trash:Add(CreateAttachedEmitter(self,'ConstructBeam01', army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter(2.00))
            self.Trash:Add(CreateAttachedEmitter(self,'ConstructBeam02', army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter(2.00))

            -- Tell the satellite that we're its parent
            self.Satellite.Parent = self
        end,

        Main = function(self)
            -- If the unit has arrived with a new player via capture, it will already have a Satellite in the wild
            if not self.Satellite then
                self.waitingForLaunch = true

                if not self.AnimManip then
                    self.AnimManip = CreateAnimator(self)
                end
                self.Trash:Add(self.AnimManip)

                self:Extend()

                -- Release unit
                self.Satellite:DetachFrom()
                IssueMove({self.Satellite}, self:GetRallyPoint())
                self.Satellite:Open()

                self.waitingForLaunch = false
                self:Retract()

                IssueClearCommands({self})
            end

            ChangeState(self, self.IdleState)
        end,
    },

    -- Override OnStartBuild to cancel any and all commands if we already have a Satellite
    OnStartBuild = function(self, unitBeingBuilt, order)
        if self.Satellite or self.waitingForLaunch then
            IssueStop({self})
            IssueClearCommands({self}) -- This clears the State launch procedure for some reason, leading to the following hack

            -- This is ugly but necessary. It will keep resetting the launch procedure if the player spams to build a Satellite before initial launch
            -- It looks bad, but it's better than that player not getting a Satellite at all
            if self.waitingForLaunch then
                ChangeState(self, self.OpenState)
            end
        else
            TAirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        end
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        self:StopBuildingEffects(unitBeingBuilt)
        self:SetActiveConsumptionInactive()
        self:StopUnitAmbientSound('ConstructLoop')
        self:PlayUnitSound('ConstructStop')

        if not unitBeingBuilt:IsBeingBuilt() and not self.Satellite and not self.waitingForLaunch then
            IssueStop({self})
            self.newSatellite = unitBeingBuilt
            ChangeState(self, self.OpenState)
        else
            unitBeingBuilt:Destroy()
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Satellite and not self.Satellite.Dead and not self.Satellite.IsDying then
            self.Satellite:Kill()
        end

        self:SetActiveConsumptionInactive()
        ChangeState(self, self.IdleState)
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
            local captorArmyIndex = captor.Army

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
