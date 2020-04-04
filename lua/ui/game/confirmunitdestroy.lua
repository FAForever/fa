-- Copyright GPG 2007

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Prefs = import('/lua/user/prefs.lua')
local CreateAnnouncement = import('/lua/ui/game/announcement.lua').CreateAnnouncement

local destructingUnits = {}
local controls = {}
local countdownThreads = {}

function ConfirmUnitDestruction(instant)
    if import('/lua/ui/campaign/campaignmanager.lua').campaignMode
    and table.getn(EntityCategoryFilterDown(categories.COMMAND, GetSelectedUnits())) > 0 then
        CreateAnnouncement('<LOC confirm_0001>You cannot self destruct during an operation!')
    else
        local units = GetSelectedUnits()
        if units then
            local unitIds = {}
            for _, unit in units do
                table.insert(unitIds, unit:GetEntityId())
            end
            SimCallback({Func = 'ToggleSelfDestruct', Args = {units = unitIds, owner = GetFocusArmy(), noDelay = instant}})
        end
    end
end
