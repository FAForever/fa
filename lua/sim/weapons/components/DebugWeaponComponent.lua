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

---@class DebugWeaponComponent
DebugWeaponComponent = ClassSimple {

    EnabledLogging = true,

    ---@param self DebugWeaponComponent | Weapon
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        local unit = self.unit

        -- allows us to track down the unit
        unit:SetCustomName(string.format("%s - %s", tostring(unit.EntityId), tostring(self.Label)))

        SPEW(unit.UnitId, unit.EntityId, self.Label, unpack(arg))
    end,

    ---@param self DebugWeaponComponent | Weapon
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        local unit = self.unit

        -- allows us to track down the unit
        unit:SetCustomName(string.format("%s - %s", tostring(unit.EntityId), tostring(self.Label)))

        _ALERT(unit.UnitId, unit.EntityId, self.Label, unpack(arg))
    end,

    ---@param self DebugWeaponComponent | Weapon
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        local unit = self.unit

        -- allows us to track down the unit
        unit:SetCustomName(string.format("%s - %s", tostring(unit.EntityId), tostring(self.Label)))

        WARN(unit.UnitId, unit.EntityId, self.Label, unpack(arg))
    end,

    ---@param self DebugWeaponComponent | Weapon
    ---@param message any
    DebugError = function(self, message)
        if not self.EnabledLogging then
            return
        end

        local unit = self.unit

        -- allows us to track down the unit
        unit:SetCustomName(string.format("%s - %s", tostring(unit.EntityId), tostring(self.Label)))

        error(
            string.format(
                "%s\t%s\t%s\t%s",
                tostring(unit.UnitId),
                tostring(unit.EntityId),
                tostring(self.Label),
                tostring(message)
            )
        )
    end,
}
