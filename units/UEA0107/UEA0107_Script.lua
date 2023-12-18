-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UEA0107/UEA0107_script.lua
-- **  Author(s):  Andres Mendez
-- **
-- **  Summary  :  UEF T1 Transport Script
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local explosion = import("/lua/defaultexplosions.lua")
local util = import("/lua/utilities.lua")

local AirTransport = import("/lua/defaultunits.lua").AirTransport
local DummyWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add
local ForkThread = ForkThread
local CreateAnimator = CreateAnimator
local CreateThrustController = CreateThrustController
local CreateSlider = CreateSlider
local WaitSeconds = WaitSeconds
local MathFloor = math.floor


---@class UEA0107 : AirTransport
UEA0107 = ClassUnit(AirTransport) {

        Weapons = {
            GuidanceSystem = ClassWeapon(DummyWeapon) {},
        },

        AirDestructionEffectBones = { 'Front_Right_Exhaust','Front_Left_Exhaust','Back_Right_Exhaust','Back_Left_Exhaust',
            'Left_Front_Leg','Right_Front_Leg','Left_Back_Leg','Right_Back_Leg'},

        BeamExhaustCruise = '/effects/emitters/transport_thruster_beam_01_emit.bp',
        BeamExhaustIdle = '/effects/emitters/transport_thruster_beam_02_emit.bp',
        EngineRotateBones = {'Front_Right_Engine', 'Front_Left_Engine', 'Back_Left_Engine', 'Back_Right_Engine', },

        PlayDestructionEffects = true,

        ---@param self UEA0107
        ---@param builder Unit
        ---@param layer string
        OnStopBeingBuilt = function(self,builder,layer)
            AirTransport.OnStopBeingBuilt(self,builder,layer)
            local trash = self.Trash
            local landingAnimManip = CreateAnimator(self)
            local bp = self.Blueprint

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

        OnMotionVertEventChange = function(self, new, old)
            AirTransport.OnMotionVertEventChange(self, new, old)
            if (new == 'Down') then
                self.LandingAnimManip:SetRate(-1)
            elseif (new == 'Up') then
                self.LandingAnimManip:SetRate(1)
            end
        end,

        -- Override air destruction effects so we can do something custom here
        CreateUnitAirDestructionEffects = function(self, scale)
            local trash = self.Trash
            TrashBagAdd(trash,ForkThread(self.AirDestructionEffectsThread, self))
        end,

        AirDestructionEffectsThread = function(self)
            local numExplosions = MathFloor(table.getn(self.AirDestructionEffectBones) * 0.5)
            for i = 0, numExplosions do
                explosion.CreateDefaultHitExplosionAtBone(self, self.AirDestructionEffectBones[util.GetRandomInt(1, numExplosions)], 0.5)
                WaitSeconds(util.GetRandomFloat(0.2, 0.9))
            end
        end,

        OnCreate = function(self)
            AirTransport.OnCreate(self)
            local trash = self.Trash

            self.Sliders = {}
            self.Sliders[1] = CreateSlider(self, 'Tail')
            self.Sliders[1]:SetGoal(0, 0, 15)
            self.Sliders[2] = CreateSlider(self, 'Head')
            self.Sliders[2]:SetGoal(0, 0, -15)
            for k, v in self.Sliders do
                v:SetSpeed(-1)
                TrashBagAdd(trash,v)
            end
        end,

        ExpandThread = function(self)
            if self.Sliders then
                for k, v in self.Sliders do
                    v:SetGoal(0, 0, 0)
                    v:SetSpeed(10)
                end
                WaitFor(self.Sliders[2])
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

TypeClass = UEA0107
