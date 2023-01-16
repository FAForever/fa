--****************************************************************************
--**
--**  File     :  /cdimage/units/OPC2002/OPC2002_script.lua
--**  Author(s):  Greg R.
--**
--**  Summary  :  Tech for OpC2
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local HoverLandUnit = import("/lua/defaultunits.lua").HoverLandUnit

---@class OPC2002 : HoverLandUnit
OPC2002 = ClassUnit(HoverLandUnit) {
    
    OnStopBeingBuilt = function(self, builder, layer)
        HoverLandUnit.OnStopBeingBuilt(self, builder, layer)
        --B04 = parent, B03 = ball, B01/2 = rings
        --CreateRotator(unit, bone, axis, [goal], [speed], [accel], [goalspeed])
        self.Trash:Add(CreateRotator(self, 'Shell01', 'x', nil, 0, 60, 40 + Random(0, 20) * self:GetRandomDir()))
        --self.Trash:Add(CreateRotator(self, 'Shell01', 'y', nil, 0, 5, 20 + Random(0, 20) * self:GetRandomDir()))
        self.Trash:Add(CreateRotator(self, 'Shell01', 'z', nil, 0, 60, 80 + Random(0, 20) * self:GetRandomDir()))

        self.Trash:Add(CreateRotator(self, 'Shell02', 'x', nil, 0, 60, 120 + Random(0, 20) * self:GetRandomDir()))
        self.Trash:Add(CreateRotator(self, 'Shell02', 'y', nil, 0, 60, 40 + Random(0, 20) * self:GetRandomDir()))
        --self.Trash:Add(CreateRotator(self, 'Shell02', 'z', nil, 0, 25, 80 + Random(0, 20) * self:GetRandomDir()))

        --self.Trash:Add(CreateRotator(self, 'Orbs', 'x', nil, 0, 15, 80 + Random(0, 20) * self:GetRandomDir()))
        self.Trash:Add(CreateRotator(self, 'Orbs', 'y', nil, 0, 15, 80 + Random(0, 5) * self:GetRandomDir()))
        --self.Trash:Add(CreateRotator(self, 'Orbs', 'z', nil, 0, 15, 0 + Random(0, 20) * self:GetRandomDir()))
    end,


    GetRandomDir = function(self)
        local num = Random(0, 2)
        if num > 1 then
            return 1
        end
        return -1
    end,
   
}

TypeClass = OPC2002