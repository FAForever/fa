-----------------------------------------------------------------
-- File     :  /cdimage/units/XEA0002/XEA0002_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  UEF Defense Satelite Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TOrbitalDeathLaserBeamWeapon = import("/lua/terranweapons.lua").TOrbitalDeathLaserBeamWeapon

---@class XEA0002 : TAirUnit
XEA0002 = Class(TAirUnit) {
    DestroyNoFallRandomChance = 1.1,

    HideBones = { 'Shell01', 'Shell02', 'Shell03', 'Shell04', },

    Weapons = {
        OrbitalDeathLaserWeapon = Class(TOrbitalDeathLaserBeamWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        TAirUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive(true)
    end,

    OnDestroy = function(self)
        -- If we were destroyed without triggering OnKilled and our parent exists, notify that we just died
        if not self.IsDying and self.Parent then
            self.Parent.Satellite = nil
            -- Rebuild a new satellite for the AI
            if self:GetAIBrain().BrainType ~= 'Human' then
                IssueBuildFactory({ self.Parent }, 'XEA0002', 1)
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
                IssueBuildFactory({ self.Parent }, 'XEA0002', 1)
            end
        end

        TAirUnit.OnKilled(self, instigator, type, overkillRatio)

        local vx, vy, vz = self:GetVelocity()

        -- randomize falling animation to prevent cntrl-k on nuke abuse
        -- use default animation if x or z speed > 0.1
        if math.abs(vx) < 0.1 and math.abs(vz) < 0.1 then
            self:AttachBoneTo(0, self.colliderProj, 'anchor')
            self.colliderProj:SetLocalAngularVelocity(0.5, 0.5, 0.5)
            local rng = Random(1, 8)
            local randomSetups = {
                { x = 1, z = 1 },
                { x = 1, z = 0 },
                { x = 1, z = -1 },
                { x = 0, z = 1 },
                { x = -1, z = -1 },
                { x = -1, z = 0 },
                { x = -1, z = 1 },
                { x = 0, z = -1 },
            }
            local x = randomSetups[rng].x
            local z = randomSetups[rng].z

            if x > 0 then
                x = x + Random(0, 8) / 10
            elseif x < 0 then
                x = x - Random(0, 8) / 10
            else
                if Random(1, 2) == 1 then
                    x = x + Random(0, 8) / 10
                else
                    x = x - Random(0, 8) / 10
                end
            end

            if z > 0 then
                z = z + Random(0, 8) / 10
            elseif z < 0 then
                z = z - Random(0, 8) / 10
            else
                if Random(1, 2) == 1 then
                    z = z + Random(0, 8) / 10
                else
                    z = z - Random(0, 8) / 10
                end
            end

            self.colliderProj:SetVelocity(x, 0, z)
        end
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
}

TypeClass = XEA0002
