-----------------------------------------------------------------
-- File     :  /cdimage/units/XEB2402/XEB2402_script.lua
-- Author(s):  Dru Staltman
-- Summary  :  UEF Sub Orbital Laser
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
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
            WARN('In Main')
            local bp = self:GetBlueprint()
            
            -- Play arm opening animation
            self.AnimManip = CreateAnimator(self)
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca')
            self:PlayUnitSound('MoveArms')
            WaitFor(self.AnimManip)
            self.Trash:Add(self.AnimManip)
            
            WARN('Past anim')
            
            -- Create Satellite, attach it to unit, play animation, release satellite
            local location = self:GetPosition('Attachpoint01')
            local army = self:GetArmy()
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04',army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.06, -0.10, 1.90))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04',army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.06, -0.10, 1.90))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04',army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(0.08, -0.5, 1.60))
            self.Trash:Add(CreateAttachedEmitter(self,'Tower_B04',army, '/effects/emitters/light_blue_blinking_01_emit.bp'):OffsetEmitter(-0.04, -0.5, 1.60))
            self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01',army, '/effects/emitters/structure_steam_ambient_01_emit.bp'):OffsetEmitter(0.7, -0.85, 0.35))
            self.Trash:Add(CreateAttachedEmitter(self,'Attachpoint01',army, '/effects/emitters/structure_steam_ambient_02_emit.bp'):OffsetEmitter(-0.7, -0.85, 0.35))
            self.Trash:Add(CreateAttachedEmitter(self,'ConstuctBeam01',army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter( 2.00 ))
            self.Trash:Add(CreateAttachedEmitter(self,'ConstuctBeam02',army, '/effects/emitters/light_red_rotator_01_emit.bp'):ScaleEmitter( 2.00 ))
            
            if not self.Satellite then
                self.Satellite = CreateUnitHPR('XEA0002', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
                self.Trash:Add(self.Satellite)
                self.Satellite:AttachTo(self, 'Attachpoint01')
            end
            
            --Tell the satellite that we're its parent
            self.Satellite.Parent = self
            
            -- Play ejection animation
            self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca')
            self:PlayUnitSound('LaunchSat')
            WaitFor(self.AnimManip)
            self.Trash:Add(CreateAttachedEmitter(self,'XEB2402',army, '/effects/emitters/uef_orbital_death_laser_launch_01_emit.bp'):OffsetEmitter(0.00, 0.00, 1.00))
            self.Trash:Add(CreateAttachedEmitter(self,'XEB2402',army, '/effects/emitters/uef_orbital_death_laser_launch_02_emit.bp'):OffsetEmitter(0.00, 2.00, 1.00))
            
            -- Release unit
            if self.Satellite then
                self.Satellite:DetachFrom()
                self.Satellite:Open()
                -- Try to reverse the animations, closing everything up to be ready for reconstruction
                WaitSeconds(2)
                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen01.sca'):SetRate(-1)
                self:PlayUnitSound('LaunchSat')
                WaitFor(self.AnimManip)
                self.AnimManip:PlayAnim('/units/XEB2402/XEB2402_aopen.sca'):SetRate(-1)
                self:PlayUnitSound('MoveArms')
                WaitFor(self.AnimManip)
            end
        end,
    },

    OnStartBuild = function(self, unitBeingBuilt, order)
        if not self.Satellite then
            TAirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        else
            IssueClearCommands({self})
        end
    end,
    
    OnStopBuild = function(self, unitBeingBuilt, order)
        WARN('OnStopBuild')
        unitBeingBuilt:Destroy()
        WARN('1')
        IssueClearCommands({self})
        WARN('2')
        if not self.Satellite then
            WARN('3')
            ChangeState(self, self.OpenState)
        end
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Satellite and not self.Satellite:IsDead() and not self.Satellite.IsDying then
            self.Satellite:Kill()
        end
        TAirFactoryUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    OnDestroy = function(self)
        if self.Satellite and not self.Satellite:IsDead() and not self.Satellite.IsDying then
            self.Satellite:Destroy()
        end
        TAirFactoryUnit.OnDestroy(self)
    end,
    
    OnCaptured = function(self, captor)
        if self and not self:IsDead() and self.Satellite and not self.Satellite:IsDead() and captor and not captor:IsDead() and self:GetAIBrain() ~= captor:GetAIBrain() then
            local captorArmyIndex = captor:GetArmy()
            local captorBrain = false
            
            -- Do callbacks
            self:DoUnitCallbacks('OnCaptured', captor)
            self.Satellite:DoUnitCallbacks('OnCaptured', captor)
            
            -- Create new callbacks
            local newUnitCallbacks = {}
            if self.EventCallbacks.OnCapturedNewUnit then
                newUnitCallbacks = self.EventCallbacks.OnCapturedNewUnit
            end
            
            local newSatUnitCallbacks = {}
            if self.Satellite.EventCallbacks.OnCapturedNewUnit then
                newSatUnitCallbacks = self.Satellite.EventCallbacks.OnCapturedNewUnit
            end
            
            -- Disable unit cap for campaigns
            if ScenarioInfo.CampaignMode then
                captorBrain = captor:GetAIBrain()
                SetIgnoreArmyUnitCap(captorArmyIndex, true)
            end
            
            -- Shift the two units to the new army
            local sat = ChangeUnitArmy(self.Satellite, captorArmyIndex)
            local newUnit = ChangeUnitArmy(self, captorArmyIndex)
            if newUnit then
                newUnit.Satellite = sat
            end

            -- Reapply unit cap checks
            if ScenarioInfo.CampaignMode and not captorBrain.IgnoreArmyCaps then
                SetIgnoreArmyUnitCap(captorArmyIndex, false)
            end
            
            -- Do custom callbacks
            for k,cb in newUnitCallbacks do
                if cb then
                    cb(newUnit, captor)
                end
            end
            for k,cb in newSatUnitCallbacks do
                if cb then
                    cb(sat, captor)
                end
            end
        end
    end,
}
TypeClass = XEB2402