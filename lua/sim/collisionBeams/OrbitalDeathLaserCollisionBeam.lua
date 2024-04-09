local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local Util = import("/lua/utilities.lua")

local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam

------------------------------------
--   ORBITAL DEATH LASER COLLISION BEAM
------------------------------------
---@class OrbitalDeathLaserCollisionBeam : SCCollisionBeam
OrbitalDeathLaserCollisionBeam = Class(SCCollisionBeam) { 
    -- used by satellite
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

    ---@param self OrbitalDeathLaserCollisionBeam
    ---@param impactType string
    ---@param targetEntity? Prop|Unit
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

    ---@param self OrbitalDeathLaserCollisionBeam
    OnDisable = function( self )
        CollisionBeam.OnDisable(self)
        KillThread(self.Scorching)
        self.Scorching = nil   
    end,

    ---@param self OrbitalDeathLaserCollisionBeam
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