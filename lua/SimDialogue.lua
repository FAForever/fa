#*****************************************************************************
#* File: lua/SimDialog.lua
#* Summary: Sim accessable UI Controls
#*
#* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

local ipairs = ipairs
local LOG = LOG
local next = next
local tableInsert = table.insert

local dialogues = {}

function Create(text, buttonText, position)
    local dlg = {}
    local id = 1
    while dialogues[id] do
        id = id + 1
    end
    
    dlg.ID = id
    dlg.text = text
    dlg.buttonText = buttonText or {}
    dlg.disabledButtons = {}
    dlg.position = position
    
    
    dlg.SetText = function(self, newtext)
        if not Sync.SetDialogueText then Sync.SetDialogueText = {} end
        dialogues[self.ID].text = newtext
        tableInsert(Sync.SetDialogueText, {ID = self.ID, text = newtext})
    end
    
    dlg.UpdateButtonText = function(self, buttonID, newtext)
        if not Sync.UpdateButtonText then Sync.UpdateButtonText = {} end
        dialogues[self.ID].buttonText[buttonID] = newtext
        tableInsert(Sync.UpdateButtonText, {ID = self.ID, buttonID = buttonID, text = newtext})
    end
    
    dlg.SetButtonDisabled = function(self, buttonID, disabled)
        if not Sync.SetButtonDisabled then Sync.SetButtonDisabled = {} end
        dialogues[self.ID].disabledButtons[buttonID] = disabled
        tableInsert(Sync.SetButtonDisabled, {ID = self.ID, buttonID = buttonID, disabled = disabled})
    end
    
    dlg.UpdatePosition = function(self, newPosition)
        if not Sync.UpdatePosition then Sync.UpdatePosition = {} end
        dialogues[self.ID].position = newPosition
        tableInsert(Sync.UpdatePosition, {ID = self.ID, position = newPosition})
    end
    
    dlg.Destroy = function(self)
        if not Sync.DestroyDialogue then Sync.DestroyDialogue = {} end
        tableInsert(Sync.DestroyDialogue, self.ID)
        dialogues[self.ID] = nil
    end
    
    dlg.OnButtonPressed = function(self, info)
        LOG('button pressed: ', repr(info))
    end
    
    dialogues[id] = dlg
    
    if not Sync.CreateSimDialogue then Sync.CreateSimDialogue = {} end
    tableInsert(Sync.CreateSimDialogue, {ID = id, buttonText = buttonText or {}, text = text, position = position})
    
    return dialogues[id]
end

function OnButtonPress(args)
    if dialogues[args.ID] then
        dialogues[args.ID]:OnButtonPressed(args)
    end
end

function OnPostLoad()
    for id, info in dialogues do
        if not Sync.CreateSimDialogue then Sync.CreateSimDialogue = {} end
        tableInsert(Sync.CreateSimDialogue, {ID = id, buttonText = info.buttonText, text = info.text, position = info.position})
        if info.disabledButtons then
            for btnID, disabled in info.disabledButtons do
                if not Sync.SetButtonDisabled then Sync.SetButtonDisabled = {} end
                tableInsert(Sync.SetButtonDisabled, {ID = id, buttonID = btnID, disabled = disabled})
            end
        end
    end
end