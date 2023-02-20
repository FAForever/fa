-- Terran CDR Nuke

local TIFMissileNuke = import("/lua/terranprojectiles.lua").TIFMissileNuke
TIFMissileNukeCDR = ClassProjectile(TIFMissileNuke) {
    BeamName = '/effects/emitters/missile_exhaust_fire_beam_06_emit.bp',
    InitialEffects = {'/effects/emitters/nuke_munition_launch_trail_02_emit.bp',},
    LaunchEffects = {
        '/effects/emitters/nuke_munition_launch_trail_03_emit.bp',
        '/effects/emitters/nuke_munition_launch_trail_05_emit.bp',
    },
    ThrustEffects = {'/effects/emitters/nuke_munition_launch_trail_04_emit.bp',},
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
        self:CreateEffects(self.InitialEffects, self.Army, 1)
        self:SetTurnRate(8)
        WaitTicks(4)
        self:CreateEffects(self.LaunchEffects, self.Army, 1)
        self:CreateEffects(self.ThrustEffects, self.Army, 1)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        local nukeDamage = function(self, instigator, pos, brain, army, damageType)
            if self.TotalTime == 0 then
                DamageArea(instigator, pos, self.Radius, self.Damage, (damageType or 'Nuke'), true, true)
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
            WaitTicks(21)
            self:SetTurnRate(20)
        elseif dist > 128 and dist <= 213 then
            -- Increase check intervals
            self:SetTurnRate(30)
            WaitTicks(16)
            self:SetTurnRate(30)
        elseif dist > 43 and dist <= 107 then
            -- Further increase check intervals
            WaitTicks(4)
            self:SetTurnRate(75)
        elseif dist > 0 and dist <= 43 then
            -- Further increase check intervals
            self:SetTurnRate(200)
            KillThread(self.MoveThread)
        end
    end,

    OnEnterWater = function(self)
        TIFMissileNuke.OnEnterWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TIFMissileNukeCDR
