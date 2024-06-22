-- Copyright GPG 2007

local CreateAnnouncement = import("/lua/ui/game/announcement.lua").CreateAnnouncement

---@param instant boolean
---@param allUnits boolean
function ConfirmUnitDestruction(instant, allUnits)
    local units = GetSelectedUnits()


    if -- do not allow self destructing of command units
    import("/lua/ui/campaign/campaignmanager.lua").campaignMode and
        not table.empty(EntityCategoryFilterDown(categories.COMMAND, units))
    then
        CreateAnnouncement('<LOC confirm_0001>You cannot self destruct during an operation!')
    else
        SimCallback({ Func = 'ToggleSelfDestruct',
            Args = { owner = GetFocusArmy(), noDelay = instant, allUnits = allUnits } }, true)
    end
end
