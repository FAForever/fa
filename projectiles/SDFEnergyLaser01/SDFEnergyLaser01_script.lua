#
# Seraphim Energy Being Laser
#
local SEnergyLaser = import('/lua/seraphimprojectiles.lua').SEnergyLaser
SDFEnergyLaser01 = Class(SEnergyLaser) {

    OnCreate = function(self)
    	  SEnergyLaser.OnCreate(self)
        self:ForkThread( self.MovementThread )
    end,
	
	  MovementThread = function(self)
	  	  WaitSeconds(.2)
	  	  self:SetAcceleration(9999)
	  end,
}

TypeClass = SDFEnergyLaser01

