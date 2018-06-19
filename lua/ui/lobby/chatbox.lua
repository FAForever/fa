local Group = import('/lua/maui/group.lua').Group
local RichTextBox = import('./richtextbox.lua').RichTextBox
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Edit = import('/lua/maui/edit.lua').Edit
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')
local gameColors = import('/lua/gameColors.lua').GameColors

local AddUnicodeCharToEditText = import('/lua/UTF.lua').AddUnicodeCharToEditText

ChatBox = Class(Group) {
    ChatEdit = nil,
    ChatList = nil,
    ExecuteCommand = nil,
    playerData = nil,
    hostID = nil,
    broadcastChatMessage = nil,
    gameInfo = nil,
    
    __init = function(self, Parent, Options, GameInfo, HostID, LocalPlayerData, CommandHandler, BroadcastChatMessageHandler)
        Group.__init(self, Parent)

        -- Properties init
        if not Options then Options = {} end

        -- Edit background
        self.EditBackground = Bitmap(self)
        self.EditBackground:SetSolidColor('FF212123')
        self.EditBackground.Left:Set(function() return self.Left() end)
        self.EditBackground.Right:Set(function() return self.Right() end) 
        self.EditBackground.Bottom:Set(function() return self.Bottom() end)
        self.EditBackground.Height:Set(25)

        -- Edit
        self.ChatEdit = Edit(self)
        self.ChatEdit.Left:Set(function() return self.Left() + 1 end)
        self.ChatEdit.Width:Set(function() return self.Width() - 2 end) 
        self.ChatEdit.Bottom:Set(function() return self.Bottom() end)
        self.ChatEdit.Height:Set(function() return self.EditBackground.Height() - 3 end)
        self:SetupEdit()
        self.ChatEdit.Depth:Set(function() return self.EditBackground.Depth() + 10 end)

        -- Messages List
        self.ChatList = RichTextBox(self, Options)
        self.ChatList.Width:Set(function() return self.Width() end)
        self.ChatList.Height:Set(function() return self.Height() - self.EditBackground.Height() end)
        self.ChatList.Left:Set(function() return self.Left() end)
        self.ChatList.Top:Set(function() return self.Top() end)        
        self.ChatList.DefaultTextOptions.FontName = UIUtil.bodyFont
        self.ChatList.DefaultTextOptions.FontSize = tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14
        self.ChatList.DefaultTextOptions.ForeColor = UIUtil.fontColor
        self.ChatList.DefaultTextOptions.DropShadow = true
        
        ExecuteCommand = CommandHandler
        playerData = LocalPlayerData
        broadcastChatMessage = BroadcastChatMessageHandler
        gameInfo = GameInfo
        hostID = HostID
    end,

    KeepFocus = function(self, value) 
        self._focus = value
        if value then 
            self.ChatEdit:AcquireFocus() 
        else
            self.ChatEdit:AbandonFocus()
        end
    end,

    SetupEdit = function(self)

        --self.ChatEdit:SetFont("Arial Gras", 12) -- Must be called after Edit's Width has been set !!   - UIUtil.bodyFont    
        self.ChatEdit:SetForegroundColor(UIUtil.fontColor) -- UIUtil.fontColor
        self.ChatEdit:ShowBackground(false)
        self.ChatEdit:SetDropShadow(true)
        self.ChatEdit:SetMaxChars(200)
        self:KeepFocus(true)


        self.ChatEdit.OnCharPressed = function(self, charcode)
            if charcode == UIUtil.VK_TAB then
                return true
            end
            local charLim = self:GetMaxChars()
            if STR_Utf8Len(self:GetText()) >= charLim then
                local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                PlaySound(sound)
            end
        end

        -- We work extremely hard to keep keyboard focus on the chat box, otherwise users can trigger
        -- in-game keybindings in the lobby.
        -- That would be very bad. We should probably instead just not assign those keybindings yet...
        self.ChatEdit.OnLoseKeyboardFocus = function(self2)
            if self._focus then        
                self2:AcquireFocus()
            end
        end
		
        local commandQueueIndex = 0
        local commandQueue = {}
        
		self.ChatEdit.OnEnterPressed = function(self2, text)
            if text:gsub("%s+", "") == '' then  -- If the text, trimmed of all space, is equal to ''
                return
            end
            table.insert(commandQueue, 1, text)
            commandQueueIndex = 0
            
            if (ExecuteCommand(self, text) == nil) then    -- If ExecuteCommand returns "Nil", this means the user DID NOT TRY to fire a command (no command prefix)
                broadcastChatMessage(text)
                self:AppendPlayerMessage(playerData.PlayerName, text, gameInfo)
            end
        end

        --- Handle up/down arrow presses for the chat box.
        self.ChatEdit.OnNonTextKeyPressed = function(self, keyCode)
            if AddUnicodeCharToEditText(self, keyCode) then
                return
            end
            if commandQueue and table.getsize(commandQueue) > 0 then
                if keyCode == 38 then
                    if commandQueue[commandQueueIndex + 1] then
                        commandQueueIndex = commandQueueIndex + 1
                        self:SetText(commandQueue[commandQueueIndex])
                    end
                end
                if keyCode == 40 then
                    if commandQueueIndex ~= 1 then
                        if commandQueue[commandQueueIndex - 1] then
                            commandQueueIndex = commandQueueIndex - 1
                            self:SetText(commandQueue[commandQueueIndex])
                        end
                    else
                        commandQueueIndex = 0
                        self:ClearText()
                    end
                end
            end
        end
    end,

    AppendText = function(self, Message, NewLine, TextOptions, LineOptions)
        local IsScrolledToBottom = self.ChatList:IsScrolledToBottom()
        self.ChatList:AppendText(Message, NewLine, TextOptions, LineOptions)
        if IsScrolledToBottom then self.ChatList:ScrollToBottom() end
    end,

    AppendLine = function(self, Message, TextOptions, LineOptions)
        self:AppendText(Message, true, TextOptions, LineOptions)
    end,

    AppendNotice = function(self, Message) 
        self:AppendText(Message, true, {ForeColor="ff777777"})
    end,

    AppendError = function(self, Message) 
        self:AppendText(Message, true, {ForeColor="ffff0000"})
    end,

    AppendPrivateMessage = function(self, PlayerName, DestinationPlayer, Message)
        self:AppendPlayerMessage(PlayerName, "<< To " .. DestinationPlayer .. " >> " .. Message)
    end,

    AppendPlayerMessage = function(self, PlayerName, Message, gameInfo)

        local Player = nil
        -- Find the PlayerName in the slots
        for k, p in gameInfo.PlayerOptions:pairs() do
            if p.PlayerName == PlayerName and p.Human then
                Player = p
            end
        end
        -- If the player was found, get his color.
        local PlayerColor = nil
        if not Player then
            -- Should not happen unless Desiredname was not available and player got a rename
            -- May be fixed in the future by using player ID instead of player name ?
            PlayerColor = "ffffffff"
        else
            PlayerColor = gameColors.PlayerColors[Player.PlayerColor]
        end

        self:AppendText(PlayerName, true, {FontName = "Arial Gras", ForeColor = PlayerColor}, {Padding = {3,0,0,0}})

        local regularColor = "ffffffff" -- (white)
        local hostColor = "ffffaa66"    -- (Host messages are orange)

        -- Find the PlayerName in the observers
        if not Player then
            for k, observer in gameInfo.Observers:pairs() do
                if observer.PlayerName == PlayerName then
                    Player = observer
                end
            end
        end
        -- Test if Player is the local player or the host
        if not Player then
            -- Should not happen - but can happen when joining own lobby with two running copies of the game
            -- Giving normal color, in doubt
            self:AppendText(Message, false, {ForeColor = regularColor})
        elseif Player.OwnerID == hostID then
            self:AppendText(Message, false, {ForeColor = hostColor})
        else
            self:AppendText(Message, false, {ForeColor = regularColor})
        end
    end,

    Refresh = function(self)
        self.ChatList:Refresh()
    end,

}