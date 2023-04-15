-- File     :  /cdimage/units/URB3103/URB3103_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Scout-Deployed Radar Tower Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit

---@class URB3103 : CStructureUnit
URB3103 = ClassUnit(CStructureUnit) {

    DestructionPartsHighToss = { 'Spinner' },
    DestructionPartsLowToss = { 'B01',
        'Front_Left_Leg_B01', 'Front_Left_Leg_B02', 'Back_Left_Leg_B01', 'Back_Left_Leg_B02',
        'Middle_Left_Leg_B01', 'Middle_Left_Leg_B02', 'Middle_Right_Leg_B01', 'Middle_Right_Leg_B02',
        'Front_Right_Leg_B01', 'Front_Right_Leg_B02', 'Back_Right_Leg_B01', 'Back_Right_Leg_B02',
    },
    DestructionPartsChassisToss = { 'URL0101' },

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        self.Animator = CreateAnimator(self)
        self.Animator:PlayAnim(self.Blueprint.Display.AnimationOpen, false)
        self.Trash:Add(self.Animator)
        self.SpinThread = ForkThread(self.SpinnerThread, self)
    end,

    SpinnerThread = function(self)
        WaitTicks(51)
        CreateRotator(self, 'Spinner', 'y', nil, 90, 5, 90)
    end
}

TypeClass = URB3103
