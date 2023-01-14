local Prefs = import("/lua/user/prefs.lua")

---@alias SelectionSetDoubleTapBehavior
--- | 'none'                        # When you double tap it will have no effect
--- | 'translate-zoom'              # When you double tap the camera translates and zooms to the units, default behavior
--- | 'translate-zoom-out-only'     # When you double tap the camera translates and zooms to the units, but it won't zoom in
--- | 'translate'                   # When you double tap the camera only translates

-- used to re-use memory where possible
local cache = {}
local cacheHead = 1

-- needs to be global in order to be saved
selectionSets = {}
selectionSetCallbacks = {}

local lastSelectionName = nil
local lastSelectionTime = 0

local playSelectionSound = true

--- Enables or disables the sound played upon selecting units
---@param flag boolean
function EnableSelectionSound(flag)
    playSelectionSound = flag
end

--- Attempts to play the selection sound, performs an early exit when it should not be played
---@param newSelection UserUnit[]
function PlaySelectionSound(newSelection)
    if playSelectionSound then
        for k, v in newSelection do
            local bp = v:GetBlueprint()
            if bp.Audio.UISelection then
                PlaySound(bp.Audio.UISelection)
                return
            end
        end
    end
end

local hidden_select = false
function IsHidden()
    return hidden_select == true
end

function Hidden(callback)
    local CM = import("/lua/ui/game/commandmode.lua")
    local current_command = CM.GetCommandMode()
    local old_selection = GetSelectedUnits() or {}

    hidden_select = true
    callback()
    SelectUnits(old_selection)
    CM.StartCommandMode(current_command[1], current_command[2])
    hidden_select = false
end


--- Registers a callback that is called when a selection is set (flag set to false) and when it is used (flag set to true)
---@param func function<UserUnit[], boolean>
function RegisterSelectionSetCallback(func)
    -- see if this function is already in here
    for i, v in selectionSetCallbacks do
        if v == func then
            return
        end
    end

    table.insert(selectionSetCallbacks, func)
end

--- Removes a callback that is called when a selection is set
---@param func function<UserUnit[], boolean>
function WithdrawSelectionSetCallback(func)
    for i, v in selectionSetCallbacks do
        if v == func then
            table.remove(selectionSetCallbacks, i)
            return
        end
    end
end

--- Removes all entries from a hash-based table, returns the hash-based table
---@param hash table<UserUnit, boolean>
---@return table<UserUnit, boolean>
local function EmptyHash(hash)
    for unit, _ in hash do
        hash[unit] = nil
    end

    return hash
end

--- Converts an array-based table to a hash-based table, returns the cache
---@param array UserUnit[]
---@param cache table<UserUnit, boolean>
---@return table<UserUnit, boolean>
local function ToHash(array, cache)
    for _, unit in array do
        cache[unit] = true
    end

    return cache
end

--- Removes all entries from an array-based table, returns the array-based table
---@param array UserUnit[]
---@return UserUnit[]
local function EmptyArray(array)
    for k = 1, cacheHead do
        array[k] = nil
    end

    cacheHead = 1

    return array
end

--- Converts an hash-based table to an array-based table, returns the cache
---@param hash table<UserUnit, boolean>
---@param cache UserUnit[]
---@return UserUnit[]
local function ToArray(hash, cache)
    for unit, _ in hash do
        cache[cacheHead] = unit
        cacheHead = cacheHead + 1
    end

    return cache
end

