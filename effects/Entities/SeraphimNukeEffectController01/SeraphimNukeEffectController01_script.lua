---------------------------------------------------------------------------------------------------------
-- File     :  /effects/Entities/SeraphimNukeEffectController01/SeraphimNukeEffectController01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Seraphim nuclear explosion script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

local SIFExperimentalStrategicMissileEffect02 = '/effects/Entities/SIFExperimentalStrategicMissileEffect02/SIFExperimentalStrategicMissileEffect02_proj.bp'
local SIFExperimentalStrategicMissileEffect04 = '/effects/Entities/SIFExperimentalStrategicMissileEffect04/SIFExperimentalStrategicMissileEffect04_proj.bp'
local SIFExperimentalStrategicMissileEffect05 = '/effects/Entities/SIFExperimentalStrategicMissileEffect05/SIFExperimentalStrategicMissileEffect05_proj.bp'
local SIFExperimentalStrategicMissileEffect06 = '/effects/Entities/SIFExperimentalStrategicMissileEffect06/SIFExperimentalStrategicMissileEffect06_proj.bp'

SeraphimNukeEffectController01 = Class(NullShell) {
    -- Create inner explosion plasma
    CreateEffectInnerPlasma = function(self)
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 12
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat(0, horizontal_angle)
        local xVec, zVec
        local offsetMultiple = 10.0
        local px, pz

        WaitSeconds(3.5)
        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)

            local proj = self:CreateProjectile(SIFExperimentalStrategicMissileEffect05, px, -10, pz, xVec, 0, zVec)
            proj:SetLifetime(5.0)
            proj:SetVelocity(7.0)
            proj:SetAcceleration(-0.35)
        end
    end,

    -- Create random wavy electricity lines
    CreateEffectElectricity = function(self)
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 7
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat(0, horizontal_angle)
        local xVec, zVec
        local offsetMultiple = 0.0
        local px, pz

        WaitSeconds(3.5)
        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)

            local proj = self:CreateProjectile(SIFExperimentalStrategicMissileEffect06, px, -8, pz, xVec, 0, zVec)
            proj:SetLifetime(3.0)
            proj:SetVelocity(RandomFloat(11, 20))
            proj:SetAcceleration(-0.35)
        end
    end,

    EffectThread = function(self)
        self:ForkThread(self.CreateEffectInnerPlasma)
        self:ForkThread(self.CreateEffectElectricity)
        local position = self:GetPosition()

        -- Knockdown force rings
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)

        -- Create full-screen glow flash
        CreateLightParticle(self, -1, self.Army, 140, 10, 'glow_02', 'ramp_blue_22')
        WaitSeconds(0.3)
        CreateLightParticle(self, -1, self.Army, 80, 36, 'glow_02', 'ramp_blue_16')

        -- Create explosion effects
        for k, v in EffectTemplate.SIFExperimentalStrategicMissileHit01 do
            emit = CreateEmitterAtEntity(self, self.Army, v)
        end
        
        WaitSeconds(3.0)
        CreateLightParticle(self, -1, self.Army, 160, 6, 'glow_02', 'ramp_blue_16')
        WaitSeconds(0.1)
        CreateLightParticle(self, -1, self.Army, 60, 60, 'glow', 'ramp_blue_22')

        -- Create detonate effects
        for k, v in EffectTemplate.SIFExperimentalStrategicMissileDetonate01 do
            emit = CreateEmitterAtEntity(self, self.Army, v)
        end

        -- Create ground decals
        local orientation = RandomFloat(0,2*math.pi)
        CreateDecal(position, orientation, 'Scorch_012_albedo', '', 'Albedo', 300, 300, 1200, 0, self.Army)
        CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 150, 150, 1200, 0, self.Army)

        -- Create explosion dust ring
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 24
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat(0, horizontal_angle)
        local xVec, zVec
        local offsetMultiple = 60.0
        local px, pz

        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)

            local proj = self:CreateProjectile(SIFExperimentalStrategicMissileEffect02, px, -12, pz, xVec, 0, zVec)
            proj:SetLifetime(12.0)
            proj:SetVelocity(10.0)
            proj:SetAcceleration(-0.35)
        end

        -- Create upward moving plasma plume
        local plume = self:CreateProjectile('/effects/entities/SIFExperimentalStrategicMissileEffect03/SIFExperimentalStrategicMissileEffect03_proj.bp', 0, 3, 0, 0, 1, 0)
        plume:SetLifetime(6.0)
        plume:SetVelocity(20.0)
        plume:SetAcceleration(-0.35)
        plume:SetCollision(false)
        plume:SetVelocityAlign(true)

        WaitSeconds(1.0)

        -- Create fireball plumes to accentuate the explosive detonation
        local num_projectiles = 15
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat(0, horizontal_angle)
        local xVec, yVec, zVec
        local angleVariation = 0.5
        local px, py, pz

        for i = 0, (num_projectiles -1) do
            xVec = math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))
            yVec = RandomFloat(0.3, 1.5) + 1.2
            zVec = math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))
            px = RandomFloat(7.5, 14.0) * xVec
            py = RandomFloat(7.5, 14.0) * yVec
            pz = RandomFloat(7.5, 14.0) * zVec

            local proj = self:CreateProjectile(SIFExperimentalStrategicMissileEffect04, px, py, pz, xVec, yVec, zVec)
            proj:SetVelocity(RandomFloat(10, 30))
            proj:SetBallisticAcceleration(-9.8)
        end
    end,
}
TypeClass = SeraphimNukeEffectController01
