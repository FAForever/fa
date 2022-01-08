#****************************************************************************
#**
#**  File     :  /data/projectiles/SAALosaareAutoCannon02/SAALosaareAutoCannon02_script.lua
#**  Author(s):  Greg Kohne, Gordon Duclos
#**
#**  Summary  :  Losaare AA AutoCannon Projectile script, XSA0401
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SLosaareAAAutoCannon = import('/lua/seraphimprojectiles.lua').SLosaareAAAutoCannon

SAALosaareAutoCannon02 = Class(SLosaareAAAutoCannon) {

  OnImpact = function(self, TargetType, TargetEntity)
      SLosaareAAAutoCannon.OnImpact(self, TargetType, TargetEntity)
      if TargetType == 'UnitAir' then
        if TargetEntity then
          local fueluse = TargetEntity:GetFuelUseTime()
          local fuelratio = TargetEntity:GetFuelRatio()
          local currentfuel = fueluse * fuelratio
          if currentfuel > 0 then
              #local newfuelvalue = ((fuelratio * fueluse) - self.Data.FuelDrainSec) # FuelDrainSec is a value in Seconds
              #TargetEntity:SetFuelRatio(newfuelvalue / fueluse)
          end
        end
      end
  end,

}
TypeClass = SAALosaareAutoCannon02
