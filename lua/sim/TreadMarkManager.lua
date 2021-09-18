
--- Allows the unit to spawn tread marks accordingly.
-- @param entity The unit to spawn tread marks for.
-- @param interval How often the tread marks should spawn.
-- @param bone The bone where they should spawn.
-- @param type The texture / splat type of the tread marks.
-- @param sx The size of the texture / splat.
-- @param sy The size of the texture / splat.
-- @param offset An offset table.
function KeepTrack(entity, interval, bone, type, sx, sy, offset)

end

--- Add a tread creator to the tinker accordingly
local AddTinker1, AddTinker2, AddTinker3, AddTinker4, AddTinker5, AddTinker6, AddTinker7, AddTinker8, AddTinker9, AddTinker10

--- Keeps track of the forked threads
local Forks = { }

-- MISCELLANEOUS FUNCTIONS -- 

-- {2, 1, 2, nil, 3, nil, 2, 1, nil, }


local function Cleanup(t, c)
    local f = 1 
    for k = 1, c do 
        -- check if the table element exists
        if t[k] then 
            t[f] = t[k]
            f = f + 1
        end
    end

    return t, f 
end

-- TINKER 2 --

do 

    -- next / layers for quick adding
    local n1, n2 = 1, 1
    local l1, l2 = { }, { }

    

    --- Adds 
    AddTinker2 = function(entity, interval, bone, type, sx, sy, offset)
        -- attempt to retrieve the table
        local data = l1[n1]
        if not data then 
            data = { }
        end

        -- set all the data
        data.Entity = entity,
        data.Bone = bone,
        data.Type = type,
        data.SizeX = sx, 
        data.SizeY = sy,
        data.Offset = offset

        -- store it and update next
        l1[n1] = data 
        n1 = n1 + 1
    end

    local Tinker = function()

        local temp = false 

        while true do 

            

            WaitTicks(2)
        end
    end

    Forks[2] = ForkThread(Tinker)

end 
