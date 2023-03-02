-- Keeps some administrative values and has generic validation functions.

local AbilityDefinition = import("/lua/abilitydefinition.lua").abilities


function GetUnitsScript(TaskName, SelectedUnits, data)
    return GetAbilityUnitsForFocusArmy(TaskName)
end

function GetRangeCheckUnits(TaskName)
    return GetAbilityRangeCheckUnitsForFocusArmy(TaskName)
end

function VerifyScriptCommand(data)
-- TODO: cooldown check to see if ability is allowed to be used
    local TaskName = data.TaskName
    local army = GetFocusArmy()
    if TaskName and UnitsAreInArmy(data.Units, army) and LocationIsOk(data, GetRangeCheckUnits(TaskName)) then
        data.AuthorizedUnits = data.Units
        data.UserValidated = true
    else
        data.UserValidated = false
    end
    return data
end

-- --------------------------------------------------

AbilityUnits = {}
AbilityRangeCheckUnits = {}



GetAbilityUnitsForFocusArmy = function(abilityName)
    local army = GetFocusArmy()
    --LOG('*DEBUG: GetAbilityUnitsForFocusArmy() abilityName = '..repr(abilityName)..' army = '..repr(army)..' units = '..repr(AbilityUnits[abilityName][army]))
    if not IsValidAbility(abilityName) then
        return false
    elseif AbilityUnits[abilityName][army] then
        return AbilityUnits[abilityName][army]
    end
    return {}
end

GetAbilityRangeCheckUnitsForFocusArmy = function(abilityName)
    local army = GetFocusArmy()
    --LOG('*DEBUG: GetAbilityRangeCheckUnitsForFocusArmy() abilityName = '..repr(abilityName)..' army = '..repr(army)..' units = '..repr(AbilityRangeCheckUnits[abilityName][army]))
    if not IsValidAbility(abilityName) then
        return false
    elseif AbilityRangeCheckUnits[abilityName][army] then
        return AbilityRangeCheckUnits[abilityName][army]
    end
    return {}
end

SetAbilityUnits = function(abilityName, army, unitIds)
    --LOG('*DEBUG: SetAbilityUnits() abilityName = '..repr(abilityName)..' army = '..repr(army)..' unitIds = '..repr(unitIds))
    if army and unitIds and army >= 0 and army < 16 and IsValidAbility(abilityName) then
        if not AbilityUnits[abilityName] then
            AbilityUnits[abilityName] = {}
        end
        if not AbilityUnits[abilityName][army] then
            AbilityUnits[abilityName][army] = {}
        end

        AbilityUnits[abilityName][army] = unitIds
        --LOG('*DEBUG: SetAbilityUnits() result = '..repr(AbilityUnits[abilityName][army]))
        return true
    end
    --LOG('*DEBUG: SetAbilityUnits() bad values')
    return false
end

SetAbilityRangeCheckUnits = function(abilityName, army, unitIds)
    -- used to add a single unit id for range checking, or more than one (provided as a table)
    --LOG('*DEBUG: SetAbilityRangeCheckUnits() abilityName = '..repr(abilityName)..' army = '..repr(army)..' unitIds = '..repr(unitIds))
    if army and unitIds and army >= 0 and army <= 16 and IsValidAbility(abilityName) then
        if not AbilityRangeCheckUnits[abilityName] then
            AbilityRangeCheckUnits[abilityName] = {}
        end
        if not AbilityRangeCheckUnits[abilityName][army] then
            AbilityRangeCheckUnits[abilityName][army] = {}
        end

        AbilityRangeCheckUnits[abilityName][army] = unitIds
        --LOG('*DEBUG: SetAbilityRangeCheckUnits() result = '..repr(AbilityRangeCheckUnits[abilityName][army]))
        return true
    end
    --LOG('*DEBUG: SetAbilityRangeCheckUnits() bad values')
    return false
end


IsValidAbility = function(abilityName)
    if AbilityDefinition[ abilityName ] then
        return true
    end
    return false
end

UnitsAreInArmy = function(units, army)
    local ua
    for _, unit in units do
        ua = unit:GetArmy()
        if not army == ua then
            return false, ua
        end
    end
    return true, army
end

LocationIsOk = function(data, RangeCheckUnits)
    -- almost same script as in worldview.lua
    local InRange, RangeLimited = true, false
    local TaskName = data.TaskName
    local posM = data.Location
    if data.ExtraInfo and data.ExtraInfo.DoRangeCheck then  -- if we do a range check then find that there's a unit in range for the current position
        RangeLimited = true
        InRange = false
        if RangeCheckUnits then
            local unit, maxDist, minDist, posU, dist
            for k, u in RangeCheckUnits do
                unit = GetUnitById(u)
                if unit then
                    maxDist = unit:GetBlueprint().SpecialAbilities[TaskName].MaxRadius
                    minDist = 0  -- TODO: minimum radius distance check currently not implemented
                    if not maxDist or maxDist < 0 then   -- unlimited range
                        InRange = true
                        RangeLimited = false
                        break
                    elseif maxDist == 0 then             -- skip unit
                        continue
                    elseif maxDist > 0 then              -- unit counts towards range check, do check
                        posU = unit:GetPosition()
                        dist = VDist2(posU[1], posU[3], posM[1], posM[3])
                        InRange = (dist >= minDist and dist <= maxDist)
                        if InRange then
                            break
                        end
                    end
                else
                    WARN('*DEBUG: LocationIsOk in tasks.lua couldnt get blueprint for unit. u = '..repr(u)..' unit = '..repr(unit))
                end
            end
        end
    end
    return InRange
end