--- Manages and applies the double tap behavior
---@param units any
local function DoubleTapBehavior(name, units)

    ---@type SelectionSetDoubleTapBehavior
    local doubleTapbehavior = Prefs.GetFromCurrentProfile('options.selection_sets_double_tap_behavior')

    -- don't do anything
    if doubleTapbehavior == 'none' then
        return
    end

    -- time window in which we consider it to be a double tab
    local curTime = GetSystemTimeSeconds()
    local diffTime = curTime - lastSelectionTime
    if diffTime > 0.001 * Prefs.GetFromCurrentProfile('options.selection_sets_double_tap_decay') then
        lastSelectionName = nil
    end
    lastSelectionTime = curTime

    -- move camera to the selection in the case of a double tab
    if name == lastSelectionName then

        if next(units) then

            -- retrieve camera and its settings
            local cam = GetCamera('WorldCamera')
            local settings = cam:SaveSettings()

            UIZoomTo(units)

            -- only zoom out, but not in
            if doubleTapbehavior == 'translate-zoom-out-only' then
                local zoom = cam:GetZoom()
                if zoom < settings.Zoom then
                    cam:SetZoom(settings.Zoom, 0)
                end

                -- do not adjust the zoom
            elseif doubleTapbehavior == 'translate' then
                cam:SetZoom(settings.Zoom, 0)
            end

            -- guarantee it looks like it should
            cam:RevertRotation()
        end

        lastSelectionName = nil
    else
        lastSelectionName = name
    end
end

--- Processes the selection set from its hash-based layout to an index-based layout
---@param name string
---@return UserUnit[]
local function ProcessSelectionSet(name)

    -- guarantee one exists
    selectionSets[name] = selectionSets[name] or {}

    -- clear out the cache
    EmptyArray(cache)
    local aUnits = ToArray(selectionSets[name], cache)

    -- validate units
    local aValidUnits = ValidateUnitsList(aUnits)

    -- clean up the cache
    EmptyHash(selectionSets[name])
    ToHash(aValidUnits, selectionSets[name])

    return aValidUnits
end

--- Add a unit to an existing selection set, called by the engine to add units that are being built to the selection group of the factory. The function userunit:AddSelectionSet(name) has already been applied at this point
---@param name string | number
---@param unit UserUnit
function AddUnitToSelectionSet(name, unit)

    -- bug where name is an index, not a key
    name = tostring(name)

    if Prefs.GetFromCurrentProfile('options.add_to_factory_control_group') then

        -- remove it from existing selection sets
        if Prefs.GetFromCurrentProfile('options.steal_from_other_control_groups') then
            local others = unit:GetSelectionSets()
            for k, other in others do
                if selectionSets[other] then
                    unit:RemoveSelectionSet(other)
                    selectionSets[other][unit] = nil
                end
            end
        end

        -- guarantee that a table exists
        selectionSets[name] = selectionSets[name] or {}
        selectionSets[name][unit] = true
        unit:AddSelectionSet(name)
    else
        unit:RemoveSelectionSet(name)
    end
end

--- Replaces the selection set with the provided units
---@param name string | number
---@param unitArray UserUnit[]
function AddSelectionSet(name, unitArray)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- guarantee that a table exists
    selectionSets[name] = selectionSets[name] or {}

    -- remove the current units in the set
    for unit, _ in selectionSets[name] do
        unit:RemoveSelectionSet(name)
        selectionSets[name][unit] = nil
    end

    -- add the new units to the set
    if unitArray then
        for _, unit in unitArray do

            -- remove it from existing selection sets
            if Prefs.GetFromCurrentProfile('options.steal_from_other_control_groups') then
                local others = unit:GetSelectionSets()
                for k, other in others do
                    unit:RemoveSelectionSet(other)
                    selectionSets[other][unit] = nil
                end
            end

            unit:AddSelectionSet(name)
            selectionSets[name][unit] = true
        end
    end

    -- peform selection set callbacks
    for i, v in selectionSetCallbacks do
        v(name, unitArray, false)
    end
end

--- Adds the current selection to the selection set
---@param name string | number
function AddCurrentSelectionSet(name)
    AddSelectionSet(name, GetSelectedUnits())
end

local oldSelection = {}

