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

--- Returns true if the give about to happen should warn the player about losing their ACU.
---@return boolean
function ShouldWarnACU()
    local scenarioInfo = SessionGetScenarioInfo()
    local acuTransfer = scenarioInfo and scenarioInfo.Options and scenarioInfo.Options.ACUTransfer
    return acuTransfer == 'free' and SelectionContainsOwnACU() and TransferWouldCauseDefeat()
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
