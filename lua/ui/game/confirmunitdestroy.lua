-- Copyright GPG 2007

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Prefs = import('/lua/user/prefs.lua')
local CreateAnnouncement = import('/lua/ui/game/announcement.lua').CreateAnnouncement

local destructingUnits = {}
local controls = {}
local countdownThreads = {}
local scenarioInfo = SessionGetScenarioInfo()

function ConfirmUnitDestruction(instant)
    local selUnits = GetSelectedUnits() or {}
    if (scenarioInfo.Options.CheatsEnabled == 'false') and (table.getn(EntityCategoryFilterDown(categories.COMMAND, selUnits)) > 0)
        and (scenarioInfo.Options.Share == 'TransferToKiller') then
        CreateAnnouncement('<LOC confirm_0001>You cannot self destruct during an operation!')
    else
        if selUnits then
            local unitIds = {}
            for _, unit in selUnits do
                table.insert(unitIds, unit:GetEntityId())
            end
            SimCallback({Func = 'ToggleSelfDestruct', Args = {units = unitIds, owner = GetFocusArmy(), noDelay = instant}})
        end
    end
end
