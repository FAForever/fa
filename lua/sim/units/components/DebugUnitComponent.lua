--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

local DebugComponent = import("/lua/shared/components/debugcomponent.lua").DebugComponent

---@class DebugUnitComponent : DebugComponent
DebugUnitComponent = Class(DebugComponent) {

    ---@param self DebugUnitComponent | Unit
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledSpewing then
            return
        end

        SPEW(self.UnitId, self.EntityId, unpack(arg))

        if IsDestroyed(self) then
            return
        end

        -- allows us the developer track down the unit
        self:SetCustomName(tostring(self.EntityId))
        self:DebugDraw('gray')
    end,

    ---@param self DebugUnitComponent | Unit
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        _ALERT(self.UnitId, self.EntityId, unpack(arg))

        if IsDestroyed(self) then
            return
        end

        -- allows the developer to track down the unit
        self:SetCustomName(tostring(self.EntityId))
        self:DebugDraw('white')
    end,

    ---@param self DebugUnitComponent | Unit
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledWarnings then
            return
        end

        WARN(self.UnitId, self.EntityId, unpack(arg))

        if IsDestroyed(self) then
            return
        end

        -- allows the developer to track down the unit
        self:SetCustomName(tostring(self.EntityId))
        self:DebugDraw('orange')
    end,

    ---@param self DebugUnitComponent | Unit
    ---@param message any
    DebugError = function(self, message)
        if not self.EnabledErrors then
            return
        end

        if not IsDestroyed(self) then
            -- allows the developer to track down the unit
            self:SetCustomName(tostring(self.EntityId))
            self:DebugDraw('red')
        end

        error(string.format("%s\t%s\t%s", tostring(self.UnitId), tostring(self.EntityId), tostring(message)))
    end,

    ---@param self DebugUnitComponent | Unit
    ---@param color? Color  # Defaults to white
    DebugDraw = function(self, color)
        if not self.EnabledDrawing then
            return
        end

        -- we can't draw dead units
        if IsDestroyed(self) then
            return
        end

        -- do not draw everything, just what the developer may be interested in
        if not (GetFocusArmy() == -1 or GetFocusArmy() == self.Army) then
            return
        end


        color = color or 'ffffff'

        local blueprint = self.Blueprint
        DrawCircle(self:GetPosition(), math.max(blueprint.SizeX, blueprint.SizeY, blueprint.SizeZ), color)
    end,
}
