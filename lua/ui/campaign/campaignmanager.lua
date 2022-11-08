--*****************************************************************************
--* File: lua/modules/ui/campaign/campaignmanager.lua
--* Author: Chris Blackwell
--* Summary: manages campiagn logic
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")

campaignSequence = {
    uef = {
        'X1CA_001',
        'X1CA_002',
        'X1CA_003',
        'X1CA_004',
        'X1CA_005',
        'X1CA_006',
    },
    cybran = {
        'X1CA_001',
        'X1CA_002',
        'X1CA_003',
        'X1CA_004',
        'X1CA_005',
        'X1CA_006',
    },
    aeon = {
        'X1CA_001',
        'X1CA_002',
        'X1CA_003',
        'X1CA_004',
        'X1CA_005',
        'X1CA_006',
    },
}

diffIntToDiffKey = {
    'easy',
    'medium',
    'hard',
}

diffKeyToDiffInt = {
    easy = 1,
    medium = 2,
    hard = 3,
}

-- this is sync'd from the sim, so it should be authoritative
campaignMode = false

--- # Campaign table format:
--- - campaignID - one for each campaign
--- - completedOperationID - each operation completed will have an entry
--- - difficulty - one entry for each difficulty completed
--- - allPrimary - `bool` true if all primary objectives completed for this difficulty
--- - allSecondary - `bool` true if all secondary objectives completed for this difficulty
local function GetCampaignTable()
    local cmpt = Prefs.GetFromCurrentProfile('campaign')
    if not cmpt then cmpt = {} end
    return cmpt
end

local function SetCampaignTable(newTable)
    Prefs.SetToCurrentProfile('campaign', newTable)
    SavePreferences()
end

function ResetCampaign(campaignID)
    local cmpt = GetCampaignTable()
    cmpt[campaignID] = nil
    SetCampaignTable(cmpt)
end

-- Returns the last completed operation ID in a campaign
-- If diff. is not supplied, returns the highest completed op in the sequence of all difficulties
function GetLastCompletedOperation(campaign, difficulty)
    if campaignSequence[campaign] then
        local campTable = GetCampaignTable()
        if campTable[campaign] then
            local lastID = false
            for _, opID in campaignSequence[campaign] do
                if difficulty then
                    if campTable[campaign][opID][difficulty].allPrimary != nil then
                        lastID = opID
                    end
                else
                    for _, diff in diffKeyToDiffInt do
                        if campTable[campaign][opID][diff].allPrimary != nil then
                            lastID = opID
                            break
                        end
                    end
                end
            end
            return lastID
        end
    end
    return false
end

-- Returns the next opID in the sequence of the campaign specified
function GetNextOperation(campaign, opKey, diff)
    if campaignSequence[campaign] then
        local found = false
        for _, opID in campaignSequence[campaign] do
            if found then
                return {opID = opID, campaignID = campaign, difficulty = diff}
            end
            if opID == opKey then
                found = true
            end
        end
    end
    return false
end

-- supplied a campaign ID and operation ID, returns whether the user can select the operation or not
function IsOperationSelectable(campaign, operation)
    if campaignSequence[campaign] then
        local campTable = GetCampaignTable()
        if campTable[campaign][operation] then
            return true
        end

        local lastCompletedOp = GetLastCompletedOperation(campaign)
        if GetNextOperation(campaign, lastCompletedOp).opID == operation then
            for i, v in campTable[campaign][lastCompletedOp] do
                if v.allPrimary == true then
                    return true
                end
            end
        end
    end
    return false
end

-- supplied a campaign ID and operation ID, returns whether the user has finished the operation or not
function IsOperationFinished(campaign, operation, difficulty)
    local campTable = GetCampaignTable()
    if campaignSequence[campaign] and campTable[campaign][operation] then
        if difficulty then
            if campTable[campaign][operation][difficulty].allPrimary == true then
                return true
            end
        else
            for i, v in campTable[campaign][operation] do
                if v.allPrimary == true then
                    return true
                end
            end
        end
    end
    return false
end

--- # Operation victory table contains the following fields
--- - `string` opKey - unique identifier for the current operation (ie SCCA_E01 would be a good key)
--- - `bool` success - instructs UI which dialog to show
--- - `int` difficulty - 1,2,3 currently supported
--- - `bool` allPrimary - true if all primary objectives completed, otherwise, false
--- - `bool` allSecondary - true if all secondary objectives completed, otherwise, false
--- - `bool` allBonus - true if all bonus objectives completed, otherwise, false
--- - `int` factionVideo - Opt.  If present, display this factions end game video
function OperationVictory(ovTable, skipDialog)
    local resultText
    if ovTable.success == true then
        resultText = "<LOC CAMPMGR_0000>Operation completed"
    else
        resultText = "<LOC CAMPMGR_0001>Operation failed"
    end

    if not skipDialog then
        import("/lua/ui/game/worldview.lua").UnlockInput()

        if ovTable.success then
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Victory'}))
        else
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Fail'}))
        end
        UIUtil.ShowInfoDialog(
            GetFrame(0),
            resultText,
            "<LOC _Ok>",
            function()
                import("/lua/ui/dialogs/score.lua").CreateDialog(ovTable.success, true, ovTable)
            end,
            true)
    end
end

function LaunchBriefing(nextOpData)
    local opID = nextOpData.opID
    if DiskGetFileInfo('/maps/'..opID..'/'..opID..'_operation.lua') then
        local opData = import('/maps/'..opID..'/'..opID..'_operation.lua')
        import("/lua/ui/campaign/operationbriefing.lua").CreateUI(opID, opData.operationData, nextOpData.campaignID, nextOpData.difficulty)
        return true
    end
    return false
end

function GetCampaignSequence(campaignID)
    local retTable = {}
    if campaignSequence[campaignID] then
        for i, v in campaignSequence[campaignID] do
            table.insert(retTable, v)
        end
        return retTable
    else
        return false
    end
end

-- insta win all the campaigns
function InstaWin()
    for camp, ops in campaignSequence do
        for index, op in ops do
            for diff = 1,3 do
                local ov = {
                    campaignID = camp,
                    opKey = op,
                    success = true,
                    difficulty = diff,
                    allPrimary = true,
                    allSecondary = true,
                }
                OperationVictory(ov, true)
            end
        end
    end
end

-- kept for mod backwards compatibility
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap