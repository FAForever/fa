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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group

local BackgroundTextures = {
    land = '/textures/ui/common/icons/units/land_up.dds',
    sea = '/textures/ui/common/icons/units/sea_up.dds',
    amph = '/textures/ui/common/icons/units/amph_up.dds',
    air = '/textures/ui/common/icons/units/air_up.dds',
}

---@class UIUnitAdjacencyLabel: Group
---@field UnitIcon Bitmap
---@field UnitBackground Bitmap
---@field UnitStrategicIcon Bitmap
---@field FrameCount number
UnitAdjacencyLabel = ClassUI(Group) {

    StandardLabelDimensions = 48,

    ---@param self UIUnitAdjacencyLabel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'unit-adjacency-label')

        self.FrameCount = 0

        self.UnitIcon = Bitmap(self, nil, 'unit-adjacency-label-icon')
        self.UnitBackground = Bitmap(self, nil, 'unit-adjacency-label-background')
        self.UnitStrategicIcon = Bitmap(self, nil, 'unit-adjacency-label-strategic-icon')
        self:SetNeedsFrameUpdate(true)
    end,

    ---@param self UIUnitAdjacencyLabel
    __post_init = function(self)
        LayoutHelpers.LayoutFor(self)
            :Width(self.StandardLabelDimensions)
            :Height(self.StandardLabelDimensions)
            :End()

        LayoutHelpers.LayoutFor(self.UnitIcon)
            :Over(self, 1)
            :Fill(self)

        LayoutHelpers.LayoutFor(self.UnitBackground)
            :Under(self.UnitIcon, 1)
            :Fill(self)

        LayoutHelpers.LayoutFor(self.UnitStrategicIcon)
            :Over(self.UnitIcon, 1)
            :Fill(self)
    end,

    ---@param self UIUnitAdjacencyLabel
    ---@param unitBlueprint UnitBlueprint
    SetUnitTexture = function(self, unitBlueprint)
        self.FrameCount = 0
        self:Show()

        ---@type FileName
        local texturePath = UIUtil.UIFile(
            string.format(
                '/textures/ui/common/icons/units/%s_icon.dds',
                unitBlueprint.BlueprintId
            )--[[@as FileName]]
        )
        if texturePath then
            self.UnitIcon:SetTexture(texturePath)
        else
            self.UnitIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/unidentified.dds'))
        end

        local backgroundPath = UIUtil.UIFile(BackgroundTextures[unitBlueprint.General.Icon or 'land'])
        if backgroundPath then
            self.UnitBackground:SetTexture(backgroundPath)
        else
            self.UnitBackground:Hide()
        end

        self.UnitStrategicIcon:Hide()
    end,

    --- Scales the label in case the unit is relative small.
    ---@param self UIUnitAdjacencyLabel
    ---@param worldView WorldView
    ---@param unit UserUnit
    SetScale = function(self, worldView, unit)
        local unitBlueprint = unit:GetBlueprint()
        local unitFootprintSize = math.min(unitBlueprint.Footprint.SizeX, unitBlueprint.Footprint.SizeZ)
        local unitPosition = unit:GetPosition()
        local unitScreenPosition1 = worldView:Project({ unitPosition[1] - unitFootprintSize / 2, unitPosition[2],
            unitPosition[3] + unitFootprintSize / 2 })
        local unitScreenPosition2 = worldView:Project({ unitPosition[1] + unitFootprintSize / 2, unitPosition[2],
            unitPosition[3] - unitFootprintSize / 2 })

        -- check if the icon fits on top of the footprint, if not then we shrink it once
        local ratio = math.floor(math.clamp((unitScreenPosition2[1] - unitScreenPosition1[1]) / (0.5 * self.StandardLabelDimensions), 0.5, 2.0) * self.StandardLabelDimensions) * (1 / self.StandardLabelDimensions)
        LayoutHelpers.LayoutFor(self)
            :Width(ratio * self.StandardLabelDimensions)
            :Height(ratio * self.StandardLabelDimensions)
    end,

    --- Positions the label on top of a unit.
    ---@param self UIUnitAdjacencyLabel
    ---@param worldView WorldView
    ---@param unit UserUnit
    SetPosition = function(self, worldView, unit)
        local unitPosition = unit:GetPosition()
        local unitScreenPosition = worldView:Project(unitPosition)
        self.Left:Set(unitScreenPosition[1] - self.Width() / 2)
        self.Top:Set(unitScreenPosition[2] - self.Height() / 2)
    end,

    ---@param self UIUnitAdjacencyLabel
    ---@param delta number
    OnFrame = function(self, delta)
        self.FrameCount = self.FrameCount + 1

        local alpha = 1 - self.FrameCount / 10
        if alpha > 0 then
            self:SetAlpha(alpha, true)
        else
            self:Hide()
        end

        -- clean up after not being used for 100 frames
        if self.FrameCount > 100 then
            self:Destroy()
        end
    end,
}

---@type table<EntityId, UIUnitAdjacencyLabel>
local UnitAdjacencyLabelCache = setmetatable({}, { __mode = 'v' })

--- Draws a unit icon on top of the unit that we're adjacent to
---@param worldView WorldView
---@param unit UserUnit                     # The unit that our build preview is adjacent to.
---@param adjacentBlueprint UnitBlueprint   # The blueprint of the build preview that is adjacent to the unit.
local function DrawUnitAdjacencyLabel(worldView, unit, adjacentBlueprint)
    ---@type EntityId
    local unitEntityId = unit:GetEntityId()

    ---@type UIUnitAdjacencyLabel
    local unitAdjacencyLabel = UnitAdjacencyLabelCache[unitEntityId]
    if IsDestroyed(unitAdjacencyLabel) then
        unitAdjacencyLabel = UnitAdjacencyLabel(GetFrame(0)) --[[@as UIUnitAdjacencyLabel]]
        UnitAdjacencyLabelCache[unitEntityId] = unitAdjacencyLabel
    end

    -- update the label
    unitAdjacencyLabel:SetUnitTexture(unit:GetBlueprint())
    unitAdjacencyLabel:SetPosition(worldView, unit)
    unitAdjacencyLabel:SetScale(worldView, unit)
end

---@param unit UserUnit                     # The unit that our build preview is adjacent to.
---@param adjacentBlueprint UnitBlueprint   # The blueprint of the build preview that is adjacent to the unit.
OnAdjacentUnit = function(unit, adjacentBlueprint)
    ---@type WorldView | nil
    local worldViewLeft = import("/lua/ui/game/worldview.lua").viewLeft
    if not worldViewLeft then
        return
    end

    DrawUnitAdjacencyLabel(worldViewLeft, unit, adjacentBlueprint)
end
