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
local AutolobbyModel = import("/lua/ui/lobby/autolobby/autolobbymodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

---@class UIAutolobbyConnectionMatrix : Group
---@field Trash TrashBag
---@field PlayerCount number
---@field Border any
---@field Background Bitmap
---@field Elements UIAutolobbyConnectionMatrixDot[][]
---@field ConnectionsObserver LazyVar
---@field StatusesObserver LazyVar
---@field OwnershipObserver LazyVar
---@field IsAliveObserver LazyVar
local AutolobbyConnectionMatrix = Class(Group) {

    ---@param self UIAutolobbyConnectionMatrix
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "AutolobbyConnectionMatrix")

        self.Trash = TrashBag()

        local model = AutolobbyModel.GetSingleton()
        self.PlayerCount = model.PlayerCount()

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

        -- hidden until we know of a peer; the observers below reveal it once
        -- there is something to show
        self:Hide()

        -- subscribe to the model directly: each handler reads its LazyVar
        -- (establishing the dependency edge) and feeds the dot grid
        self.ConnectionsObserver = self.Trash:Add(
            LazyVarDerive(model.Connections, function(connectionsLazy)
                self:OnConnectionsChanged(connectionsLazy())
            end))
        self.StatusesObserver = self.Trash:Add(
            LazyVarDerive(model.Statuses, function(statusesLazy)
                self:OnStatusesChanged(statusesLazy())
            end))
        self.OwnershipObserver = self.Trash:Add(
            LazyVarDerive(model.Ownership, function(ownershipLazy)
                self:OnOwnershipChanged(ownershipLazy())
            end))
        self.IsAliveObserver = self.Trash:Add(
            LazyVarDerive(model.IsAliveStamp, function(stampLazy)
                self:OnIsAliveChanged(stampLazy())
            end))
    end,

    ---@param self UIAutolobbyConnectionMatrix
    OnDestroy = function(self)
        self.Trash:Destroy()
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
        -- a StartSpot can fall outside the grid; guard the row lookup
        if not self.Elements[id] then
            return
        end
        ---@type UIAutolobbyConnectionMatrixDot
        local dot = self.Elements[id][id]
        if dot then
            dot:SetIsAliveTimestamp(GetSystemTimeSeconds())
        end
    end,

    ---------------------------------------------------------------------------
    --#region Model observers

    ---@param self UIAutolobbyConnectionMatrix
    ---@param connections UIAutolobbyConnections
    OnConnectionsChanged = function(self, connections)
        if not connections then
            return
        end

        -- reveal the matrix only once we actually know of a peer; the initial
        -- (empty) derivation should not flash an empty grid on screen
        if next(AutolobbyModel.GetSingleton().ConnectionMatrix()) then
            self:Show()
        end
        self:UpdateConnections(connections)
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param statuses UIAutolobbyStatus
    OnStatusesChanged = function(self, statuses)
        if not statuses then
            return
        end

        if next(statuses) then
            self:Show()
        end
        self:UpdateStatuses(statuses)
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param ownership boolean[][] | false
    OnOwnershipChanged = function(self, ownership)
        if not ownership then
            return
        end

        self:Show()
        self:UpdateOwnership(ownership)
    end,

    ---@param self UIAutolobbyConnectionMatrix
    ---@param stamp UIAutolobbyAliveStamp | false
    OnIsAliveChanged = function(self, stamp)
        if not stamp then
            return
        end

        self:UpdateIsAliveTimestamp(stamp.Index)
    end,

    --#endregion
}

---@param parent Control
---@return UIAutolobbyConnectionMatrix
Create = function(parent)
    return AutolobbyConnectionMatrix(parent)
end
