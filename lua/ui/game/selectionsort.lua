local techCats = {
    [1] = "TECH1",
    [2] = "TECH2",
    [3] = "TECH3",
    [4] = "EXPERIMENTAL",
}

-- TODO: refactor this for better performance :)))
function insertIntoTableLowestTechFirst(units, t, isLowFuel, isIdleCon)


    local didInsert = false
    local isPut = false
    for _, tech in techCats do
        for i, v in units do
            if v[1]:IsInCategory(tech) then
                table.insert(t, { type = 'unitstack', id = i, units = v, lowFuel = isLowFuel, idleCon = isIdleCon })
                units[i] = nil
                isPut = true
                didInsert = true
            end
        end
    end

    -- Adding units without TECH category
    for i, v in units do
        table.insert(t, { type = 'unitstack', id = i, units = v, lowFuel = isLowFuel, idleCon = isIdleCon })
    end

    return t, didInsert
end
