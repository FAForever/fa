--****************************************************************************
--**
--**  File     :  /data/projectiles/SAABlazarAutoCannon02/SAABlazarAutoCannon02_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Blazar AA AutoCannon Projectile script, XSA0401
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SBlazarAAAutoCannon = import("/lua/seraphimprojectiles.lua").SBlazarAAAutoCannon

SAABlazarAutoCannon02 = Class(SBlazarAAAutoCannon) {

  OnImpact = function(self, TargetType, TargetEntity)
      SBlazarAAAutoCannon.OnImpact(self, TargetType, TargetEntity)
      if TargetType == 'UnitAir' then
        if TargetEntity then
          local fueluse = TargetEntity:GetFuelUseTime()
          local fuelratio = TargetEntity:GetFuelRatio()
          local currentfuel = fueluse * fuelratio
          if currentfuel > 0 then
              --local newfuelvalue = ((fuelratio * fueluse) - self.Data.FuelDrainSec) -- FuelDrainSec is a value in Seconds
              --TargetEntity:SetFuelRatio(newfuelvalue / fueluse)
          end
        end
      end
  end,

}
TypeClass = SAABlazarAutoCannon02
