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

---@class DebugProjectileComponent: DebugComponent
DebugProjectileComponent = Class(DebugComponent) {

    ---@param self DebugProjectileComponent | Projectile
    ---@param ... any
    DebugSpew = function(self, ...)
        if not self.EnabledSpewing then
            return
        end

        local launcher = self.Launcher
        if launcher and IsUnit(launcher) and (not IsDestroyed(launcher)) then
            -- allows the developer to track down the launcher
            launcher:SetCustomName(launcher.EntityId or 'unknown')
            self:DebugDraw('gray')
        end

        SPEW(launcher.UnitId, launcher.EntityId, self.Blueprint.BlueprintId, unpack(arg))
    end,

    ---@param self DebugProjectileComponent | Projectile
    ---@param ... any
    DebugLog = function(self, ...)
        if not self.EnabledLogging then
            return
        end

        local launcher = self.Launcher
        if launcher and IsUnit(launcher) and (not IsDestroyed(launcher)) then
            -- allows the developer to track down the launcher
            launcher:SetCustomName(launcher.EntityId or 'unknown')
            self:DebugDraw('white')
        end

        _ALERT(launcher.UnitId, launcher.EntityId, self.Blueprint.BlueprintId, unpack(arg))
    end,

    ---@param self DebugProjectileComponent | Projectile
    ---@param ... any
    DebugWarn = function(self, ...)
        if not self.EnabledWarnings then
            return
        end

        local launcher = self.Launcher
        if launcher and IsUnit(launcher) and (not IsDestroyed(launcher)) then
            -- allows the developer to track down the launcher
            launcher:SetCustomName(launcher.EntityId or 'unknown')
            self:DebugDraw('orange')
        end

        WARN(launcher.UnitId, launcher.EntityId, self.Blueprint.BlueprintId, unpack(arg))
    end,

    ---@param self DebugProjectileComponent | Projectile
    ---@param message any
    DebugError = function(self, message)
        if not self.EnabledErrors then
            return
        end

        local launcher = self.Launcher
        if launcher and IsUnit(launcher) and (not IsDestroyed(launcher)) then
            -- allows the developer to track down the launcher
            launcher:SetCustomName(launcher.EntityId or 'unknown')
            self:DebugDraw('red')
        end

        error(
            string.format(
                "%s\t%s\t%s\t%s",
                tostring(launcher.UnitId),
                tostring(launcher.EntityId),
                tostring(self.Blueprint.BlueprintId),
                tostring(message)
            )
        )
    end,

    ---@param self DebugProjectileComponent | Projectile
    ---@param color? Color  # Defaults to white
    DebugDraw = function(self, color)
        if not self.EnabledDrawing then
            return
        end

        -- we can't draw dead things
        if IsDestroyed(self) then
            return
        end

        -- do not draw everything, just what the developer may be interested in
        if not (GetFocusArmy() == -1 or GetFocusArmy() == self.Army) then
            return
        end

        color = color or 'ffffff'

        local launcher = self.Launcher
        if launcher and not IsDestroyed(launcher) then
            launcher:DebugDraw(color)
            DrawLine(launcher:GetPosition(), self:GetPosition(), color)
        end

        DrawCircle(self:GetPosition(), 0.25, color)
    end,
}
