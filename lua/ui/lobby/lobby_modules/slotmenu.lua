--*****************************************************************************
--* File: lua/ui/lobby/slotmenu.lua
--* Summary: Pure slot menu data/builder utilities extracted from lobby.lua
--*****************************************************************************


local slotMenuStrings = {
    open = "<LOC lobui_0219>Open",
    close = "<LOC lobui_0220>Close",
    closed = "<LOC lobui_0221>Closed",
    occupy = "<LOC lobui_0222>Occupy",
    pm = "<LOC lobui_0223>Private Message",
    remove_to_kik = "<LOC lobui_0428>Kick Player",
    remove_to_observer = "<LOC lobui_0429>Move Player to Observer",
    close_spawn_mex = "<LOC lobui_0431>Close - spawn mex",
    closed_spawn_mex = "<LOC lobui_0432>Closed - spawn mex",
}

local baseSlotMenuData = {
    open = {
        host = {
            'close',
            'occupy',
            'ailist',
        },
        client = {
            'occupy',
        },
    },
    closed = {
        host = {
            'open',
        },
        client = {},
    },
    player = {
        host = {
            'pm',
            'remove_to_observer',
            'remove_to_kik',
            'move'
        },
        client = {
            'pm',
        },
    },
    ai = {
        host = {
            'remove_to_kik',
            'ailist',
        },
        client = {},
    },
}

local function deepcopy(tbl)
    local result = {}
    for k, v in tbl do
        if type(v) == "table" then
            result[k] = deepcopy(v)
        else
            result[k] = v
        end
    end
    return result
end

function GetData(adaptiveMap)
    local data = deepcopy(baseSlotMenuData)

    if adaptiveMap then
        data.closed_spawn_mex = {
            host = {
                'open',
                'close',
            },
            client = {},
        }

        table.insert(data.open.host, 2, 'close_spawn_mex')
        table.insert(data.closed.host, 2, 'close_spawn_mex')
    end

    return data
end

function Build(stateKey, hostKey, options)
    local menuData = GetData(options.adaptiveMap)

    local keys = {}
    local strings = {}
    local tooltips = {}

    if not menuData[stateKey] then
        WARN("Invalid slot menu state selected: " .. tostring(stateKey))
        return nil
    end

    if not menuData[stateKey][hostKey] then
        WARN("Invalid slot menu host key selected: " .. tostring(hostKey))
        return nil
    end

    for _, key in menuData[stateKey][hostKey] do

        if key == 'ailist' then

            if options.slotNum then
                for i = 1, options.numOpenSlots do
                    if i ~= options.slotNum then
                        table.insert(keys, 'move_player_to_slot' .. i)
                        table.insert(strings, LOCF("<LOC lobui_0607>Move AI to slot %s", i))
                        table.insert(tooltips, nil)
                    end
                end
            end

            table.destructiveCat(keys, options.AIKeys or {})
            table.destructiveCat(strings, options.AIStrings or {})
            table.destructiveCat(tooltips, options.AITooltips or {})

        elseif key == 'move' then

            for i = 1, options.numOpenSlots do
                if i ~= options.slotNum then
                    table.insert(keys, 'move_player_to_slot' .. i)
                    table.insert(strings, LOCF("<LOC lobui_0596>Move Player to slot %s", i))
                    table.insert(tooltips, nil)
                end
            end

        else

            if not (options.isPlayerReady and key == 'occupy') then
                table.insert(keys, key)
                table.insert(strings, slotMenuStrings[key])
                table.insert(tooltips, nil)
            end
        end
    end

    return keys, strings, tooltips
end

function GetStrings()
    return slotMenuStrings
end

