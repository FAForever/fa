
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

---@class UILobbyComponentMapPreview : Group
---@field Lobby UILobby
LobbyComponentMapPreview = Class(Group) {

    ---@param self UILobbyComponentMapPreview
    ---@param parent UILobby
    __init = function(self, parent)
        self:Debug(string.format("__init()"))
        Group.__init(self, parent, 'UILobbyComponentMapPreview')

        if self.Debugging then
            self.DebugFill = UIUtil.CreateBitmapColor(self, '44ffffff')
            LayoutHelpers.FillParent(self.DebugFill, self)
        end
    end,

    ---@param self UILobbyComponentMapPreview
    ---@param parent UILobby
    __post_init = function(self, parent)
        self:Debug(string.format("__post_init()"))

        self.Lobby = parent
    end,

    ---@param self UILobbyComponentMapPreview
    ---@param info? UILobbydDiscoveryInfo
    Populate = function(self, info)
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbyComponentMapPreview
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyComponentMapPreview: %s", message))
        end
    end,

    ---@param self UILobbyComponentMapPreview
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbyComponentMapPreview: %s", message))
    end,

    ---@param self UILobbyComponentMapPreview
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbyComponentMapPreview: %s", message))
    end,

    --#endregion
}
