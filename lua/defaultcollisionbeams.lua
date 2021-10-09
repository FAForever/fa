------------------------------------------------------------
--
--  File     :  /lua/defaultcollisionbeams.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  Default definitions collision beams
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local CollisionBeam = import('/lua/sim/CollisionBeam.lua').CollisionBeam
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('utilities.lua')

-------------------------------
--   Base class that defines supreme commander specific defaults
-------------------------------
SCCollisionBeam = Class(CollisionBeam) {
    FxImpactUnit = EffectTemplate.DefaultProjectileLandUnitImpact,
    FxImpactLand = {},-- EffectTemplate.DefaultProjectileLandImpact,
    FxImpactWater = EffectTemplate.DefaultProjectileWaterImpact,
    FxImpactUnderWater = EffectTemplate.DefaultProjectileUnderWaterImpact,
    FxImpactAirUnit = EffectTemplate.DefaultProjectileAirUnitImpact,
    FxImpactProp = {},
    FxImpactShield = {},    
    FxImpactNone = {},
}

-------------------------------
--   Ginsu COLLISION BEAM
-------------------------------
GinsuCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {'/effects/emitters/riot_gun_beam_01_emit.bp',
              '/effects/emitters/riot_gun_beam_02_emit.bp',},
    FxBeamEndPoint = {'/effects/emitters/sparks_02_emit.bp',},


    FxImpactUnit = {'/effects/emitters/riotgun_hit_flash_01_emit.bp',},
    FxUnitHitScale = 0.125,
    FxImpactLand = {'/effects/emitters/destruction_land_hit_puff_01_emit.bp',
                    '/effects/emitters/destruction_explosion_flash_01_emit.bp'},
    FxLandHitScale = 0.1625,
    FxImpactUnderWater = {},
}

------------------------------------
--   PARTICLE CANNON COLLISION BEAM
------------------------------------
ParticleCannonCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {
		'/effects/emitters/particle_cannon_beam_01_emit.bp',
        '/effects/emitters/particle_cannon_beam_02_emit.bp'
	},
    FxBeamEndPoint = {
		'/effects/emitters/particle_cannon_end_01_emit.bp',
		'/effects/emitters/particle_cannon_end_02_emit.bp',
	},
    FxBeamEndPointScale = 1,
}

------------------------------------
--   ZAPPER COLLISION BEAM
------------------------------------
ZapperCollisionBeam = Class(SCCollisionBeam) {
    FxBeam = {'/effects/emitters/zapper_beam_01_emit.bp'},
    FxBeamEndPoint = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',
                       '/effects/emitters/sparks_07_emit.bp',},
}

