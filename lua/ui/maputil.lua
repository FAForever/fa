-- Hooking GetStartPositions

-- given a scenario table, loads the save file and puts all the start positions in a table
-- I've made this function so it works with the old data format and the new
-- Returning an empty table means scenario data was ill formed
function GetStartPositions(scenario)
    local saveData = {}
    doscript('/lua/dataInit.lua', saveData)
    
    if not scenario.save then
        WARN('No save file found for selected map')
        return {}
    end
    
    doscript(scenario.save, saveData)

    local armyPositions = {}

    -- try new data first
    if scenario.Configurations.standard and scenario.Configurations.standard.teams then
        -- find the "FFA" team
        for index, teamConfig in scenario.Configurations.standard.teams do
            if teamConfig.name and (teamConfig.name == 'FFA') then
                for armyIndex, armyName in teamConfig.armies do
                    armyPositions[armyName] = {}
                end
                break
            end
        end
        if table.getsize(armyPositions) == 0 then
            WARN("Unable to find FFA configuration in " .. scenario.file)
        end
    end

    -- try old data if nothing added to army positions
    if table.getsize(armyPositions) == 0 then
        -- figure out all the armies in this map
        -- make sure old data is there
        if scenario.Games then
            for index, game in scenario.Games do
                for k, army in game do
                    armyPositions[army] = {}
                end
            end
        end
    end

    -- if we found armies, then get the positions
    if table.getsize(armyPositions) > 0 then
        for army, position in armyPositions do
            if saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers[army] then
                pos = saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers[army].position
                -- x and z value are of interest so ignore y (index 2)
                position[1] = pos[1]
                position[2] = pos[3]
            else
                WARN("No initial position marker for army " .. army .. " found in " .. scenario.save)
                position[1] = 0
                position[2] = 0
            end
        end
    else
        WARN("No start positions defined in " .. scenario.file)
    end

    return armyPositions
end
