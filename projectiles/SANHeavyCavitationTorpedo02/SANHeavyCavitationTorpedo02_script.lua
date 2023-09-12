-- File     :  /data/projectiles/SANHeavyCavitationTorpedo02/SANHeavyCavitationTorpedo02_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SHeavyCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SHeavyCavitationTorpedo
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local EffectTemplate = import("/lua/effecttemplates.lua")

SANHeavyCavitationTorpedo02 = ClassProjectile(SHeavyCavitationTorpedo) {
    FxSplashScale = .4,
    FxEnterWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
    },

    FxSplit = {
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_01_emit.bp',
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_02_emit.bp',
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_03_emit.bp',
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_04_emit.bp',
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_05_emit.bp',
    },

    OnEnterWater = function(self)
        SHeavyCavitationTorpedo.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.5)

        self.AirTrails:Destroy()
        CreateEmitterOnEntity(self,self.Army,EffectTemplate.SHeavyCavitationTorpedoFxTrails)
        self:SetCollideSurface(false)
    end,

    OnCreate = function(self, inWater)
        SHeavyCavitationTorpedo.OnCreate(self, inWater)
        self.Trash:Add(ForkThread(self.ProjectileSplit,self))
        self.AirTrails = CreateEmitterOnEntity(self,self.Army,EffectTemplate.SHeavyCavitationTorpedoFxTrails02)
    end,

    ProjectileSplit = function(self)
        WaitTicks(2)
        local ChildProjectileBP = '/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_proj.bp'
        local vx, vy, vz = self:GetVelocity()
        local velocity = 7

        -- Create projectiles in a dispersal pattern
        local numProjectiles = 3
        local angle = (2*math.pi) / numProjectiles
        local angleInitial = RandomFloat(0, angle)

        -- Randomization of the spread
        local angleVariation = angle * 0.4 -- Adjusts angle variance spread
        local spreadMul = 0.4 -- Adjusts the width of the dispersal
        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Divide the damage between each projectile.  The damage in the BP is used as the initial projectile's
        -- damage, in case the torpedo hits something before it splits.
        local DividedDamageData = self.DamageData
        DividedDamageData.DamageAmount = DividedDamageData.DamageAmount / numProjectiles
        self.DamageData = nil

        local FxFragEffect = EffectTemplate.SHeavyCavitationTorpedoSplit

        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtEntity(self, self.Army, v)
        end

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, (numProjectiles -1) do
            xVec = vx + (math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj.DamageData = DividedDamageData
            proj:PassData(self:GetTrackingTarget())
            proj:SetVelocity(xVec,yVec,zVec)
            proj:SetVelocity(velocity)
        end
        self:Destroy()
    end,
}
TypeClass = SANHeavyCavitationTorpedo02