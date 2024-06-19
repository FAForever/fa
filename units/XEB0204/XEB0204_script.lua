-- File     :  /units/XEB0204/XEB0204_script.lua
-- Author(s):  Dru Staltman
-- Summary  :  UEF Engineering tower
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
local TPodTowerUnit = import("/lua/terranunits.lua").TPodTowerUnit

---@class XEB0204 : TPodTowerUnit
XEB0204 = ClassUnit(TPodTowerUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        TPodTowerUnit.OnStopBeingBuilt(self, builder, layer)
        local openAnim = self.OpenAnim

        if not openAnim then
            openAnim = CreateAnimator(self)
            self.OpenAnim = openAnim
            self.Trash:Add(openAnim)
        end

        openAnim:PlayAnim(self.Blueprint.Display.AnimationOpen, false):SetRate(0.4)
    end,
}

TypeClass = XEB0204
