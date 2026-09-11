local Utilities = import("/lua/utilities.lua")

local pairs, ipairs = pairs, ipairs
local iscallable = iscallable

-------------------------------------------------------------------------------------------------------------------------
--- This is the AttackManager class that is used for campaign/coop
--- Vanilla Supreme Commander (referred to as *SC1* from now on) used this along with the PBM for its skirmish AI as well
--- A quick rundown how it works in practice:
---		- In FA, it's used by the "BaseOpAI.lua", with platoons created via the BaseManager
---		- The BaseManager builds a bunch of PBM platoons, then combines them into an AM platoon
---		- The PBM platoons are defined in the many *save.lua files in "lua/AI/OpAI"
---		- Platoons containing the 'Child' name are the ones to be combined
---		- Platoons containing the 'Master' name are the ones to be converted to AM Platoons
---		- The AM is capable of forming random platoon compositions this way
---		- It's also less likely to leave units sitting at bases, since it combines existing platoons into a new one
---		- By default, the loading of platoons is handled in "ScenarioUtilities.lua", in the 'OSB' related functions
---		- AM platoons can be added in other ways, it's up to the mission maker/scripter how they do it
--------------------------------------------------------------------------------------------------------------------------
--- An example of the Attack Manager platoon 'builder' template:
---
---    Platoons = 
---		{
---        {
---            PlatoonName = string,
---            AttackConditions = { function, {args} },	-- Literally build conditions, just with a different name, all of them need to return true in order for the platoon to be formed
---            AIThread = function, 					-- If AMPlatoon needs a specific function
---            AIName = string, 						-- AI plans from platoon.lua
---            Priority = num,
---            PlatoonData = table,
---            OverrideFormation = string, 				-- Formation to use for the attack platoon
---            FormCallbacks = table, 					-- Table of functions called when an AM Platoon forms
---            DestroyCallbacks = table, 				-- Table of functions called when the platoon is destroyed
---            LocationType = string, 					-- Location from PBM -- used if you want to get units from pool
---            PlatoonType = string,					-- 'Air', 'Sea', 'Land' -- MUST BE SET IF UsePool IS TRUE
---            UsePool = bool, 							-- Bool to use pool or not
---        },
---    },

--- Example how to pick the master platoon - within PlatoonData
--- PlatoonData = {
---     AMPlatoons = { AMPlatoonName, AMPlatoonName, etc },
--- },
--- Example how to set a master platoon - within PlatoonData
--- PlatoonData = {
---     AMMasterPlatoon = true,
--- },

---@class AMBuilder
---@field PlatoonName string
---@field AttackConditions BuildCondition[] List of conditions that have to pass for the platoon to be formed
---@field AIThread FileFunctionRef
---@field AIName string
---@field Priority integer
---@field PlatoonData table
---@field OverrideFormation UnitFormations|nil Formation to use for the formed platoon
---@field FormCallbacks table<integer, FileFunctionRef|fun(platoon: Platoon)>|nil Table of functions called when an AM Platoon forms
---@field DestroyCallbacks FileFunctionRef[]|nil Table of functions called when the platoon is destroyed
---@field LocationType string Location from PBM -- used if you want to get units from pool
---@field PlatoonType "Air" | "Gate" | "Land" | "Sea" | "Any" MUST BE SET IF UsePool IS `true`
---@field UsePool boolean Bool to use pool or not. Defaults to `false`


---@alias AttackManagerState "ACTIVE" | "PAUSED"

