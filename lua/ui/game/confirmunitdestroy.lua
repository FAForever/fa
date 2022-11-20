-- Copyright GPG 2007

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Prefs = import("/lua/user/prefs.lua")
local CreateAnnouncement = import("/lua/ui/game/announcement.lua").CreateAnnouncement

local destructingUnits = {}
local controls = {}
local countdownThreads = {}

function ConfirmUnitDestruction(instant)

    -- get selected units
    local units = GetSelectedUnits()

    if  
        -- if we're in campaign mode
        import("/lua/ui/campaign/campaignmanager.lua").campaignMode  

        -- and we're trying to self destruct a command unit
        and not table.empty(EntityCategoryFilterDown(categories.COMMAND, units)) 
    then
        -- don't allow that, as it would end the operation
        CreateAnnouncement('<LOC confirm_0001>You cannot self destruct during an operation!')
    else
        -- do the callback accordingly
        SimCallback({Func = 'ToggleSelfDestruct', Args = { owner = GetFocusArmy(), noDelay = instant }}, true)
    end
end
