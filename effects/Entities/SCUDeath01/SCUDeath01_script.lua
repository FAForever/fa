-- File     :  /effects/Entities/SCUDeath01/SCUDeath01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  SCU Death Explosion
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local Util = import("/lua/utilities.lua")
local RandomFloat = Util.GetRandomFloat

SCUDeath01 = Class(NullShell) {

    OnCreate = function(self)
        NullShell.OnCreate(self)
        local myBlueprint = self.Blueprint

        -- Play the "NukeExplosion" sound
        if myBlueprint.Audio.NukeExplosion then
            self:PlaySound(myBlueprint.Audio.NukeExplosion)
        end

        -- Create thread that spawns and controls effects
        self.Trash:Add(ForkThread(self.EffectThread, self))
    end,

    PassDamageData = function(self, damageData)
        NullShell.PassMetaDamage(self, damageData)
        local instigator = self.Launcher
        if instigator == nil then
            instigator = self
        end

        self:DoDamage(instigator, self.DamageData, nil)
    end,

    OnImpact = function(self, targetType, targetEntity)
        self:Destroy()
    end,

    EffectThread = function(self)
        local army = self.Army
        local position = self:GetPosition()
        if position[2] + 2 > GetSurfaceHeight(position[1], position[3]) then
            self.Trash:Add(ForkThread(self.CreateOuterRingWaveSmokeRing, self))
        end

        -- Create full-screen glow flash
        CreateLightParticle(self, -1, army, 10, 4, 'glow_02', 'ramp_red_02')
        WaitTicks(3)
        CreateLightParticle(self, -1, army, 10, 20, 'glow_03', 'ramp_fire_06')
        WaitTicks(6)

        CreateLightParticle(self, -1, army, 20, 250, 'glow_03', 'ramp_nuke_04')

        -- Create ground decals
        local orientation = RandomFloat(0, 2 * math.pi)
        CreateDecal(position, orientation, 'Crater01_albedo', '', 'Albedo', 20, 20, 1200, 0, army)
        CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 20, 20, 1200, 0, army)
        CreateDecal(position, orientation, 'nuke_scorch_003_albedo', '', 'Albedo', 20, 20, 1200, 0, army)

        -- Knockdown force rings
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
        WaitTicks(11)
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
    end,

    CreateOuterRingWaveSmokeRing = function(self)
        local sides = 10
        local angle = (2 * math.pi) / sides
        local velocity = 2
        local OffsetMod = 4
        local projectiles = {}

        for i = 0, (sides - 1) do
            local X = math.sin(i * angle)
            local Z = math.cos(i * angle)
            local proj = self:CreateProjectile('/effects/entities/SCUDeathShockwave01/SCUDeathShockwave01_proj.bp',
                X * OffsetMod, 2, Z * OffsetMod, X, 0, Z)
                :SetVelocity(velocity)
            table.insert(projectiles, proj)
        end

        WaitTicks(31)

        -- Slow projectiles down to normal speed
        for k, v in projectiles do
            v:SetAcceleration(-0.45)
        end
    end,
}
TypeClass = SCUDeath01
