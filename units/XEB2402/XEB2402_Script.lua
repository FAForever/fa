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
            -- A station that was given or captured keeps its old satellite, or rebuilds it when it had none
            if self.SkipSatelliteLaunch then
                self.SkipSatelliteLaunch = nil
            elseif not self.Satellite then
                self.waitingForLaunch = true

                if not self.AnimManip then
                    self.AnimManip = CreateAnimator(self)
                end
                self.Trash:Add(self.AnimManip)

                self:Extend()

                -- Release unit
                self.Satellite:DetachFrom()
                IssueToUnitMove(self.Satellite, self:GetRallyPoint())
                self.Satellite:Open()

                self.waitingForLaunch = false
                self:Retract()

                IssueToUnitClearCommands(self)
            end

            ChangeState(self, self.IdleState)
        end,
    },

    -- Override OnStartBuild to cancel any and all commands if we already have a Satellite
    OnStartBuild = function(self, unitBeingBuilt, order)
        if self.Satellite or self.waitingForLaunch then
            IssueToUnitStop(self)
            IssueToUnitClearCommands(self) -- This clears the State launch procedure for some reason, leading to the following hack

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
            IssueToUnitStop(self)
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
            if base then
                self:TransferSatellite(base)
            end

            -- Reapply unit cap checks
            local captorBrain = captor:GetAIBrain()
            if ScenarioInfo.CampaignMode and not captorBrain.IgnoreArmyCaps then
                SetIgnoreArmyUnitCap(captorArmyIndex, false)
            end
        end
    end,

    ---@param self XEB2402
    ---@param newUnit XEB2402
    OnGiven = function(self, newUnit)
        TAirFactoryUnit.OnGiven(self, newUnit)
        self:TransferSatellite(newUnit)
    end,

    --- Moves the satellite of this station to the station that replaces it after a change of army.
    --- The engine doesn't transfer the satellite with the station, and the new station launches a
    --- new satellite when it is created. Without this, a satellite in flight would reappear at the
    --- station, a satellite that isn't launched yet would stay with the old army, and a station without
    --- a satellite would get a free one.
    ---@param self XEB2402
    ---@param newUnit XEB2402
    TransferSatellite = function(self, newUnit)
        -- `newSatellite` is a satellite that the station finished building but hasn't launched yet
        local satellite = self.Satellite or self.newSatellite
        self.Satellite = nil
        self.newSatellite = nil

        if satellite and not satellite.Dead and not IsDestroyed(satellite) then
            local docked = satellite:GetParent() == self
            local massKilled = satellite.VetExperience

            -- the old satellite is destroyed by the change of army, so it shouldn't order the old station to rebuild it
            satellite.Parent = nil
            local newSatellite = ChangeUnitArmy(satellite, newUnit.Army)
            if newSatellite then
                if massKilled and massKilled > 0 then
                    newSatellite:CalculateVeterancyLevelAfterTransfer(massKilled, true)
                end

                if docked then
                    -- launched by the `OpenState` of the new station
                    newSatellite:AttachTo(newUnit, 'Attachpoint01')
                    newUnit.newSatellite = newSatellite
                else
                    newSatellite.Parent = newUnit
                    newUnit.Satellite = newSatellite
                    newSatellite:Open()
                end
                return
            end

            -- the new army is at its unit cap
            satellite:Destroy()
        end

        -- No satellite to transfer: rebuild it instead of launching a free one. A satellite that was
        -- being built is rebuilt to its progress by `FactoryRebuildUnits` when the station is given.
        newUnit.SkipSatelliteLaunch = true
        if not newUnit.FacRebuild_UnitId then
            IssueToUnitBuildFactory(newUnit, 'XEA0002', 1)
        end
    end,
}

TypeClass = XEB2402
