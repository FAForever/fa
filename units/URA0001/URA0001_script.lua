--****************************************************************************
--**
--**  File     :  /cdimage/units/URA0001/URA0001_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Cybran Builder bot units
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CreateCybranBuildBeams = import('/lua/EffectUtilities.lua').CreateCybranBuildBeams

URA0001 = Class(CAirUnit) {
    spawnedBy = nil,

    OnCreate = function(self)
        CAirUnit.OnCreate(self)
        --CreateBuilderArmController(unit,turretBone, [barrelBone], [aimBone])
        --BuilderArmManipulator:SetAimingArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)
        self.BuildArmManipulator = CreateBuilderArmController(self, 'URA0001' , 'URA0001', 0)
        self.BuildArmManipulator:SetAimingArc(-180, 180, 360, -90, 90, 360)
        self.BuildArmManipulator:SetPrecedence(5)
        self.Trash:Add(self.BuildArmManipulator)
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        self.BuildEffectsBag:Add(AttachBeamEntityToEntity(self, 'Muzzle_03', self, 'Muzzle_01', self:GetArmy(), '/effects/emitters/build_beam_02_emit.bp'))
        self.BuildEffectsBag:Add(AttachBeamEntityToEntity(self, 'Muzzle_03', self, 'Muzzle_02', self:GetArmy(), '/effects/emitters/build_beam_02_emit.bp'))
        CreateCybranBuildBeams( self, unitBeingBuilt, {'Muzzle_03',}, self.BuildEffectsBag )
    end,

    OnStartReclaim = function(self, target)
        IssueStop( {self} )  -- you can't reclaim!
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CAirUnit.OnStopBuild(self, unitBeingBuilt)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        Main = function(self)
            IssueClearCommands({self})
            IssueMove({self}, self:GetPosition())
            WaitSeconds(0.5)
            IssueMove({self}, self.spawnedBy)

            local delay = 0.1
            local wait = 0

            while wait < 4 do
                local pos = self:GetPosition()
                local bpos = self.spawnedBy:GetPosition()

                if VDist2(pos[1], pos[3], bpos[1], bpos[3]) < 1 then
                    break
                end

                wait = wait + delay
                WaitSeconds(delay)
            end

            self:Destroy()
        end,
    },

    BuildState = State {
        Main = function(self)
            local focus = self.spawnedBy:GetFocusUnit()

            if not focus then
                ChangeState(self, self.IdleState)
            end

            IssueClearCommands({self})
            IssueGuard({self}, focus)
        end,
    },
}

TypeClass = URA0001
