-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local GlobalMethods = _G
local GlobalMethodsCreateEmitterAtEntity = GlobalMethods.CreateEmitterAtEntity
local GlobalMethodsCreateEmitterOnEntity = GlobalMethods.CreateEmitterOnEntity

local IEffectMethods = _G.moho.IEffect
local IEffectMethodsScaleEmitter = IEffectMethods.ScaleEmitter

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetCollideSurface = ProjectileMethods.SetCollideSurface
local ProjectileMethodsSetVelocity = ProjectileMethods.SetVelocity
-- End of automatically upvalued moho functions

#****************************************************************************
#**
#**  File     :  /data/projectiles/SANHeavyCavitationTorpedo02/SANHeavyCavitationTorpedo02_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SHeavyCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SHeavyCavitationTorpedo
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

SANHeavyCavitationTorpedo02 = Class(SHeavyCavitationTorpedo)({
    FxSplashScale = 0.4,
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
        EntityMethodsSetCollisionShape(self, 'Sphere', 0, 0, 0, 0.1)
        SHeavyCavitationTorpedo.OnEnterWater(self)

        for i in self.FxEnterWaterEmitter do
            #splash
            IEffectMethodsScaleEmitter(CreateEmitterAtEntity(self, self.Army, FxEnterWaterEmitter[i]), self.FxSplashScale)
        end
        self.AirTrails:Destroy()
        GlobalMethodsCreateEmitterOnEntity(self, self.Army, EffectTemplate.SHeavyCavitationTorpedoFxTrails)
        ProjectileMethodsSetCollideSurface(self, false)
    end,

    OnCreate = function(self)
        SHeavyCavitationTorpedo.OnCreate(self)
        self:ForkThread(self.ProjectileSplit)
        self.AirTrails = CreateEmitterOnEntity(self, self.Army, EffectTemplate.SHeavyCavitationTorpedoFxTrails02)
    end,

    ProjectileSplit = function(self)
        WaitSeconds(0.1)
        local ChildProjectileBP = '/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_proj.bp'
        local vx, vy, vz = self:GetVelocity()
        local velocity = 7

        # Create projectiles in a dispersal pattern
        local numProjectiles = 3
        local angle = 2 * math.pi / numProjectiles
        local angleInitial = RandomFloat(0, angle)

        # Randomization of the spread
        # Adjusts angle variance spread
        local angleVariation = angle * 0.4
        # Adjusts the width of the dispersal
        local spreadMul = 0.4
        local xVec = 0
        local yVec = vy
        local zVec = 0

        # Divide the damage between each projectile.  The damage in the BP is used as the initial projectile's
        # damage, in case the torpedo hits something before it splits.
        local DividedDamageData = self.DamageData
        DividedDamageData.DamageAmount = DividedDamageData.DamageAmount / numProjectiles

        local FxFragEffect = EffectTemplate.SHeavyCavitationTorpedoSplit

        # Split effects
        for k, v in FxFragEffect do
            GlobalMethodsCreateEmitterAtEntity(self, self.Army, v)
        end

        # Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            xVec = vx + math.sin(angleInitial + i * angle + RandomFloat(-angleVariation, angleVariation)) * spreadMul
            zVec = vz + math.cos(angleInitial + i * angle + RandomFloat(-angleVariation, angleVariation)) * spreadMul
            local proj = self:CreateChildProjectile(ChildProjectileBP)
            proj:PassDamageData(DividedDamageData)
            proj:PassData(self:GetTrackingTarget())
            ProjectileMethodsSetVelocity(proj, xVec, yVec, zVec)
            ProjectileMethodsSetVelocity(proj, velocity)
        end
        self:Destroy()
    end,
})
TypeClass = SANHeavyCavitationTorpedo02