--- Selects the selection set provided
---@param name string | number
function ApplySelectionSet(name)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- validate units, remove the ones that got transformed into wrecks
    local aValidUnits = ProcessSelectionSet(name)
    local aSelection = EntityCategoryFilterDown(categories.ALLUNITS - (categories.FACTORY - categories.MOBILE),
        aValidUnits)
    if table.getsize(aSelection) == 0 then
        aSelection = EntityCategoryFilterDown(categories.FACTORY - categories.MOBILE, aValidUnits)
        if table.getsize(aSelection) == 0 then
            AddSelectionSet(name, nil)
            return
        end
    end

    oldSelection = GetSelectedUnits()
    SelectUnits(aSelection)
    DoubleTapBehavior(name, aSelection)

    -- perform callbacks
    for i, v in selectionSetCallbacks do
        v(name, aSelection, true)
    end
end

--- Reverts the selection to the one before applying (recalling) a selection set
function RevertSelectionSet()
    local aValidUnits = ValidateUnitsList(oldSelection)
    SelectUnits(aValidUnits)

    -- prevent accidental double tab
    lastSelectionName = nil
end

--- Attempts to select the factories of the selection set
---@param name string | number
function FactorySelection(name)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- validate units, remove the ones that got transformed into wrecks
    local aValidUnits = ProcessSelectionSet(name)
    local aSelection = EntityCategoryFilterDown(categories.FACTORY, aValidUnits)

    oldSelection = GetSelectedUnits()
    SelectUnits(aSelection)
end

--- Appends the selection set to the selection
---@param name string | number
function AppendSetToSelection(name)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- retrieve the two groups of units
    local aValidUnits = ProcessSelectionSet(name)
    local aSelectedUnits = GetSelectedUnits()

    if aSelectedUnits then

        -- append the selection set
        for k, unit in aValidUnits do
            table.insert(aSelectedUnits, unit)
        end

        -- select them together
        SelectUnits(aSelectedUnits)
        DoubleTapBehavior(aSelectedUnits)
    end
end

--- Appends the selection to the selection set
---@param name string | number
function AppendSelectionToSet(name)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- retrieve the two groups of units
    local aValidUnits = ProcessSelectionSet(name)
    local aSelectedUnits = GetSelectedUnits()

    if aSelectedUnits then

        -- append the selection set
        for k, unit in aValidUnits do
            table.insert(aSelectedUnits, unit)
        end

        -- turn that into the new selection set
        AddSelectionSet(name, aSelectedUnits)
        DoubleTapBehavior(aSelectedUnits)
    end
end

--- Adds the selection to the selection set and selects the entire selection set
---@param name string | number
function CombineSelectionAndSet(name)

    -- bug where name is an index, not a key
    name = tostring(name)

    -- retrieve the two groups of units
    local aValidUnits = ProcessSelectionSet(name)
    local aSelectedUnits = GetSelectedUnits()

    if aSelectedUnits then

        -- append the selection set
        for k, unit in aValidUnits do
            table.insert(aSelectedUnits, unit)
        end

        -- turn that into the new selection set and select it
        AddSelectionSet(name, aSelectedUnits)
        SelectUnits(aSelectedUnits)
        DoubleTapBehavior(aSelectedUnits)
    end
end

local OldSelection = { }
local Splits = { }
local SplitCount = 0
local SplitCurrent = 0

local function SelectSplit(units)
    import("/lua/ui/game/commandmode.lua").CacheCommandMode()
    SelectUnits(units)
    import("/lua/ui/game/commandmode.lua").RestoreCommandMode()
end

--- Select the next split, or return to the old selection if there are no next splits. Preserves the command mode
function SplitNext()
    SplitCurrent = SplitCurrent + 1
    if SplitCurrent > SplitCount then
        SelectSplit(OldSelection)
        return
    end

    SelectSplit(Splits[SplitCurrent])
end

