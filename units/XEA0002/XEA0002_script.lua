-----------------------------------------------------------------
-- File     :  /cdimage/units/XEA0002/XEA0002_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  UEF Defense Satelite Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TOrbitalDeathLaserBeamWeapon = import('/lua/terranweapons.lua').TOrbitalDeathLaserBeamWeapon

XEA0002 = Class(TAirUnit) {
    DestroyNoFallRandomChance = 1.1,

    HideBones = {'Shell01', 'Shell02', 'Shell03', 'Shell04',},

    Weapons = {
        OrbitalDeathLaserWeapon = Class(TOrbitalDeathLaserBeamWeapon){},
    },
    
    OnDestroy = function(self)
        -- If we were destroyed without triggering OnKilled and our parent exists, notify that we just died
        if not self.IsDying and self.Parent then
            self.Parent.Satellite = nil
            -- Rebuild a new satellite for the AI
            if self:GetAIBrain().BrainType ~= 'Human' then
                IssueBuildFactory({self.Parent}, 'XEA0002', 1)
            end
        end

        TAirUnit.OnDestroy(self)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        if self.IsDying then
            return
        end

        local wep = self:GetWeaponByLabel('OrbitalDeathLaserWeapon')
        for _, v in wep.Beams do
            v.Beam:Disable()
        end

        self.IsDying = true

        -- If our parent exists, notify that we just died
        if self.Parent then
            self.Parent.Satellite = nil
            -- Rebuild a new satellite for the AI
            if self:GetAIBrain().BrainType ~= 'Human' then
                IssueBuildFactory({self.Parent}, 'XEA0002', 1)
            end
        end

        TAirUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    Open = function(self)
        ChangeState(self, self.OpenState)
    end,

    OpenState = State() {
        Main = function(self)
            -- Create the animator to open the fins
            self.OpenAnim = CreateAnimator(self)
            self.Trash:Add(self.OpenAnim)

            -- Play the fist part of the animation
            self.OpenAnim:PlayAnim('/units/XEA0002/xea0002_aopen01.sca')
            WaitFor(self.OpenAnim)

            -- Hide desired bones and play part two
            for _, v in self.HideBones do
                self:HideBone(v, true)
            end
            self.OpenAnim:PlayAnim('/units/XEA0002/xea0002_aopen02.sca')
        end,
    },

    -- Make this unit ignore all but nuclear damage (Kills it when parked above a launcher)
    OnDamage = function(self, instigator, amount, vector, damageType)
        if EntityCategoryContains(categories.NUKE, instigator) then
            self:Destroy()
        end
    end,
}

TypeClass = XEA0002
