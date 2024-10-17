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

---@class UIAutolobbyInterfaceState
---@field PlayerOptions? table<UILobbyPlayerId, UIAutolobbyPlayer>
---@field GameOptions? UILobbyLaunchGameOptionsConfiguration

---@class UIAutolobbyInterface : Group
---@field State UIAutolobbyInterfaceState
---@field BackgroundTextures string[]
---@field Background Bitmap
---@field Preview UIAutolobbyMapPreview
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
    end,

    ---@param self UIAutolobbyInterface
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Fill(parent)
            :End()

        LayoutHelpers.LayoutFor(self.Background)
            :Fill(self)
            :End()

        LayoutHelpers.LayoutFor(self.Preview)
            :AtCenterIn(self)
            :Width(400)
            :Height(400)
            :Hide()
            :End()
    end,

    ---@param self UIAutolobbyInterface
    ---@param playerOptions table<UILobbyPlayerId, UIAutolobbyPlayer>
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

    --#region Debugging

    ---@param self UIAutolobbyInterface
    ---@param state UIAutolobbyInterfaceState
    RestoreState = function(self, state)
        if state.PlayerOptions then
            self:UpdatePlayerOptions(state.PlayerOptions)
        end

        if state.GameOptions then
            self:UpdateGameOptions(state.GameOptions)
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

    -- trigger a reload
    ForkThread(
        function()
            WaitSeconds(1.0)
            import(__moduleinfo.name)
        end
    )
end

--#endregionGetSingleton
