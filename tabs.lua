do
    local objEntry = {action = 'ShowObj', label='<LOC _Show_Scenario_Info>Scenario', tooltip = 'show_scenario'}
    table.insert(menus.main.replay, 3, objEntry)
    table.insert(menus.main.lan, 2, objEntry)
    table.insert(menus.main.gpgnet, 2, objEntry)
    table.insert(menus.main.singlePlayer, 4, objEntry)

    actions.ShowObj = function() import("/lua/ui/game/objectiveDetail.lua").ToggleDisplay() end
end
