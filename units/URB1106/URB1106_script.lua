-- File     :  /cdimage/units/URB1106/URB1106_script.lua
-- Author(s):  Jessica St. Croix, David Tomandl
-- Summary  :  Cybran Mass Storage
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CMassStorageUnit = import("/lua/cybranunits.lua").CMassStorageUnit

---@class URB1106 : CMassStorageUnit
URB1106 = ClassUnit(CMassStorageUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        CMassStorageUnit.OnStopBeingBuilt(self,builder,layer)
        local audio = self.Blueprint.Audio.DoneBeingBuilt
        if audio then
            self:PlaySound(audio)
        end

        self.Trash:Add(CreateStorageManip(self, 'B01', 'MASS', 0, 0, 0, 0, 0, .61))
    end,
}

TypeClass = URB1106