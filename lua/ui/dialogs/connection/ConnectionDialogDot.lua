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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local ColorUtils = import("/lua/shared/color.lua")

local Group = import("/lua/maui/group.lua").Group

---@class UIConnectionDialogDot : Group
---@field Background Bitmap
---@field BackgroundHighlight Bitmap
---@field Color number[]
---@field ClientA string    # name of client
---@field ClientB string    # name of client
---@field ClientPingAvg number      # average of ping
---@field ClientPingSd number       # standard deviation of ping
---@field ClientQuietAvg number     # average of time quiet
---@field ClientQuietSd number      # standard deviation of time quiet
UIConnectionDialogDot = ClassUI(Group) {

    ---@param self UIConnectionDialogDot
    ---@param parent UIConnectionDialog
    ---@param clientA string
    ---@param clientB string
    __init = function(self, parent, clientA, clientB)
        Group.__init(self, parent, 'GridReclaimUIUpdate')

        self:SetNeedsFrameUpdate(true)

        self.Color = { 1, 1, 1 }
        self.ClientA = clientA
        self.ClientB = clientB
        self.ClientPingAvg = 0
        self.ClientPingSd = 0
        self.ClientQuietAvg = 0
        self.ClientQuietSd = 0

        self.Background = UIUtil.CreateBitmapColor(self, '000000')
        self.Background:DisableHitTest(true)

        self.BackgroundHighlight = UIUtil.CreateBitmapColor(self, 'ffffff')
        self.BackgroundHighlight:DisableHitTest(true)
        self.BackgroundHighlight:SetAlpha(0)
    end,

    ---@param self UIConnectionDialogDot
    ---@param parent UIConnectionDialog
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Over(parent, 10)
            :Height(24)
            :Width(24)

        LayoutHelpers.LayoutFor(self.BackgroundHighlight)
            :AtLeftTopIn(self, -1, -1)
            :Height(26)
            :Width(26)

        LayoutHelpers.LayoutFor(self.Background)
            :Over(self.BackgroundHighlight, 1)
            :Fill(self)
    end,

    --- Called by the engine on each frame
    ---@param self UIConnectionDialogDot
    ---@param delta number
    OnFrame = function(self, delta)

        -- slowly turn the color black to create a heartbeat-like effect
        local color = self.Color
        local inverseDelta = math.max(1 - 0.25 * delta, 0)
        color[1] = inverseDelta * color[1]
        color[2] = inverseDelta * color[2]
        color[3] = inverseDelta * color[3]

        self.Background:SetSolidColor(ColorUtils.ColorRGB(color[1], color[2], color[3], 1))
    end,

    ---@param self UIConnectionDialogDot
    ---@param pingAvg number
    ---@param pingSd number
    ---@param quietAvg number
    ---@param quietSd number
    Update = function(self, pingAvg, pingSd, quietAvg, quietSd)
        self.ClientPingAvg = pingAvg
        self.ClientPingSd = pingSd
        self.ClientQuietAvg = quietAvg
        self.ClientQuietSd = quietSd

        -- update the color indicator
        local color = self.Color
        if pingAvg == -1 and quietAvg == -1 then
            color[1] = 0
            color[2] = 0
            color[3] = 0
            self:SetNeedsFrameUpdate(false)
        elseif pingAvg == 0 and quietAvg == 0 then
            color[1] = 0.25
            color[2] = 0.25
            color[3] = 0.25
        else
            color[1] = math.min(quietAvg / 100, 1)
            color[2] = 1
            color[3] = 0
        end

        self.Background:SetSolidColor(ColorUtils.ColorRGB(color[1], color[2], color[3], 1))
    end,

    ---@param self UIConnectionDialogDot
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self.BackgroundHighlight:SetAlpha(0.8)
        elseif event.Type == 'MouseExit' then
            self.BackgroundHighlight:SetAlpha(0.0)
        end

        local parent = self:GetParent() --[[@as UIConnectionDialog]]
        parent:OnHover(self, event)
    end,
}
