--******************************************************************************************************
--** Helpers shared by the unit-give paths for the "Free ACU Transfer" lobby option.
--**
--** When free ACU transfer is enabled a player can hand their ACU to an ally. In Assassination this
--** means giving away your ACU defeats you, so we show a confirmation first. In every other victory
--** condition losing the ACU does not, by itself, defeat you, so no extra warning is shown.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")

--- Returns true if the local player's current selection contains their own ACU.
---@return boolean
function SelectionContainsOwnACU()
    local selection = GetSelectedUnits()
    if not selection then
        return false
    end
    for _, unit in selection do
        if EntityCategoryContains(categories.COMMAND, unit) then
            return true
        end
    end
    return false
end

--- Returns true if giving away the ACU would immediately defeat the player.
--- Only Assassination (demoralization) makes "no ACU" an unconditional, instant defeat.
---@return boolean
function TransferWouldCauseDefeat()
    local scenarioInfo = SessionGetScenarioInfo()
    local victory = scenarioInfo and scenarioInfo.Options and scenarioInfo.Options.Victory
    if victory == 'demoralization' then
        return true
    end
    -- In Supremacy (domination) the ACU counts as an engineer, so giving it away can defeat you
    -- if it was your last structure/engineer. Uncomment to warn there too:
    -- if victory == 'domination' then return true end
    return false
end

--- Returns true if this is a campaign or co-op mission, where ACU transfer is disabled because
--- missions have scripted commanders and army logic that a transfer could break.
---@return boolean
function InCampaign()
    return import("/lua/ui/campaign/campaignmanager.lua").campaignMode == true
end

--- Returns true if free ACU transfer is actually usable this game. It requires the option to
--- be set to 'free', a share condition that keeps a transferred ACU with the recipient, and a
--- non-campaign game. Under the other share conditions a manually shared ACU is destroyed or
--- reclaimed when the giver dies, which would undo the transfer, so the option is ignored there.
---@return boolean
function FreeTransferEnabled()
    local scenarioInfo = SessionGetScenarioInfo()
    local options = scenarioInfo and scenarioInfo.Options
    if not options or options.ACUTransfer ~= 'free' then
        return false
    end
    if InCampaign() then
        return false
    end
    local share = options.Share
    return share == 'FullShare' or share == 'PartialShare'
end

--- If free ACU transfer is selected but this is a campaign mission and the player is trying to
--- give their own ACU, shows an on-screen message and returns true so the caller aborts the give.
---@return boolean
function BlockACUTransferInCampaign()
    local scenarioInfo = SessionGetScenarioInfo()
    local options = scenarioInfo and scenarioInfo.Options
    if options and options.ACUTransfer == 'free' and InCampaign() and SelectionContainsOwnACU() then
        print(LOC("<LOC acu_transfer_campaign_01>ACU transfer is not possible in campaign missions."))
        return true
    end
    return false
end

--- Returns true if the give about to happen should warn the player about losing their ACU.
---@return boolean
function ShouldWarnACU()
    return FreeTransferEnabled() and SelectionContainsOwnACU() and TransferWouldCauseDefeat()
end

--- Runs `onConfirm` directly, unless an ACU-loss warning is warranted, in which case a
--- confirmation dialog is shown first and `onConfirm` only runs if the player accepts.
---@param onConfirm function
function MaybeConfirmACUTransfer(onConfirm)
    if ShouldWarnACU() then
        UIUtil.QuickDialog(GetFrame(0),
            "<LOC acu_transfer_warn_01>You are about to give away your ACU. If you have no ACU left you will be defeated. Continue?",
            "<LOC _Yes>", onConfirm,
            "<LOC _No>", nil,
            nil, nil, nil,
            { worldCover = false, enterButton = 1, escapeButton = 2 }
        )
    else
        onConfirm()
    end
end
