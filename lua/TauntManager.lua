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

function CreateTauntManager(name, fileName)
    local tManager = {
        Trash = TrashBag(),

        ManagerName = name,
        TauntingCharacter = false,
        Active = false,
        TauntNumber = 0,
        TauntData = {},
        UnlockTimer = 30,

        CustomTaunts = {},
        PlayedTaunts = {},
        FileName = false,
        FileData = false,

        Activate = function(self, bool)
            self.Active = bool
        end,

        IsActive = function(self)
            return self.Active
        end,



        ---------- CONFIRMED WORKING TAUNTS ----------
        AddAttackTaunt = function(self,diagData,opAI,attacks)
            local currNum, callback = self:TauntBasics(diagData)
            if not attacks then
                attacks = 'All'
            end
            local attackFunc = function(platoon)
                if not ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] then
                    ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] = 0
                end
                ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] = ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] + 1
                if type(attacks) == 'table' then
                    for k,v in attacks do
                        if v == ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] then
                            callback()
                            break
                        end
                    end
                elseif attacks == ScenarioInfo.VarTable[platoon.PlatoonData.PlatoonName..'_FormedCounter'] then
                    callback()
                elseif attacks == 'All' then
                    callback()
                end
            end
            opAI:AddFormCallback(attackFunc)
        end,

        AddAreaTaunt = function(self,diagData,area,category,brain,number)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateAreaTrigger(callback, area, category, true, false, brain, number, true)
        end,

        AddPlayerIntelCategoryTaunt = function(self, diagData, targetBrain, category )
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', false, true, category, true, targetBrain)
        end,

        AddIntelCategoryTaunt = function(self, diagData, lookingBrain, targetBrain, category)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', false, true, category, true, targetBrain)
        end,

        AddPlayerIntelUnitTaunt = function(self, diagData, unit)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateArmyIntelTrigger(callback, ArmyBrains[1], 'LOSNow', unit, true, categories.ALLUNITS, true, unit:GetAIBrain() )
        end,

        AddIntelUnitTaunt = function(self, diagData, unit, lookingBrain)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateArmyIntelTrigger(callback, lookingBrain, 'LOSNow', unit, true, categories.ALLUNITS, true, unit:GetAIBrain() )
        end,

        AddUnitDestroyedTaunt = function(self,diagData,unit)
            self:AddUnitKilledTaunt(diagData,unit,true)
        end,

        AddUnitKilledTaunt = function(self,diagData,unit,destroyed)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateUnitDeathTrigger(callback, unit)
            if destroyed then
                TriggerFile.CreateUnitCapturedTrigger(callback, nil, unit)
                TriggerFile.CreateUnitReclaimedTrigger(callback, unit)
            end
        end,

        AddUnitGroupDeathTaunt = function(self,diagData,unitTable,number)
            local currNum, callback = self:TauntBasics(diagData)
            if not number then
                TriggerFile.CreateGroupDeathTrigger( callback, unitTable )
            else
                TriggerFile.CreateSubGroupDeathTrigger(callback, unitTable, number)
            end
        end,

        AddUnitGroupDeathPercentTaunt = function(self,diagData,unitTable,percent)
            local unitNum = table.getn(unitTable)
            local newNum = math.ceil(percent * unitNum)
            self:AddUnitGroupDeathTaunt(diagData,unitTable,newNum)
        end,

        AddDamageTaunt = function(self,diagData,unit,percent)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateUnitDamagedTrigger( callback, unit, percent )
        end,

        AddConstructionTaunt = function(self,diagData,brain,category,number)
            local currNum, callback = self:TauntBasics(diagData)
            if not number then
                number = 1
            end
            TriggerFile.CreateArmyStatTrigger( callback, brain, 'ConstructionTaunt' .. self.ManagerName .. currNum,
                {
                    {
                        StatType = 'Units_History',
                        CompareType = 'GreaterThanOrEqual',
                        Value = brain:GetBlueprintStat('Units_History',category) + number,
                        Category = category,
                    },
                }
            )
        end,

        AddStartBuildTaunt = function(self, diagData, brain, category, delaySecs)
            local currNum, callback = self:TauntBasics(diagData, delaySecs)

            TriggerFile.CreateArmyStatTrigger( callback, brain, 'BuildTaunt' .. self.ManagerName .. currNum,
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

        AddUnitsKilledTaunt = function(self,diagData,brain,category,number)
            local currNum, callback = self:TauntBasics(diagData)
            if not number then
                number = 1
            end
            TriggerFile.CreateArmyStatTrigger( callback, brain, 'UnitsKilled_' .. self.ManagerName .. currNum,
                {
                    {
                        StatType = 'Units_Killed',
                        CompareType = 'GreaterThanOrEqual',
                        Value = brain:GetBlueprintStat('Units_Killed',category) + number,
                        Category = category,
                    },
                }
            )
        end,

        AddEnemiesKilledTaunt = function(self,diagData,brain,category,number)
            local currNum, callback = self:TauntBasics(diagData)
            if not number then
                number = 1
            end
            TriggerFile.CreateArmyStatTrigger( callback, brain, 'EnemiesKilled_' .. self.ManagerName .. currNum,
                {
                    {
                        StatType = 'Enemies_Killed',
                        CompareType = 'GreaterThanOrEqual',
                        Value = brain:GetBlueprintStat('Enemies_Killed',category) + number,
                        Category = category,
                    },
                }
            )
        end,

        AddTimerTaunt = function(self,diagData,seconds)
            local currNum, callback = self:TauntBasics(diagData)
            TriggerFile.CreateTimerTrigger(callback, seconds)
        end,

        AddCustomTaunt = function(self,diagData,customName)
            if self.CustomTaunts[customName] then
                error('Custom taunt named "' .. customName .. '" already exists in TauntManager "' .. self.ManagerName .. '"', 2)
                return
            end
            local currNum, callback = self:TauntBasics(diagData)
            self.CustomTaunts[customName] = currNum
        end,

        PlayCustomTaunt = function(self,customName)
            if not self.CustomTaunts[customName] then
                error('Custom taunt named "' .. customName .. '" not found in TauntManager "' .. self.ManagerName .. '"', 2)
                return
            end
            self:PlayTaunt(self.CustomTaunts[customName])
        end,





        ------------ MISC FUNCTIONS ------------
        TauntingCharacterCheck = function(self)
            if not self.TauntingCharacter or not self.TauntingCharacter:IsDead() then
                return true
            end
            return false
        end,

        AddTauntingCharacter = function(self,unit)
            if not unit:IsDead() then
                self.TauntingCharacter = unit
            end
        end,

        TauntBasics = function(self,diagData, delaySecs)
            self.TauntNumber = self.TauntNumber + 1
            local currNum = self.TauntNumber
            if type(diagData) == 'table' then
                self.TauntData[currNum] = diagData
            elseif type(diagData) == 'string' then
                self.TauntData[currNum] = { diagData }
            else
                error('Invalid data for Taunt - must be table of strings or a string',2)
            end
            local callback = false

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

        PlayTaunt = function(self,tauntNum)
            if not self:IsActive() then
                return
            end
            if not self:TauntingCharacterCheck() then
                return
            end

            local possibleTaunts = {}
            for num,name in self.TauntData[tauntNum] do
                if not self.PlayedTaunts[name] then
                    table.insert(possibleTaunts, name)
                end
            end
            if table.getn(possibleTaunts) == 0 then
                return
            end

            if not self.TauntsLocked then
                local num = Random(1,table.getn(possibleTaunts))
                local tauntName = possibleTaunts[num]
                local unlockCallback = function()
                    self:UnlockTaunts()
                end
                self.PlayedTaunts[tauntName] = true
                self.TauntsLocked = true
                ScenarioFramework.Dialogue( self.FileData[tauntName], unlockCallback )
            end
        end,

        SetTauntFile = function(self,fileName)
            self.FileName = fileName
            self.FileData = import(fileName)
            self.Active = true
        end,

        SetUnlockTime = function(self,seconds)
            self.UnlockTimer = seconds
        end,

        UnlockTaunts = function(self)
            WaitSeconds(self.UnlockTimer)
            self.TauntsLocked = false
        end,
    }
    if not ScenarioInfo.TauntManagers then
        ScenarioInfo.TauntManagers = {}
    end
    ScenarioInfo.TauntManagers[name] = tManager

    if fileName then
        tManager:SetTauntFile(fileName)
    end

    return tManager
end