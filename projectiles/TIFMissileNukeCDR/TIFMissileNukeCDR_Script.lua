--
-- Terran CDR Nuke
--

-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsDamageArea = GlobalMethods.DamageArea

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
-- End of automatically upvalued moho functions

local TIFMissileNuke = import('/lua/terranprojectiles.lua').TIFMissileNuke

TIFMissileNukeCDR = Class(TIFMissileNuke)({

    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {
        '/effects/emitters/nuke_munition_launch_trail_02_emit.bp',
    },
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {
        '/effects/emitters/nuke_munition_launch_trail_04_emit.bp',
    },

    OnCreate = function(self)
        TIFMissileNuke.OnCreate(self)
        self.effectEntityPath = '/effects/Entities/UEFNukeEffectController02/UEFNukeEffectController02_proj.bp'
        self:LauncherCallbacks()
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        if EntityCategoryContains(categories.AEON * categories.PROJECTILE * categories.ANTIMISSILE * categories.TECH_TWO, TargetEntity) then
            self:Destroy()
        else

            TIFMissileNuke.OnImpact(self, TargetType, TargetEntity)
        end
    end,


    -- Tactical nuke has different flight path
    MovementThread = function(self)
        local target = self:GetTrackingTarget()
        local launcher = self:GetLauncher()
        self.CreateEffects(self, self.InitialEffects, self.Army, 1)
        self.WaitTime = 0.1
        ProjectileMethodsSetTurnRate(self, 8)
        WaitSeconds(0.3)
        self.CreateEffects(self, self.LaunchEffects, self.Army, 1)
        self.CreateEffects(self, self.ThrustEffects, self.Army, 1)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        local nukeDamage = function(self, instigator, pos, brain, army, damageType)
            if self.TotalTime == 0 then
                GlobalMethodsDamageArea(instigator, pos, self.Radius, self.Damage, (damageType or 'Nuke'), true, true)
            end
        end

        self.InnerRing.DoNukeDamage = nukeDamage
        self.OuterRing.DoNukeDamage = nukeDamage
        TIFMissileNuke.DoDamage(self, instigator, DamageData, targetEntity)
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 50 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            ProjectileMethodsSetTurnRate(self, 20)
        elseif dist > 128 and dist <= 213 then
            -- Increase check intervals
            ProjectileMethodsSetTurnRate(self, 30)
            WaitSeconds(1.5)
            ProjectileMethodsSetTurnRate(self, 30)
        elseif dist > 43 and dist <= 107 then
            -- Further increase check intervals
            WaitSeconds(0.3)
            ProjectileMethodsSetTurnRate(self, 75)
        elseif dist > 0 and dist <= 43 then
            -- Further increase check intervals
            ProjectileMethodsSetTurnRate(self, 200)
            KillThread(self.MoveThread)
        end
    end,

    OnEnterWater = function(self)
        TIFMissileNuke.OnEnterWater(self)
        ProjectileMethodsSetDestroyOnWater(self, true)
    end,
})
TypeClass = TIFMissileNukeCDR
