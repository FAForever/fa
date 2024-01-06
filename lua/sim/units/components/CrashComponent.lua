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

---@class CrashComponent : moho.unit_methods
---@field CrashThreadInstance? thread
CrashComponent = ClassSimple {

    -- There's a couple of things that you wish worked, but don't work:
    -- - We can't use manipulators (such as sliders) as they move the mesh but not the collision shape
    -- - We can't use a collision detector as it detects the water surface but not the terrain below it
    --
    -- Therefore we rely on a dummy projectile to pass these events to the unit.

    ---@param self Unit
    Crash = function(self)
        -- local scope for performance
        local trash = self.Trash
        local blueprint = self.Blueprint
        local crashWatchBone = blueprint.CrashWatchBone
        local crashRadius = blueprint.CrashRadius
        local px, py, pz = self:GetPositionXYZ(crashWatchBone)
        local inWater = GetSurfaceHeight(px, pz) > py

        -- multiply velocity with tick rate
        local uvx, uvy, uvz = self:GetVelocity()
        uvx = 10 * uvx
        uvy = 10 * uvy
        uvz = 10 * uvz

        -- create air or wter projectile
        local crashProjectile
        if inWater then
            crashProjectile = self:CreateProjectileAtBone(
                '/effects/Entities/CrashProjectile/CrashWaterProjectile_proj.bp',
                crashWatchBone
            ) --[[@as DummyProjectile]]

            self.CrashThreadInstance = trash:Add(
                ForkThread(
                    self.CrashWaterBehaviorThread,
                    self,
                    crashProjectile, uvx, uvy, uvz
                )
            )
        else
            crashProjectile = self:CreateProjectileAtBone(
                '/effects/Entities/CrashProjectile/CrashAirProjectile_proj.bp',
                crashWatchBone
            ) --[[@as DummyProjectile]]

            self.CrashThreadInstance = trash:Add(
                ForkThread(
                    self.CrashAirBehaviorThread,
                    self,
                    crashProjectile, uvx, uvy, uvz
                )
            )
        end

        -- attach the unit to the projectile
        self:AttachBoneTo(crashWatchBone, crashProjectile, -2)

        -- inherit the unit velocity
        crashProjectile:SetVelocity(uvx, uvy, uvz)
        crashProjectile:ChangeDetonateBelowHeight(crashRadius)

        -- clear out the movement effects
        self:DestroyMovementEffects()
        self:DestroyTopSpeedEffects()
        self:DestroyBeamExhaust()
    end,

    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    ---@param uvx number
    ---@param uvy number
    ---@param uvz number
    CrashAirBehaviorThread = function(self, crashProjectile, uvx, uvy, uvz)
    end,

    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    ---@param uvx number
    ---@param uvy number
    ---@param uvz number
    CrashWaterBehaviorThread = function(self, crashProjectile, uvx, uvy, uvz)
        crashProjectile:SetMaxSpeed(0.4)
        WaitTicks(3)
        crashProjectile:SetMaxSpeed(0.8)
        WaitTicks(3)
        crashProjectile:SetMaxSpeed(1.2)
    end,

    --- Called when the dummy projectile impacts with the terrain
    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    ---@param inWater boolean
    OnCrashIntoTerrain = function(self, crashProjectile, inWater)
        KillThread(self.CrashThreadInstance)
        crashProjectile:Destroy()

        -- create debris?
        ForkThread(self.DestroyUnit, self, 0)
    end,

    --- Called when the dummy projectile impacts with a shield
    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    ---@param shield Unit
    ---@param inWater any
    OnCrashIntoShield = function(self, crashProjectile, shield, inWater)
        if not inWater then
            self:CrashReflect(crashProjectile, shield)
        end

        crashProjectile:SetCollideEntity(false)
    end,

    --- Called when the dummy projectile impacts with the water surface
    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    OnCrashIntoWater = function(self, crashProjectile)
        local trash = self.Trash
        local blueprint = self.Blueprint
        local crashWatchBone = blueprint.CrashWatchBone
        local crashRadius = blueprint.CrashRadius

        -- match velocity of the projectile with the velocity of the unit when it died
        local uvx, uvy, uvz = self:GetVelocity()
        uvx = 10 * uvx
        uvy = 10 * uvy
        uvz = 10 * uvz

        -- apply water crash behavior
        KillThread(self.CrashThreadInstance)
        self.CrashThreadInstance = trash:Add(
            ForkThread(
                self.CrashWaterBehaviorThread,
                self,
                crashProjectile,
                uvx, uvy, uvz
            )
        )

        crashProjectile:SetMaxSpeed(0.2)
    end,

    ---@param self Unit
    ---@param crashProjectile CrashAirProjectile | CrashWaterProjectile
    ---@param shield Unit
    CrashReflect = function(self, crashProjectile, shield)

        -- https://gamedev.stackexchange.com/questions/150322/how-to-find-collision-reflection-vector-on-a-sphere
        -- https://3dkingdoms.com/weekly/weekly.php?a=2

        local cpx, cpy, cpz = crashProjectile:GetPositionXYZ()
        local cvx, cvy, cvz = crashProjectile:GetVelocity()
        local spx, spy, spz = shield:GetPositionXYZ()

        -- from velocity/tick to velocity/second
        cvx = 10 * cvx
        cvy = 10 * cvy
        cvz = 10 * cvz

        -- compute normal
        local nx = cpx - spx
        local ny = cpy - spy
        local nz = cpz - spz
        local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
        nx = nx / nl
        ny = ny / nl
        nz = nz / nl

        -- compute dot product
        local d = nx * cvx + ny * cvy + nz * cvz

        -- compute reflection
        local rvx = -2 * d * nx + cvx
        local rvy = -2 * d * ny + cvy
        local rvz = -2 * d * nz + cvz

        -- local factor = 25
        -- DrawCircle({ cpx, cpy, cpz }, 0.5, 'ffffff')
        -- DrawLine({ cpx, cpy, cpz }, { cpx + factor * nx, cpy + factor * ny, cpz + factor * nz }, 'ffffff')
        -- DrawCircle({ cpx + factor * nx, cpy + factor * ny, cpz + factor * nz }, 0.5, 'ffffff')
        -- DrawLine({ cpx, cpy, cpz }, { cpx + factor * rvx, cpy + factor * rvy, cpz + factor * rvz }, '00ff00')
        -- DrawCircle({ cpx + factor * rvx, cpy + factor * rvy, cpz + factor * rvz }, 0.5, '00ff00')
        -- DrawLine({ cpx, cpy, cpz }, { cpx - factor * cvx, cpy - factor * cvy, cpz - factor * cvz }, '0000ff')
        -- DrawCircle({ cpx - factor * cvx, cpy - factor * cvy, cpz - factor * cvz }, 0.5, '0000ff')

        -- LOG("velocity", cvx, cvy, cvz)
        -- LOG("normal ", nx, ny, nz)
        -- LOG("reflection", rvx, rvy, rvz)

        -- update velocity
        local damping = 0.5
        crashProjectile:SetVelocity(damping * rvx, damping * rvy, damping * rvz)
        crashProjectile:SetPosition({ cpx + 0.1 * nx, cpy + 0.1 * ny, cpz + 0.1 * nz }, true)
    end,
}