---@class AttackManager
---@field brain CampaignAIBrain AI Brain
---@field Trash TrashBag
---@field PlatoonCount table<string, integer>
---@field AttackCheckInterval integer HOw often the AM should attempt to form platoons
---@field Platoons AMBuilder[] Table of platoons belonging to the AI
---@field AttackManagerState AttackManagerState Either 'ACTIVE' or 'PAUSED', used to check if the AM is active for an AI
---@field AMFormThread thread|nil
AttackManager = ClassSimple {
    brain = nil,
    NeedSort = false,
    PlatoonCount = { DefaultGroupAir = 0, DefaultGroupLand = 0, DefaultGroupSea = 0, },

	--- Engine level initialization, usually triggered by *AIBrain:InitializeAttackManager(attackDataTable)* in the campaign AI brain
	---@param self AttackManager
	---@param brain CampaignAIBrain Brain
	---@param attackDataTable table See *Initialize()* below for its expected contents
    __init = function(self, brain, attackDataTable)
        self.Trash = TrashBag()
        self.brain = brain
        self:Initialize(attackDataTable)
    end,

	--- Unique ForkThread for this class, for easy syntax usage, and data trash handling
	--- Swaps the order of params for simpler function call
	---@param self AttackManager
	---@param fn function
	---@param ... any Further parameters for the function we want to be forked
    ---@return thread|nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

	--- The actual initialization of all necessary data, and the main Thread
	---@param self AttackManager
    ---@param attackDataTable table # Optional table containing the loop check delay, default build conditions, and default platoons to load
    Initialize = function(self, attackDataTable)
        self:AddDefaultPlatoons(attackDataTable.AttackConditions)
        if attackDataTable then
            self.AttackCheckInterval = attackDataTable.AttackCheckInterval or 10
            if attackDataTable.Platoons then
                self:AddPlatoonsTable(attackDataTable.Platoons)
            end
        elseif not self.AttackCheckInterval then
            self.AttackCheckInterval = 10
        end

        self.AttackManagerState = 'ACTIVE'
        self.AMFormThread = self:ForkThread(self.AttackManagerThread)
    end,

	--- The main thread that forms the AM platoons periodically
	---@param self AttackManager
    AttackManagerThread = function(self)
        while true do
            if self.AttackManagerState == 'ACTIVE' and self.Platoons then
                self:AttackManageAttackVectors()
                if self.NeedSort then
                    self:SortPlatoonsViaPriority()
                end
                self:FormAttackPlatoon()
            end
			WaitSeconds(self.AttackCheckInterval)
        end
    end,

	--- Loads the default AM platoons, these aren't formed in coop/campaign, they were used by SC1's skirmish AIs
	---@param self AttackManager
    ---@param attackConds? BuildCondition[] Table of conditions that return with either true or false
    AddDefaultPlatoons = function(self, attackConds)
        attackConds = attackConds or {
            {'/lua/editor/MiscBuildConditions.lua', 'False', {}}
        }

        local platoons = {
            {
                PlatoonName = 'DefaultGroupAir',
                AttackConditions = attackConds,
                AIName = 'HuntAI',
                Priority = 1,
                PlatoonType = 'Air',
                UsePool = true,
            },
            {
                PlatoonName = 'DefaultGroupLand',
                AttackConditions = attackConds,
                AIName = 'AttackForceAI',
                Priority = 1,
                PlatoonType = 'Land',
                UsePool = true,
				PlatoonData = {
					UseFormation = 'GrowthFormation',
				}
            },
            {
                PlatoonName = 'DefaultGroupSea',
                AttackConditions = attackConds,
                AIName = 'HuntAI',
                Priority = 1,
                PlatoonType = 'Sea',
                UsePool = true,
            },
        }

        self:AddPlatoonsTable(platoons)
    end,

	--- Adds a table of platoon builders to the AM
	---@param self AttackManager
	---@param platoons AMBuilder[] Table of platoon builders
    AddPlatoonsTable = function(self, platoons)
        for _, v in pairs(platoons) do
            self:AddPlatoon(v)
        end
    end,

	--- Adds a single platoon builder to the AM
	---@param self AttackManager
	---@param pltnTable AMBuilder table of a platoon builder instance
    AddPlatoon = function(self, pltnTable)
        if not pltnTable.AttackConditions then
            WARN('*AI WARNING: AttackManager: Invalid platoon builder - Missing AttackConditions', repr(pltnTable))
            return
        elseif not pltnTable.AIThread and not pltnTable.AIName then
            WARN('*AI WARNING: AttackManager: Invalid platoon builder - Missing either AIName or AIThread', repr(pltnTable))
            return
        elseif not pltnTable.Priority then
            WARN('*AI WARNING: AttackManager: Invalid platoon builder - Missing Priority', repr(pltnTable))
            return
        end

        if not pltnTable.UsePool then
            pltnTable.UsePool = false
        end
        if not self.Platoons then
            self.Platoons = {}
        end

        --- If the first entry is "default_brain", it will be removed, this is a GPG thing ever since SC1, because the Brain param provided is always THIS AI's brain
	    --- My guess is that they planned to have any brain be providable, or that they moved these from C Engine side to Lua, and this is a leftover
        for _, v in pairs(pltnTable.AttackConditions) do
            if v[3][1] == "default_brain" then
                table.remove(v[3], 1)
            end
        end

        self.NeedSort = true
        table.insert(self.Platoons, pltnTable)
    end,

	--- Wipes the current platoon list, useful if you want to give the AI a whole new list of platoons to be formed over the old ones
	---@param self AttackManager
    ClearPlatoonList = function(self)
        self.Platoons = {}
        self.NeedSort = false
    end,

	--- Sets the loop delay for the main platoon forming thread
	---@param self AttackManager
	---@param interval integer
    SetAttackCheckInterval = function(self, interval)
        self.AttackCheckInterval = interval
    end,

	--- Returns true if all attack conditions pass
	---@param self AttackManager
	---@param pltnInfo AMBuilder
	---@return boolean
    CheckAttackConditions = function(self, pltnInfo)
        for _, v in pairs(pltnInfo.AttackConditions) do
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

	---@param self AttackManager
	---@param builderName string
	---@param priority integer
    SetPriority = function(self, builderName, priority)
        for _, v in pairs(self.Platoons) do
            if v.PlatoonName == builderName then
                v.Priority = priority
            end
        end
    end,

	---@param self AttackManager
    SortPlatoonsViaPriority = function(self)
        table.sort(self.Platoons, function(a, b) return a.Priority > b.Priority end)
        self.NeedSort = false
        return self.Platoons
    end,

	--- The main function that forms the AM platoons
	---@param self AttackManager
    FormAttackPlatoon = function(self)
        local poolPlatoon = self.brain:GetPlatoonUniquelyNamed('ArmyPool')

		-- Loop through all of the AM platoons
        for _, v in ipairs(self.Platoons) do
            if not self:CheckAttackConditions(v) then
                continue
            end

            local combineList = {}
            local platoonList = self.brain:GetPlatoonsList()

            -- Loop through all of the platoons the AI has, check if it's part of the attack force
            -- The PBM platoons are the ones set to be part of the attack force, if they have 'AMPlatoons' platoon data set, this is handled by the "PBMFormPlatoons()" function
            -- If it's part of it, check the PlatoonData for the name of the 'master' platoon it belongs to, and if it matches, insert this platoon to the combineList
            -- These are defined in the lua/AI/OpAI *save.lua files, containing all of the default platoons
            for _, platoon in pairs(platoonList) do
                if not platoon:IsPartOfAttackForce() then
                    continue
                end

                for _, name in pairs(platoon.PlatoonData.AMPlatoons) do
                    if name == v.PlatoonName then
                        table.insert(combineList, platoon)
                        break
                    end
                end
            end

            -- If the combineList is not empty, it will form the AM platoon
            -- Usually platoons inside the combineList are PBM ones
            -- If UsePool is true, it can cause some wonky behaviour, it can additionally grab units from the ArmyPool, but will mess up the actual unit counts defined in the platoon templates
            -- This can result in platoons not forming properly, thus units sitting at their bases cluttering up
            -- By default it's practically not used at all
            if table.empty(combineList) and not v.UsePool then
                continue
            end

            local tempPlatoon
            if v.AIName then
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

            -- This section is only relevant if we want the AM platoon to grab from the ArmyPool, it was used for SC1's skirmish AI
            -- I've added additional categories to be filtered out, we don't want land platoons to grab unassigned transports or such in case we ever decide to make use of the ArmyPool
            if v.UsePool then
                local checkCategory
                -- Only T1-T3 aerial combat units
                if v.PlatoonType == 'Air' then
                    checkCategory = categories.AIR * categories.MOBILE - categories.TRANSPORTATION - categories.EXPERIMENTAL - categories.SCOUT
                -- Only T1-T3 surface combat units
                elseif v.PlatoonType == 'Land' then
                    checkCategory = categories.LAND * categories.MOBILE - categories.ENGINEER - categories.EXPERIMENTAL - categories.SCOUT
                -- Only T1-T3 naval combat units
                elseif v.PlatoonType == 'Sea' then
                    checkCategory = categories.NAVAL * categories.MOBILE - categories.EXPERIMENTAL
                -- Only T1-T3 combined-arms combat units
                elseif v.PlatoonType == 'Any' then
                    checkCategory = categories.MOBILE - categories.ENGINEER - categories.TRANSPORTATION - categories.EXPERIMENTAL - categories.SCOUT
                else
                    error('*AI WARNING: Invalid Platoon Type - ' .. v.PlatoonType, 2)
                end

                local poolUnits = poolPlatoon:GetPlatoonUnits()
                local addUnits = {}

                -- If the AM platoon has a base of origin, it will only grab ArmyPool units from near it
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
                        if Utilities.GetDistanceBetweenTwoVectors(unit:GetPosition(), location.Location) <= location.Radius and EntityCategoryContains(checkCategory, unit) then
                            table.insert(addUnits, unit)
                        end
                    end
                -- If there's no base of origin, grab ArmyPool units from anywhere
                else
                    for i,unit in poolUnits do
                        if EntityCategoryContains(checkCategory, unit) then
                            table.insert(addUnits, unit)
                        end
                    end
                end
                self.brain:AssignUnitsToPlatoon(tempPlatoon, addUnits, 'Attack', formation)
            end

            -- Set the platoon's data
            if v.PlatoonData then
                tempPlatoon:SetPlatoonData(v.PlatoonData)
            else
                tempPlatoon.PlatoonData = {}
            end
            -- Set the platoon's name
            tempPlatoon.PlatoonData.PlatoonName = v.PlatoonName

            -- Set the platoon AI function
            if v.AIThread then
                tempPlatoon:ForkAIThread(import(v.AIThread[1])[v.AIThread[2]])
            end

            -- Add callbacks when the platoon is destroyed
            if v.DestroyCallbacks then
                for _, destroyCallback in ipairs(v.DestroyCallbacks) do
                    tempPlatoon:AddDestroyCallback(import(destroyCallback[1])[destroyCallback[2]])
                end
            end

            -- Call for the specified callbacks, since we were just formed
            if v.FormCallbacks then
                for _, callback in ipairs(v.FormCallbacks) do
                    if type(callback) == 'function' then
                        self.Trash:Add(ForkThread(callback, tempPlatoon))
                    else
                        self.Trash:Add(ForkThread(import(callback[1])[callback[2]], tempPlatoon))
                    end
                end
            end
        end
    end,

	--- Completely removes the AM thread
	---@param self AttackManager
    DestroyAttackManager = function(self)
        if self.AMFormThread then
            self.AMFormThread:Destroy()
            self.AMFormThread = nil
        end
    end,

	--- Pauses the AM thread
	---@param self AttackManager
    PauseAttackManager = function(self)
        self.AttackManagerState = 'PAUSED'
    end,

	--- Re-enables the AM thread
	---@param self AttackManager
    UnPauseAttackManager = function(self)
        self.AttackManagerState = 'ACTIVE'
    end,

	--- Checks if the AttackManager has been enabled
	---@param self AttackManager
	---@return boolean
    IsAttackManagerActive = function(self)
        if self.AMFormThread and self.AttackManagerState == 'ACTIVE' then
            return true
        end
        return false
    end,

	--- Returns with the number of platoons part of the attack force
	---@param self AttackManager
	---@return number count
    GetNumberAttackForcePlatoons = function(self)
        local platoonList = self.brain:GetPlatoonsList()
        local result = 0
        for _, v in pairs(platoonList) do
            if v:IsPartOfAttackForce() then
                result = result + 1
            end
        end
        -- Add in pool platoon, pool platoon is always used.
        result = result + 1
        return result
    end,

	--- SC1's use of attack vector data, mostly on the engine side, so I can't comment on it
	---@param self AttackManager
    AttackManageAttackVectors = function(self)
        local enemyBrain = self.brain:GetCurrentEnemy()
        if enemyBrain then
            self.brain:SetUpAttackVectorsToArmy()
        end
    end,

    --- XXX: refactor this later, artifact from moving AttackManager from aibrain
	---@param brain CampaignAIBrain
	---@param platoon Platoon
    DecrementCount = function(brain, platoon)
        local AM = brain.AttackManager
        local data = platoon.PlatoonData
        for _,v in data.AMPlatoons do
            AM.PlatoonCount[v] = AM.PlatoonCount[v] - 1
        end
    end
}
