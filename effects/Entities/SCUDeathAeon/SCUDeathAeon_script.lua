------------------------------------------------------------------------------
--  Summary  : Aeon SCU Death Explosion
------------------------------------------------------------------------------

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('/lua/utilities.lua')
local RandomFloat = Util.GetRandomFloat

SCUDeath01 = Class(NullShell) {

    CloudFlareEffects = {
    '/effects/emitters/quantum_warhead_02_emit.bp',
    '/effects/emitters/quantum_warhead_04_emit.bp',
	},

    OnCreate = function(self)
        NullShell.OnCreate(self)
        local myBlueprint = self:GetBlueprint()

        -- Play the "NukeExplosion" sound
        if myBlueprint.Audio.NukeExplosion then
            self:PlaySound(myBlueprint.Audio.NukeExplosion)
        end

		-- Create thread that spawns and controls effects
        self:ForkThread(self.EffectThread)
    end,

    PassDamageData = function(self, damageData)
        NullShell.PassDamageData(self, damageData)
        local instigator = self:GetLauncher()
        if instigator == nil then
            instigator = self
        end

        -- Do Damage
        self:DoDamage( instigator, self.DamageData, nil )  
    end,

    OnImpact = function(self, targetType, targetEntity)
        self:Destroy()
    end,

    EffectThread = function(self)
        local army = self:GetArmy()
        local position = self:GetPosition()
        self:ForkThread(self.DistortionField)
        self:ForkThread(self.InnerCloudFlares)
        self:ForkThread(self.Shockwave)
        self:ForkThread(self.CreateOuterRingWaveSmokeRing)
		
        -- Create full-screen glow flash
        CreateLightParticle(self, -1, army, 10, 4, 'glow_02', 'ramp_quantum_warhead_flash_01')
        WaitSeconds( 0.25 )
        CreateLightParticle(self, -1, army, 13, 200, 'glow_03', 'ramp_quantum_warhead_flash_01')
        
        -- Create ground decals
        local orientation = RandomFloat( 0, 2 * math.pi )
        CreateDecal(position, orientation, 'Crater01_albedo', '', 'Albedo', 20, 20, 1200, 0, army)
        CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 20, 20, 1200, 0, army)

		-- Knockdown force rings
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 15, 1, 'Force', true)
    end,

    CreateOuterRingWaveSmokeRing = function(self) -- New
        local sides = 10*6
        local angle = (2*math.pi) / sides
        local velocity = 4
        local OffsetMod = 1
        local projectiles = {}
        local Deceleration = -0.45

        for i = 0, (sides-1) do
            local X = math.sin(i*angle)
            local Z = math.cos(i*angle)
            local proj = self:CreateProjectile('/effects/entities/SACUShockwaveEdgeThin/SACUShockwaveEdgeThin_proj.bp', X * OffsetMod , 2, Z * OffsetMod, X, 0, Z)
                :SetVelocity(velocity):SetAcceleration(Deceleration)
        end
    end,

    DistortionField = function( self )
        local proj = self:CreateProjectile('/effects/QuantumWarhead/QuantumWarheadEffect01_proj.bp')
        local scale = proj:GetBlueprint().Display.UniformScale
        local army = self:GetArmy()

        proj:SetScaleVelocity(0.2 * scale,-0.3 * scale,0.2 * scale)
        WaitSeconds(4.0)
        proj:SetScaleVelocity(-0.1 * scale,-0.1 * scale,-0.1 * scale)
    end,

    Shockwave = function( self )
        local army = self:GetArmy()
        for i = 0, 2 do
			CreateEmitterAtEntity( self, army, '/effects/emitters/quantum_warhead_01_emit.bp'):ScaleEmitter(0.40)
        end
    end,

    InnerCloudFlares = function(self, army)
        local numFlares = 25
        local angle = (2*math.pi) / numFlares
        local angleInitial = 0.0 --RandomFloat( 0, angle )
        local angleVariation = (2*math.pi) --0.0 --angle * 0.5

        local emit, x, y, z = nil
        local DirectionMul = 0.02
        local OffsetMul = 2

        for i = 0, (numFlares - 1) do
            x = math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            y = 0.5 --RandomFloat(0.5, 1.5)
            z = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation)) 

            for k, v in self.CloudFlareEffects do
                emit = CreateEmitterAtEntity( self, army, v )
                emit:OffsetEmitter( x * OffsetMul, y * OffsetMul, z * OffsetMul )
                emit:SetEmitterCurveParam('XDIR_CURVE', x * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('YDIR_CURVE', y * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('ZDIR_CURVE', z * DirectionMul, 0.01)
            end
            
            if math.mod(i,11) == 0 then
                CreateLightParticle(self, -1, army, 13, 3, 'beam_white_01', 'ramp_quantum_warhead_flash_01')
            end
            WaitSeconds(RandomFloat( 0.10, 0.30 ))
        end
    end,
}

TypeClass = SCUDeath01