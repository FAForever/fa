--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local SHoverLandUnit = import('/lua/seraphimunits.lua').SHoverLandUnit
local DefaultBeamWeapon = import('/lua/sim/DefaultWeapons.lua').DefaultBeamWeapon

-- Seraphim energy ball units
---@class SEnergyBallUnit : SHoverLandUnit
SEnergyBallUnit = ClassUnit(SHoverLandUnit) {
    timeAlive = 0,

    OnCreate = function(self)
        SHoverLandUnit.OnCreate(self)
        self:SetUnSelectable(true)
        self.CanTakeDamage = false
        self.CanBeKilled = false
        self:PlayUnitSound('Spawn')
        ChangeState(self, self.KillingState)
    end,

    KillingState = State {
        LifeThread = function(self)
            WaitSeconds(self:GetBlueprint().Lifetime)
            ChangeState(self, self.DeathState)
        end,

        Main = function(self)
            local bp = self:GetBlueprint()
            local aiBrain = self:GetAIBrain()

            -- Queue up random moves
            local x, y,z = unpack(self:GetPosition())
            for i = 1, 100 do
                IssueToUnitMove(self, {x + Random(-bp.MaxMoveRange, bp.MaxMoveRange), y, z + Random(-bp.MaxMoveRange, bp.MaxMoveRange)})
            end

            -- Weapon information
            local weaponMaxRange = bp.Weapon[1].MaxRadius
            local weaponMinRange = bp.Weapon[1].MinRadius or 0
            local beamLifetime = bp.Weapon[1].BeamLifetime or 1
            local reaquireTime = bp.Weapon[1].RequireTime or 0.5
            local weapon = self:GetWeapon(1)

            self:ForkThread(self.LifeThread)

            while true do
                local location = self:GetPosition()
                local targets = aiBrain:GetUnitsAroundPoint(categories.LAND - categories.UNTARGETABLE, location, weaponMaxRange)

                local filteredUnits = {}
                for k, v in targets do
                    if VDist3(location, v:GetPosition()) >= weaponMinRange and v ~= self then
                        table.insert(filteredUnits, v)
                    end
                end

                local target = table.random(filteredUnits)
                if target then
                    weapon:SetTargetEntity(target)
                else
                    weapon:SetTargetGround({location[1] + Random(-20, 20), location[2], location[3] + Random(-20, 20)})
                end
                -- Wait a tick to let the target update awesomely.
                WaitTicks(2)
                self.timeAlive = self.timeAlive + .1

                weapon:FireWeapon()

                WaitSeconds(beamLifetime)
                DefaultBeamWeapon.PlayFxBeamEnd(weapon, weapon.Beams[1].Beam)
                WaitSeconds(reaquireTime)
            end
        end,

        ComputeWaitTime = function(self)
            local timeLeft = self:GetBlueprint().Lifetime - self.timeAlive

            local maxWait = 75
            if timeLeft < 7.5 and timeLeft > 2.5 then
                maxWait = timeLeft * 10
            end
            local waitTime = timeLeft
            if timeLeft > 2.5 then
                waitTime = Random(5, maxWait)
            end

            self.timeAlive = self.timeAlive + (waitTime * .1)
            WaitSeconds(waitTime * .1)
        end,
    },

    DeathState = State {
        Main = function(self)
            self.CanBeKilled = true
            if self.Layer == 'Water' then
                self:PlayUnitSound('HoverKilledOnWater')
            end
            self:PlayUnitSound('Destroyed')
            self:Destroy()
        end,
    },
}
