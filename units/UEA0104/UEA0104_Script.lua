-- File     :  /cdimage/units/UEA0104/UEA0104_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos, Andres Mendez
-- Summary  :  UEF T2 Transport Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local WeaponsFile = import("/lua/terranweapons.lua")
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local TAirToAirLinkedRailgun = WeaponsFile.TAirToAirLinkedRailgun
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon

---@class UEA0104 : AirTransport
UEA0104 = ClassUnit(AirTransport) {
    AirDestructionEffectBones = { 'Char04', 'Char03', 'Char02', 'Char01',
        'Front_Right_Exhaust', 'Front_Left_Exhaust', 'Back_Right_Exhaust', 'Back_Left_Exhaust',
        'Right_Arm05', 'Right_Arm07', 'Right_Arm02', 'Right_Arm03', 'Right_Arm04', 'Right_Arm01'
    },
    BeamExhaustCruise = '/effects/emitters/transport_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/transport_thruster_beam_02_emit.bp',
    Weapons = {
        FrontLinkedRailGun = ClassWeapon(TAirToAirLinkedRailgun) {},
        BackLinkedRailGun = ClassWeapon(TAirToAirLinkedRailgun) {},
        FrontRiotGun = ClassWeapon(TDFRiotWeapon) {},
        BackRiotGun = ClassWeapon(TDFRiotWeapon) {},
    },
    EngineRotateBones = { 'Front_Right_Engine', 'Front_Left_Engine', 'Back_Left_Engine', 'Back_Right_Engine', },

    ---@param self UEA0104
    OnCreate = function(self)
        AirTransport.OnCreate(self)
        local slider = self.Sliders

        slider = {}
        slider[1] = CreateSlider(self, 'Char01')
        slider[1]:SetGoal(0, 0, -35)
        slider[2] = CreateSlider(self, 'Char02')
        slider[2]:SetGoal(0, 0, -15)
        slider[3] = CreateSlider(self, 'Char03')
        slider[3]:SetGoal(0, 0, 15)
        slider[4] = CreateSlider(self, 'Char04')
        slider[4]:SetGoal(0, 0, 35)
        for k, v in slider do
            v:SetSpeed(-1)
            self.Trash:Add(v)
        end
    end,

    ---@param self UEA0104
    ExpandThread = function(self)
        local slider = self.Sliders
        if slider then
            for k, v in slider do
                v:SetGoal(0, 0, 0)
                v:SetSpeed(10)
            end
            WaitFor(slider[4])
            for k, v in slider do
                v:Destroy()
            end
        end
    end,
}
TypeClass = UEA0104

-- kept for backwards compatibility
local explosion = import("/lua/defaultexplosions.lua")
local util = import("/lua/utilities.lua")