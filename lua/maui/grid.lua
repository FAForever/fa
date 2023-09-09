local Control = import("/lua/maui/control.lua").Control
local Group = import("/lua/maui/group.lua").Group
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber
local LazyVar = import("/lua/lazyvar.lua")

---@class Grid : Group
Grid = ClassUI(Group) {
    -- note that the grid "assumes" your entries will be the correct width and height but doesn't enforce it
    -- controls could be bigger or smaller, it's up to you, but if they're bigger they will overlap as only
    -- the left top is placed, the whole grid is not resized
    __init = function(self, parent, itemWidth, itemHeight)
        Group.__init(self, parent, "Grid")
        self._itemWidth = ScaleNumber(itemWidth)
        self._itemHeight = ScaleNumber(itemHeight)
        self._items = {}
        self._top = {
            ["Horz"] = 1,
            ["Vert"] = 1
        }
        self._lines = {
            ["Horz"] = 0,
            ["Vert"] = 0
        }
        
        -- visible
        self._visible = {
            ["Horz"] = LazyVar.Create(),
            ["Vert"] = LazyVar.Create()
        }

        self._visible["Horz"]:Set(function() return math.floor(self.Width() / self._itemWidth) end)
        self._visible["Vert"]:Set(function() return math.floor(self.Height() / self._itemHeight) end)
        self._visible["Horz"].OnDirty = function(var)
            if self._lastVisible["Horz"] ~= var() then
                self:_CalculateVisible()
                self._lastVisible["Horz"] = var()
            end
        end
        self._visible["Vert"].OnDirty = function(var)
            if self._lastVisible["Vert"] ~= var() then
                self:_CalculateVisible()
                self._lastVisible["Vert"] = var()
            end
        end

        self._lastVisible = {
            ["Horz"] = 0,
            ["Vert"] = 0
        }
    end,

    _CheckRow = function(self, row)
        if (row > self._lines["Vert"]) or (row < 1) then
            error("Grid: Attempt to set row out of range (requested = " .. row .. " range = " .. self._lines["Vert"] .. ")")
            return false
        end
        return true
    end,

    _CheckCol = function(self, col)
        if (col > self._lines["Horz"]) or (col < 1) then
            error("Grid: Attempt to set column out of range (requested = " .. col .. " range = " .. self._lines["Horz"] .. ")")
            return false
        end
        return true
    end,

    GetVisible = function(self)
        return self._visible["Horz"](), self._visible["Vert"]()
    end,

    GetDimensions = function(self)
        return self._lines["Horz"], self._lines["Vert"]
    end,

    -- allow changing grid dimensions without need to re-create the whole grid
    SetDimensions = function(self, itemWidth, itemHeight)
        self:DeleteAndDestroyAll(true)
        self._itemWidth = ScaleNumber(itemWidth)
        self._itemHeight = ScaleNumber(itemHeight)
        self._visible["Horz"]:Set(function() return math.floor(self.Width() / self._itemWidth) end)
        self._visible["Vert"]:Set(function() return math.floor(self.Height() / self._itemHeight) end)
    end,

    AppendRows = function(self, count, batch)
        if count < 1 then
            count = 1
        end
        for row = self._lines["Vert"] + 1, self._lines["Vert"] + count do
            self._items[row] = {}
        end
        self._lines["Vert"] = self._lines["Vert"] + count
        if not batch then self:_CalculateVisible() end
    end,

    AppendCols = function(self, count, batch)
        if count < 1 then
            count = 1
        end
        self._lines["Horz"] = self._lines["Horz"] + count
        if not batch then self:_CalculateVisible() end
    end,

    DeleteRow = function(self, row, batch)
        if not self:_CheckRow(row) then return end
        for col = 1, self._lines["Horz"] do
            if self._items[row][col] then self._items[row][col]:Hide() end
            self._items[row][col] = nil
        end
        table.remove(self._items, row)
        self._lines["Vert"] = self._lines["Vert"] - 1
        if not batch then self:_CalculateVisible() end
    end,

    DeleteCol = function(self, col, batch)
        if not self:_CheckCol(col) then return end
        for row = 1, self._lines["Vert"] do
            if self._items[row][col] then
                self._items[row][col]:Hide()
                self._items[row][col] = nil
                table.remove(self.items[row], col)
            end
        end
        self._lines["Horz"] = self._lines["Horz"] - 1
        if not batch then self:_CalculateVisible() end
    end,

    DeleteAll = function(self, batch)
        for row = 1, self._lines["Vert"] do
            for col = 1, self._lines["Horz"] do
                if self._items[row][col] then self._items[row][col]:Hide() end
                self._items[row][col] = nil
            end
            self._items[row] = nil
        end
        self._lines["Horz"] = 0
        self._lines["Vert"] = 0
        self:ScrollSetTop("Horz", 1)
        self:ScrollSetTop("Vert", 1)
        if not batch then self:_CalculateVisible() end
    end,

    -- change and item at a particular position and destroy anything already there
    -- note that setting an item will reparent it to the grid control
    SetItem = function(self, control, col, row, batch)
        if not self:_CheckRow(row) then return end
        if not self:_CheckCol(col) then return end
        control:SetParent(self)
        control.Depth:Set(function() return self.Depth() + 1 end)
        self._items[row][col] = control
        if not batch then self:_CalculateVisible() end
    end,

    GetItem = function(self, col, row)
        if not self:_CheckRow(row) then return end
        if not self:_CheckCol(col) then return end
        return self._items[row][col]
    end,

    -- remove is useful when the grid doesn't own the items
    RemoveItem = function(self, col, row, batch)
        if not self:_CheckRow(row) then return end
        if not self:_CheckCol(col) then return end
        if self._items[row][col] ~= nil then
            if self._items[row][col] then self._items[row][col]:Hide() end
            self._items[row][col] = nil
        end
        if not batch then self:_CalculateVisible() end
    end,

    RemoveAllItems = function(self, batch)
        for row = 1, self._lines["Vert"] do
            for col = 1, self._lines["Horz"] do
                if self._items[row][col] then self._items[row][col]:Hide() end
                self._items[row][col] = nil
            end
        end
        self:ScrollSetTop("Horz", 1)
        self:ScrollSetTop("Vert", 1)
        if not batch then self:_CalculateVisible() end
    end,

    -- destroy is useful when the grid has ownership of the items
    DestroyItem = function(self, col, row, batch)
        if not self:_CheckRow(row) then return end
        if not self:_CheckCol(col) then return end
        if self._items[row][col] ~= nil then
            self._items[row][col]:Destroy()
            self._items[row][col] = nil
        end
        if not batch then self:_CalculateVisible() end
    end,

    DestroyAllItems = function(self, batch)
        for row = 1, self._lines["Vert"] do
            for col = 1, self._lines["Horz"] do
                if self._items[row][col] then
                    self._items[row][col]:Destroy()
                    self._items[row][col] = nil
                end
            end
        end
        self:ScrollSetTop("Horz", 1)
        self:ScrollSetTop("Vert", 1)
        if not batch then self:_CalculateVisible() end
    end,

    DeleteAndDestroyAll = function(self, batch)
        for row = 1, self._lines["Vert"] do
            for col = 1, self._lines["Horz"] do
                if self._items[row][col] then
                    self._items[row][col]:Destroy()
                    self._items[row][col] = nil
                end
            end
            self._items[row] = nil
        end
        self._lines["Horz"] = 0
        self._lines["Vert"] = 0
        self:ScrollSetTop("Horz", 1)
        self:ScrollSetTop("Vert", 1)
        if batch then self:_CalculateVisible() end
    end,

    -- Batch mode operators don't calculate visible after adding/removing so make sure you call
    -- EndBatch when done adding
    EndBatch = function(self)
        self:_CalculateVisible()
    end,

    GetScrollValues = function(self, axis)
        local rangeMin = 0
        local rangeMax = math.max(self._lines[axis], self._visible[axis]())
        local visibleMin = self._top[axis] - 1
        local visibleMax = (self._top[axis] - 1) + self._visible[axis]()
        return rangeMin, rangeMax, visibleMin, visibleMax
    end,

    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._top[axis] + delta)
    end,

    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._top[axis] + (delta * self._visible[axis]()))
    end,

    ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self._top[axis] then return end
        self._top[axis] = math.max(math.min(self._lines[axis] - self._visible[axis]() + 1 , top), 1)
        self:_CalculateVisible()
    end,

    IsScrollable = function(self, axis)
        if self._lines[axis] > self._visible[axis]() then
            return true
        else
            return false
        end
    end,

    _CalculateVisible = function(self)
        if not self._lines then return end -- protect against premature calls
        for row = 1, self._lines["Vert"] do
            for col = 1, self._lines["Horz"] do
                local control = self._items[row][col]
                if not IsDestroyed(control) then
                    if  (col >= self._top["Horz"]) and (col < self._top["Horz"] + self._visible["Horz"]()) and
                        (row >= self._top["Vert"]) and (row < self._top["Vert"] + self._visible["Vert"]()) then
                        control:SetHidden(false)
                        local column = col
                        local rowumn = row
                        local horzPad = math.max(0, (self._itemWidth - control.Width()) / 2)
                        local vertPad = math.max(0, (self._itemHeight - control.Height()) / 2)
                        control.Left:Set(function() return math.floor(((column - self._top["Horz"]) * self._itemWidth) + self.Left() + horzPad) end)
                        control.Top:Set(function() return math.floor(((rowumn - self._top["Vert"]) * self._itemHeight) + self.Top() + vertPad) end)
                    else
                        control:SetHidden(true)
                    end
                end
            end
        end
    end,

    OnHide = function(self, hidden)
        self:_CalculateVisible()
        -- when the grid is being shown, we want to return true so its children are not shown
        -- note that this only works if the grid elements are children of the grid, and it's
        -- possible to make them not so.
        return not hidden
    end,

    OnDestroy = function(self)
        self._visible["Horz"]:Destroy()
        self._visible["Horz"] = nil
        self._visible["Vert"]:Destroy()
        self._visible["Vert"] = nil
    end
}