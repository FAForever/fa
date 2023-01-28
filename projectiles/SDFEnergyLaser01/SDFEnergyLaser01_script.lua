-- Seraphim Energy Being Laser

local SEnergyLaser = import("/lua/seraphimprojectiles.lua").SEnergyLaser
SDFEnergyLaser01 = ClassProjectile(SEnergyLaser) {
    OnCreate = function(self)
		SEnergyLaser.OnCreate(self)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
	  MovementThread = function(self)
	  	  WaitTicks(3)
	  	  self:SetAcceleration(9999)
	  end,
}
TypeClass = SDFEnergyLaser01