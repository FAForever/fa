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

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local LandFactoryUnit = import('/lua/defaultunits.lua').LandFactoryUnit

---@class CConstructionEggUnit : CStructureUnit
CConstructionEggUnit = ClassUnit(CStructureUnit) {

    ---@param self CConstructionEggUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        LandFactoryUnit.OnStopBeingBuilt(self, builder, layer)

        -- prevent the unit from being reclaimed
        self:SetReclaimable(false)

        local bp = self:GetBlueprint()
        local buildUnit = bp.Economy.BuildUnit
        local pos = self:GetPosition()
        local aiBrain = self:GetAIBrain()


        self.Spawn = CreateUnitHPR(
            buildUnit,
            aiBrain.Name,
            pos[1], pos[2], pos[3],
            0, 0, 0
        )

        self:ForkThread(function()
            self.OpenAnimManip = CreateAnimator(self)
            self.Trash:Add(self.OpenAnimManip)
            self.OpenAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationOpen, false):SetRate(0.1)
            self:PlaySound(bp.Audio['EggOpen'])

            WaitFor(self.OpenAnimManip)

            self.EggSlider = CreateSlider(self, 0, 0, -20, 0, 5)
            self.Trash:Add(self.EggSlider)
            self:PlaySound(bp.Audio['EggSink'])

            WaitFor(self.EggSlider)

            self:Destroy()
        end
        )
    end,

    ---@param self CConstructionEggUnit
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Spawn then overkillRatio = 1.1 end
        CStructureUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}
