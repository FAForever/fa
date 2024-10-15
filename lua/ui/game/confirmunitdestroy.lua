-- Copyright GPG 2007

local CreateAnnouncement = import("/lua/ui/game/announcement.lua").CreateAnnouncement

---@param instant boolean
function ConfirmUnitDestruction(instant)

    if -- do not allow self destructing of command units in campaign
    import("/lua/ui/campaign/campaignmanager.lua").campaignMode and
        not table.empty(EntityCategoryFilterDown(categories.COMMAND, GetSelectedUnits()))
    then
        CreateAnnouncement('<LOC confirm_0001>You cannot self destruct during an operation!')
    else
        SimCallback({ Func = 'ToggleSelfDestruct', Args = { owner = GetFocusArmy(), noDelay = instant } }, true)
    end
end
