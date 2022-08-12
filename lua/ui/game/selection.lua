
---@alias SelectionSetDoubleTapBehavior
--- | 'none'                        # When you double tap it will have no effect
--- | 'translate-zoom'              # When you double tap the camera translates and zooms to the units, default behavior
--- | 'translate-zoom-if-lower'     # When you double tap the camera translates and zooms to the units, but it won't zoom in
--- | 'translate'                   # When you double tap the camera only translates

---@alias SelectionSetAppendBehavior
--- | 'add-selection-set-to-selection'          # Adds the selection set to the current selection
--- | 'add-selection-to-selection-set'          # Adds the current selection to the selection set
--- | 'combine-and-select-with-selection-set'   # Adds the current selection to the selection set and selects the new selection set

-- used to re-use memory where possible
local cache = { }
local cacheHead = 1

-- needs to be global in order to be saved
selectionSets = {}
local selectionSetCallbacks = {}
local lastSelectionName = nil
local lastSelectionTime = 0
local lastSelectionDecay = 0.2                          -- adjustable via options -> interface

-- allows you to tweak functionality
local stealFromOtherSelectionSets = true                -- adjustable via options -> interface
local addProducedUnitToSelectionSet = true              -- adjustable via options -> interface

---@type SelectionSetDoubleTapBehavior
local doubleTapbehavior = 'translate-zoom-if-lower'     -- adjustable via options -> interface

---@type SelectionSetAppendBehavior
local appendBehavior = 'add-selection-set-to-selection' -- adjustable via options -> interface

local playSelectionSound = true

--- Enables or disables the sound played upon selecting
---@param flag any
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

--- Registers a callback that is called when a selection is set (flag set to false) and when it is used (flag set to true)
---@param func function<UserUnit[], boolean>
function RegisterSelectionSetCallback(func)
    -- see if this function is already in here
    for i,v in selectionSetCallbacks do
        if v == func then
            return
        end
    end

    table.insert(selectionSetCallbacks, func)
end

--- Removes a callback that is called when a selection is set
---@param func function<UserUnit[], boolean>
function WithdrawSelectionSetCallback(func)
    for i,v in selectionSetCallbacks do
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

    -- don't do anything
    if doubleTapbehavior == 'none' then
        return
    end

    -- time window in which we consider it to be a double tab
    local curTime = GetSystemTimeSeconds()
    local diffTime = curTime - lastSelectionTime
    if diffTime > lastSelectionDecay then
        lastSelectionName = nil
    end
    lastSelectionTime = curTime

    -- move camera to the selection in the case of a double tab
    if name == lastSelectionName then

        -- retrieve camera and its settings
        local cam = GetCamera('WorldCamera')
        local settings = cam:SaveSettings()

        UIZoomTo(units)

        -- only zoom out, but not in
        if doubleTapbehavior == 'translate-zoom-if-lower' then
            local zoom = cam:GetZoom()
            if zoom < settings.Zoom then 
                cam:SetZoom(settings.Zoom, 0)
            end

        -- do not adjust the zoom
        elseif doubleTapbehavior == 'translate' then
            cam:SetZoom(settings.Zoom, 0)
        end

        -- always revert to the default rotation
        -- cam:RevertRotation()

        lastSelectionName = nil
    else
        lastSelectionName = name
    end
end

local function ProcessSelectionSet(name)
   -- clear out the cache
   EmptyArray(cache)
   local aUnits = ToArray(selectionSets[name], cache)

   -- validate units
   return ValidateUnitsList(aUnits)
end

--- Add a unit to an existing selection set, called by the engine to add units that are being built to the selection group of the factory. The function userunit:AddSelectionSet(name) has already been applied at this point
---@param name string
---@param unit UserUnit
function AddUnitToSelectionSet(name, unit)
    if addProducedUnitToSelectionSet then
        -- remove it from existing selection sets
        if stealFromOtherSelectionSets then
            local others = unit:GetSelectionSets()
            for k, other in others do
                selectionSets[name][unit] = nil
            end
        end

        -- guarantee that a table exists
        selectionSets[name] = selectionSets[name] or { }
        selectionSets[name][unit] = true
    end
end

