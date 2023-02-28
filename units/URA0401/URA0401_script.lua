--------------------------------------------------------------------------------
--  File     :  /cdimage/units/URA0401/URA0401_script.lua
-- Author(s):  John Comes, Andres Mendez, Gordon Duclos
-- Summary  :  Cybran Gunship Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local CAirUnit = import("/lua/cybranunits.lua").CAirUnit
local CDFRocketIridiumWeapon = import("/lua/cybranweapons.lua").CDFRocketIridiumWeapon
local CAAMissileNaniteWeapon = import("/lua/cybranweapons.lua").CAAMissileNaniteWeapon
local CDFHeavyElectronBolterWeapon = import("/lua/cybranweapons.lua").CDFHeavyElectronBolterWeapon
local util = import("/lua/utilities.lua")
local fxutil = import("/lua/effectutilities.lua")

---@class URA0401 : CAirUnit
URA0401 = ClassUnit(CAirUnit) {
    Weapons = {
        Missile01 = ClassWeapon(CDFRocketIridiumWeapon) {},
        Missile02 = ClassWeapon(CDFRocketIridiumWeapon) {},
        HeavyBolter = ClassWeapon(CDFHeavyElectronBolterWeapon){},
        HeavyBolterBack = ClassWeapon(CDFHeavyElectronBolterWeapon){},
        AAMissile01 = ClassWeapon(CAAMissileNaniteWeapon) {},
        AAMissile02 = ClassWeapon(CAAMissileNaniteWeapon) {},
    },

    MovementAmbientExhaustBones = {
        'Exhaust_Left01',
        'Exhaust_Left02',
        'Exhaust_Left03',
        'Exhaust_Right01',
        'Exhaust_Right02',
        'Exhaust_Right03',
    },

    DestructionPartsChassisToss = {'URA0401',},
    DestroyNoFallRandomChance = 1.1,

    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetScriptBit('RULEUTC_StealthToggle', true)
        self.AnimManip = CreateAnimator(self)
        self.Trash:Add(self.AnimManip)
    end,

    OnMotionHorzEventChange = function(self, new, old )
        CAirUnit.OnMotionHorzEventChange(self, new, old)

        if self.ThrustExhaustTT1 == nil then 
            if self.MovementAmbientExhaustEffectsBag then
                fxutil.CleanupEffectBag(self,'MovementAmbientExhaustEffectsBag')
            else
                self.MovementAmbientExhaustEffectsBag = {}
            end
            self.ThrustExhaustTT1 = self:ForkThread(self.MovementAmbientExhaustThread)
        end

        if new == 'Stopped' and self.ThrustExhaustTT1 ~= nil then
            KillThread(self.ThrustExhaustTT1)
            fxutil.CleanupEffectBag(self, 'MovementAmbientExhaustEffectsBag')
            self.ThrustExhaustTT1 = nil
        end      
    end,

    MovementAmbientExhaustThread = function(self)
        while not self.Dead do
            local ExhaustEffects = {
                '/effects/emitters/dirty_exhaust_smoke_01_emit.bp',
                '/effects/emitters/dirty_exhaust_sparks_01_emit.bp',            
            }
            local ExhaustBeam = '/effects/emitters/missile_exhaust_fire_beam_03_emit.bp'        

            for kE, vE in ExhaustEffects do
                for kB, vB in self.MovementAmbientExhaustBones do
                    table.insert(self.MovementAmbientExhaustEffectsBag, CreateAttachedEmitter(self, vB, self.Army, vE))
                    table.insert(self.MovementAmbientExhaustEffectsBag, CreateBeamEmitterOnEntity(self, vB, self.Army, ExhaustBeam))
                end
            end

            WaitSeconds(2)
            fxutil.CleanupEffectBag(self, 'MovementAmbientExhaustEffectsBag')
                            
            WaitSeconds(util.GetRandomFloat(1,7))
        end 
    end,

    OnMotionVertEventChange = function(self, new, old)
        CAirUnit.OnMotionVertEventChange(self, new, old)

        if ((new == 'Top' or new == 'Up') and old == 'Down') then
            self.AnimManip:SetRate(-1)
        elseif (new == 'Down') then
            self.AnimManip:PlayAnim(self:GetBlueprint().Display.AnimationLand, false):SetRate(1.5)
        elseif (new == 'Up') then
            self.AnimManip:PlayAnim(self:GetBlueprint().Display.AnimationTakeOff, false):SetRate(1)
        end
    end,
}

TypeClass = URA0401
