--******************************************************************************************************
--** Copyright (c) 2024  Willem 'Jip' Wijnia
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
--******************************************************************************************************

---@alias BlinkingLightsUnitComponentState 'Green' | 'Yellow' | 'Red'

---@class BlinkingLightsUnitComponent
---@field FxBlinkingLightsBag TrashBag
---@field BlinkingLightsState BlinkingLightsUnitComponentState
BlinkingLightsUnitComponent = ClassSimple {

    ---@param self BlinkingLightsUnitComponent | StructureUnit
    OnCreate = function(self)
        self.BlinkingLightsState = 'Yellow'
        self.FxBlinkingLightsBag = self.Trash:Add(TrashBag())
    end,

    ---@param self BlinkingLightsUnitComponent | StructureUnit
    ChangeBlinkingLights = function(self, state)
        local oldState = self.BlinkingLightsState
        self.BlinkingLightsState = state

        if state == 'Yellow' then
            if oldState == 'Green' then
                self:CreateBlinkingLights('Yellow')
            end
        elseif state == 'Green' then
            if oldState == 'Yellow' then
                self:CreateBlinkingLights('Green')
            elseif oldState == 'Red' then
                local brain = self.Brain

                -- remain red if storage is empty
                if brain.MassStorageState == 'EconLowMassStore' or brain.EnergyStorageState == 'EconLowEnergyStore' then
                    return
                end

                if self:GetNumBuildOrders(categories.ALLUNITS) == 0 then
                    self:CreateBlinkingLights('Green')
                else
                    self:CreateBlinkingLights('Yellow')
                    self.BlinkingLightsState = 'Yellow'
                end
            end
        elseif state == 'Red' then
            self:CreateBlinkingLights('Red')
        end
    end,

    ---@param self BlinkingLightsUnitComponent | StructureUnit
    ---@param color? BlinkingLightsUnitComponentState
    CreateBlinkingLights = function(self, color)
        color = color or self.BlinkingLightsState

        self:DestroyBlinkingLights()
        local blueprintDisplay = self.Blueprint.Display
        local blueprintDisplayBlinkingLights = blueprintDisplay.BlinkingLights
        local blueprintDisplayBlinkingLightsFx = blueprintDisplay.BlinkingLightsFx

        if blueprintDisplayBlinkingLights and blueprintDisplayBlinkingLightsFx then

            local army = self.Army
            local fxBlinkingLightsBag = self.FxBlinkingLightsBag
            local fxbp = blueprintDisplayBlinkingLightsFx[color]
            if not fxbp then
                -- WARN("")
                return
            end

            for _, config in blueprintDisplayBlinkingLights do
                local fx = CreateEmitterAtBone(self, config.BLBone, army, fxbp)
                fx:OffsetEmitter(config.BLOffsetX, config.BLOffsetY, config.BLOffsetZ)
                fx:ScaleEmitter(config.BLScale)

                fxBlinkingLightsBag:Add(fx)
            end
        end
    end,

    ---@param self BlinkingLightsUnitComponent | StructureUnit
    DestroyBlinkingLights = function(self)
        self.FxBlinkingLightsBag:Destroy()
    end,

    --- Implemented at the unit (type) level
    ---@param self BlinkingLightsUnitComponent | StructureUnit
    ---@param state AIBrainMassStorageState
    OnMassStorageStateChange = function(self, state)
    end,

    --- Implemented at the unit (type) level
    ---@param self BlinkingLightsUnitComponent | StructureUnit
    ---@param state AIBrainEnergyStorageState
    OnEnergyStorageStateChange = function(self, state)
    end,
}
