function PlaySelectionSound(newSelection)
    for k, v in newSelection do
        local bp = v:GetBlueprint()
        if bp.Audio.UISelection then
            PlaySound(bp.Audio.UISelection)
            return
        end
    end
end

selectionSets = {}
local selectionSetCallbacks = {}
local lastSelectionName = nil
local lastSelectionTime = 0

-- add a function to get called when a selection set changes
-- with parameters function(name, unitArray, applied)
-- name: name of the selection set
-- unitArray: the actual array of units
-- applied: true if the set was applied, false if it was just created
function RegisterSelectionSetCallback(func)
    -- see if this function is already in here
    for i,v in selectionSetCallbacks do
        if v == func then
            return
        end
    end

    table.insert(selectionSetCallbacks, func)
end

function WithdrawSelectionSetCallback(func)
    for i,v in selectionSetCallbacks do
        if v == func then
            table.remove(selectionSetCallbacks, i)
            return
        end
    end
end

-- add a unit to an existing selection set
function AddUnitToSelectionSet(name, unit)
    if selectionSets[name] then
        table.insert(selectionSets[name],unit)
    end
end

-- add a selection set based on the current selection
function AddCurrentSelectionSet(name)
    AddSelectionSet(name, GetSelectedUnits())
end

-- add a selection set based on an array of units
-- if selectedUnits is nil, clears the selection set
function AddSelectionSet(name, unitArray)
    -- remove units from the selection set if it already exists
    if selectionSets[name] then
        for index, unit in selectionSets[name] do
            unit:RemoveSelectionSet(name)
        end
    end
    
    selectionSets[name] = unitArray

    -- add new units to selection set (unitArray could be nil, so check first)
    if selectionSets[name] then
        for index, unit in selectionSets[name] do
            unit:AddSelectionSet(name)
        end
    end
    
    for i,v in selectionSetCallbacks do
        v(name, unitArray, false)
    end
end

-- select a specified selection set in the session
function ApplySelectionSet(name)

    # get a filtered list of only valid units back from the function
    if not selectionSets[name] then return end
    selectionSets[name] = ValidateUnitsList(selectionSets[name])
    local selection = EntityCategoryFilterDown(categories.ALLUNITS - (categories.FACTORY - categories.MOBILE) , selectionSets[name])
    if table.getsize(selection) == 0 then 
        selection = EntityCategoryFilterDown(categories.FACTORY - categories.MOBILE, selectionSets[name])
        if table.getsize(selection) == 0 then
            AddSelectionSet(name, nil)
            return
        end
    end
    if table.getn(selection) > 0 then
        SelectUnits(selection)
        local unitIDs = {}
        for _, unit in selection do
            table.insert(unitIDs, unit:GetEntityId())
        end
        SimCallback({Func = 'OnControlGroupApply', Args = unitIDs})
    
        # Time the difference between the 2 selection application to
        # determine if this is a double tap selection
        local curTime = GetSystemTimeSeconds()
        local diffTime = curTime - lastSelectionTime
        if diffTime > 1.0 then
            lastSelectionName = nil
        end
        lastSelectionTime = curTime
    
        # If this is a double tap then we want to soom in onto the central unit of the group
        if name == lastSelectionName then
            if selection then
                UIZoomTo(selection)
            end
            lastSelectionName = nil
        else
            lastSelectionName = name
        end        
       
        # if we are out of units. just set our set to nil
        if table.getn(selection) == 0 then
            selectionSets[name] = nil
        else        
            for i,v in selectionSetCallbacks do
                v(name, selectionSets[name], true)
            end
        end
    end
end

function AppendSetToSelection(name)
    # get a filtered list of only valid units back from the function
    local setID = tostring(name)
    selectionSets[setID] = ValidateUnitsList(selectionSets[setID])
    local selectionSet = EntityCategoryFilterDown(categories.ALLUNITS - categories.FACTORY, selectionSets[setID])
    local curSelection = GetSelectedUnits()
    if curSelection and selectionSet then
        for i, unit in selectionSet do
            table.insert(curSelection, unit)
        end
        SelectUnits(curSelection)
    
        # Time the difference between the 2 selection application to
        # determine if this is a double tap selection
        local curTime = GetSystemTimeSeconds()
        local diffTime = curTime - lastSelectionTime
        if diffTime > 1.0 then
            lastSelectionName = nil
        end
        lastSelectionTime = curTime
    
        # If this is a double tap then we want to soom in onto the central unit of the group
        if name == lastSelectionName then
            UIZoomTo(curSelection)
            lastSelectionName = nil
        else
            lastSelectionName = name
        end
    elseif selectionSet then
        ApplySelectionSet(setID)
    end
end

function FactorySelection(name)
    # get a filtered list of only valid units back from the function
    local setID = tostring(name)
    selectionSets[setID] = ValidateUnitsList(selectionSets[setID])
    local selectionSet = EntityCategoryFilterDown(categories.FACTORY, selectionSets[setID])
    
    SelectUnits(selectionSet)
    
    # Time the difference between the 2 selection application to
    # determine if this is a double tap selection
    local curTime = GetSystemTimeSeconds()
    local diffTime = curTime - lastSelectionTime
    if diffTime > 1.0 then
        lastSelectionName = nil
    end
    lastSelectionTime = curTime

    # If this is a double tap then we want to soom in onto the central unit of the group
    if name == lastSelectionName then
        UIZoomTo(selectionSet)
        lastSelectionName = nil
    else
        lastSelectionName = name
    end
end

function ResetSelectionSets(new_sets)
    selectionSets = new_sets
end

-- from schook selection.lua

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
