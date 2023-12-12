------------------------------------------------------------------------------------------------------
-- File     :  \data\effects\Entities\InainoEffectController01\InainoBombEffectController01_script.lua
-- Author(s):  Gordon Duclos, Matt Vainio
-- Summary  :  Inaino Bomb effect controller script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

local SIFInainoStrategicMissileEffect01 = '/effects/Entities/SIFInainoStrategicMissileEffect01/SIFInainoStrategicMissileEffect01_proj.bp'
local SIFInainoStrategicMissileEffect02 = '/effects/Entities/SIFInainoStrategicMissileEffect02/SIFInainoStrategicMissileEffect02_proj.bp'
local SIFInainoStrategicMissileEffect03 = '/effects/Entities/SIFInainoStrategicMissileEffect03/SIFInainoStrategicMissileEffect03_proj.bp'

---@class InainoEffectController01 : NullShell
InainoEffectController01 = Class(NullShell) {

    ---@param self InainoEffectController01
    ---@param Data table unused
    EffectThread = function(self, Data)
        self.Trash:Add(ForkThread(self.CreateInitialHit, self.Army, self))
        self.Trash:Add(ForkThread(self.CreateInitialBuildup, self.Army, self))
        self.Trash:Add(ForkThread(self.CreateGroundFingers, self))
        self.Trash:Add(ForkThread(self.CreateInitialFingers, self))
        self.Trash:Add(ForkThread(self.MainBlast, self.Army, self))
    end,

    ---@param self InainoEffectController01
    ---@param army number
    CreateInitialHit = function(self, army)
        for k, v in EffectTemplate.SIFInainoHit01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
    end,

    ---@param self InainoEffectController01
    ---@param army number
    CreateInitialBuildup = function(self, army)
        WaitSeconds(2.0)
        for k, v in EffectTemplate.SIFInainoHit02 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
    end,

    ---@param self InainoEffectController01
    ---@param army number
    MainBlast = function(self, army)
        WaitSeconds(5.00)

        -- Create a light for this thing's flash.
        CreateLightParticle(self, -1, self.Army, 160, 14, 'flare_lens_add_03', 'ramp_white_07')

        -- Create our decals
        CreateDecal(self:GetPosition(), RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 80, 80, 1000, 0, self.Army)

        -- Create explosion effects
        for k, v in EffectTemplate.SIFInainoDetonate01 do
            emit = CreateEmitterAtEntity(self,army,v)
        end
        self:ShakeCamera(55, 10, 0, 2.5)

        WaitSeconds(0.3)

        -- Create upward moving smoke plume
        local plume = self:CreateProjectile('/effects/entities/SIFInainoStrategicMissileEffect04/SIFInainoStrategicMissileEffect04_proj.bp', 0, 3, 0, 0, 0, 0)
        plume:SetLifetime(5.35)
        plume:SetVelocity(10.0)
        plume:SetAcceleration(-0.35)
        plume:SetCollision(false)
        plume:SetVelocityAlign(true)

        -- Create explosion dust ring
        local vx, vy, vz = self:GetVelocity()
        local num_projectiles = 16
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat(0, horizontal_angle)
        local xVec, zVec
        local offsetMultiple = 30.0
        local px, pz

        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle)))
            zVec = (math.cos(angleInitial + (i*horizontal_angle)))
            px = (offsetMultiple*xVec)
            pz = (offsetMultiple*zVec)

            local proj = self:CreateProjectile(SIFInainoStrategicMissileEffect03, px, 1, pz, xVec, 0, zVec)
            proj:SetLifetime(12.0)
            proj:SetVelocity(10.0)
            proj:SetAcceleration(-0.35)
        end
    end,

    ---@param self InainoEffectController01
    CreateGroundFingers = function(self)
        -- Outward rushing fingers that spawn the upward fingers
        local num_projectiles = 5
        local horizontal_angle = (2*math.pi) / num_projectiles
        local xVec, zVec
        local px, pz

        for i = 0, (num_projectiles -1) do
            xVec = math.sin(i*horizontal_angle)
            zVec = math.cos(i*horizontal_angle)
            px = 1 * xVec
            pz = 1 * zVec

            local proj = self:CreateProjectile(SIFInainoStrategicMissileEffect02, px, 2.0, pz, xVec, 0.0, zVec)
            proj:SetVelocity(15)
        end
    end,

    ---@param self InainoEffectController01
    CreateInitialFingers = function(self)
        WaitSeconds(1.75)
        -- Upward rising fingers that join to form explosion
        local num_projectiles = 5
        local horizontal_angle = (2*math.pi) / num_projectiles
        local xVec, zVec
        local px, pz

        for i = 0, (num_projectiles -1) do
            xVec = math.sin(i*horizontal_angle)
            zVec = math.cos(i*horizontal_angle)
            px = 25.0 * xVec
            pz = 25.0 * zVec

            local proj = self:CreateProjectile(SIFInainoStrategicMissileEffect01, px, 2.0, pz, -xVec, 2.0, -zVec)
            proj:SetVelocity(20)
            proj:SetBallisticAcceleration(-5.0)
        end
    end,
}
TypeClass = InainoEffectController01

-- Kept for Backwards Compatibility
local SIFInainoStrategicMissileEffect04 = '/effects/Entities/SIFInainoStrategicMissileEffect04/SIFInainoStrategicMissileEffect04_proj.bp'