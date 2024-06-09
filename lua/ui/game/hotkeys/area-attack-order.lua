--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local UIRenderableCircle = import('/lua/ui/game/renderable/circle.lua').UIRenderableCircle
local ComputeAttackLocations = import("/lua/shared/commands/area-attack-order.lua").ComputeAttackLocations
local UserDecal = import("/lua/user/userdecal.lua").UserDecal

local RadialDragger = import("/lua/ui/controls/draggers/radial.lua").RadialDragger
local MaximumWidth = import("/lua/shared/commands/area-reclaim-order.lua").MaximumWidth
local MaximumDistance = import("/lua/shared/commands/area-reclaim-order.lua").MaximumDistance

---@type number
local MinimumDistance = 4

---@param value number
SetMinimumDistance = function(value)
    if type(value) ~= 'number' then
        error('Expected a number, got ' .. type(value))
    end

    MinimumDistance = value
end

---@type Keycode
local DragKeycode = 'LBUTTON'

---@param value Keycode
SetDragKeyCode = function(value)
    if type(value) ~= 'string' then
        error('Expected a string, got ' .. type(value))
    end

    DragKeycode = value
end

---@param origin Vector
---@param radius number
local AreaReclaimOrderCallback = function(origin, radius)
    if radius < MinimumDistance then
        return
    end

    SimCallback({ Func = 'ExtendAttackOrder', Args = { Origin = origin, Radius = radius } }, true)
end

---@param command UserCommand
AreaAttackOrder = function(command)

    local worldView = import("/lua/ui/game/worldview.lua").viewLeft

    ---@type UIRadialDragger
    local dragger = RadialDragger(
        worldView,
        AreaReclaimOrderCallback,
        DragKeycode,
        MinimumDistance,
        MaximumWidth,
        MaximumDistance
    )

    local subDecals = {}
    for k = 1, table.getn(command.Units) do
        local unit = command.Units[k]
        local unitBlueprint = unit:GetBlueprint()
        local unitBlueprintDamageRadius = 12

        local decal = UserDecal()
        decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds")
        decal:SetScale({ 1, 1, 1 })
        decal:SetPosition({0, 0, 0})
        subDecals[k] = dragger.Trash:Add(decal)
    end

    dragger.OnMove = function(self, x, y)


        local width = self.Width
        local view = self.WorldView

        local ps = self.Origin
        local pe = UnProject(view, { x, y })

        local dx = ps[1] - pe[1]
        local dz = ps[3] - pe[3]
        local distance = math.sqrt(dx * dx + dz * dz)

        local targets = ComputeAttackLocations(table.getn(command.Units), distance, command.Target.Position[1],
            command.Target.Position[2], command.Target.Position[3])

        for k = 1, table.getn(subDecals) do
            subDecals[k]:SetPosition(targets[k])
        end

        if distance > self.MinimumDistance then
            self.ShapeStart:Show()
            self.ShapeStart.Size = distance
        else
            -- try to hide it
            self.ShapeStart:Hide()
        end
    end
end
