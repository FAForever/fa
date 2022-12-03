local Utilities = import("/lua/utilities.lua")

-- ATTACK MANAGER SPEC
--{
--    AttackCheckInterval = interval,
--    Platoons = {
--        {
--            PlatoonName = string,
--            AttackConditions = { function, {args} },
--            AIThread = function, -- If AMPlatoon needs a specific function
--            AIName = string, -- AIs from platoon.lua
--            Priority = num,
--            PlatoonData = table,
--            OverrideFormation = string, -- formation to use for the attack platoon
--            FormCallbacks = table, -- table of functions called when an AM Platoon forms
--            DestroyCallbacks = table, -- table of functions called when the platoon is destroyed
--            LocationType = string, -- location from PBM -- used if you want to get units from pool
--            PlatoonType = string, -- 'Air', 'Sea', 'Land' -- MUST BE SET IF UsePool IS TRUE
--            UsePool = bool, -- bool to use pool or not
--        },
--    },
--}
--
-- Spec for Platoons - within PlatoonData
-- PlatoonData = {
--     AMPlatoons = { AMPlatoonName, AMPlatoonName, etc },
-- },

---@class AttackManager
AttackManager = ClassSimple {
    brain = nil,
    NeedSort = false,
    PlatoonCount = { DefaultGroupAir = 0, DefaultGroupLand = 0, DefaultGroupSea = 0, },

    __init = function(self, brain, attackDataTable)
        self.Trash = TrashBag()
        self.brain = brain
        self:Initialize(table)
    end,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    Initialize = function(self, attackDataTable)
        self:AddDefaultPlatoons(attackDataTable.AttackConditions)
        if attackDataTable then
            self.AttackCheckInterval = attackDataTable.AttackCheckInterval or 13
            if attackDataTable.Platoons then
                self:AddPlatoonsTable(attackDataTable.Platoons)
            end
        elseif not self.AttackCheckInterval then
            self.AttackCheckInterval = 13
        end
        self['AttackManagerState'] = 'ACTIVE'
        self['AttackManagerThread'] = self:ForkThread(self.AttackManagerThread)
    end,

    AttackManagerThread = function(self)
        local ad = self
        local alertLocation, alertLevel, tempLevel
        while true do
            WaitSeconds(ad.AttackCheckInterval)
            if ad.AttackManagerState == 'ACTIVE' and self.Platoons then
                self:AttackManageAttackVectors()
                self:FormAttackPlatoon()
            end
        end
    end,

    AddDefaultPlatoons = function(self, AttackConds)
        local atckCond = {}
        if not AttackConds then
            AttackConds = {
                { '/lua/editor/platooncountbuildconditions.lua', 'NumGreaterOrEqualAMPlatoons', {'default_brain', 'DefaultGroupAir', 3} },
            }
        end

        local platoons = {
            {
                PlatoonName = 'DefaultGroupAir',
                AttackConditions = AttackConds,
                AIName = 'HuntAI',
                Priority = 1,
                PlatoonType = 'Air',
                UsePool = true,
            },
            {
                PlatoonName = 'DefaultGroupLand',
                AttackConditions = AttackConds,
                AIName = 'AttackForceAI',
                Priority = 1,
                PlatoonType = 'Land',
                UsePool = true,
            },
            {
                PlatoonName = 'DefaultGroupSea',
                AttackConditions = AttackConds,
                AIName = 'HuntAI',
                Priority = 1,
                PlatoonType = 'Sea',
                UsePool = true,
            },
        }

        self:AddPlatoonsTable(platoons)
    end,

    AddPlatoonsTable = function(self, platoons)
        for k,v in platoons do
            self:AddPlatoon(v)
        end
    end,

    AddPlatoon = function(self, pltnTable)
        if not pltnTable.AttackConditions then
            error('*AI WARNING: INVALID ATTACK MANAGER PLATOON LIST - Missing AttackConditions', 2)
            return
        end
        if not pltnTable.AIThread and not pltnTable.AIName then
            error('*AI WARNING: INVALID ATTACK MANAGER PLATOON LIST - Mission either AIName or AIThread', 2)
            return
        end
        if not pltnTable.Priority then
            error('*AI WARNING: INVALID ATTACK MANAGER PLATOON LIST - Missing Priority', 2)
            return
        end
        if not pltnTable.UsePool then
            pltnTable.UsePool = false
        end
        if not self then
            self = {}
        end
        if not self.Platoons then
            self.Platoons = {}
        end
        self.NeedSort = true
        table.insert(self.Platoons, pltnTable)
    end,

    ClearPlatoonList = function(self)
        self.Platoons = {}
        self.NeedSort = false
    end,

    SetAttackCheckInterval = function(self, interval)
        self.AttackCheckInterval = interval
    end,

    CheckAttackConditions = function(self, pltnInfo)
        for k, v in pltnInfo.AttackConditions do
            if v[3][1] == "default_brain" then
                table.remove(v[3], 1)
            end
            if iscallable(v[1]) then
                if not v[1](self.brain, unpack(v[2])) then
                    return false
                end
            else
                if not import(v[1])[v[2]](self.brain, unpack(v[3])) then
                    return false
                end
            end
        end
        return true
    end,

    SetPriority = function(self, builderName, priority)
        for k,v in self.Platoons do
            if v.PlatoonName == builderName then
                v.Priority = priority
            end
        end
    end,

    SortPlatoonsViaPriority = function(self)
        local sortedList = {}
        --Simple selection sort, this can be made faster later if we decide we need it.
        if self.Platoons then
            for i = 1, table.getn(self.Platoons) do
                local highest = 0
                local key, value
                for k, v in self.Platoons do
                    if v.Priority > highest then
                        highest = v.Priority
                        value = v
                        key = k
                    end
                end
                sortedList[i] = value
                table.remove(self.Platoons, key)
            end
            self.Platoons = sortedList
        end
        self.NeedSort = false
        return sortedList
    end,

    FormAttackPlatoon = function(self)
        local attackForcePL = {}
        local namedPlatoonList = {}
        local poolPlatoon = self.brain:GetPlatoonUniquelyNamed('ArmyPool')
        if poolPlatoon then
            table.insert(attackForcePL, poolPlatoon)
        end
        if self.NeedSort then
            self:SortPlatoonsViaPriority()
        end
        for k,v in self.Platoons do
            if self:CheckAttackConditions(v) then
                local combineList = {}
                local platoonList = self.brain:GetPlatoonsList()
                for j, platoon in platoonList do
                    if platoon:IsPartOfAttackForce() then
                        for i, name in platoon.PlatoonData.AMPlatoons do
                            if name == v.PlatoonName then
                                table.insert(combineList, platoon)
                            end
                        end
                    end
                end
                if not table.empty(combineList) or v.UsePool then
                    local tempPlatoon
                    if self.Platoons[k].AIName then
                        tempPlatoon = self.brain:CombinePlatoons(combineList, v.AIName)
                    else
                        tempPlatoon = self.brain:CombinePlatoons(combineList)
                    end
                    local formation = 'GrowthFormation'

                    if v.PlatoonData.OverrideFormation then
                        tempPlatoon:SetPlatoonFormationOverride(v.PlatoonData.OverrideFormation)
                    elseif v.PlatoonType == 'Air' and not v.UsePool then
                        tempPlatoon:SetPlatoonFormationOverride('GrowthFormation')
                    end

                    if v.UsePool then
                        local checkCategory
                        if v.PlatoonType == 'Air' then
                            checkCategory = categories.AIR * categories.MOBILE
                        elseif v.PlatoonType == 'Land' then
                            checkCategory = categories.LAND * categories.MOBILE - categories.ENGINEER - categories.EXPERIMENTAL
                        elseif v.PlatoonType == 'Sea' then
                            checkCategory = categories.NAVAL * categories.MOBILE
                        elseif v.PlatoonType == 'Any' then
                            checkCategory = categories.MOBILE - categories.ENGINEER
                        else
                            error('*AI WARNING: Invalid Platoon Type - ' .. v.PlatoonType, 2)
                            break
                        end
                        local poolPlatoon = self.brain:GetPlatoonUniquelyNamed('ArmyPool')
                        local poolUnits = poolPlatoon:GetPlatoonUnits()
                        local addUnits = {}
                        if v.LocationType then
                            local location = false
                            for locNum, locData in self.brain.PBM.Locations do
                                if v.LocationType == locData.LocationType then
                                    location = locData
                                    break
                                end
                            end
                            if not location then
                                SPEW('*AI WARNING: No EngineerManager present at location - ' .. v.LocationType, '[FormAttackPlatoon]')
                                break
                            end
                            for i,unit in poolUnits do
                                if Utilities.GetDistanceBetweenTwoVectors(unit:GetPosition(), location.Location) <= location.Radius
                                    and EntityCategoryContains(checkCategory, unit) then
                                        table.insert(addUnits, unit)
                                end
                            end
                        else
                            for i,unit in poolUnits do
                                if EntityCategoryContains(checkCategory, unit) then
                                    table.insert(addUnits, unit)
                                end
                            end
                        end
                        self.brain:AssignUnitsToPlatoon(tempPlatoon, addUnits, 'Attack', formation)
                    end
                    if v.PlatoonData then
                        tempPlatoon:SetPlatoonData(v.PlatoonData)
                    else
                        tempPlatoon.PlatoonData = {}
                    end
                    tempPlatoon.PlatoonData.PlatoonName = v.PlatoonName
                    --LOG('*AM DEBUG: AM Master Platoon Formed, Builder Named: ', repr(v.BuilderName))
                    --LOG('*AI DEBUG: ARMY ', repr(self:GetArmyIndex()),': AM Master Platoon formed - ',repr(v.BuilderName))
                    if v.AIThread then
                        tempPlatoon:ForkAIThread(import(v.AIThread[1])[v.AIThread[2]])
                        --LOG('*AM DEBUG: AM Master Platoon using AI Thread: ', repr(v.AIThread[2]), ' Builder named: ', repr(v.BuilderName))
                    end
                    if v.DestroyCallbacks then
                        for dcbNum, destroyCallback in v.DestroyCallbacks do
                            tempPlatoon:AddDestroyCallback(import(destroyCallback[1])[destroyCallback[2]])
                            --LOG('*AM DEBUG: AM Master Platoon adding destroy callback: ', destroyCallback[2], ' Builder named: ', repr(v.BuilderName))
                        end
                    end
                    if v.FormCallbacks then
                        for cbNum, callback in v.FormCallbacks do
                            if type(callback) == 'function' then
                                self.Trash:Add(ForkThread(callback, tempPlatoon))
                            else
                                self.Trash:Add(ForkThread(import(callback[1])[callback[2]], tempPlatoon))
                            end
                            --LOG('*AM DEBUG: AM Master Platoon Form callback: ', repr(callback[2]), ' Builder Named: ', repr(v.BuilderName))
                        end
                    end
                end
            end
        end
    end,

    DestroyAttackManager = function(self)
        if self.AttackManagerThread then
            self.AttackManagerThread:Destroy()
            self.AttackManagerThread = nil
        end
    end,

    PauseAttackManager = function(self)
        self.AttackManagerState = 'PAUSED'
    end,

    UnPauseAttackManager = function(self)
        self.AttackManagerState = 'ACTIVE'
    end,

    IsAttackManagerActive = function(self)
        if self and self.AttackManagerThread and self.AttackManagerState == 'ACTIVE' then
            return true
        end
        return false
    end,

    GetNumberAttackForcePlatoons = function(self)
        local platoonList = self.brain:GetPlatoonsList()
        local result = 0
        for k, v in platoonList do
            if v:IsPartOfAttackForce() then
                result = result + 1
            end
        end
        --Add in pool platoon, pool platoon is always used.
        result = result + 1
        return result
    end,

    AttackManageAttackVectors = function(self)
        local enemyBrain = self.brain:GetCurrentEnemy()
        if enemyBrain then
            self.brain:SetUpAttackVectorsToArmy()
        end
    end,

    -- XXX: refactor this later, artifact from moving AttackManager from aibrain
    DecrementCount = function(brain, platoon)
        local AM = brain.AttackManager
        local data = platoon.PlatoonData
        for k,v in data.AMPlatoons do
            AM.PlatoonCount[v] = AM.PlatoonCount[v] - 1
        end
    end
}
