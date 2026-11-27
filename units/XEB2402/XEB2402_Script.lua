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
        -- A station that was just built launches a satellite for free. `TransferSatellite` takes
        -- this away from a station that replaces another one after a change of army.
        self.FreeSatelliteLaunch = true
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
            elseif self.FreeSatelliteLaunch then
                self.Satellite = CreateUnitHPR('XEA0002', self.Army, location[1], location[2], location[3], 0, 0, 0)
                self.Satellite:AttachTo(self, 'Attachpoint01')
            else
                -- the satellite that was going to be launched died
                return
            end
            self.FreeSatelliteLaunch = nil

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
            if not self.Satellite and (self.newSatellite or self.FreeSatelliteLaunch) then
                self.waitingForLaunch = true

                if not self.AnimManip then
                    self.AnimManip = CreateAnimator(self)
                end
                self.Trash:Add(self.AnimManip)

                self:Extend()

                -- Release unit
                local satellite = self.Satellite
                if satellite then
                    satellite:DetachFrom()
                    IssueToUnitMove(satellite, self:GetRallyPoint())
                    satellite:Open()
                end

                self.waitingForLaunch = false
                self:Retract()

                IssueToUnitClearCommands(self)

                -- the satellite died during the launch, and clearing the commands removed its rebuild order
                if not self.Satellite then
                    self:RebuildSatellite()
                end
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
            unitBeingBuilt.Parent = self
            ChangeState(self, self.OpenState)
        else
            unitBeingBuilt:Destroy()
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        local satellite = self.Satellite
        self.Satellite = nil
        if satellite and not satellite.Dead and not satellite.IsDying then
            satellite:Kill()
        end
        self:DestroyNewSatellite()

        self:SetActiveConsumptionInactive()
        ChangeState(self, self.IdleState)
        TAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnDestroy = function(self)
        local satellite = self.Satellite
        self.Satellite = nil
        if satellite and not satellite.Dead and not satellite.IsDying then
            satellite:Destroy()
        end
        self:DestroyNewSatellite()
        TAirFactoryUnit.OnDestroy(self)
    end,

    --- Destroys a satellite that the station finished building but hasn't launched yet, so it doesn't
    --- survive the station.
    ---@param self XEB2402
    DestroyNewSatellite = function(self)
        local newSatellite = self.newSatellite
        if newSatellite then
            self.newSatellite = nil
            if not IsDestroyed(newSatellite) then
                newSatellite:Destroy()
            end
        end
    end,

    --- Called by a satellite of this station when it dies or is destroyed.
    ---@param self XEB2402
    ---@param satellite XEA0002
    OnSatelliteLost = function(self, satellite)
        if self.Satellite == satellite then
            self.Satellite = nil
        elseif self.newSatellite == satellite then
            self.newSatellite = nil
        else
            -- the station already let go of this satellite
            return
        end
        self:RebuildSatellite()
    end,

    --- Orders the station to build a new satellite. During the launch sequence, the sequence gives
    --- the order when it ends, because a build order would restart it.
    ---@param self XEB2402
    RebuildSatellite = function(self)
        if not self.waitingForLaunch then
            IssueToUnitBuildFactory(self, 'XEA0002', 1)
        end
    end,

    --- Also called for a capture, through `Unit.OnCaptured`.
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
        -- `newSatellite` is a satellite that the station finished building but hasn't launched yet.
        -- Letting go of the satellite first keeps the old one, which the change of army destroys,
        -- from ordering the old station to rebuild it.
        local satellite = self.Satellite or self.newSatellite
        self.Satellite = nil
        self.newSatellite = nil
        newUnit.FreeSatelliteLaunch = nil

        if satellite and not satellite.Dead and not IsDestroyed(satellite) then
            local docked = satellite:GetParent() == self
            local massKilled = satellite.VetExperience

            local newSatellite = ChangeUnitArmy(satellite, newUnit.Army)
            if newSatellite then
                if massKilled and massKilled > 0 then
                    newSatellite:CalculateVeterancyLevelAfterTransfer(massKilled, true)
                end

                newSatellite.Parent = newUnit
                if docked then
                    -- launched by the `OpenState` of the new station
                    newSatellite:AttachTo(newUnit, 'Attachpoint01')
                    newUnit.newSatellite = newSatellite
                else
                    newUnit.Satellite = newSatellite
                    newSatellite:Open()
                end
                return
            end

            -- the new army is at its unit cap
            satellite:Destroy()
        end

        -- No satellite to transfer: rebuild it. When the station is given while it builds a satellite,
        -- `FactoryRebuildUnits` replaces this order with one that keeps the progress.
        newUnit:RebuildSatellite()
    end,
}

TypeClass = XEB2402
