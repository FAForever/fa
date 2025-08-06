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

local Group = import("/lua/maui/group.lua").Group

local AutolobbyConnectionMatrixDot = import("/lua/ui/lobby/autolobby/autolobbyconnectionmatrixdot.lua")

---@class UIAutolobbyConnectionMatrix : Group
---@field PlayerCount number
---@field Elements UIAutolobbyConnectionMatrixDot[][]
local AutolobbyConnectionMatrix = Class(Group) {

    ---@param self UIAutolobbyConnectionMatrix
    ---@param parent Control
    __init = function(self, parent, playerCount)
        Group.__init(self, parent, "AutolobbyConnectionMatrix")

        self.PlayerCount = playerCount

        self.Border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')
        self.Background = UIUtil.CreateBitmapColor(self, '99000000')

        -- create the matrix
        self.Elements = {}
        for y = 1, self.PlayerCount do
            self.Elements[y] = {}
            for x = 1, self.PlayerCount do
                self.Elements[y][x] = AutolobbyConnectionMatrixDot.Create(self)
            end
        end
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Width(self.PlayerCount * 24)
            :Height(self.PlayerCount * 24)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Background)
            :Fill(self)
            :End()

        -- layout the matrix
        for y = 1, self.PlayerCount do
            for x = 1, self.PlayerCount do
                LayoutHelpers.ReusedLayoutFor(self.Elements[y][x])
                    :Width(22)
                    :Height(22)
                    :AtLeftTopIn(self, 2 + 24 * (x - 1), 2 + 24 * (y - 1))
            end
        end
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param ownershipMatrix boolean[][]
    UpdateOwnership = function(self, ownershipMatrix)
        for y, connectionRow in ownershipMatrix do
            for x, isOwned in connectionRow do
                ---@type UIAutolobbyConnectionMatrixDot
                local dot = self.Elements[y][x]
                if dot and y ~= x then
                    dot:SetOwnership(isOwned)
                end
            end
        end
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param connectionMatrix UIAutolobbyConnections
    UpdateConnections = function(self, connectionMatrix)
        for y, connectionRow in connectionMatrix do
            for x, isConnected in connectionRow do
                ---@type UIAutolobbyConnectionMatrixDot
                local dot = self.Elements[y][x]
                if dot and y ~= x then
                    dot:SetConnected(isConnected)
                end
            end
        end
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param statuses UIAutolobbyStatus
    UpdateStatuses = function(self, statuses)
        for k, status in statuses do
            ---@type UIAutolobbyConnectionMatrixDot
            local dot = self.Elements[k][k]
            if dot then
                dot:SetStatus(status)
            end
        end
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param id number
    UpdateIsAliveTimestamp = function(self, id)
        ---@type UIAutolobbyConnectionMatrixDot
        local dot = self.Elements[id][id]
        if dot then
            dot:SetIsAliveTimestamp(GetSystemTimeSeconds())
        end
    end,
}

---@param parent Control
---@param count number
---@return UIAutolobbyConnectionMatrix
Create = function(parent, count)
    return AutolobbyConnectionMatrix(parent, count)
end
