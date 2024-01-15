--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local SeaFactoryUnit = import('/lua/defaultunits.lua').SeaFactoryUnit
local CreateAeonFactoryBuildingEffects = import('/lua/effectutilities.lua').CreateAeonFactoryBuildingEffects

-- upvalue scope for performance
local ForkThread = ForkThread

---@class ASeaFactoryUnit : SeaFactoryUnit
---@field BuildEffectsBag TrashBag
ASeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self ASeaFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local buildEffectBones = self.BuildEffectBones
        local buildEffectsBag = self.BuildEffectsBag
        local thread = ForkThread(
            CreateAeonFactoryBuildingEffects,
            self,
            unitBeingBuilt,
            buildEffectBones,
            'Attachpoint01',
            buildEffectsBag
        )

        self.Trash:Add(thread)
        unitBeingBuilt.Trash:Add(thread)
    end,
}
