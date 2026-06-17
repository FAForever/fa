--*****************************************************************************
--* File: lua/ui/lobby/chathandler.lua
--* Summary: Chat UI and logic extraction for the lobby
--*****************************************************************************

local Prefs = import("/lua/user/prefs.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local gameColors = import("/lua/gamecolors.lua").GameColors
local Edit = import("/lua/maui/edit.lua").Edit
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")
local AddUnicodeCharToEditText = import("/lua/utf.lua").AddUnicodeCharToEditText

-- Local state dependencies injected from lobby.lua
local GUI = false
local lobbyComm = false
local gameInfo = false
local localPlayerID = false
local FACTION_NAMES = false
local GetLocalPlayerData = false
local FindNameForID = false
local FindIDForName = false

function Init(deps)
    GUI = deps.GUI
    lobbyComm = deps.lobbyComm
    gameInfo = deps.gameInfo
    localPlayerID = deps.localPlayerID
    FACTION_NAMES = deps.FACTION_NAMES
    GetLocalPlayerData = deps.GetLocalPlayerData
    FindNameForID = deps.FindNameForID
    FindIDForName = deps.FindIDForName
end

function AddChatText(text, playerID, scrollToBottom)
    if not GUI or not GUI.chatDisplay then
        LOG("Can't add chat text -- no chat display")
        LOG("text=" .. repr(text))
        return
    end

    local chatPlayerColor = Prefs.GetFromCurrentProfile('ChatPlayerColor')
    if chatPlayerColor == nil then
        chatPlayerColor = true
    end

    local scrolledToBottom = GUI.chatPanel:IsScrolledToBottom() or scrollToBottom
    local nameColor = "AAAAAA" 
    local textColor = "AAAAAA"
    local nameFont = "Arial Gras"
    
    for id, player in gameInfo.PlayerOptions:pairs() do
        if player.OwnerID == playerID and player.Human then
            textColor = nil
            nameColor = gameColors.PlayerColors[player.PlayerColor]
            if not chatPlayerColor then
                nameFont = UIUtil.bodyFont
                if Prefs.GetOption('faction_font_color') then
                    nameColor = import("/lua/skins/skins.lua").skins[ FACTION_NAMES[GetLocalPlayerData():AsTable().Faction] ].fontColor
                    textColor = nameColor
                else
                    nameColor = nil
                end
            end
            break
        end
    end
    
    local name = FindNameForID(playerID)

    GUI.chatDisplay:PostMessage(text, name, {fontColor = textColor}, {fontColor = nameColor, fontFamily = nameFont})
    if scrolledToBottom then
        GUI.chatPanel:ScrollToBottom()
    else
        GUI.newMessageArrow:Enable()
    end
end

function PublicChat(text)
    lobbyComm:BroadcastData({
        Type = "PublicChat",
        Text = text,
    })
    AddChatText(text, localPlayerID, true)
end

function PrivateChat(targetID, text)
    if targetID ~= localPlayerID then
        lobbyComm:SendData(targetID, {
            Type = 'PrivateChat',
            Text = text,
        })
    end
    local targetName = FindNameForID(targetID)
    if targetName then
        AddChatText("<<"..LOCF("<LOC lobui_0443>To %s", targetName)..">> " .. text)
    end
end

local function ParseWhisper(params)
    local delimStart = string.find(params, " ")
    if delimStart then
        local name = string.sub(params, 1, delimStart-1)
        local targID = FindIDForName(name)
        if targID then
            PrivateChat(targID, string.sub(params, delimStart+1))
        else
            AddChatText(LOC("<LOC lobby_0007>Invalid whisper target."))
        end
    end
end

local commands = {
    pm = ParseWhisper,
    private = ParseWhisper,
    w = ParseWhisper,
    whisper = ParseWhisper,
}

function setupChatEdit(chatPanel)
    GUI.chatEdit = Edit(chatPanel)
    LayoutHelpers.AtLeftTopIn(GUI.chatEdit, GUI.chatBG, 4, 3)
    GUI.chatEdit.Width:Set(GUI.chatBG.Width() - LayoutHelpers.ScaleNumber(4))
    LayoutHelpers.SetHeight(GUI.chatEdit, 22)
    GUI.chatEdit:SetFont(UIUtil.bodyFont, 16)
    GUI.chatEdit:SetForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:ShowBackground(false)
    GUI.chatEdit:SetDropShadow(true)
    GUI.chatEdit:AcquireFocus()

    GUI.chatDisplayScroll = UIUtil.CreateLobbyVertScrollbar(chatPanel, -15, 25, 0)
    GUI.chatEdit:SetMaxChars(200)
    
    GUI.chatEdit.OnCharPressed = function(self, charcode)
        if charcode == UIUtil.VK_TAB then
            return true
        end

        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    GUI.chatEdit.OnLoseKeyboardFocus = function(self)
        self:AcquireFocus()
    end

    local commandQueueIndex = 0
    local commandQueue = {}
    
    GUI.chatEdit.OnEnterPressed = function(self, text)
        if text:gsub("%s+", "") == '' then 
            return
        end
        GpgNetSend('Chat', text)
        table.insert(commandQueue, 1, text)
        commandQueueIndex = 0
        if string.sub(text, 1, 1) == '/' then
            local spaceStart = string.find(text, " ") or string.len(text) + 1
            local comKey = string.sub(text, 2, spaceStart - 1)
            local params = string.sub(text, spaceStart + 1)
            local commandFunc = commands[string.lower(comKey)]
            if not commandFunc then
                AddChatText(LOCF("<LOC lobui_0396>Command Not Known: %s", comKey))
                return
            end
            commandFunc(params)
        else
            PublicChat(text)
        end
    end

    GUI.chatEdit.OnEscPressed = function(self, text)
        local changelogDialogManager = import("/lua/ui/lobby/changelog/changelogdialog.lua")
        local changelogDialogIsOpen = changelogDialogManager.IsOpen()

        if HasCommandLineArg("/gpgnet") or changelogDialogIsOpen then
            EscapeHandler.HandleEsc(not changelogDialogIsOpen)
        else
            GUI.exitButton.OnClick()
        end
        return true
    end

    GUI.chatEdit.OnNonTextKeyPressed = function(self, keyCode)
        if AddUnicodeCharToEditText(self, keyCode) then
            return
        end
        if commandQueue and not table.empty(commandQueue) then
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
    chatPanel.edit = GUI.chatEdit
end