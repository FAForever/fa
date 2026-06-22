--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- The observer strip: subscribes to the model's `Observers` list and renders a header
-- with the count plus the names. Read-only for now — a player becomes an observer via
-- the host's "Move to observers", and rejoins by right-clicking an open slot ("Play
-- this slot"); per-observer host actions can be a later slice.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbyObserversInterface : Group
---@field Trash TrashBag
---@field Header Text
---@field Names Text
---@field ObserversObserver LazyVar
local CustomLobbyObserversInterface = Class(Group) {

    ---@param self UICustomLobbyObserversInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyObservers")

        self.Trash = TrashBag()

        self.Header = UIUtil.CreateText(self, "Observers (0)", 14, UIUtil.titleFont)
        self.Names = UIUtil.CreateText(self, "—", 12, UIUtil.bodyFont)
        self.Names:SetColor('ff9aa0a8')

        local model = CustomLobbyAuthoritativeModel.GetSingleton()
        self.ObserversObserver = self.Trash:Add(
            LazyVarDerive(model.Observers, function(observersLazy)
                self:OnObserversChanged(observersLazy())
            end))
    end,

    ---@param self UICustomLobbyObserversInterface
    __post_init = function(self)
        Layouter(self.Header):AtLeftTopIn(self):End()
        Layouter(self.Names):AtLeftIn(self):AnchorToBottom(self.Header, 4):End()
    end,

    --- Renders the observer count + names.
    ---@param self UICustomLobbyObserversInterface
    ---@param observers UICustomLobbyPlayer[]
    OnObserversChanged = function(self, observers)
        local count = table.getn(observers)
        self.Header:SetText("Observers (" .. count .. ")")

        if count == 0 then
            self.Names:SetText("—")
            return
        end

        local names = {}
        for i = 1, count do
            names[i] = observers[i].PlayerName or "?"
        end
        self.Names:SetText(table.concat(names, ", "))
    end,

    ---@param self UICustomLobbyObserversInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyObserversInterface
Create = function(parent)
    return CustomLobbyObserversInterface(parent)
end
