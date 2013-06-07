#****************************************************************************
#**
#**  File     :  /effects/entities/UnitTeleport01/UnitTeleport01_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Unit Teleport effect entity
#**
#**  Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

UnitTeleportEffect02 = Class(NullShell) {

    OnCreate = function(self)
        NullShell.OnCreate(self)
        self:ForkThread(self.TeleportEffectThread)
    end,

    TeleportEffectThread = function(self)
        local army = self:GetArmy()
        local pos = self:GetPosition()
        pos[2] = GetSurfaceHeight(pos[1], pos[3]) - 2

        for k, v in EffectTemplate.CSGTestEffect2 do
            CreateEmitterOnEntity( self, army, v )
        end

        # Initial light flashs
        CreateLightParticleIntel( self, -1, army, 18, 4, 'flare_lens_add_02', 'ramp_blue_13' )
        WaitSeconds(0.3)
        CreateLightParticleIntel( self, -1, army, 35, 10, 'flare_lens_add_02', 'ramp_blue_13' )

		#self:CreateEnergySpinner()
        self:CreateQuantumEnergy(army)

		# Wait till we want the commander to appear visibily
		WaitSeconds(1.8)

        # Smoke ring, explosion effects
        CreateLightParticleIntel( self, -1, army, 35, 10, 'glow_02', 'ramp_blue_13' )

        for k, v in EffectTemplate.CommanderTeleport01 do
            CreateEmitterOnEntity( self, army, v )
        end
        #self:ForkThread(self.CreateSmokeRing)

        local decalOrient = RandomFloat(0,2*math.pi)
        CreateDecal(self:GetPosition(), decalOrient, 'nuke_scorch_002_albedo', '', 'Albedo', 28, 28, 500, 600, army)
        CreateDecal(self:GetPosition(), decalOrient, 'Crater05_normals', '', 'Normals', 28, 28, 500, 600, army)
        CreateDecal(self:GetPosition(), decalOrient, 'Crater05_normals', '', 'Normals', 12, 12, 500, 600, army)

    end,

	CreateEnergySpinner = function(self)
		self:CreateProjectile( '/effects/entities/TeleportSpinner01/TeleportSpinner01_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
		self:CreateProjectile( '/effects/entities/TeleportSpinner02/TeleportSpinner02_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
		self:CreateProjectile( '/effects/entities/TeleportSpinner03/TeleportSpinner03_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
	end,

    CreateQuantumEnergy = function(self, army)
        for k, v in EffectTemplate.CommanderQuantumGateInEnergy do
            CreateEmitterOnEntity( self, army, v )
        end
    end,


    CreateFlares = function( self, army )
        local numFlares = 45
        local angle = (2*math.pi) / numFlares
        local angleInitial = 0.0 #RandomFloat( 0, angle )
        local angleVariation = (2*math.pi) #0.0 #angle * 0.5

        local emit, x, y, z = nil
        local DirectionMul = 0.02
        local OffsetMul = 1

        for i = 0, (numFlares - 1) do
            x = math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))
            y = 0.5 #RandomFloat(0.5, 1.5)
            z = math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))

            for k, v in EffectTemplate.CloudFlareEffects01 do
                emit = CreateEmitterAtEntity( self, army, v )
                emit:OffsetEmitter( x * OffsetMul, y * OffsetMul, z * OffsetMul )
                emit:SetEmitterCurveParam('XDIR_CURVE', x * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('YDIR_CURVE', y * DirectionMul, 0.01)
                emit:SetEmitterCurveParam('ZDIR_CURVE', z * DirectionMul, 0.01)
                emit:ScaleEmitter( 0.25 )
            end

            WaitSeconds(RandomFloat( 0.1, 0.15 ))
        end
    end,

    CreateSmokeRing = function(self)
        local blanketSides = 36
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 8
        local projectileList = {}

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)
            local proj = self:CreateProjectile('/effects/Nuke/Shockwave01_proj.bp', blanketX * 6, 0.35, blanketZ * 6, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-3)
            table.insert( projectileList, proj )
        end

        WaitSeconds( 2.5 )
        for k, v in projectileList do
            v:SetAcceleration(0)
        end
    end,
}

TypeClass = UnitTeleportEffect02

