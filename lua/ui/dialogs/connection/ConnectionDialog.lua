--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local Window = import("/lua/maui/window.lua").Window
local Matrix = import("/lua/maui/matrix.lua").Matrix

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local UIConnectionDialogDot = import("/lua/ui/dialogs/connection/ConnectionDialogDot.lua").UIConnectionDialogDot
local SessionClientsOverride = import("/lua/ui/override/sessionclients.lua")

local ConnectionDialogData = import("/lua/ui/dialogs/connection/ConnectionDialogData.lua")

---@class UIConnectionDialogMessage : number[]
---@field Identifier string
---@field Sendee number

---@type UIConnectionDialog | false
local UIConnectionDialogInstance = false

---@class UIConnectionDialog : Window
---@field Grid Grid
---@field ItemClientAValue Text
---@field ItemClientBValue Text
---@field ItemClientArrow Text
---@field ItemPingLabel Text
---@field ItemPingAvgLabel Text
---@field ItemPingAvgValue Text
---@field ItemPingDevLabel Text
---@field ItemPingDevValue Text
---@field ItemQuietLabel Text
---@field ItemQuietAvgLabel Text
---@field ItemQuietAvgValue Text
---@field ItemQuietDevLabel Text
---@field ItemQuietDevValue Text
UIConnectionDialog = ClassUI(Window) {

    _MessageIdentifier = "Connection",

    --- Called by Lua to initialize the controls
    ---@param self UIConnectionDialog
    ---@param parent Control
    __init = function(self, parent)

        -- fields for the window class
        local title = "Connection dialog"
        local icon = false
        local pin = false
        local config = false
        local lockSize = true
        local lockPosition = false
        local identifier = "ConnectionDialog1"
        local defaultPosition = {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 625
        }

        Window.__init(self, parent, title, icon, pin, config, lockSize, lockPosition, identifier, defaultPosition)

        do

            -- this is where we receive the information from other players. We interpret
            -- and update our internal state along with our interface.

            ForkThread(self.TransmitMessageThread, self)

            import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
            ---@param sender string
            ---@param data UIConnectionDialogMessage
                function(sender, data)
                    self:ReceiveMessage(data)
                end,
                self._MessageIdentifier
            )

        end

        do

            -- this is where we create the interface that users can use to navigate the data

            local clients = GetSessionClients()
            local clientCount = table.getn(clients)

            ---@type Grid
            local grid = {}
            for x = 1, clientCount do
                local clientA = clients[x]
                grid[x] = {}
                for y = 1, clientCount do
                    local clientB = clients[y]
                    local uiDot = UIConnectionDialogDot(self, clientA.name, clientB.name)
                    grid[x][y] = uiDot
                end
            end

            self.Grid = grid

            self.ItemClientAValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)
            self.ItemClientBValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)
            self.ItemClientArrow = UIUtil.CreateText(self.ClientGroup, ' -> ', 12, UIUtil.bodyFont)

            self.ItemPingLabel = UIUtil.CreateText(self.ClientGroup, 'Ping: ', 14, UIUtil.bodyFont)
            self.ItemPingAvgLabel = UIUtil.CreateText(self.ClientGroup, '- average: ', 12, UIUtil.bodyFont)
            self.ItemPingAvgValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)
            self.ItemPingDevLabel = UIUtil.CreateText(self.ClientGroup, '- standard deviation: ', 12, UIUtil.bodyFont)
            self.ItemPingDevValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)

            self.ItemQuietLabel = UIUtil.CreateText(self.ClientGroup, 'Quiet: ', 14, UIUtil.bodyFont)
            self.ItemQuietAvgLabel = UIUtil.CreateText(self.ClientGroup, '- average: ', 12, UIUtil.bodyFont)
            self.ItemQuietAvgValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)
            self.ItemQuietDevLabel = UIUtil.CreateText(self.ClientGroup, '- standard deviation: ', 12, UIUtil.bodyFont)
            self.ItemQuietDevValue = UIUtil.CreateText(self.ClientGroup, '...', 12, UIUtil.bodyFont)
        end
    end,

    --- Called by Lua to position the controls
    ---@param self UIConnectionDialog
    ---@param parent Control
    __post_init = function(self, parent)

        local grid = self.Grid
        local clients = GetSessionClients()
        local clientCount = table.getn(clients)

        for x = 1, clientCount do
            for y = 1, clientCount do
                LayoutHelpers.LayoutFor(grid[x][y])
                    :AtLeftTopIn(self.ClientGroup, 14 + 26 * (x - 1), 10 + 26 * (y - 1))
            end
        end

        -- client information

        LayoutHelpers.LayoutFor(self.ItemClientAValue)
            :AtLeftTopIn(self.ClientGroup, 14, 20 + 26 * clientCount)

        LayoutHelpers.LayoutFor(self.ItemClientArrow)
            :RightOf(self.ItemClientAValue, 2)

        LayoutHelpers.LayoutFor(self.ItemClientBValue)
            :RightOf(self.ItemClientArrow, 2)

        -- ping information

        LayoutHelpers.LayoutFor(self.ItemPingLabel)
            :Below(self.ItemClientAValue, 2)

        LayoutHelpers.LayoutFor(self.ItemPingAvgLabel)
            :Below(self.ItemPingLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemPingAvgValue)
            :RightOf(self.ItemPingAvgLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemPingDevLabel)
            :Below(self.ItemPingAvgLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemPingDevValue)
            :RightOf(self.ItemPingDevLabel, 2)

        -- quiet information

        LayoutHelpers.LayoutFor(self.ItemQuietLabel)
            :Below(self.ItemPingDevLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemQuietAvgLabel)
            :Below(self.ItemQuietLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemQuietAvgValue)
            :RightOf(self.ItemQuietAvgLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemQuietDevLabel)
            :Below(self.ItemQuietAvgLabel, 2)

        LayoutHelpers.LayoutFor(self.ItemQuietDevValue)
            :RightOf(self.ItemQuietDevLabel, 2)

        self:SetWindowAlpha(0.8)
    end,

    --- Called when the control is destroyed
    ---@param self UIConnectionDialog
    OnDestroy = function(self)
        Window.OnDestroy(self)
    end,

    ---@param self UIConnectionDialog
    TransmitMessageThread = function(self)

        ---@type number[]
        local mCache = {}

        ---@type number[]
        local sCache = {}

        ---@type number[]
        local recipients = {}

        ---@type UIConnectionDialogMessage
        local message = {
            Identifier = self._MessageIdentifier,
            Sendee = -1,
        }

        while not IsDestroyed(self) do

            -- this is where we send the clients information to the other players. We use
            -- a 'structure of arrays' as that is cheaper to send without abstracting the
            -- information too much.

            local clients = GetSessionClients()
            local clientCount = table.getn(clients)

            -- determine recipients
            for k = 1, clientCount do
                recipients[k] = nil
            end

            local recipientHead = 1
            for k = 1, clientCount do
                local client = clients[k]
                if client.connected then
                    recipients[recipientHead] = k
                    recipientHead = recipientHead + 1
                end

                if client["local"] then
                    message.Sendee = k
                end
            end

            for k = 1, table.getn(message) do
                message[k] = nil
            end

            -- populate with ping values
            mCache, sCache = ConnectionDialogData.ComputeStatisticsPing(mCache, sCache)
            for k = 1, clientCount do
                message[k + 0 * clientCount] = mCache[k]
            end

            for k = 1, clientCount do
                message[k + 1 * clientCount] = sCache[k]
            end

            -- populate with quiet values
            mCache, sCache = ConnectionDialogData.ComputeStatisticsQuiet(mCache, sCache)
            for k = 1, clientCount do
                message[k + 2 * clientCount] = mCache[k]
            end

            for k = 1, clientCount do
                message[k + 3 * clientCount] = sCache[k]
            end

            -- send out the message
            SessionSendChatMessage(recipients, message)

            -- delay frequency when we're not visible
            if self:IsHidden() then
                WaitSeconds(16.0)
            else
                WaitSeconds(2.0)
            end
        end
    end,

    ---@param self UIConnectionDialog
    ---@param message UIConnectionDialogMessage
    ReceiveMessage = function(self, message)
        local clients = GetSessionClients()
        local clientCount = table.getn(clients)

        local grid = self.Grid
        for k = 1, clientCount do
            ---@type UIConnectionDialogDot
            local item = grid[message.Sendee][k]
            local pingMean = message[k + 0 * clientCount]
            local pingDeviation = message[k + 1 * clientCount]
            local quietMean = message[k + 2 * clientCount]
            local quietDeviation = message[k + 3 * clientCount]
            item:Update(pingMean, pingDeviation, quietMean, quietDeviation)
        end
    end,

    --- Called by the engine when the dialog changes visiblity via `Control:Show()` and `Control:Hide()`
    ---@param self UIConnectionDialog
    ---@param hidden boolean
    ---@return boolean  # if true, skips the call to `Control:OnHide` of children of this control
    OnHide = function(self, hidden)
        return true
    end,

    ---@param self UIConnectionDialog
    ---@param item UIConnectionDialogDot
    ---@param event KeyEvent
    OnHover = function(self, item, event)
        if event.Type == 'MouseExit' then
            self.ItemClientAValue:SetText('...')
            self.ItemClientBValue:SetText('...')
            self.ItemPingAvgValue:SetText('...')
            self.ItemPingDevValue:SetText('...')
            self.ItemQuietAvgValue:SetText('...')
            self.ItemQuietDevValue:SetText('...')
        else
            self.ItemClientAValue:SetText(item.ClientA)
            self.ItemClientBValue:SetText(item.ClientB)
            self.ItemPingAvgValue:SetText(string.format('%.2f', item.ClientPingAvg))
            self.ItemPingDevValue:SetText(string.format('%.2f', item.ClientPingSd))
            self.ItemQuietAvgValue:SetText(string.format('%.2f', item.ClientQuietAvg))
            self.ItemQuietDevValue:SetText(string.format('%.2f', item.ClientQuietSd))
        end
    end,

    ---@param self UIConnectionDialog
    OnClose = function(self)
        self:Hide()
    end,
}

--- Open the dialog
function OpenDialog()
    if UIConnectionDialogInstance and not IsDestroyed(UIConnectionDialog) then
        UIConnectionDialogInstance:Show()
    else
        UIConnectionDialogInstance = UIConnectionDialog(GetFrame(0))
        UIConnectionDialogInstance:Show()
    end
end

--- Close the dialog
function CloseDialog()
    if UIConnectionDialogInstance then
        UIConnectionDialogInstance:Hide()
    end
end

--- Toggle the dialog
function ToggleDialog()
    if (not UIConnectionDialogInstance) or IsDestroyed(UIConnectionDialogInstance) or
        UIConnectionDialogInstance:IsHidden() then
        OpenDialog()
    else
        CloseDialog()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if UIConnectionDialogInstance then
        UIConnectionDialogInstance:Destroy()
        UIConnectionDialogInstance = false
    end
end
