-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UEA0104/UEA0104_script.lua
-- **  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos, Andres Mendez
-- **
-- **  Summary  :  UEF T2 Transport Script
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local explosion = import("/lua/defaultexplosions.lua")
local util = import("/lua/utilities.lua")
local WeaponsFile = import("/lua/terranweapons.lua")


local AirTransport = import("/lua/defaultunits.lua").AirTransport
local TAirToAirLinkedRailgun = WeaponsFile.TAirToAirLinkedRailgun
local TDFRiotWeapon = WeaponsFile.TDFRiotWeapon

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add
local ForkThread = ForkThread
local CreateAnimator = CreateAnimator
local CreateThrustController = CreateThrustController
local CreateSlider = CreateSlider
local WaitSeconds = WaitSeconds
local MathFloor = math.floor



---@class UEA0104 : AirTransport
UEA0104 = ClassUnit(AirTransport) {
    AirDestructionEffectBones = { 'Char04', 'Char03', 'Char02', 'Char01',
                                'Front_Right_Exhaust','Front_Left_Exhaust','Back_Right_Exhaust','Back_Left_Exhaust',
                                'Right_Arm05','Right_Arm07','Right_Arm02','Right_Arm03', 'Right_Arm04','Right_Arm01'},


    BeamExhaustCruise = '/effects/emitters/transport_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/transport_thruster_beam_02_emit.bp',

    Weapons = {
        FrontLinkedRailGun = ClassWeapon(TAirToAirLinkedRailgun) {},
        BackLinkedRailGun = ClassWeapon(TAirToAirLinkedRailgun) {},
        FrontRiotGun = ClassWeapon(TDFRiotWeapon) {},
        BackRiotGun = ClassWeapon(TDFRiotWeapon) {},
    },

    EngineRotateBones = {'Front_Right_Engine', 'Front_Left_Engine', 'Back_Left_Engine', 'Back_Right_Engine', },

    ---@param self UEA0104
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self,builder,layer)
        AirTransport.OnStopBeingBuilt(self,builder,layer)
        local trash = self.Trash
        local bp = self.Blueprint
        local landingAnimManip = CreateAnimator(self)

        -- create the engine thrust manipulators
        for _, bone in self.EngineRotateBones do
            local controller = CreateThrustController(self, 'Thruster', bone)
            controller:SetThrustingParam(-0.25, 0.25, -0.75, 0.75, -0.0, 0.0, 1.0, 0.25)
            TrashBagAdd(trash,controller)
        end

        landingAnimManip:SetPrecedence(0)
        TrashBagAdd(trash,landingAnimManip)
        landingAnimManip:PlayAnim(bp.Display.AnimationLand):SetRate(1)
        TrashBagAdd(trash,ForkThread(self.ExpandThread, self))
    end,

    ---@param self UEA0104
    ---@param new any
    ---@param old any
    OnMotionVertEventChange = function(self, new, old)
        AirTransport.OnMotionVertEventChange(self, new, old)
        if (new == 'Down') then
            self.LandingAnimManip:SetRate(-1)
        elseif (new == 'Up') then
            self.LandingAnimManip:SetRate(1)
        end
    end,

    -- Override air destruction effects so we can do something custom here
    ---@param self UEA0104
    ---@param scale number unused
    CreateUnitAirDestructionEffects = function(self, scale)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread(self.AirDestructionEffectsThread, self))
    end,

    ---@param self UEA0104
    AirDestructionEffectsThread = function(self)
        local numExplosions = MathFloor(table.getn(self.AirDestructionEffectBones) * 0.5)
        for i = 0, numExplosions do
            explosion.CreateDefaultHitExplosionAtBone(self, self.AirDestructionEffectBones[util.GetRandomInt(1, numExplosions)], 0.5)
            WaitSeconds(util.GetRandomFloat(0.2, 0.9))
        end
    end,

    ---@param self UEA0104
    OnCreate = function(self)
        self.Sliders = {}
        local sliders = self.Sliders
        local trash = self.Trash


        AirTransport.OnCreate(self)
        -- CreateSlider(unit, bone, [goal_x, goal_y, goal_z, [speed,
        sliders[1] = CreateSlider(self, 'Char01')
        sliders[1]:SetGoal(0, 0, -35)
        sliders[2] = CreateSlider(self, 'Char02')
        sliders[2]:SetGoal(0, 0, -15)
        sliders[3] = CreateSlider(self, 'Char03')
        sliders[3]:SetGoal(0, 0, 15)
        sliders[4] = CreateSlider(self, 'Char04')
        sliders[4]:SetGoal(0, 0, 35)
        for k, v in sliders do
            v:SetSpeed(-1)
            TrashBagAdd(trash,v)
        end
    end,

    ---@param self UEA0104
    ExpandThread = function(self)
        if self.Sliders then
            for k, v in self.Sliders do
                v:SetGoal(0, 0, 0)
                v:SetSpeed(10)
            end
            WaitFor(self.Sliders[4])
            for k, v in self.Sliders do
                v:Destroy()
            end
        end
    end,

    GetUnitSizes = function(self)
        local bp = self.Blueprint
        if self:GetFractionComplete() < 1.0 then
            return bp.SizeX, bp.SizeY, bp.SizeZ * 0.5
        else
            return bp.SizeX, bp.SizeY, bp.SizeZ
        end
    end,

}

TypeClass = UEA0104
