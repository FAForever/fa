
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

local Prefs = import("/lua/user/prefs.lua")

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

---@class UILobby : Group
---@field OnDestroyCallbacks table<string, fun()>
---@field OnExitCallbacks table<string, fun()>
---@field LobbyCommunication UILobbyCommunication
---@field ComponentMapPreview UILobbyComponentMapPreview
---@field Debugging boolean
Lobby = Class(Group) {

    LobbyCommunication = false,
    LobbyAPI = false,

    OnExitCallbacks = { },
    OnDestroyCallbacks = { },

    ---@param self UILobby
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'UILobby')

        LayoutHelpers.AtCenterIn(self, GetFrame(0))
        LayoutHelpers.SetDimensions(self, 1024, 768)
        self:DisableHitTest()

        if self.Debugging then
            self.DebugFill = UIUtil.CreateBitmapColor(self, '44ffffff')
            LayoutHelpers.FillParent(self.DebugFill, self)
            LayoutHelpers.DepthUnderParent(self.DebugFill, self, 1)
            self.DebugFill:DisableHitTest()
        end

        self.ComponentMapPreview = import("/lua/ui/lobby/components/map-preview.lua").LobbyComponentMapPreview(self)
        LayoutHelpers.SetDimensions(self.ComponentMapPreview, 200, 200)
        LayoutHelpers.AtCenterIn(self.ComponentMapPreview, self)

        self.ButtonExit = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', LOC("<LOC tooltipui0285>Exit"))
        LayoutHelpers.AtLeftBottomIn(self.ButtonExit, self, 33)
        LayoutHelpers.DepthOverParent(self.ButtonExit, self, 10000)
    end,

    ---@param self UILobby
    ---@param parent Control
    __post_init = function(self, parent)
        self.ButtonExit.OnClick = function(button)
            self:Destroy()
        end
    end,

    ---@param self UILobby
    ---@param lobbyCommunication UILobbyCommunication
    SetupLobbyCommunication = function(self, lobbyCommunication)
        self.LobbyCommunication = lobbyCommunication
    end,

    SetupLobbyAPI = function(self)
        -- todo
    end,

    ---------------------------------------------------------------------------
    --#region Connectivity

    ---@param self UILobby
    ---@param gameName string
    ---@param gameScenario string
    ---@param isSinglePlayer boolean
    Host = function(self, gameName, gameScenario, isSinglePlayer)
        if not self.LobbyCommunication then
            self:Warn("Unable to host a lobby - lobby communications are not setup")
            return
        end

        self.LobbyName = gameName
        self.LobbyScenario = gameScenario
        self.LobbySingleplayer = isSinglePlayer

        self.LobbyCommunication:HostGame()
    end,

    ---@param self UILobby
    ---@param address string
    ---@param remoteName? string
    ---@param remoteUID? string
    Join = function(self, address, remoteName, remoteUID)
        if not self.LobbyCommunication then
            self:Warn("Unable to join a lobby - lobby communications are not setup")
            return
        end

        self.LobbyCommunication:JoinGame(address, remoteName, remoteUID)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Callbacks

    ---@param self UILobbySelection
    ---@param callback fun()
    ---@param name string
    AddOnExitCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnExitCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnExitCallback'")
            return
        end

        self.OnExitCallbacks[name] = callback
    end,

    ---@param self UILobbySelection
    ---@param callback fun()
    ---@param name string
    AddOnDestroyCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnDestroyCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnDestroyCallback'")
            return
        end

        self.OnDestroyCallbacks[name] = callback
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbyCommunication
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyCommunication: %s", message))
        end
    end,

    ---@param self UILobbyCommunication
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbyCommunication: %s", message))
    end,

    ---@param self UILobbyCommunication
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbyCommunication: %s", message))
    end,

    --#endregion
}

-- Create a new unconnected lobby.
---@param localPort number
---@param localName string
---@param localUID? string
---@return UILobby
function CreateLobby(localPort, localName, localUID)
    -- if not GetPreference("profile.current") then
    --     Prefs.CreateProfile("FAF_"..desiredPlayerName)
    -- end

    local lobbyCommunication = import("/lua/ui/lobby/lobby-communication.lua").CreateLobbyCommunications(
        localPort, localName, localUID
    )

    local lobby = Lobby(GetFrame(0)) --[[@as UILobby]]
    lobby:SetupLobbyCommunication(lobbyCommunication)

    lobby:AddOnDestroyCallback(
        function ()
            lobbyCommunication:Destroy()
        end, 'LobbyCommunication'
    )

    return lobby
end