--******************************************************************************************************
--** Copyright (c) 2024  FAForever
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

local Window = import("/lua/maui/window.lua").Window
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

local Grid   = import("/lua/maui/grid.lua").Grid

local UIConnectionDialogDot = import("/lua/ui/dialogs/connection/ConnectionDialogDot.lua").UIConnectionDialogDot
local SessionClientsOverride = import("/lua/ui/override/sessionclients.lua")

---@class UIConnectionDialogMessage
---@field Identifier string
---@field Sendee number
---@field Ping number[]
---@field Quiet number[]

---@type UIConnectionDialog | false
local UIConnectionDialogInstance = false

---@class UIConnectionDialog : Window
---@field Grid Grid
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
        local identifier = "ConnectionDialog"
        local defaultPosition = {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 525
        }

        Window.__init(self, parent, title, icon, pin, config, lockSize, lockPosition, identifier, defaultPosition)

        do
            -- this is where we send the clients information to the other players. We use
            -- a 'structure of arrays' as that is cheaper to send without abstracting the
            -- information too much.

            ---@type number[]
            local recipients = {}

            ---@type UIConnectionDialogMessage
            local message = {
                Identifier = self._MessageIdentifier,
                Ping = {},
                Quiet = {},
            }

            SessionClientsOverride.Observable:AddObserver(

            ---@param clients Client[]
                function(clients)
                    -- clean up old entries
                    for k = 1, table.getn(recipients) do
                        recipients[k] = nil
                    end

                    recipientHead = 1

                    -- populate with new entries
                    for k = 1, table.getn(clients) do
                        local client = clients[k]
                        if client.connected then
                            recipients[recipientHead] = k
                            recipientHead = recipientHead + 1

                            message.Ping[k * 2] = client.ping
                            message.Quiet[k * 2] = client.quiet
                        else
                            message.Ping[k] = -1
                            message.Quiet[k] = -1
                        end

                        if client["local"] then
                            message.Sendee = k
                        end
                    end

                    -- send the clients table to the other players
                    SessionSendChatMessage(recipients, message)
                end,
                self._MessageIdentifier
            )
        end

        do

            -- this is where we receive the information from other players. We interpret
            -- and update our internal state along with our interface.

            import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
                ---@param sender string
                ---@param data UIConnectionDialogMessage
                function(sender, data)

                    local clients = GetSessionClients()
                    local clientCount = table.getn(clients)

                    local grid = self.Grid
                    for k = 1, clientCount do
                        ---@type UIConnectionDialogDot
                        local item = grid[data.Sendee][k]
                        item:Update(data.Ping[k], 0, data.Quiet[k], 0)
                    end

                    LOG("UIConnectionDialog", sender, reprsl(data))
                end,
                self._MessageIdentifier
            )

        end

        do 

            -- this is where we create the interface that users can use to navigate the data

            local clients = GetSessionClients()
            local clientCount = table.getn(clients)

            ---@type Grid
            local grid = { }
            for x = 1, clientCount do
                local clientA = clients[x]
                grid[x] = { }
                for y = 1, clientCount do
                    local clientB = clients[y]
                    local uiDot = UIConnectionDialogDot(self, clientA.name, clientB.name)
                    grid[x][y] = uiDot
                end
            end

            self.Grid = grid
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
                    :AtLeftTopIn(self, 26 * x, 26 * y )
            end
        end

        self:SetWindowAlpha(0.8)
    end,

    --- Called when the control is destroyed
    ---@param self UIConnectionDialog
    OnDestroy = function(self)
        Window.OnDestroy(self)
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

    end,

    ---@param self UIConnectionDialog
    OnClose = function(self)
        self:Destroy()
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
    if (not UIConnectionDialogInstance) or UIConnectionDialogInstance:IsHidden() then
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