--- Select the previous split, or return to the old selection if there are no previous splits. Preserves the command mode
function SplitPrevious()
    SplitCurrent = SplitCurrent - 1
    if SplitCurrent < 1 then
        SelectSplit(OldSelection)
        return
    end

    SelectSplit(Splits[SplitCurrent])
end

--- Computes the center position of a set of units
---@param units UserUnit[]
---@return number x component of center
---@return number z component of center
local function GetCenter(units)
    local cx, cz = 0, 0
    local n = table.getn(units)
    for i = 1, n do
        local pos = units[i]:GetPosition()
        cx = cx + pos[1]
        cz = cz + pos[3]
    end

    cx = cx / n
    cz = cz / n

    return cx, cz
end

--- Computes the two eigen vectors based on the x and z coordinates of each unit
--- https://en.wikipedia.org/wiki/Principal_component_analysis
---@param units UserUnit[]
---@return Vector2 principle
---@return Vector2 secondary
---@return number
---@return number
local function GetPrincipleComponents(units)
    -- calculate means
    local cx, cz = GetCenter(units)

    -- calculate covariance
    local covar, numer = 0, 0
    for i = 1, table.getn(units) do
        local pos = units[i]:GetPosition()
        local xadj = pos[1] - cx
        local zadj = pos[3] - cz
        covar = covar + zadj*zadj - xadj*xadj
        numer = numer + xadj * zadj
    end
    covar = covar / (2 * numer)

    -- calculate eigenvectors
    local orth = math.sqrt(covar*covar + 1)
    local minor = {covar + orth, 1}
    local major = {covar - orth, 1}

    return minor, major, cx, cz
end

--- Splits the table of units into two tables, using the axis as the divider
---@param units UserUnit[]
---@param ax number x component of axis
---@param az number z component of axis
---@param cx number x component of center
---@param cz number z component of center
function SplitOverAxis(units, ax, az, cx, cz)

    local a1, a2 = {}, {}
    for k, unit in units do
        -- direction to center
        local pos = unit:GetPosition()
        local dx = pos[1] - cx
        local dz = pos[3] - cz

        -- normalize
        local l = dx * dx + dz * dz
        dx = 1 / l * dx
        dz = 1 / l * dz

        -- determine dot product sign
        if dx * ax + dz * az < 0 then
            table.insert(a1, unit)
        else
            table.insert(a2, unit)
        end
    end

    OldSelection = units
    SplitCurrent = 1
    SplitCount = 2
    Splits = {
        a1, a2
    }

    SelectSplit(a1)
end

--- Splits the current selection into two sets by using the major axis as the divider
function SplitMajorAxis()
    ---@type UserUnit[]
    local units = GetSelectedUnits()
    local minor, major, cx, cz = GetPrincipleComponents(units)
    SplitOverAxis(units, major[1], major[2], cx, cz)
end

--- Splits the current selection into two sets by using the minor axis as the divider
function SplitMinorAxis()
    ---@type UserUnit[]
    local units = GetSelectedUnits()
    local minor, major, cx, cz = GetPrincipleComponents(units)
    SplitOverAxis(units, minor[1], minor[2], cx, cz)
end

--- Splits the current selection into two sets by dividing it with the line between the mouse location and the center of the selection
function SplitMouseAxis()
    ---@type UserUnit[]
    local units = GetSelectedUnits()
    local cx, cz = GetCenter(units)
    local mouse = GetMouseWorldPos()

    local ax = cx - mouse[1]
    local az = cz - mouse[3]

    SplitOverAxis(units, az, -1 * ax, cx, cz)
end

--- Splits the current selections into two sets by dividing it with the line orthogonal with the line between the mouse location and the center of the selection
function SplitMouseOrthogonalAxis()
    ---@type UserUnit[]
    local units = GetSelectedUnits()
    local cx, cz = GetCenter(units)
    local mouse = GetMouseWorldPos()

    local ax = cx - mouse[1]
    local az = cz - mouse[3]

    SplitOverAxis(units, ax, az, cx, cz)
end