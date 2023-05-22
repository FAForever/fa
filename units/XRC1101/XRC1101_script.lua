-- File     :  /cdimage/units/XRC1101/XRC1101_script.lua
-- Authors: Greg Kohne
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CCivilianStructureUnit = import("/lua/cybranunits.lua").CCivilianStructureUnit
local SSQuantumJammerTowerAmbient = import("/lua/effecttemplates.lua").SJammerTowerAmbient

---@class XRC1101 : CCivilianStructureUnit
XRC1101 = ClassUnit(CCivilianStructureUnit)
{
    OnCreate = function(self, builder, layer)
        CCivilianStructureUnit.OnCreate(self)

        for k, v in SSQuantumJammerTowerAmbient do
            CreateAttachedEmitter(self, 'Jammer', self.Army, v)
        end

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self.Blueprint.Display.AnimationIdle, true)
    end,
}
TypeClass = XRC1101