--- Replaces the selection set with the provided units
---@param name string
---@param unitArray UserUnit[]
function AddSelectionSet(name, unitArray)

    -- guarantee that a table exists
    selectionSets[name] = selectionSets[name] or { }

    -- remove the current units in the set
    for unit, _ in selectionSets[name] do
        unit:RemoveSelectionSet(name)
        selectionSets[name][unit] = nil
    end

    -- add the new units to the set
    if unitArray then
        for _, unit in unitArray do

            -- remove it from existing selection sets
            if stealFromOtherSelectionSets then
                local others = unit:GetSelectionSets()
                reprsl(others)
                for k, other in others do 
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
---@param name string
function AddCurrentSelectionSet(name)
    AddSelectionSet(name, GetSelectedUnits())
end

--- Selects the selection set provided
---@param name string
function ApplySelectionSet(name)
    -- get a filtered list of only valid units back from the function
    if not selectionSets[name] then
        return
    end

    -- validate units, remove the ones that got transformed into wrecks
    local aValidUnits = ProcessSelectionSet(name)
    local aSelection = EntityCategoryFilterDown(categories.ALLUNITS - (categories.FACTORY - categories.MOBILE) , aValidUnits)
    if table.getsize(aSelection) == 0 then
        aSelection = EntityCategoryFilterDown(categories.FACTORY - categories.MOBILE, aValidUnits)
        if table.getsize(aSelection) == 0 then
            AddSelectionSet(name, nil)
            return
        end
    end

    -- clean up the cache
    EmptyHash(selectionSets[name])
    ToHash(aSelection, selectionSets[name])

    SelectUnits(aSelection)
    DoubleTapBehavior(name, aSelection)

    -- perform callbacks
    for i, v in selectionSetCallbacks do
        v(name, aSelection, true)
    end
end

--- Attempts to select the factories of the selection set
---@param name any
function FactorySelection(name)

    -- validate units, remove the ones that got transformed into wrecks
    local aValidUnits = ProcessSelectionSet(name)
    local aSelection = EntityCategoryFilterDown(categories.FACTORY, aValidUnits)

    -- clean up the cache
    EmptyHash(selectionSets[name])
    ToHash(aSelection, selectionSets[name])

    SelectUnits(aSelection)
end

---Adds the current selected units to the selection set
---@param name any
function AppendSetToSelection(name)

    -- retrieve the two groups of units
    local aValidUnits = ProcessSelectionSet(name)
    local aSelectedUnits = GetSelectedUnits()

    if appendBehavior == 'add-selection-set-to-selection' then

        -- remove factories, unless we only have factories
        local aSelectionSetUnits = EntityCategoryFilterDown(categories.FACTORY, aValidUnits)
        if not next(aSelectionSetUnits) then 
            aSelectionSetUnits = aValidUnits
        end

        -- append the selection set
        for k, unit in aSelectionSetUnits do 
            table.insert(aSelectedUnits, unit)
        end

        -- select them together
        SelectUnits(aSelectedUnits)

        DoubleTapBehavior(aSelectedUnits)
    elseif appendBehavior == 'add-selection-to-selection-set' then

        -- remove factories, unless we only have factories
        local aSelectionSetUnits = EntityCategoryFilterDown(categories.FACTORY, aValidUnits)
        if not next(aSelectionSetUnits) then
            aSelectionSetUnits = aValidUnits
        end

        -- append the selection set
        for k, unit in aSelectionSetUnits do
            table.insert(aSelectedUnits, unit)
        end

        -- turn that into the new selection set
        AddSelectionSet(name, aSelectedUnits)

        DoubleTapBehavior(aSelectedUnits)
    elseif appendBehavior == 'combine-and-select-with-selection-set' then

        -- remove factories, unless we only have factories
        local aSelectionSetUnits = EntityCategoryFilterDown(categories.FACTORY, aValidUnits)
        if not next(aSelectionSetUnits) then
            aSelectionSetUnits = aValidUnits
        end

        -- append the selection set
        for k, unit in aSelectionSetUnits do
            table.insert(aSelectedUnits, unit)
        end

        -- turn that into the new selection set and select it
        AddSelectionSet(name, aSelectedUnits)
        SelectUnits(aSelectedUnits)
        
        DoubleTapBehavior(aSelectedUnits)
    end
end

local hidden_select = false
function IsHidden()
    return hidden_select == true
end

function Hidden(callback)
    local CM = import('/lua/ui/game/commandmode.lua')
    local current_command = CM.GetCommandMode()
    local old_selection = GetSelectedUnits() or {}

    hidden_select = true
    callback()
    SelectUnits(old_selection)
    CM.StartCommandMode(current_command[1], current_command[2])
    hidden_select = false
end
