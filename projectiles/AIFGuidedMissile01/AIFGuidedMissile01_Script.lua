-------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFGuidedMissile01/AIFGuidedMissile01_script.lua
-- Author(s):  Matt Vainio, Gordon Duclos
-- Summary  :  Aeon Guided Missile, DAA0206
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------

local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local AGuidedMissileProjectileOnCreate = AGuidedMissileProjectile.OnCreate

-- pre-import for performance
local AMercyGuidedMissileSplit = import("/lua/effecttemplates.lua").AMercyGuidedMissileSplit

-- upvalue scope for performance
local MathSin = math.sin
local MathCos = math.cos
local ForkThread = ForkThread
local IsDestroyed = IsDestroyed
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticleIntel = CreateLightParticleIntel

---@class AIFGuidedMissile : AGuidedMissileProjectile
AIFGuidedMissile = ClassProjectile(AGuidedMissileProjectile) {

    ---@param self AIFGuidedMissile
    OnCreate = function(self)
        AGuidedMissileProjectileOnCreate(self)

        -- tell the mercy to self destruct
        local launcher = self.Launcher
        if launcher and not IsDestroyed(launcher) then
            launcher:ProjectileFired()
        end

        self.Trash:Add(ForkThread(self.SplitThread, self))
    end,

    ---@param self AIFGuidedMissile
    SplitThread = function(self)
        -- local scope for performance
        local army = self.Army

        -- create a split effect
        for k, v in AMercyGuidedMissileSplit do
            CreateEmitterOnEntity(self, army, v)
        end

        -- we wait here so that the projectile has all the statistics set
        WaitTicks(1)

        -- create the dummy projectiles
        -- Create several other projectiles in a dispersal pattern
        local vx, vy, vz = self:GetVelocity()
        local numProjectiles = 8
        local angle = (2 * math.pi) / numProjectiles
        local ChildProjectileBP = '/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_proj.bp'
        local spreadMul = 0.4 -- Adjusts the width of the dispersal
        local xVec, yVec, zVec = 0, vy, 0
        local target = self:GetCurrentTargetPosition()
        local tx, ty, tz = target[1], target[2], target[3]
        local radius = 50

        -- Adjust damage by number of split projectiles
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / numProjectiles

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles - 1) do
            -- create the projectile
            local proj = self:CreateChildProjectile(ChildProjectileBP)

            -- match velocity
            xVec = vx + MathSin(i * angle) * spreadMul
            zVec = vz + MathCos(i * angle) * spreadMul
            proj:SetVelocity(xVec, yVec, zVec)
            proj:SetVelocity( 20 )

            -- determine new target on the unit circle
            local newTarget = {
                tx + radius * MathSin(i * angle),
                ty,
                tz + radius * MathCos(i * angle),
            }

            -- set the new target
            proj:SetNewTargetGround(newTarget)
            proj.DamageData = self.DamageData
            proj.tx = tx
            proj.tz = tz
        end
    end,

    ---@param self AIFGuidedMissile
    ---@param TargetType any
    ---@param TargetEntity any
    OnImpact = function(self, TargetType, TargetEntity)
        -- local scope for performance
        local army = self.Army

        -- let bloom thrive a bit
        CreateLightParticleIntel(self, -1, army, 9, 8, 'glow_02', 'ramp_flare_02')

        -- create the impact effects
        CreateEmitterAtEntity(self, army, '/effects/emitters/_Mercy_Circle_1.bp')
        CreateEmitterAtEntity(self, army, '/effects/emitters/_Mercy_Circle_2.bp')
        CreateEmitterAtEntity(self, army, '/effects/emitters/_Mercy_Fog.bp'):SetEmitterParam('LIFETIME', 100)
        CreateEmitterAtEntity(self, army, '/effects/emitters/_Mercy_sparkle_2.bp'):SetEmitterParam('LIFETIME', 100)
        self:Destroy()
    end
}
TypeClass = AIFGuidedMissile

-- "Umbrella" version

--   Create new target above impact point

--  local vertTarget = {
--     tx,
--     ty + 8,
--     tz,
-- }

-- self:SetNewTargetGround(vertTarget)

-- local px, py, pz = self:GetPositionXYZ()

-- local timeToImpact = math.floor( (tx-px)/vx )

-- WARN("Time to impact: " .. tostring(timeToImpact))

-- WaitTicks(timeToImpact - 1)

-- -- Launch projectiles at semi-random angles away from split location

-- for i = 0, (numProjectiles -1) do
--     xVec = math.sin(i*angle) * spreadMul
--     yVec = -0.5
--     zVec = math.cos(i*angle) * spreadMul
--     local proj = self:CreateChildProjectile(ChildProjectileBP)
--     proj:SetVelocity( xVec, yVec, zVec )
--     proj:SetVelocity( velocity )
--     local newTarget = {
--         tx + radius * math.sin(i*angle),
--         ty,
--         tz + radius * math.cos(i*angle),
--     }
--     proj:SetNewTargetGround(newTarget)
--     proj.DamageData = self.DamageData
-- end
-- self:Destroy()
-- end,

-- "Direct" version
-- -- Launch projectiles at semi-random angles away from split location

-- for i = 0, (numProjectiles -1) do
--     xVec = vx + math.sin(i*angle) * spreadMul
--     zVec = vz + math.cos(i*angle) * spreadMul
--     local proj = self:CreateChildProjectile(ChildProjectileBP)
--     proj:SetVelocity( xVec, yVec, zVec )
--     proj:SetVelocity( velocity )
--     local newTarget = {
--         tx + radius * math.sin(i*angle),
--         ty,
--         tz + radius * math.cos(i*angle),
--     }
--     proj:SetNewTargetGround(newTarget)
--     proj.DamageData = self.DamageData
-- end
-- self:Destroy()
