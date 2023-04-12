-- File     :  /cdimage/units/UEA0107/UEA0107_script.lua
-- Author(s):  Andres Mendez
-- Summary  :  UEF T1 Transport Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local DummyWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon

---@class UEA0107 : AirTransport
UEA0107 = ClassUnit(AirTransport) {
    Weapons = {
        GuidanceSystem = ClassWeapon(DummyWeapon) {},
    },
    AirDestructionEffectBones = { 'Front_Right_Exhaust', 'Front_Left_Exhaust', 'Back_Right_Exhaust', 'Back_Left_Exhaust',
        'Left_Front_Leg', 'Right_Front_Leg', 'Left_Back_Leg', 'Right_Back_Leg'
    },
    BeamExhaustCruise = '/effects/emitters/transport_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/transport_thruster_beam_02_emit.bp',
    EngineRotateBones = { 'Front_Right_Engine', 'Front_Left_Engine', 'Back_Left_Engine', 'Back_Right_Engine', },
    PlayDestructionEffects = true,

    ---@param self UEA0107
    OnCreate = function(self)
        AirTransport.OnCreate(self)
        local slider = self.Sliders
        slider = {}
        slider[1] = CreateSlider(self, 'Tail')
        slider[1]:SetGoal(0, 0, 15)
        slider[2] = CreateSlider(self, 'Head')
        slider[2]:SetGoal(0, 0, -15)
        for k, v in slider do
            v:SetSpeed(-1)
            self.Trash:Add(v)
        end
    end,

    ---@param self UEA0107
    ExpandThread = function(self)
        local slider = self.Sliders
        if slider then
            for k, v in slider do
                v:SetGoal(0, 0, 0)
                v:SetSpeed(10)
            end
            WaitFor(slider[2])
            for k, v in slider do
                v:Destroy()
            end
        end
    end,
}
TypeClass = UEA0107

-- kept for backwards compatibility
local explosion = import("/lua/defaultexplosions.lua")
local util = import("/lua/utilities.lua")