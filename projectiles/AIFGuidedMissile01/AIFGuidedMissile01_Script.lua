-------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFGuidedMissile01/AIFGuidedMissile01_script.lua
-- Author(s):  Matt Vainio, Gordon Duclos
-- Summary  :  Aeon Guided Missile, DAA0206
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------
local AGuidedMissileProjectile = import("/lua/aeonprojectiles.lua").AGuidedMissileProjectile
local RandF = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

AIFGuidedMissile = ClassProjectile(AGuidedMissileProjectile) {
    OnCreate = function(self)
        AGuidedMissileProjectile.OnCreate(self)
        local launcher = self.Launcher
        if launcher and not launcher:IsDead() then
            launcher:ProjectileFired()
        end
        self.Trash:Add(ForkThread(self.SplitThread, self))
    end,

    SplitThread = function(self)
        ------Create/play the split effects.
        for k, v in EffectTemplate.AMercyGuidedMissileSplit do
            CreateEmitterOnEntity(self, self.Army, v)
        end
        WaitTicks(1)

        -- Create several other projectiles in a dispersal pattern
        local vx, vy, vz = self:GetVelocity()
        local velocity = 16
        local numProjectiles = 8
        local angle = (2 * math.pi) / numProjectiles
        local ChildProjectileBP = '/projectiles/AIFGuidedMissile02/AIFGuidedMissile02_proj.bp'
        local spreadMul = 0.4 -- Adjusts the width of the dispersal
        local xVec = 0
        local yVec = vy
        local zVec = 0
        local target = self.OriginalTarget
        local tx, ty, tz = target:GetPositionXYZ()
        local radius = 7.5


        -- Adjust damage by number of split projectiles
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / numProjectiles

        -- -- Launch projectiles at semi-random angles away from split location

        for i = 0, (numProjectiles - 1) do
            addx = math.sin(i * angle) * spreadMul
            addz = math.cos(i * angle) * spreadMul
            --equalizer = 1.4
            --WARN("addx = " .. tostring(addx) .. "    vx = " .. tostring(vx) .. "   sum = " .. tostring(addx + vx))
            xVec = vx + addx
            zVec = vz + addz
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:SetVelocity(xVec, yVec, zVec)
            --proj:SetVelocity( velocity )
            local newTarget = {
                tx + radius * math.sin(i * angle),
                ty,
                tz + radius * math.cos(i * angle),
            }
            proj:SetNewTargetGround(newTarget)
            proj.DamageData = self.DamageData
            proj.tx = tx
            proj.tz = tz
        end
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Circle_1.bp')
        CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Circle_2.bp')
        CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_Fog.bp'):SetEmitterParam('LIFETIME', 100)
        CreateEmitterAtEntity(self, self.Army, '/effects/emitters/_Mercy_sparkle_2.bp'):SetEmitterParam('LIFETIME', 100)
        WARN("Sup bitch")
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
