--****************************************************************************
--**
--**  File     :  /lua/sc/TauntManager.lua
--**  Author(s): Drew Staltman
--**
--**  Summary  : Functions for use in the Operations.
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TriggerFile = import("/lua/scenariotriggers.lua")
local ScenarioFramework = import("/lua/scenarioframework.lua")

local pairs = pairs
local type = type
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds
local mathCeil = math.ceil
local tableEmpty = table.empty
local tableInsert = table.insert
local tableGetn = table.getn
local tableRandom = table.random

---Plays scripted voice-line taunts for a scenario/operation.
---
---Taunts are registered against triggers (unit death, area entry, intel detection, construction,
---timers, platoon formation, etc.) and are played back through `ScenarioFramework.Dialogue`
---once their condition fires. Only one taunt plays at a time: after a taunt finishes,
---further taunts are locked out for `UnlockTimer` seconds, and each taunt line is only
---ever played once, so that the same taunt can be added with multiple triggers.
---Taunts are optionally bound to a `TauntingCharacter` unit so taunts stop being played
---once that unit dies.
---@class TauntManager
---@field Active boolean
---@field Name string Name of the taunt manager
---@field TauntingCharacter? Unit
---@field protected FileName string
---@field protected FileData table<string, DialogueTable>
---@field protected CustomTaunts table<string, integer>
---@field protected PlayedTaunts table<string, boolean> Keeps track of taunt that were already played
---@field protected TauntNumber integer
---@field protected UnlockTimer integer Defaults to 30 seconds.
---@field protected TauntData table<integer, string[]>
---@field protected TauntsLocked boolean Prevents taunts to be played
---@field protected Trash TrashBag
---@overload fun(name: string, filename?: FileName): TauntManager
TauntManager = ClassSimple {
    ---@param self TauntManager
    ---@param name string
    ---@param filename? FileName
    __init = function(self, name, filename)
        self.Trash = TrashBag()

        self.Name = name
        self.Active = false
        self.TauntNumber = 0
        self.TauntData = {}
        self.UnlockTimer = 30

        self.CustomTaunts = {}
        self.PlayedTaunts = {}

        if filename then
            self:SetTauntFile(filename)
        end
    end,

    ---Imports given file to be used for taunts and activates the manager.
    ---@param self TauntManager
    ---@param fileName FileName
    SetTauntFile = function(self, fileName)
        self.FileName = fileName
        self.FileData = import(fileName)
        self:Activate(true)
    end,

    ---Activates the manager, allows taunts to be played.
    ---@param self TauntManager
    ---@param bool boolean
    Activate = function(self, bool)
        if bool and not (self.FileName and self.FileData) then
            error('TauntManager: ' .. self.Name .. " failed to activate. No file with taunt data set.", 2)
        end
        self.Active = bool
    end,

    ---Adds a unit as a character for the taunts. Prevents playing more taunts after this unit died.
    ---@param self TauntManager
    ---@param unit Unit
    AddTauntingCharacter = function(self, unit)
        if unit.Dead then return end

        self.TauntingCharacter = unit
    end,

    ---If the character unit is set, checks if it isn't dead
    ---@param self TauntManager
    ---@return boolean
    ---@protected
    TauntingCharacterCheck = function(self)
        return not self.TauntingCharacter or not self.TauntingCharacter.Dead
    end,

    ---Sets up the taunt in manager
    ---@param self TauntManager
    ---@param diagData string[]|string Specific taunt name or a list of possible taunts.
    ---@param delaySecs? integer Delays playing the taunt after it's triggered.
    ---@return integer index Internal index under which it's saved in the manager.
    ---@return function cb Callback function that will play the taunt.
    ---@protected
    TauntBasics = function(self, diagData, delaySecs)
        self.TauntNumber = self.TauntNumber + 1
        local currNum = self.TauntNumber
        if type(diagData) == 'table' then
            self.TauntData[currNum] = diagData
        elseif type(diagData) == 'string' then
            self.TauntData[currNum] = { diagData }
        else
            error('TauntManager: Invalid data for Taunt - must be table of strings or a string', 3)
        end

        local callback

        if delaySecs then
            callback = function()
                local thread = ForkThread(function()
                    WaitSeconds(delaySecs)
                    --LOG('*DEBUG: Taunt played number ' .. currNum)
                    self:PlayTaunt(currNum)
                end)
                self.Trash:Add(thread)
            end
        else
            callback = function()
                --LOG('*DEBUG: Taunt played number ' .. currNum)
                self:PlayTaunt(currNum)
            end
        end

        return currNum, callback
    end,

    ---Tries to play a taunt.
    ---@param self TauntManager
    ---@param tauntNum integer
    ---@protected
    PlayTaunt = function(self, tauntNum)
        if not self.Active then return end
        if not self:TauntingCharacterCheck() then return end

        local possibleTaunts = {}
        for _, name in pairs(self.TauntData[tauntNum]) do
            if not self.PlayedTaunts[name] then
                tableInsert(possibleTaunts, name)
            end
        end

        if tableEmpty(possibleTaunts) then return end

        if self.TauntsLocked then return end

        local tauntName = tableRandom(possibleTaunts)
        self.PlayedTaunts[tauntName] = true
        self.TauntsLocked = true

        ScenarioFramework.Dialogue(self.FileData[tauntName], function()
            self:UnlockTaunts()
        end)
    end,

    ---Starts a timer using `self.UnlockTimer` value. Allows taunts to be played again after the timer expires.
    ---@param self TauntManager
    ---@protected
    UnlockTaunts = function(self)
        WaitSeconds(self.UnlockTimer)
        self.TauntsLocked = false
    end,

    ---Changes the cooldown after a taunt is played that prevents other taunts from the manager to be played.
    ---@param self TauntManager
    ---@param seconds integer
    SetUnlockTime = function(self, seconds)
        self.UnlockTimer = seconds
    end,

    ---Plays a taunt when platoon is formed.
    ---@param self TauntManager
    ---@param diagData string[]|string Dialogues name or list of dialogues for the taunt.
    ---@param opAI OpAI
    ---@param attacks integer|integer[]|'All' `N` = played when formed `Nth` time. `{2, 4}` = play when formed 2nd and 4th time. `'All'` play each time.
    AddAttackTaunt = function(self, diagData, opAI, attacks)
        local currNum, callback = self:TauntBasics(diagData)

        attacks = attacks or 'All'

        ---@param platoon Platoon
        local attackFunc = function(platoon)
            local name = platoon.PlatoonData.PlatoonName .. '_FormedCounter'
            local counter = ScenarioInfo.VarTable[name] or 0
            counter = counter + 1
            ScenarioInfo.VarTable[name] = counter

            if type(attacks) == 'table' then
                for _, numFormed in pairs(attacks) do
                    if numFormed == counter then
                        callback()
                        break
                    end
                end
            elseif attacks == counter then
                callback()
            elseif attacks == 'All' then
                callback()
            end
        end

        opAI:AddFormCallback(attackFunc)
    end,

    ---Plays a taunt when `brain` has >= `number` of `category` units in specified `area`.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param area AreaName|Rectangle
    ---@param category EntityCategory
    ---@param brain AIBrain
    ---@param number integer
    AddAreaTaunt = function(self, diagData, area, category, brain, number)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateAreaTrigger(callback, area, category, true, false, brain, number, true)
    end,

    ---Plays a taunt when Player sees any `category` units of `targetBrain`. 
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param targetBrain AIBrain
    ---@param category EntityCategory
    AddPlayerIntelCategoryTaunt = function(self, diagData, targetBrain, category)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', false, true, category, true, targetBrain)
    end,

    ---Plays a taunt when `lookingBrain` sees any `category` units of `targetBrain`. 
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param lookingBrain AIBrain
    ---@param targetBrain AIBrain
    ---@param category EntityCategory
    AddIntelCategoryTaunt = function(self, diagData, lookingBrain, targetBrain, category)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', false, true, category, true, targetBrain)
    end,

    ---Plays a taunt when Player sees `unit`
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unit Unit
    AddPlayerIntelUnitTaunt = function(self, diagData, unit)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', unit, true, categories.ALLUNITS, true, unit:GetAIBrain())
    end,

    ---Plays a taunt when `lookingBrain` sees `unit`
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unit Unit
    ---@param lookingBrain AIBrain
    AddIntelUnitTaunt = function(self, diagData, unit, lookingBrain)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', unit, true, categories.ALLUNITS, true, unit:GetAIBrain())
    end,

    ---Plays a taunt when `unit` is killed, captured or reclaimed.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unit Unit
    AddUnitDestroyedTaunt = function(self, diagData, unit)
        self:AddUnitKilledTaunt(diagData, unit, true)
    end,

    ---Plays a taunt when `unit` is just killed or (killed, reclaimed or captured) when `destroyed` is set.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unit Unit
    ---@param destroyed? boolean Defaults to `false` = only when the unit is killed. `true` also captured or reclaimed.
    AddUnitKilledTaunt = function(self, diagData, unit, destroyed)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateUnitDeathTrigger(callback, unit)
        if destroyed then
            TriggerFile.CreateUnitCapturedTrigger(callback, nil, unit)
            TriggerFile.CreateUnitReclaimedTrigger(callback, unit)
        end
    end,

    ---Plays a taunt when a group of units is killed.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unitTable Unit[]
    ---@param number? integer Number of units to be killed to trigger the taunt. Defaults to the whole group.
    AddUnitGroupDeathTaunt = function(self, diagData, unitTable, number)
        local currNum, callback = self:TauntBasics(diagData)
        if not number then
            TriggerFile.CreateGroupDeathTrigger(callback, unitTable)
        else
            TriggerFile.CreateSubGroupDeathTrigger(callback, unitTable, number)
        end
    end,

    ---Plays a taunt when a % of units in a group is killed.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unitTable Unit[]
    ---@param percent number `0.0` - `1.0`
    AddUnitGroupDeathPercentTaunt = function(self, diagData, unitTable, percent)
        local unitNum = tableGetn(unitTable)
        local newNum = mathCeil(percent * unitNum)
        self:AddUnitGroupDeathTaunt(diagData, unitTable, newNum)
    end,

    ---Plays a taunt when `unit` is damaged by `percent`.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param unit Unit
    ---@param percent number `0.0` - `1.0` lost health ratio. `0.05` = when `unit` took 5% damage.
    AddDamageTaunt = function(self, diagData, unit, percent)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateUnitDamagedTrigger(callback, unit, percent)
    end,

    ---Plays a taunt when `brain` builds `number` of `category` units.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param brain AIBrain
    ---@param category EntityCategory
    ---@param number integer
    AddConstructionTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'ConstructionTaunt' .. self.Name .. currNum,
            {
                {
                    StatType = 'Units_History',
                    CompareType = 'GreaterThanOrEqual',
                    Value = brain:GetBlueprintStat('Units_History', category) + number,
                    Category = category,
                },
            }
        )
    end,

    ---Plays a taunt when `brain` starts building `category` unit.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param brain AIBrain
    ---@param category EntityCategory
    ---@param delaySecs? integer Delays playing the taunt when the condition is met.
    AddStartBuildTaunt = function(self, diagData, brain, category, delaySecs)
        local currNum, callback = self:TauntBasics(diagData, delaySecs)

        TriggerFile.CreateArmyStatTrigger(callback, brain, 'BuildTaunt' .. self.Name .. currNum,
            {
                {
                    StatType = 'Units_BeingBuilt',
                    CompareType = 'GreaterThanOrEqual',
                    Value = brain:GetBlueprintStat('Units_History', category) + 1,
                    Category = category,
                },
            }
        )
    end,

    ---Plays a taunt when `brain` loses `number` of `category` units.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param brain AIBrain
    ---@param category EntityCategory
    ---@param number? integer Defaults to `1`.
    AddUnitsKilledTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'UnitsKilled_' .. self.Name .. currNum,
            {
                {
                    StatType = 'Units_Killed',
                    CompareType = 'GreaterThanOrEqual',
                    Value = brain:GetBlueprintStat('Units_Killed', category) + number,
                    Category = category,
                },
            }
        )
    end,

    ---Plays a taunt when `brain` kill `number` of enemy `category` units.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param brain AIBrain
    ---@param category EntityCategory
    ---@param number? integer Defaults to `1`.
    AddEnemiesKilledTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'EnemiesKilled_' .. self.Name .. currNum,
            {
                {
                    StatType = 'Enemies_Killed',
                    CompareType = 'GreaterThanOrEqual',
                    Value = brain:GetBlueprintStat('Enemies_Killed', category) + number,
                    Category = category,
                },
            }
        )
    end,

    ---Plays a taunt after `seconds` passed.
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param seconds integer
    AddTimerTaunt = function(self, diagData, seconds)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateTimerTrigger(callback, seconds)
    end,

    ---Adds a custom taunt that can be later played by `PlayCustomTaunt`
    ---@param self TauntManager
    ---@param diagData string|string[] Name of the dialogue or a list of names for the taunt. If it's a list, the taunt is picked randomly each time it's played. This name must be defined in the provided taunt file.
    ---@param customName string
    AddCustomTaunt = function(self, diagData, customName)
        if self.CustomTaunts[customName] then
            WARN('TauntManager: ' .. self.Name .. ' trying to add duplicate custom taunt: ' .. customName)
            return
        end
        local currNum, callback = self:TauntBasics(diagData)
        self.CustomTaunts[customName] = currNum
    end,

    ---Plays a custom taunt previously added by `AddCustomTaunt`
    ---@param self TauntManager
    ---@param customName string
    PlayCustomTaunt = function(self, customName)
        if not self.CustomTaunts[customName] then
            WARN('TauntManager: ' .. self.Name .. ' custom taunt: ' .. customName .. ' not found')
            return
        end
        self:PlayTaunt(self.CustomTaunts[customName])
    end,
}

---Creates a new TauntManager and initializes if `fileName` is provided.
---
---Reference to the manager is saved by the name into `ScenarioInfo.TauntManagers`
---
---See `ScenarioFramework.Dialogue` for the format of the dialoguges expected in the file.
---@param name string Custom name for the manager
---@param fileName? FileName Path to the file with defined dialogues. Added taunts are looking up the dialogue data in this file.
---@return TauntManager
function CreateTauntManager(name, fileName)
    ScenarioInfo.TauntManagers = ScenarioInfo.TauntManagers or {}
    local tm = TauntManager(name, fileName)
    ScenarioInfo.TauntManagers[name] = tm
    return tm
end
