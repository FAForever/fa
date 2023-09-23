
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview

---@type { Binary: string, Version: string }[]
local AllMaps = {}
for _, scenario in import("/lua/ui/maputil.lua").EnumerateSkirmishScenarios() do
    if scenario.file then
        AllMaps[string.lower(tostring(scenario.file))] = {
            Binary = tostring(scenario.map),
            Version = tostring(scenario.map_version or 1)
        }
    end
end

---@class UILobbySelectionRow : Group
---@field Debugging boolean
---@field GameConfiguration? UILobbydDiscoveryInfo
---@field OnJoinGameCallbacks table<string, fun(gameConfig: UILobbydDiscoveryInfo)>
---@field OnObserveGameCallbacks table<string, fun(gameConfig: UILobbydDiscoveryInfo)>
---@field Panel Bitmap
---@field ButtonJoin Button
---@field ButtonObserve Button
---@field MapPreview MapPreview
---@field MapGlow Control
---@field MapNoPreview Text
---@field GameName Text
---@field DebugUI Control
---@field DebugFill Control
LobbySelectionRow = Class(Group) {

    OnJoinGameCallbacks = { },
    OnObserveGameCallbacks = { },

    ---@param self UILobbySelectionRow
    ---@param parent Control
    __init = function(self, parent)
        self:Debug(string.format("__init()"))

        Group.__init(self, parent, 'UILobbySelectionRow')

        -- can help us understand where various elements are
        self.DebugUI = Group(parent)
        LayoutHelpers.FillParent(self.DebugUI, self)

        self.DebugFill = UIUtil.CreateBitmapColor(self.DebugUI, '44ffffff')
        LayoutHelpers.FillParent(self.DebugFill, self)

        self.Panel = UIUtil.CreateBitmap(self, '/scx_menu/gameselect/slot_bmp.dds')
        LayoutHelpers.AtLeftCenterIn(self.Panel, self, 260)

        self.ButtonJoin = UIUtil.CreateButton(self, 
            '/scx_menu/small-short-btn/small-btn_up.dds',   
            '/scx_menu/small-short-btn/small-btn_down.dds',
            '/scx_menu/small-short-btn/small-btn_over.dds',
            '/scx_menu/small-short-btn/small-btn_dis.dds',
            '<LOC _Join>Join', 14, 0, 0
        )
        LayoutHelpers.AtLeftTopIn(self.ButtonJoin, self, 0, -2)

        self.ButtonObserve = UIUtil.CreateButton(self,
            '/scx_menu/small-short-btn/small-btn_up.dds',
            '/scx_menu/small-short-btn/small-btn_down.dds',
            '/scx_menu/small-short-btn/small-btn_over.dds',
            '/scx_menu/small-short-btn/small-btn_dis.dds',
            '<LOC _Observe>Observe', 14, 0, 0
        )
        LayoutHelpers.AtLeftBottomIn(self.ButtonObserve, self, 0, -2)

        self.MapPreview = MapPreview(self.Panel)
        LayoutHelpers.SetDimensions(self.MapPreview, self.Panel.Height, self.Panel.Height)
        LayoutHelpers.CenteredLeftOf(self.MapPreview, self.Panel, 8)
        
        self.MapGlow = Bitmap(self.MapPreview, UIUtil.UIFile('/scx_menu/gameselect/map-panel-glow_bmp.dds'))
        LayoutHelpers.FillParentFixedBorder(self.MapGlow, self.MapPreview, -3)

        self.MapNoPreview = UIUtil.CreateText(self.MapPreview, '?', 60, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(self.MapNoPreview, self.MapPreview)

        self.GameName = UIUtil.CreateText(self.Panel, '', 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftCenterIn(self.GameName, self.Panel, 12)
    end,

    ---@param self UILobbySelectionRow
    ---@param parent Control
    __post_init = function(self, parent)
        self:Debug(string.format("__post_init()"))

        -- do not let the debug UI interfere with the usual UI
        self.DebugUI.Show = function(debugUI)
            if self.Debugging then
                Group.Show(debugUI)
            else
                Group.Hide(debugUI)
            end
        end

        self.DebugUI:DisableHitTest(true)
        if not self.Debugging then
            self.DebugUI:Hide()
        end

        self.ButtonJoin.OnClick = function()
            self:Debug(string.format("ButtonJoin()"))

            for name, callback in self.OnJoinGameCallbacks do
                local ok, msg = pcall(callback, self.GameConfiguration)
                if not ok then
                    self:Warn(string.format("Callback '%s' for 'ButtonJoin' failed: \r\n %s", name, msg))
                end
            end
        end

        self.ButtonObserve.OnClick = function()
            self:Debug(string.format("ButtonObserve()"))

            for name, callback in self.OnObserveGameCallbacks do
                local ok, msg = pcall(callback, self.GameConfiguration)
                if not ok then
                    self:Warn(string.format("Callback '%s' for 'ButtonObserve' failed: \r\n %s", name, msg))
                end
            end
        end
    end,

    ---@param self UILobbySelectionRow
    ---@param info? UILobbydDiscoveryInfo
    Populate = function(self, info)
        self.GameConfiguration = info
        if not info then
            self:Hide()
            return
        end

        -- show it all!
        self:Show()

        local scenarioFile = info.Options.ScenarioFile
        local scenarioInfo = AllMaps[scenarioFile]
        if scenarioFile and scenarioInfo and DiskGetFileInfo(scenarioFile) then
            self.MapPreview:SetTextureFromMap(scenarioInfo.Binary)
            self.MapPreview:Show()
            self.MapNoPreview:Hide()
        else
            self.MapPreview:Hide()
            self.MapNoPreview:Show()
        end

        self.GameName:SetText(info.GameName or '')
    end,

    ---------------------------------------------------------------------------
    --#region Event callbacks

    ---@param self UILobbySelectionRow
    ---@param callback fun(gameConfig: UILobbydDiscoveryInfo)
    ---@param name string
    AddOnJoinGameCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnJoinGameCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnJoinGameCallback'")
            return
        end

        self.OnJoinGameCallbacks[name] = callback
    end,

    ---@param self UILobbySelectionRow
    ---@param callback fun(gameConfig: UILobbydDiscoveryInfo)
    ---@param name string
    AddOnObserveGameCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'OnObserveGameCallbacks'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'OnObserveGameCallbacks'")
            return
        end

        self.OnObserveGameCallbacks[name] = callback
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbySelectionRow
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbySelectionRow: %s", message))
        end
    end,

    ---@param self UILobbySelectionRow
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbySelectionRow: %s", message))
    end,

    ---@param self UILobbySelectionRow
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbySelectionRow: %s", message))
    end,
}
