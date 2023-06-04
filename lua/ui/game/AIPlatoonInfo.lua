local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class AIPlatoonInfoUI : Window
---@field Data AIPlatoonDebugInfo
---@field List Scrollbar
---@field Structures { Tech1: Button, Tech2: Button, Tech3: Button, Experimental: Button }
---@field First number
---@field NumberOfElements number
---@field NumberOfUIElements number
---@field UIElements Text[]
AIPlatoonInfoUI = ClassUI(Window) {

    ---@param self AIPlatoonInfoUI
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "AI Platoon information", false, true, true, true, false, "AIPlatoonInfo2", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 525
        })

        self.List = UIUtil.CreateLobbyVertScrollbar(self, 0, 0, 0)
        self.First = 0
        self.NumberOfElements = 0
        self.NumberOfUIElements = 12
        self.UIElements = {}

        for k = 1, self.NumberOfUIElements do
            local text = UIUtil.CreateText(self, '', 12, UIUtil.bodyFont)
            self.UIElements[k] = text
        end

        AddOnSyncHashedCallback(
        ---@param data AIPlatoonDebugInfo
            function(data)
                if not IsDestroyed(self) then
                    self.Data = data
                    self.NumberOfElements = table.getn(data.PlatoonInfo.DebugMessages)
                    self:CalcVisible()
                end
            end, 'AIPlatoonInfo', 'AIPlatoonInfo.lua'
        )

        AddOnSyncHashedCallback(
            function(data)
                if Root then
                    if not IsDestroyed(self) then
                        self.Data = nil
                        self.NumberOfElements = 0
                        self:CalcVisible()
                    end
                end
            end, 'FocusArmyChanged', 'AIPlatoonInfo.lua'
        )
    end,

    ---@param self AIPlatoonInfoUI
    __post_init = function(self, parent)

        -- position the first one
        local last = self.UIElements[1]
        LayoutHelpers.LayoutFor(last)
            :Over(self, 5)
            :AtLeftTopIn(self, 10, 30)
            :End()

        -- position all others
        for k = 2, self.NumberOfUIElements do
            LayoutHelpers.LayoutFor(self.UIElements[k])
                :Over(self, 5)
                :Below(last, 4)
                :End()

            last = self.UIElements[k]
        end

        LayoutHelpers.LayoutFor(self)
            :AtBottomIn(last, -20)
            :End()
    end,

    ---@param self AIPlatoonInfoUI
    Update = function(self)
    end,

    ---@param self AIPlatoonInfoUI
    OnClose = function(self)
        self:Hide()
    end,

    ---@param self AIPlatoonInfoUI
    ---@param rotation number
    OnMouseWheel = function(self, rotation)
        if rotation > 0 then
            self:ScrollLines(nil, -1)
        else
            self:ScrollLines(nil, 1)
        end
    end,

    ---@param self AIPlatoonInfoUI
    OnConfigClick = function(self)
        if self.Data then
            reprsl(self.Data)
        end
    end,

    ---@param self AIPlatoonInfoUI
    OnPinCheck = function(self)
        if self.Data then
            local camera = GetCamera('WorldCamera')

            local rect = Rect(
                self.Data.Position[1] - 20,
                self.Data.Position[3] - 20,
                self.Data.Position[1] + 20,
                self.Data.Position[3] + 20
            )

            camera:MoveToRegion(rect, 1)
        end
    end,

    ---@param self AIPlatoonInfoUI
    ---@return number
    ---@return number
    ---@return number
    ---@return number
    GetScrollValues = function(self)
        return 0, self.NumberOfElements, self.First,
            math.min(self.First + self.NumberOfUIElements, self.NumberOfElements)
    end,

    ---@param self AIPlatoonInfoUI
    ---@param axis any
    ---@param delta number
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta))
    end,

    ---@param self AIPlatoonInfoUI
    ---@param axis any
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta) * self.NumberOfUIElements)
    end,

    ---@param self AIPlatoonInfoUI
    ---@param axis any
    ---@param top number
    ScrollSetTop = function(self, axis, top)

        -- compute where we end up
        local size = self.NumberOfElements
        local first = math.max(math.min(size - self.NumberOfUIElements, math.floor(top)), 0)

        -- check if it is different
        if first == self.First then
            return
        end

        -- if so, store it and compute what is visible
        self.First = first
        self:CalcVisible()
    end,

    IsScrollable = function(self, axis)
        return true
    end,

    ---@param self AIPlatoonInfoUI
    CalcVisible = function(self)
        for k = 1, self.NumberOfUIElements do
            local index = k + self.First
            if index <= self.NumberOfElements then
                self.UIElements[k]:SetText(self.Data.PlatoonInfo.DebugMessages[index])
            else
                self.UIElements[k]:SetText('')
            end
        end
    end,

    ---@param self AIPlatoonInfoUI
    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
        end
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = AIPlatoonInfoUI(GetFrame(0))
        Root:Show()
    end
end

function CloseWindow()
    if Root then
        Root:Hide()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Root then
        Root:Destroy()
        Root = false
    end
end
