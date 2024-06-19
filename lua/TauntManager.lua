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


TauntManager = ClassSimple
{
    __init = function(self, name, filename)
        self.Trash = TrashBag()

        self.ManagerName = name
        self.TauntingCharacter = false
        self.Active = false
        self.TauntNumber = 0
        self.TauntData = {}
        self.UnlockTimer = 30

        self.CustomTaunts = {}
        self.PlayedTaunts = {}
        self.FileName = false
        self.FileData = false

        if filename then
            self:SetTauntFile(filename)
        end
    end,


    Activate = function(self, bool)
        self.Active = bool
    end,

    IsActive = function(self)
        return self.Active
    end,



    ---------- CONFIRMED WORKING TAUNTS ----------
    AddAttackTaunt = function(self, diagData, opAI, attacks)
        local currNum, callback = self:TauntBasics(diagData)

        attacks = attacks or 'All'

        local attackFunc = function(platoon)

            local counter = ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName .. '_FormedCounter'] or 0
            counter = counter + 1
            ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName .. '_FormedCounter'] = counter

            if type(attacks) == 'table' then
                for k, v in attacks do
                    if v == counter then
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

    AddAreaTaunt = function(self, diagData, area, category, brain, number)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateAreaTrigger(callback, area, category, true, false, brain, number, true)
    end,

    AddPlayerIntelCategoryTaunt = function(self, diagData, targetBrain, category)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', false, true, category, true, targetBrain)
    end,

    AddIntelCategoryTaunt = function(self, diagData, lookingBrain, targetBrain, category)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', false, true, category, true, targetBrain)
    end,

    AddPlayerIntelUnitTaunt = function(self, diagData, unit)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', unit, true, categories.ALLUNITS, true,
            unit:GetAIBrain())
    end,

    AddIntelUnitTaunt = function(self, diagData, unit, lookingBrain)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', unit, true, categories.ALLUNITS, true,
            unit:GetAIBrain())
    end,

    AddUnitDestroyedTaunt = function(self, diagData, unit)
        self:AddUnitKilledTaunt(diagData, unit, true)
    end,

    AddUnitKilledTaunt = function(self, diagData, unit, destroyed)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateUnitDeathTrigger(callback, unit)
        if destroyed then
            TriggerFile.CreateUnitCapturedTrigger(callback, nil, unit)
            TriggerFile.CreateUnitReclaimedTrigger(callback, unit)
        end
    end,

    AddUnitGroupDeathTaunt = function(self, diagData, unitTable, number)
        local currNum, callback = self:TauntBasics(diagData)
        if not number then
            TriggerFile.CreateGroupDeathTrigger(callback, unitTable)
        else
            TriggerFile.CreateSubGroupDeathTrigger(callback, unitTable, number)
        end
    end,

    AddUnitGroupDeathPercentTaunt = function(self, diagData, unitTable, percent)
        local unitNum = table.getn(unitTable)
        local newNum = math.ceil(percent * unitNum)
        self:AddUnitGroupDeathTaunt(diagData, unitTable, newNum)
    end,

    AddDamageTaunt = function(self, diagData, unit, percent)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateUnitDamagedTrigger(callback, unit, percent)
    end,

    AddConstructionTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'ConstructionTaunt' .. self.ManagerName .. currNum,
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

    AddStartBuildTaunt = function(self, diagData, brain, category, delaySecs)
        local currNum, callback = self:TauntBasics(diagData, delaySecs)

        TriggerFile.CreateArmyStatTrigger(callback, brain, 'BuildTaunt' .. self.ManagerName .. currNum,
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

    AddUnitsKilledTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'UnitsKilled_' .. self.ManagerName .. currNum,
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

    AddEnemiesKilledTaunt = function(self, diagData, brain, category, number)
        local currNum, callback = self:TauntBasics(diagData)
        number = number or 1
        TriggerFile.CreateArmyStatTrigger(callback, brain, 'EnemiesKilled_' .. self.ManagerName .. currNum,
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

    AddTimerTaunt = function(self, diagData, seconds)
        local currNum, callback = self:TauntBasics(diagData)
        TriggerFile.CreateTimerTrigger(callback, seconds)
    end,

    AddCustomTaunt = function(self, diagData, customName)
        if self.CustomTaunts[customName] then
            error('Custom taunt named "' .. customName .. '" already exists in TauntManager "' .. self.ManagerName .. '"'
                , 2)
            return
        end
        local currNum, callback = self:TauntBasics(diagData)
        self.CustomTaunts[customName] = currNum
    end,

    PlayCustomTaunt = function(self, customName)
        if not self.CustomTaunts[customName] then
            error('Custom taunt named "' .. customName .. '" not found in TauntManager "' .. self.ManagerName .. '"', 2)
            return
        end
        self:PlayTaunt(self.CustomTaunts[customName])
    end,





    ------------ MISC FUNCTIONS ------------
    TauntingCharacterCheck = function(self)
        return not self.TauntingCharacter or not self.TauntingCharacter:IsDead()
    end,

    AddTauntingCharacter = function(self, unit)
        if unit:IsDead() then return end

        self.TauntingCharacter = unit
    end,

    TauntBasics = function(self, diagData, delaySecs)
        self.TauntNumber = self.TauntNumber + 1
        local currNum = self.TauntNumber
        if type(diagData) == 'table' then
            self.TauntData[currNum] = diagData
        elseif type(diagData) == 'string' then
            self.TauntData[currNum] = { diagData }
        else
            error('Invalid data for Taunt - must be table of strings or a string', 2)
        end
        local callback

        if delaySecs then
            callback = function()
                ForkThread(function()
                    WaitSeconds(delaySecs)
                    LOG('*DEBUG: Taunt played number ' .. currNum)
                    self:PlayTaunt(currNum)
                end)
            end
        else
            callback = function()
                LOG('*DEBUG: Taunt played number ' .. currNum)
                self:PlayTaunt(currNum)
            end
        end

        return currNum, callback
    end,

    PlayTaunt = function(self, tauntNum)
        if not self:IsActive() then return end
        if not self:TauntingCharacterCheck() then return end

        local possibleTaunts = {}
        for num, name in self.TauntData[tauntNum] do
            if not self.PlayedTaunts[name] then
                table.insert(possibleTaunts, name)
            end
        end

        if table.empty(possibleTaunts) then return end

        if self.TauntsLocked then return end

        local tauntName = table.random(possibleTaunts)
        self.PlayedTaunts[tauntName] = true
        self.TauntsLocked = true
        ScenarioFramework.Dialogue(self.FileData[tauntName], function()
            self:UnlockTaunts()
        end)

    end,

    SetTauntFile = function(self, fileName)
        self.FileName = fileName
        self.FileData = import(fileName)
        self.Active = true
    end,

    SetUnlockTime = function(self, seconds)
        self.UnlockTimer = seconds
    end,

    UnlockTaunts = function(self)
        WaitSeconds(self.UnlockTimer)
        self.TauntsLocked = false
    end,

}


function CreateTauntManager(name, fileName)
    ScenarioInfo.TauntManagers = ScenarioInfo.TauntManagers or {}
    ScenarioInfo.TauntManagers[name] = TauntManager(name, fileName)
    return ScenarioInfo.TauntManagers[name]
end