------------------------------------
--   QUANTUM BEAM GENERATOR COLLISION BEAM
------------------------------------
QuantumBeamGeneratorCollisionBeam = Class(SCCollisionBeam) { -- used by CZAR
    TerrainImpactType = 'LargeBeam02',
    TerrainImpactScale = 1,
        
    FxBeam = {'/effects/emitters/quantum_generator_beam_01_emit.bp'},
    FxBeamEndPoint = {
		'/effects/emitters/quantum_generator_end_01_emit.bp',
        '/effects/emitters/quantum_generator_end_03_emit.bp',
        '/effects/emitters/quantum_generator_end_04_emit.bp',
        '/effects/emitters/quantum_generator_end_05_emit.bp',
        '/effects/emitters/quantum_generator_end_06_emit.bp',
	},
    FxBeamStartPoint = {
		'/effects/emitters/quantum_generator_01_emit.bp',
        '/effects/emitters/quantum_generator_02_emit.bp',
        '/effects/emitters/quantum_generator_04_emit.bp',
    },
    
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.5,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 3.5 + (Random() * 3.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 200, 150, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 3.2 + (Random() * 3.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,    
}

DisruptorBeamCollisionBeam = Class(SCCollisionBeam) {
    
    FxBeam = {'/effects/emitters/disruptor_beam_01_emit.bp'},
    FxBeamEndPoint = { 
        '/effects/emitters/aeon_commander_disruptor_hit_01_emit.bp', 
        '/effects/emitters/aeon_commander_disruptor_hit_02_emit.bp', 
    },
    FxBeamEndPointScale = 1.0,
    
    FxBeamStartPoint = { 
        '/effects/emitters/aeon_commander_disruptor_flash_01_emit.bp', 
        '/effects/emitters/aeon_commander_disruptor_flash_02_emit.bp', 
    },

    
}

MicrowaveLaserCollisionBeam01 = Class(SCCollisionBeam) { -- used by ML & cyb ACU

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.CMicrowaveLaserMuzzle01,
    FxBeam = {'/effects/emitters/microwave_laser_beam_01_emit.bp'},
    FxBeamEndPoint = EffectTemplate.CMicrowaveLaserEndPoint01,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.5 + (Random() * 1.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 200, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 1.2 + (Random() * 1.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}

MicrowaveLaserCollisionBeam02 = Class(MicrowaveLaserCollisionBeam01) {
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.CMicrowaveLaserMuzzle01,
    FxBeam = {'/effects/emitters/microwave_laser_beam_02_emit.bp'},
    FxBeamEndPoint = EffectTemplate.CMicrowaveLaserEndPoint01,
}


PhasonLaserCollisionBeam = Class(SCCollisionBeam) { -- used by GC

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.APhasonLaserMuzzle01,
    FxBeam = {'/effects/emitters/phason_laser_beam_01_emit.bp'},
    FxBeamEndPoint = EffectTemplate.APhasonLaserImpact01,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,
    
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.5 + (Random() * 1.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 200, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 1.2 + (Random() * 1.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}



TractorClawCollisionBeam = Class(CollisionBeam) {
    
    FxBeam = {EffectTemplate.ACollossusTractorBeam01},
    FxBeamEndPoint = {EffectTemplate.ACollossusTractorBeamGlow02},
    FxBeamEndPointScale = 1.0,
    FxBeamStartPoint = { EffectTemplate.ACollossusTractorBeamGlow01 },
}

------------------------------------
--   QUANTUM BEAM GENERATOR COLLISION BEAM
------------------------------------
ExperimentalPhasonLaserCollisionBeam = Class(SCCollisionBeam) { -- unknown unit (big size though)

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.SExperimentalPhasonLaserMuzzle01,
    FxBeam = EffectTemplate.SExperimentalPhasonLaserBeam,
    FxBeamEndPoint = EffectTemplate.SExperimentalPhasonLaserHitLand,
    SplatTexture = 'scorch_004_albedo',
    ScorchSplatDropTime = 0.1,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,
    
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 4.0 + (Random() * 1.0) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 4.0 + (Random() * 1.0)
            CurrentPosition = self:GetPosition(1)
        end
    end,
    
    CreateBeamEffects = function(self)
        SCCollisionBeam.CreateBeamEffects(self)
        for k, v in EffectTemplate.SExperimentalPhasonLaserBeam do
			local fxBeam = CreateBeamEntityToEntity(self, 0, self, 1, self:GetArmy(), v )
			table.insert( self.BeamEffectsBag, fxBeam )
			self.Trash:Add(fxBeam)
        end
        -- local fxBeam = CreateBeamEntityToEntity(self, 0, self, 1, self:GetArmy(), '/effects/emitters/seraphim_expirimental_laser_beam_02_emit.bp' )

    end, 
}



UnstablePhasonLaserCollisionBeam = Class(SCCollisionBeam) { -- ythota death energy ball

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.SExperimentalUnstablePhasonLaserMuzzle01,
    FxBeam = EffectTemplate.OthuyElectricityStrikeBeam,
    FxBeamEndPoint = EffectTemplate.OthuyElectricityStrikeHit,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,

    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.5 + (Random() * 1.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 250, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 1.2 + (Random() * 1.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}



-- This is for sera destro and sera T2 point defense.
UltraChromaticBeamGeneratorCollisionBeam = Class(SCCollisionBeam) {

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.SUltraChromaticBeamGeneratorMuzzle01,
    FxBeam = EffectTemplate.SUltraChromaticBeamGeneratorBeam,
    FxBeamEndPoint = EffectTemplate.SUltraChromaticBeamGeneratorHitLand,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,
    
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1 + (Random() * 1) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 70, 50, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 1 + (Random() * 1)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}

-- This is for sera destro and sera T2 point defense. (adjustment for ship muzzleflash)
UltraChromaticBeamGeneratorCollisionBeam02 = Class(UltraChromaticBeamGeneratorCollisionBeam) {
	FxBeamStartPoint = EffectTemplate.SUltraChromaticBeamGeneratorMuzzle02,
}

------------------------------------
--   HIRO LASER COLLISION BEAM
------------------------------------
TDFHiroCollisionBeam = Class(CollisionBeam) { -- used by UEF battlecruser

    TerrainImpactType = 'LargeBeam01',
    TerrainImpactScale = 1,
    FxBeamStartPoint = EffectTemplate.TDFHiroGeneratorMuzzle01,
    FxBeam = EffectTemplate.TDFHiroGeneratorBeam,
    FxBeamEndPoint = EffectTemplate.TDFHiroGeneratorHitLand,
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.25,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,
    
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 1.5 + (Random() * 1.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 100, 70, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 1.2 + (Random() * 1.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,
}


------------------------------------
--   ORBITAL DEATH LASER COLLISION BEAM
------------------------------------
OrbitalDeathLaserCollisionBeam = Class(SCCollisionBeam) { -- used by satellite
    TerrainImpactType = 'LargeBeam02',
    TerrainImpactScale = 1,
        
    FxBeam = {'/effects/emitters/uef_orbital_death_laser_beam_01_emit.bp'},
    FxBeamEndPoint = {
		'/effects/emitters/uef_orbital_death_laser_end_01_emit.bp',			-- big glow
		'/effects/emitters/uef_orbital_death_laser_end_02_emit.bp',			-- random bright blueish dots
		'/effects/emitters/uef_orbital_death_laser_end_03_emit.bp',			-- darkening lines
		'/effects/emitters/uef_orbital_death_laser_end_04_emit.bp',			-- molecular, small details
		'/effects/emitters/uef_orbital_death_laser_end_05_emit.bp',			-- rings
		'/effects/emitters/uef_orbital_death_laser_end_06_emit.bp',			-- upward sparks
		'/effects/emitters/uef_orbital_death_laser_end_07_emit.bp',			-- outward line streaks
		'/effects/emitters/uef_orbital_death_laser_end_08_emit.bp',			-- center glow
		'/effects/emitters/uef_orbital_death_laser_end_distort_emit.bp',	-- screen distortion
	},
    FxBeamStartPoint = {
		'/effects/emitters/uef_orbital_death_laser_muzzle_01_emit.bp',	-- random bright blueish dots
		'/effects/emitters/uef_orbital_death_laser_muzzle_02_emit.bp',	-- molecular, small details
		'/effects/emitters/uef_orbital_death_laser_muzzle_03_emit.bp',	-- darkening lines
		'/effects/emitters/uef_orbital_death_laser_muzzle_04_emit.bp',	-- small downward sparks
		'/effects/emitters/uef_orbital_death_laser_muzzle_05_emit.bp',	-- big glow
    },
    
    SplatTexture = 'czar_mark01_albedo',
    ScorchSplatDropTime = 0.5,

    OnImpact = function(self, impactType, targetEntity)
        if impactType ~= 'Shield' and impactType ~= 'Water' and impactType ~= 'Air' and impactType ~= 'UnitAir' and impactType ~= 'Projectile' then
            if self.Scorching == nil then
                self.Scorching = self:ForkThread( self.ScorchThread )   
            end
        else
            KillThread(self.Scorching)
            self.Scorching = nil
        end
        CollisionBeam.OnImpact(self, impactType, targetEntity)
    end,
    
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ScorchThread = function(self)
        local army = self:GetArmy()
        local size = 3.5 + (Random() * 3.5) 
        local CurrentPosition = self:GetPosition(1)
        local LastPosition = Vector(0,0,0)
        local skipCount = 1
        -- local FriendlyFire = self.DamageData.DamageFriendly
        
        while true do
            if Util.GetDistanceBetweenTwoVectors( CurrentPosition, LastPosition ) > 0.25 or skipCount > 100 then
                CreateSplat( CurrentPosition, Util.GetRandomFloat(0,2*math.pi), self.SplatTexture, size, size, 250, 100, army )
                LastPosition = CurrentPosition
                skipCount = 1

                -- commented due to hard-crash potential
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)
                -- DamageArea(self, CurrentPosition, size, 1, 'Force', FriendlyFire)

            else
                skipCount = skipCount + self.ScorchSplatDropTime
            end
                
            WaitSeconds( self.ScorchSplatDropTime )
            size = 3.2 + (Random() * 3.5)
            CurrentPosition = self:GetPosition(1)
        end
    end,    
}