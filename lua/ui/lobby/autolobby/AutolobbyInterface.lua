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

-- This module is designed to support a form of 'hot reload' that is seen in modern programming
-- languages. To make this possible there can be only one instance of the class that this module
-- represents. And no direct references of the module and/or of the instance should be kept. In
-- short:
--
-- - (1) Always import the module whenever you need to interact with it.
-- - (2) Always use the `GetSingleton` helper function to obtain a reference to the instance.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local AutolobbyMapPreview = import("/lua/ui/lobby/autolobby/AutolobbyMapPreview.lua")
local AutolobbyConnectionMatrix = import("/lua/ui/lobby/autolobby/AutolobbyConnectionMatrix.lua")

---@class UIAutolobbyInterfaceState
---@field PlayerOptions? table<UILobbyPeerId, UIAutolobbyPlayer>
---@field GameOptions? UILobbyLaunchGameOptionsConfiguration
---@field Connections? UIAutolobbyConnections
---@field Statuses? UIAutolobbyStatus

---@class UIAutolobbyInterface : Group
---@field State UIAutolobbyInterfaceState
---@field BackgroundTextures string[]
---@field Background Bitmap
---@field Preview UIAutolobbyMapPreview
---@field ConnectionMatrix UIAutolobbyConnectionMatrix
local AutolobbyInterface = Class(Group) {

    BackgroundTextures = {
        "/menus02/background-paint01_bmp.dds",
        "/menus02/background-paint02_bmp.dds",
        "/menus02/background-paint03_bmp.dds",
        "/menus02/background-paint04_bmp.dds",
        "/menus02/background-paint05_bmp.dds",
    },

    ---@param self UIAutolobbyInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "AutolobbyInterface")

        -- initial, empty state
        self.State = {}

        self.Background = UIUtil.CreateBitmap(self, self.BackgroundTextures[math.random(1, 5)])
        self.Preview = AutolobbyMapPreview.GetInstance(self)
        self.ConnectionMatrix = AutolobbyConnectionMatrix.Create(self, 4) -- TODO: determine this number dynamically
    end,

    ---@param self UIAutolobbyInterface
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self)
            :Fill(parent)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Background)
            :Fill(self)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Preview)
            :AtCenterIn(self, -100, 0)
            :Width(400)
            :Height(400)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.ConnectionMatrix)
            :CenteredBelow(self.Preview, 20)
            :Hide()
            :End()
    end,

    ---@param self UIAutolobbyInterface
    ---@param connections UIAutolobbyConnections
    UpdateConnections = function(self, connections)
        self.State.Connections = connections
        
        self.ConnectionMatrix:Show()
        self.ConnectionMatrix:UpdateConnections(connections)
    end,

    ---@param self UIAutolobbyInterface
    ---@param statuses UIAutolobbyStatus
    UpdateLaunchStatuses = function(self, statuses)
        self.State.Statuses = statuses

        self.ConnectionMatrix:Show()
        self.ConnectionMatrix:UpdateStatuses(statuses)
    end,

    ---@param self UIAutolobbyInterface
    ---@param playerOptions table<UILobbyPeerId, UIAutolobbyPlayer>
    UpdatePlayerOptions = function(self, playerOptions)
        self.State.PlayerOptions = playerOptions
    end,

    ---@param self UIAutolobbyInterface
    ---@param gameOptions UILobbyLaunchGameOptionsConfiguration
    UpdateGameOptions = function(self, gameOptions)
        self.State.GameOptions = gameOptions

        local scenarioFile = self.State.GameOptions.ScenarioFile
        if scenarioFile then
            self.Preview:Show()
            self.Preview:UpdateScenario(scenarioFile)
        else
            self.Preview:Hide()
        end
    end,

    ---@param self UIAutolobbyInterface
    ---@param id number
    UpdateIsAliveStamp = function(self, id)
        self.ConnectionMatrix:UpdateIsAliveTimestamp(id)
    end,

    --#region Debugging

    ---@param self UIAutolobbyInterface
    ---@param state UIAutolobbyInterfaceState
    RestoreState = function(self, state)
        self.State = state

        if state.PlayerOptions then
            local ok, msg = pcall(self.UpdatePlayerOptions, self, state.PlayerOptions)
            if not ok then
                WARN(msg)
            end
        end

        if state.GameOptions then
            local ok, msg = pcall(self.UpdateGameOptions, self, state.GameOptions)
            if not ok then
                WARN(msg)
            end
        end

        if state.Connections then
            local ok, msg = pcall(self.UpdateConnections, self, state.Connections)
            if not ok then
                WARN(msg)
            end
        end

        if state.Statuses then
            local ok, msg = pcall(self.UpdateLaunchStatuses, self, state.Statuses)
            if not ok then
                WARN(msg)
            end
        end
    end,

    --#endregion
}

--- A trashbag that should be destroyed upon reload.
local ModuleTrash = TrashBag()

---@type UIAutolobbyInterface | false
local AutolobbyInterfaceInstance = false

---@return UIAutolobbyInterface
GetSingleton = function()
    if AutolobbyInterfaceInstance then
        return AutolobbyInterfaceInstance
    end

    AutolobbyInterfaceInstance = AutolobbyInterface(GetFrame(0))
    ModuleTrash:Add(AutolobbyInterfaceInstance)
    return AutolobbyInterfaceInstance
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if AutolobbyInterfaceInstance then
        local handle = newModule.GetSingleton(GetFrame(0))
        handle:RestoreState(AutolobbyInterfaceInstance.State)
    end
end

--- Called by the module manager when this module becomes dirty
function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()
    import(__moduleinfo.name)
end

--#endregionGetSingleton
