do
    local objEntry = {action = 'ShowObj', label='<LOC _Show_Scenario_Info>Scenario', tooltip = 'show_scenario'}
    table.insert(menus.main.replay, 4, objEntry)
    table.insert(menus.main.lan, 3, objEntry)
    table.insert(menus.main.gpgnet, 3, objEntry)
    table.insert(menus.main.singlePlayer, 5, objEntry)

    actions.ShowObj = function() import("/lua/ui/game/objectiveDetail.lua").ToggleDisplay() end
end
