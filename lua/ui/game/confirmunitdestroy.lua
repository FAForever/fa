
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')

local destructingUnits = {}
local controls = {}
local countdownThreads = {}

function ConfirmUnitDestruction()
    if import('/lua/ui/campaign/campaignmanager.lua').campaignMode and table.getn(EntityCategoryFilterDown(categories.COMMAND, GetSelectedUnits())) > 0 then
        UIUtil.QuickDialog(GetFrame(0), '<LOC confirm_0001>You cannot self destruct during an operation!', '<LOC _Ok>', nil, 
            nil,  nil, 
            nil, nil,
            true, {worldCover = false, enterButton = 1, escapeButton = 1})
    else
        local units = GetSelectedUnits()

        if units then
            local dialogue = nil

            if options.confirm_self_destruct == 1 and table.getn(EntityCategoryFilterDown(categories.COMMAND, units)) > 0 then
                dialogue = '<LOC confirm_0002>You are going to self destruct your ACU, are you sure?'
            elseif options.confirm_self_destruct == 2 and table.getn(EntityCategoryFilterDown(categories.COMMAND, units)) > 0 then
                dialogue = '<LOC confirm_0003>Your ACU is among the selected units for self destruction, do you wish to proceed?'
            elseif options.confirm_self_destruct == 2 then
                dialogue = '<LOC confirm_0004>Are you sure you wish to destroy the selected unit(s)?'
            end

            if dialogue then
                UIUtil.QuickDialog(GetFrame(0), dialogue, 
                '<LOC _Yes>', function()
                    local unitIds = {}
                    for _, unit in units do
                        table.insert(unitIds, unit:GetEntityId())
                    end
                    SimCallback({Func = 'ToggleSelfDestruct', Args = {units = unitIds, owner = GetFocusArmy()}})
                end,
                '<LOC _No>', nil,
                nil, nil,
                true, {worldCover = false, enterButton = 1, escapeButton = 2})
            else
                local unitIds = {}
                for _, unit in units do
                    table.insert(unitIds, unit:GetEntityId())
                end
                SimCallback({Func = 'ToggleSelfDestruct', Args = {units = unitIds, owner = GetFocusArmy()}})
            end
        end
    end
end