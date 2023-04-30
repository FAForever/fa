
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap 

-- upvalue for performance
local MathMax = math.max
local MathMin = math.min

--- A small UI component created according to the Model / View / Controller (MVC) principle
---@class ConnectionStatus : Group
ConnectionStatus = ClassUI(Group) {

    -- Initialisation

    __init = function(self, parent)
        Group.__init(self, parent)

        -- set our dimensions
        LayoutHelpers.SetDimensions(self, 200, 110)

        -- put a border around ourselves
        UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')

        -- give ourself a background to become more readable
        self.Background = Bitmap(self)
        self.Background:SetSolidColor("000000")
        self.Background:SetAlpha(0.2)
        LayoutHelpers.FillParent(self.Background, self, 0.01)

        -- generic header
        self.HeaderText = UIUtil.CreateText(
            self, 
            "", 
            16, 
            UIUtil.titleFont
        )
        LayoutHelpers.AtCenterIn(self.HeaderText, self, 0.18)
        LayoutHelpers.AtTopIn(self.HeaderText, self, 6)

        -- connection status to other players
        self.ConnectionsText = UIUtil.CreateText(
            self, 
            "", 
            16, 
            UIUtil.bodyFont
        )
        LayoutHelpers.CenteredBelow(self.ConnectionsText, self.HeaderText, 20)
        self.ConnectionsCheckbox = UIUtil.CreateCheckboxStd(self, '/dialogs/check-box_btn/radio')
        -- self.ConnectionsCheckbox:Disable()
        LayoutHelpers.LeftOf(self.ConnectionsCheckbox, self.ConnectionsText)
        LayoutHelpers.AtVerticalCenterIn(self.ConnectionsCheckbox, self.ConnectionsText)

        -- hide for now
        self.ConnectionsCheckbox:Hide()

        -- initial view update
        self:UpdateView()
    end,

    -- Model elements

    -- these start at 1 as we're always connected to ourself
    TotalPlayersCount = 1,
    IsTotalPlayersCountSet = false,
    ConnectedPlayersCount = 1,


    -- View elements

    --- Updates the view of the model / view / controller of this UI element
    UpdateView = function(self)
        local headerText = LOC('<LOC AutoLobbyHeaderText>Connection status')
        self.HeaderText:SetText(headerText)

        local connectionsText
        if not self.IsTotalPlayersCountSet then 
            
            if self.ConnectedPlayersCount == 1 then 
                connectionsText = LOCF('<LOC AutoLobbyConnectionsTextSingularNoTotal>%s player is connected', tostring(self.ConnectedPlayersCount))
            else 
                connectionsText = LOCF('<LOC AutoLobbyConnectionsTextPluralNoTotal>%s players are connected', tostring(self.ConnectedPlayersCount))
            end
        else 
            if self.ConnectedPlayersCount == 1 then 
                connectionsText = LOCF('<LOC AutoLobbyConnectionsTextSingular>%s / %s is connected', tostring(self.ConnectedPlayersCount), tostring(self.TotalPlayersCount))
            else 
                connectionsText = LOCF('<LOC AutoLobbyConnectionsTextPlural>%s / %s are connected', tostring(self.ConnectedPlayersCount), tostring(self.TotalPlayersCount))
            end
        end

        self.ConnectionsText:SetText(connectionsText)
        self.ConnectionsCheckbox:SetCheck(self.ConnectedPlayersCount == self.TotalPlayersCount)
    end,

    -- Controller elements

    --- Updates the internal state and the text
    SetTotalPlayersCount = function(self, count)
        self.TotalPlayersCount = count
        self.IsTotalPlayersCountSet = true 
        self:UpdateView()
    end,

    --- Updates the internal state and the text
    SetPlayersConnectedCount = function(self, count)
        self.ConnectedPlayersCount = MathMax(MathMin(count, self.TotalPlayersCount), 1) 
        self:UpdateView()
    end,

    AddConnectedPlayer = function(self)
        self.ConnectedPlayersCount = self.ConnectedPlayersCount + 1
        if self.IsTotalPlayersCountSet then 
            self.ConnectedPlayersCount = MathMin(self.ConnectedPlayersCount, self.TotalPlayersCount)
        end

        self:UpdateView()
    end,

    RemoveConnectedPlayer = function(self)
        self.ConnectedPlayersCount = MathMax(self.ConnectedPlayersCount - 1, 1)
        self:UpdateView()
    end,
}