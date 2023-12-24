local SEnergyLaser = import("/lua/seraphimprojectiles.lua").SEnergyLaser

-- upvalue for perfomance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local TrashBagAdd = TrashBag.Add

--- Seraphim Energy Being Laser
---@class SDFEnergyLaser01 : SEnergyLaser
SDFEnergyLaser01 = ClassProjectile(SEnergyLaser) {

	---@param self SDFEnergyLaser01
	OnCreate = function(self)
		SEnergyLaser.OnCreate(self)
		local trash = self.Trash
        TrashBagAdd(trash,ForkThread( self.MovementThread,self ))
    end,

	---@param self SDFEnergyLaser01
	MovementThread = function(self)
	  	WaitTicks(3)
		self:SetAcceleration(9999)
	 end,
}
TypeClass = SDFEnergyLaser01