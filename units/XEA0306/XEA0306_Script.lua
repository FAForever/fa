-----------------------------------------------------------------
-- File     :  /data/units/XEA0306/XEA0306_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  UEF Heavy Air Transport Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local explosion = import("/lua/defaultexplosions.lua")
local util = import("/lua/utilities.lua")
local WeaponsFile = import("/lua/terranweapons.lua")
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local TSAMLauncher = import("/lua/terranweapons.lua").TSAMLauncher
local TWeapons = import("/lua/terranweapons.lua")
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon

---@class XEA0306 : AirTransport
XEA0306 = ClassUnit(AirTransport) {
    AirDestructionEffectBones = { 'FrontRight_Engine_Exhaust', 'FrontLeft_Engine_Exhaust', 'BackRight_Engine_Exhaust',
        'BackLeft_Engine_Exhaust' },

    ShieldEffects = {
        '/effects/emitters/terran_shield_generator_mobile_01_emit.bp',
        '/effects/emitters/terran_shield_generator_mobile_02_emit.bp',
    },

    BeamExhaustCruise = '/effects/emitters/transport_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/transport_thruster_beam_02_emit.bp',

    Weapons = {
        MissleRackFrontLeft = ClassWeapon(TSAMLauncher) {},
        MissleRackBackLeft = ClassWeapon(TSAMLauncher) {},
        MissleRackBackRight = ClassWeapon(TSAMLauncher) {},
        MissleRackFrontRight = ClassWeapon(TSAMLauncher) {},
        PlasmaLeft = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
        PlasmaRight = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
    },

    EngineRotateBones = { 'FrontRight_Engine', 'FrontLeft_Engine', 'BackRight_Engine', 'BackLeft_Engine', },

    OnCreate = function(self)
        AirTransport.OnCreate(self)

        self.UnfoldAnim = CreateAnimator(self)
        self.UnfoldAnim:PlayAnim('/units/xea0306/xea0306_aunfold.sca')
        self.UnfoldAnim:SetRate(0)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AirTransport.OnStopBeingBuilt(self, builder, layer)
        self.EngineManipulators = {}

        self.UnfoldAnim:SetRate(1)

        -- create the engine thrust manipulators
        for k, v in self.EngineRotateBones do
            table.insert(self.EngineManipulators, CreateThrustController(self, "thruster", v))
        end

        -- set up the thursting arcs for the engines
        for keys, values in self.EngineManipulators do
            --                      XMAX,XMIN,YMAX,YMIN,ZMAX,ZMIN, TURNMULT, TURNSPEED
            values:SetThrustingParam(-0.25, 0.25, -0.75, 0.75, -0.0, 0.0, 1.0, 0.25)
        end

        self.LandingAnimManip = CreateAnimator(self)
        self.LandingAnimManip:SetPrecedence(0)
        self.Trash:Add(self.LandingAnimManip)
        self.LandingAnimManip:PlayAnim(self.Blueprint.Display.AnimationLand):SetRate(1)
    end,

    -- When a unit attaches or detaches, tell the shield about it.
    OnTransportAttach = function(self, attachBone, unit)
        AirTransport.OnTransportAttach(self, attachBone, unit)
        self.MyShield:AddProtectedUnit(unit)
    end,

    OnTransportDetach = function(self, attachBone, unit)
        AirTransport.OnTransportDetach(self, attachBone, unit)
        self.MyShield:RemoveProtectedUnit(unit)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if damageType == 'Nuke' or damageType == 'Deathnuke' then
            self.MyShield:SetContentsVulnerable(true)
        end

        AirTransport.OnDamage(self, instigator, amount, vector, damageType)
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
        self:ForkThread(self.AirDestructionEffectsThread, self)
    end,

    AirDestructionEffectsThread = function(self)
        local numExplosions = math.floor(table.getn(self.AirDestructionEffectBones) * 0.5)
        for i = 0, numExplosions do
            explosion.CreateDefaultHitExplosionAtBone(self,
                self.AirDestructionEffectBones[util.GetRandomInt(1, numExplosions)], 0.5)
            WaitSeconds(util.GetRandomFloat(0.2, 0.9))
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

TypeClass = XEA0306
