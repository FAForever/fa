#****************************************************************************
#**
#**  File     :  /cdimage/units/URA0001/URA0001_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Cybran Builder bot units
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit
local CreateCybranBuildBeams = import('/lua/EffectUtilities.lua').CreateCybranBuildBeams

URA0001 = Class(CAirUnit) {

    OnCreate = function(self)
        CAirUnit.OnCreate(self) 
        #CreateBuilderArmController(unit,turretBone, [barrelBone], [aimBone])
        #BuilderArmManipulator:SetAimingArc(minHeading, maxHeading, headingMaxSlew, minPitch, maxPitch, pitchMaxSlew)        
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
        IssueStop( {self} )  # you can't reclaim!
    end,
}

TypeClass = URA0001
