-- File     :  /lua/ai/SorianStrategyBuilders.lua
-- Summary  : Default Naval structure builders for skirmish
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local MIBC = '/lua/editor/miscbuildconditions.lua'
local MABC = '/lua/editor/markerbuildconditions.lua'
local EBC = '/lua/editor/economybuildconditions.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'
local AIUtils = import("/lua/ai/aiutilities.lua")
local Behaviors = import("/lua/ai/aibehaviors.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local UpgradeTemplates = import("/lua/upgradetemplates.lua")
local SUtils = import("/lua/ai/sorianutilities.lua")

local econThread

---@param aiBrain AIBrain
function EconWatch(aiBrain)
    local factionIndex = aiBrain:GetFactionIndex()
    local cats = {
        categories.MASSEXTRACTION * categories.TECH1,
        categories.FACTORY * categories.TECH1,
        categories.MASSEXTRACTION * categories.TECH2,
        categories.FACTORY * categories.TECH2,
        categories.MASSEXTRACTION * categories.TECH3,
        categories.FACTORY * categories.TECH3,
    }
    repeat
        for _,cat in cats do
            local units = aiBrain:GetListOfUnits(cat, false)
            if table.empty(units) then continue end
            for k, unit in units do
                if unit.Dead then continue end
                local upgradeID
                if EntityCategoryContains(categories.MOBILE, unit) then
                    upgradeID = aiBrain:FindUpgradeBP(unit.UnitId, UpgradeTemplates.UnitUpgradeTemplates[factionIndex])
                else
                    upgradeID = aiBrain:FindUpgradeBP(unit.UnitId, UpgradeTemplates.StructureUpgradeTemplates[factionIndex])
                end
                if upgradeID and EntityCategoryContains(categories.STRUCTURE, unit) and not unit:CanBuild(upgradeID) then
                    continue
                end
                if upgradeID then
                    IssueStop({unit})
                    IssueUpgrade({unit}, upgradeID)
                end
                WaitSeconds(2)
                if AIUtils.AIGetEconomyNumbers(aiBrain).MassEfficiency < 1.0
                or AIUtils.AIGetEconomyNumbers(aiBrain).EnergyEfficiency < 1.0 then break end
            end
            if AIUtils.AIGetEconomyNumbers(aiBrain).MassEfficiency < 1.0
            or AIUtils.AIGetEconomyNumbers(aiBrain).EnergyEfficiency < 1.0 then break end
        end
        WaitSeconds(1)
    until AIUtils.AIGetEconomyNumbers(aiBrain).MassEfficiency < 1.0
    or AIUtils.AIGetEconomyNumbers(aiBrain).EnergyEfficiency < 1.0

    econThread = nil
end

BuilderGroup {
    BuilderGroupName = 'Sorian Excess Mass Strategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Excess Mass Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = true
            if econThread then
                KillThread(econThread)
            end
            econThread = aiBrain:ForkThread(EconWatch)
        end,
        OnStrategyDeactivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = false
            if econThread then
                KillThread(econThread)
                econThread = nil
            end
        end,
        PriorityFunction = function(self, aiBrain)
            if econThread or not (econThread and Builders[self.BuilderName].Running) then
                return 100
            elseif not econThread and Builders[self.BuilderName].Running then
                return 0
            end
        end,
        BuilderConditions = {
            { SBC, 'GreaterThanGameTime', { 300 }},
            { SBC, 'CategoriesNotRestricted', { {'T2', 'T3'} }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.0, 1.0}},
            { SIBC, 'GreaterThanEconEfficiency', { 1.0, 1.0 }},
            { EBC, 'GreaterThanEconStorageRatio', {0.5, 0}},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Land Exp1 Engineer - Excess Mass',
                'Sorian T3 Land Exp1 Engineer - Large Map - Excess Mass',
                'Sorian T3 Engineer Assist Experimental Mobile Land - Excess Mass',
                'Sorian T3 Air Exp1 Engineer 1 - Excess Mass',
                'Sorian T3 Air Exp1 Engineer 1 - Small Map - Excess Mass',
                'Sorian T3 Engineer Assist Experimental Mobile Air - Excess Mass',
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Sorian Tele SCU Strategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Tele SCU Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = true
            local x,z = aiBrain:GetArmyStartPos()
            local faction = aiBrain:GetFactionIndex()
            local upgrades
            local removes
            if faction == 2 then
                upgrades = {'StabilitySuppressant', 'Teleporter'}
            elseif faction == 4 then
                upgrades = {'Shield', 'Teleporter'}
            end
            local SCUs = {}
            local possSCUs = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.SUBCOMMANDER, {x,0,z}, 200)
            for k,v in possSCUs do
                table.insert(SCUs, v)
                if table.getn(SCUs) > 2 then
                    break
                end
            end
            for k,v in SCUs do
                if v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) then
                    v.PlatoonHandle:RemoveEngineerCallbacksSorian()
                    v.PlatoonHandle:Stop()
                    v.PlatoonHandle:PlatoonDisbandNoAssign()
                end
                if v.NotBuildingThread then
                    KillThread(v.NotBuildingThread)
                    v.NotBuildingThread = nil
                end
                if v.ProcessBuild then
                    KillThread(v.ProcessBuild)
                    v.ProcessBuild = nil
                end
                v.BuilderManagerData.EngineerManager:RemoveUnit(v)
                IssueStop({v})
                IssueClearCommands({v})
                if v:HasEnhancement('Overcharge') then
                    local order = {
                        TaskName = "EnhanceTask",
                        Enhancement = "OverchargeRemove"
                    }
                    IssueScript({v}, order)
                elseif v:HasEnhancement('ResourceAllocation') then
                    local order = {
                        TaskName = "EnhanceTask",
                        Enhancement = "ResourceAllocationRemove"
                    }
                    IssueScript({v}, order)
                end
            end
            local plat = aiBrain:MakePlatoon('', '')
            aiBrain:AssignUnitsToPlatoon(plat, SCUs, 'attack', 'None')
            for k,v in SCUs do
                for x,z in upgrades do
                    if not v:HasEnhancement(z) then
                        local order = {
                            TaskName = "EnhanceTask",
                            Enhancement = z
                        }
                        IssueScript({v}, order)
                    end
                end
            end
            local allDead
            local upgradesFinished
            repeat
                WaitSeconds(5)
                allDead = true
                upgradesFinished = true
                if not aiBrain:PlatoonExists(plat) then
                    Builders[self.BuilderName].Running = false
                    return
                end
                for k,v in plat:GetPlatoonUnits() do
                    if not v.Dead then
                        allDead = false
                    end
                    if not v:HasEnhancement(upgrades[2]) then
                        upgradesFinished = false
                    end
                end
            until allDead or upgradesFinished

            if allDead then return end

            local targetLocation = Behaviors.GetHighestThreatClusterLocationSorian(aiBrain, plat)
            for k,v in SCUs do
                local telePos = AIUtils.RandomLocation(targetLocation[1],targetLocation[3])
                IssueTeleport({v}, telePos)
            end
            WaitSeconds(45)
            plat:HuntAISorian()
            Builders[self.BuilderName].Running = false
        end,
        PriorityFunction = function(self, aiBrain)
            if Builders[self.BuilderName].Running then
                return 100
            end
            local enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            if Random(1,10) == 7 then
                returnval = 100
            end

            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { MIBC, 'FactionIndex', {2, 4}},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 2, 'SUBCOMMANDER' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.3}},
            { SIBC, 'GreaterThanEconIncome', {15, 1000}},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {}
    },
}

BuilderGroup {
    BuilderGroupName = 'Sorian Engy Drop Strategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Engy Drop Strategy',
        StrategyType = 'Intermediate',
        Priority = 0, --100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = true
            LOG('*AI DEBUG: Sorian Engy Drop Strategy Activated by '..aiBrain.Nickname..'!')
            local x,z = aiBrain:GetArmyStartPos()
            local count = 0
            repeat
                WaitSeconds(5)
                count = count + 1
                if count > 18 then
                    Builders[self.BuilderName].Running = false
                    Builders[self.BuilderName].Done = true
                    return
                end
                airfacs = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.AIR * categories.FACTORY, {x,0,z}, 150)
            until not table.empty(airfacs)
            local ex, ey = aiBrain:GetCurrentEnemy():GetArmyStartPos()
            local Engies = {}
            local possEngies = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.ENGINEER * categories.TECH1, {x,0,z}, 200)
            for k,v in possEngies do
                table.insert(Engies, v)
                if table.getn(Engies) > 3 then
                    break
                end
            end
            if table.getn(Engies) < 2 then
                Builders[self.BuilderName].Running = false
                Builders[self.BuilderName].Done = true
                return
            end
            for k,v in Engies do
                if v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) then
                    v.PlatoonHandle:RemoveEngineerCallbacksSorian()
                    v.PlatoonHandle:Stop()
                    v.PlatoonHandle:PlatoonDisbandNoAssign()
                end
                if v.NotBuildingThread then
                    KillThread(v.NotBuildingThread)
                    v.NotBuildingThread = nil
                end
                if v.ProcessBuild then
                    KillThread(v.ProcessBuild)
                    v.ProcessBuild = nil
                end
                v.BuilderManagerData.EngineerManager:RemoveUnit(v)
                IssueStop({v})
                IssueClearCommands({v})
            end
            local plat = aiBrain:MakePlatoon('', '')
            aiBrain:AssignUnitsToPlatoon(plat, Engies, 'support', 'None')
            for x=-60, 60, 60 do
                for y=-60, 60, 60 do
                    if not (x == 0 and y == 0) then
                        tempPos = {ex + x ,0, ey + y}
                        local nextbase = (table.getn(aiBrain.TacticalBases) + 1)
                        table.insert(aiBrain.TacticalBases,
                            {
                            Position = tempPos,
                            Name = 'TacticalBase'..nextbase,
                            }
                        )
                    end
                end
            end
            local targetPos = AIUtils.AIFindFirebaseLocationSorian(aiBrain, 'Main', 75, 'Expansion Area', -1000, 99999, 1, 'AntiSurface', 1, 'STRATEGIC', 20)
            if not targetPos then
                Builders[self.BuilderName].Running = false
                Builders[self.BuilderName].Done = true
                return
            end
            local data = {
                Construction = {
                    BuildClose = false,
                    BaseTemplate = 'ExpansionBaseTemplates',
                    FireBase = true,
                    FireBaseRange = 75,
                    NearMarkerType = 'Expansion Area',
                    LocationType = 'MAIN',
                    ThreatMin = -1000,
                    ThreatMax = 99999,
                    ThreatRings = 1,
                    ThreatType = 'AntiSurface',
                    MarkerUnitCount = 1,
                    MarkerUnitCategory = 'STRATEGIC',
                    MarkerRadius = 20,
                    BuildStructures = {
                        'T1GroundDefense',
                        'T1GroundDefense',
                        'T1GroundDefense',
                        'T1GroundDefense',
                        'T1AADefense',
                        'T1GroundDefense',
                        'T1GroundDefense',
                        'T1GroundDefense',
                        'T1GroundDefense',
                    }
                }
            }
            plat:SetPlatoonData(data)
            local usedTransports = AIAttackUtils.SendPlatoonWithTransportsSorian(aiBrain, plat, targetPos, true, true, true)
            if not usedTransports then
                Builders[self.BuilderName].Running = false
                Builders[self.BuilderName].Done = true
                return
            end
            plat:EngineerBuildAISorian()
            Builders[self.BuilderName].Running = false
            Builders[self.BuilderName].Done = true
        end,
        PriorityFunction = function(self, aiBrain)
            if Builders[self.BuilderName].Running then
                return 100
            --elseif Builders[self.BuilderName].Done then
            --	return 0
            end
            local enemyIndex
            local returnval = 0
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            --if Random(1,100) == 100 then
                returnval = 100
            --end

            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH1' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SBC, 'MapLessThan', { 1000, 1000 }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            FactoryManager = {
                'Sorian T1 Air Transport - GG',
            },
            EngineerManager = {
                'SorianAirFactoryHighPrio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'Sorian PD Creep Strategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian PD Creep Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = true
            local x,z = aiBrain:GetArmyStartPos()
            local ex, ez = aiBrain:GetCurrentEnemy():GetArmyStartPos()
            local path, reason, pathDistance = AIAttackUtils.PlatoonGenerateSafePathToNavMesh(aiBrain, 'Land', {x,0,z}, {ex,0,ez}, 10)
            if path then
                for pathnum,waypoint in path do
                    local nextbase = (table.getn(aiBrain.TacticalBases) + 1)
                    table.insert(aiBrain.TacticalBases,
                        {
                        Position = waypoint,
                        Name = 'PDCreep'..nextbase,
                        }
                    )
                end
            end
        end,
        PriorityFunction = function(self, aiBrain)
            if Builders[self.BuilderName].Running then
                return 100
            elseif Builders[self.BuilderName].Done then
                return 0
            end
            local enemyIndex
            local returnval = 0
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            if Random(1,15) == 3 then
                returnval = 100
            end

            Builders[self.BuilderName].Done = true

            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH3' }},
            { SBC, 'MapLessThan', { 1000, 1000 }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T1 - High Prio Defensive Point Engineer',
                'Sorian T2 - High Prio Defensive Point Engineer UEF',
                'Sorian T2 - High Prio Defensive Point Engineer Cybran',
                'Sorian T2 - High Prio Defensive Point Engineer',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianWaterMapLowLand',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Water Map Low Land',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SBC, 'IsIslandMap', { true } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 29, categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Bot - Early Game Rush',
                'Sorian T1 Bot - Early Game',
                'Sorian T1 Light Tank - Tech 1',
                'Sorian T1 Light Tank - Tech 2',
                'Sorian T1 Light Tank - Tech 3',
                'Sorian T1 Mortar',
                'Sorian T1 Mortar - Not T1',
                'Sorian T1 Mortar - tough def',
                'Sorian T1 Mobile AA',
                'Sorian T1 Mobile AA - Response',
                'Sorian T1 Tank Enemy Nearby',
                'Sorian T2 Tank - Tech 2',
                'Sorian T2 Tank 2 - Tech 3',
                'Sorian T2 MML',
                'Sorian T2AttackTank - Tech 2',
                'Sorian T2AttackTank2 - Tech 3',
                --'Sorian T2 Amphibious Tank - Tech 2',
                --'Sorian T2 Amphibious Tank - Tech 3',
                --'Sorian T2 Amphibious Tank - Tech 2 Cybran',
                --'Sorian T2 Amphibious Tank - Tech 3 Cybran',
                'Sorian T2MobileShields',
                'Sorian T2 Tank Enemy Nearby',
                'Sorian T2 Mobile Flak',
                'Sorian T2 Mobile Flak Response',
                'Sorian T3 Siege Assault Bot',
                'Sorian T3 Mobile Heavy Artillery',
                'Sorian T3 Mobile Heavy Artillery - tough def',
                'Sorian T3 Mobile Flak',
                'Sorian T3SniperBots',
                --'Sorian T3ArmoredAssault',
                'Sorian T3MobileMissile',
                'Sorian T3MobileShields',
                'Sorian T3 Mobile AA Response',
                'Sorian T3 Assault Enemy Nearby',
                'Sorian T3 SiegeBot Enemy Nearby',
            },
        },
        AddBuilders = {}
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianBigAirGroup',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Big Air Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end
            if not aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * categories.TECH3) > 1 then
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiAir', enemyIndex)
            local numEUnits = aiBrain:GetNumUnitsAroundPoint(categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, Vector(0,0,0), 100000, 'Enemy')

            returnval = (enemyThreat * 1.5) - numEUnits
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            --{ SBC, 'GreaterThanThreatAtEnemyBase', { 'AntiAir', 55 }},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 1, 'FACTORY AIR TECH3' }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 5, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, 'Enemy'}},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                'Sorian T2 Air Gunship',
                'Sorian T2 Air Gunship - Anti Navy',
                'Sorian T2 Air Gunship - Stomp Enemy',
                'Sorian T2FighterBomber',
                'Sorian T2 Air Gunship2',
                'Sorian T2FighterBomber2',
                'Sorian T3 Air Gunship',
                'Sorian T3 Air Gunship - Anti Navy',
                'Sorian T3 Air Bomber',
                'Sorian T3 Air Bomber - Stomp Enemy',
                'Sorian T3 Air Gunship2',
                'Sorian T3 Air Bomber2',
            },
            PlatoonFormManager = {
                'Sorian BomberAttackT1Frequent',
                'Sorian BomberAttackT1Frequent - Anti-Land',
                --'Sorian BomberAttackT1Frequent - Anti-Resource',
                'Sorian BomberAttackT2Frequent',
                'Sorian BomberAttackT2Frequent - Anti-Land',
                --'Sorian BomberAttackT2Frequent - Anti-Resource',
                'Sorian BomberAttackT3Frequent',
                'Sorian BomberAttackT3Frequent - Anti-Land',
                --'Sorian BomberAttackT3Frequent - Anti-Resource',
                'Sorian T1 Bomber Attack Weak Enemy Response',
                --'Sorian BomberAttack Mass Hunter',
            }
        },
        AddBuilders = {
            FactoryManager = {
                'Sorian T2 Air Bomber - High Prio',
                'Sorian T3 Air Bomber Special - High Prio',
            },
            PlatoonFormManager = {
                'Sorian Bomber Attack - Big',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianJesterRush',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Jester Rush Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        PriorityFunction = function(self, aiBrain)
            local enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            local myFacs = aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR)

            if aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * (categories.TECH3 + categories.TECH2)) > 0 or myFacs < 1 then
                return returnval
            end

            local eUnits = aiBrain:GetUnitsAroundPoint(categories.AIR * categories.FACTORY, Vector(0,0,0), 100000, 'Enemy')
            local count = 0

            for k,v in eUnits do
                if v:GetAIBrain():GetArmyIndex() == enemyIndex then
                    count = count + 1
                end
            end

            returnval = 74 + (myFacs * 5) - (count * 4)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { MIBC, 'FactionIndex', {3}},
            { SBC, 'MapLessThan', { 1000, 1000 }},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY AIR' }},
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY AIR TECH2, FACTORY AIR TECH3' }},
            --{ SBC, 'TargetHasLessThanUnitsWithCategory', { 3, categories.AIR * categories.FACTORY }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 3, categories.AIR * categories.FACTORY, 'Enemy'}},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Fighter',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                --'Sorian T1 Interceptors',
                --'Sorian T1 Interceptors - Enemy Air',
                --'Sorian T1 Interceptors - Enemy Air Extra',
                --'Sorian T1 Interceptors - Enemy Air Extra 2',
                'Sorian T2 Air Gunship',
                'Sorian T2 Air Gunship - Anti Navy',
                'Sorian T2 Air Gunship - Stomp Enemy',
                'Sorian T2FighterBomber',
                'Sorian T1 Air Fighter - T2',
                'Sorian T2 Air Gunship2',
                'Sorian T2FighterBomber2',
                --'Sorian T2AntiAirPlanes Initial Higher Pri',
                --'Sorian T2AntiAirPlanes - Enemy Air',
                --'Sorian T2AntiAirPlanes - Enemy Air Extra',
                --'Sorian T2AntiAirPlanes - Enemy Air Extra 2',
                'Sorian T3 Air Gunship',
                'Sorian T3 Air Gunship - Anti Navy',
                'Sorian T3 Air Bomber',
                'Sorian T3 Air Bomber - Stomp Enemy',
                'Sorian T3 Air Gunship2',
                'Sorian T3 Air Bomber2',
            },
            PlatoonFormManager = {
                'Sorian GunshipAttackT1Frequent',
                'Sorian GunshipAttackT2Frequent',
                'Sorian GunshipAttackT3Frequent',
                'Sorian T1 GunShip Attack Weak Enemy Response',
                'Sorian Mass Hunter Gunships',
            }
        },
        AddBuilders = {
            FactoryManager = {
                'Sorian T1Gunship - High Prio',
            },
            PlatoonFormManager = {
                'Sorian GunShip Attack - Large',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianRushGunUpgrades',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Rush Gun Upgrades',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            Builders[self.BuilderName].Running = true
        end,
        PriorityFunction = function(self, aiBrain)
            if Builders[self.BuilderName].Running then
                return 100
            elseif Builders[self.BuilderName].Done then
                return 0
            end
            local returnval = 0

            if Random(1,10) > 5 then
                returnval = 100
            end

            Builders[self.BuilderName].Done = true

            return returnval
        end,
        BuilderConditions = {
            { SBC, 'ClosestEnemyLessThan', { 750 } },
            { SBC, 'EnemyToAllyRatioLessOrEqual', { 1.0 } },
            { SBC, 'IsBadMap', { false } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            EngineerManager = {
                'Sorian UEF CDR Upgrade AdvEng - Pods',
                'Sorian UEF CDR Upgrade T3 Eng - Shields',
                'Sorian Aeon CDR Upgrade AdvEng - Resource - Crysalis',
                'Sorian Aeon CDR Upgrade T3 Eng - ResourceAdv - EnhSensor',
                'Sorian Cybran CDR Upgrade AdvEng - Laser Gen',
                'Sorian Cybran CDR Upgrade T3 Eng - Resource',
                'Sorian Seraphim CDR Upgrade AdvEng - Resource - Crysalis',
                'Sorian Seraphim CDR Upgrade T3 Eng - ResourceAdv - EnhSensor',
            },
        },
        AddBuilders = {
            EngineerManager = {
                'Sorian UEF CDR Upgrade - Rush - Gun',
                'Sorian UEF CDR Upgrade - Rush - Eng',
                'Sorian UEF CDR Upgrade - Rush - Shield',
                'Sorian Aeon CDR Upgrade - Rush - Gun',
                'Sorian Aeon CDR Upgrade - Rush - Eng',
                'Sorian Aeon CDR Upgrade T3 - Rush - Shield',
                'Sorian Cybran CDR Upgrade - Rush - Gun',
                'Sorian Cybran CDR Upgrade - Rush - Eng',
                'Sorian Cybran CDR Upgrade - Rush - Laser',
                'Sorian Seraphim CDR Upgrade - Rush - Gun',
                'Sorian Seraphim CDR Upgrade - Rush - Eng',
                'Sorian Seraphim CDR Upgrade - Rush - Regen',
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianGhettoGunship',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Ghetto Gunship Strategy',
        StrategyType = 'Intermediate',
        Priority = 0, --100,
        InstanceCount = 1,
        StrategyTime = 300,
        InterruptStrategy = true,
        OnStrategyActivate = function(self, aiBrain)
            LOG('*AI DEBUG: SorianGhettoGunship strat activated')
        end,
        PriorityFunction = function(self, aiBrain)
            local enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            local myFacs = aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR)

            if aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * (categories.TECH3 + categories.TECH2)) > 0 or myFacs < 1 then
                return returnval
            end

            local eUnits = aiBrain:GetUnitsAroundPoint(categories.AIR * categories.FACTORY, Vector(0,0,0), 100000, 'Enemy')
            local count = 0

            for k,v in eUnits do
                if v:GetAIBrain():GetArmyIndex() == enemyIndex then
                    count = count + 1
                end
            end

            returnval = 69 + (myFacs * 5) - (count * 2)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { MIBC, 'FactionIndex', {1, 2, 3}},
            { SBC, 'MapLessThan', { 1000, 1000 }},
            --{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'FACTORY AIR' }},
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY AIR TECH2, FACTORY AIR TECH3' }},
            --{ SBC, 'TargetHasLessThanUnitsWithCategory', { 3, categories.AIR * categories.FACTORY }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 3, categories.AIR * categories.FACTORY, 'Enemy'}},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            FactoryManager = {
                'Sorian T1 Air Transport - GG',
                'Sorian T1 Bot - GG',
            },
            PlatoonFormManager = {
                'Sorian GG Force',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianSmallMapRush',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Small Map Rush Strategy',
        StrategyType = 'Overall',
        Priority = 100,
        InstanceCount = 1,
        PriorityFunction = function(self, aiBrain)
            local returnval = 1
            local enemies = 0
            local allies = 0
            for k,v in ArmyBrains do
                if not v:IsDefeated() and not ArmyIsCivilian(v:GetArmyIndex()) and IsEnemy(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
                    enemies = enemies + 1
                elseif not v:IsDefeated() and not ArmyIsCivilian(v:GetArmyIndex()) and IsAlly(v:GetArmyIndex(), aiBrain:GetArmyIndex()) then
                    allies = allies + 1
                end
            end

            local ratio = allies / enemies

            local gtime = GetGameTimeSeconds()

            returnval = 75 + (ratio * 5) - (gtime * .004)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'IsIslandMap', { false } },
            { SBC, 'ClosestEnemyLessThan', { 750 } },
            { SBC, 'NoRushTimeCheck', { 0 }},
            --{ SBC, 'EnemyToAllyRatioLessOrEqual', { 1 } },
            --{ SBC, 'LessThanGameTime', { 1200 } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            EngineerManager = {
                'Sorian T1VacantStartingAreaEngineer - Rush',
                'Sorian T1VacantStartingAreaEngineer',
                'Sorian T1 Vacant Expansion Area Engineer(Full Base)',
            },
        },
        AddBuilders = {
            EngineerManager = {
                'Sorian T1VacantStartingAreaEngineer - HP Strategy',
                'Sorian T1VacantStartingAreaEngineer Strategy',
                'Sorian T1 Vacant Expansion Area Engineer(Full Base) - Strategy',
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3ArtyRush',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian T3 Arty Rush Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'rush arty' then
                return 100
            end
            local arties = aiBrain:GetCurrentUnits(categories.ARTILLERY * categories.STRUCTURE * categories.TECH3)

            local eUnits = aiBrain:GetNumUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE * categories.TECH3, Vector(0,0,0), 100000, 'Enemy')

            if arties - eUnits >= 3 then
                return returnval
            end

            returnval = 70 + (arties * 5) - (eUnits * 5)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH3' }},
            --{ SIBC, 'HaveLessThanUnitsWithCategory', { 1, 'ARTILLERY STRUCTURE TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 6, categories.SHIELD * categories.TECH3 * categories.STRUCTURE, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SIBC, 'GreaterThanEconIncome',  { 100, 3000}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', true } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Arty Engineer - High Prio',
                'Sorian T3 Engineer Assist Build Arty - High Prio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT3FBRush',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian T3 FB Rush Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'rush arty' then
                return 100
            end
            local arties = aiBrain:GetCurrentUnits(categories.ARTILLERY * categories.STRUCTURE * categories.TECH3)

            local eUnits = aiBrain:GetNumUnitsAroundPoint(categories.SHIELD * categories.STRUCTURE * categories.TECH3, Vector(0,0,0), 100000, 'Enemy')

            if arties - eUnits >= 3 then
                return returnval
            end

            returnval = 70 + (arties * 5) - (eUnits * 5)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH3' }},
            --{ SIBC, 'HaveLessThanUnitsWithCategory', { 1, 'ARTILLERY STRUCTURE TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 6, categories.SHIELD * categories.TECH3 * categories.STRUCTURE, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SIBC, 'GreaterThanEconIncome',  { 100, 3000}},
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Expansion Area Firebase Engineer - Cybran - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Aeon - HP',
                'Sorian T3 Expansion Area Firebase Engineer - UEF - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Seraphim - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Cybran - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Aeon - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - UEF - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Seraphim - DP - HP',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEnemyTurtle - In Range',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'SorianEnemyTurtle - In Range',
        Priority = 100,
        InstanceCount = 1,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            --local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiSurface', enemyIndex)
            local enemyThreat = SUtils.GetThreatAtPosition(aiBrain, {StartX, 0, StartZ}, 1, 'AntiSurface', {'Commander', 'Air', 'Experimental'}, enemyIndex)

            --If enemy base has more than 1750 anti-surface threat
            --T2 Arty, T1 PD, T2 PD, Bots, Tanks, Mobile Arty, Gunships, Bombers, ACU, SCUs.
            returnval = enemyThreat * 0.0429
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', true } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            PlatoonFormManager = {
                'Sorian Frequent Land Attack T1',
                'Sorian Frequent Land Attack T2',
                'Sorian Frequent Land Attack T3',
                'Sorian Start Location Attack',
                'Sorian Early Attacks Small',
                'Sorian Early Attacks Medium',
                'Sorian T2/T3 Land Weak Enemy Response',
                'Sorian T1 Land Weak Enemy Response',
                'Sorian T1 Hunters',
                'Sorian T2 Hunters',
                'Sorian T4 Exp Land',
            }
        },
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Arty Engineer - High Prio',
                'Sorian T3 Engineer Assist Build Arty - High Prio',
                'Sorian T3 Nuke Engineer - High Prio',
                'Sorian T3 Engineer Assist Build Nuke - High Prio',
                'Sorian T3 Engineer Assist Build Nuke Missile - High Prio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianEnemyTurtle - Out of Range',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'SorianEnemyTurtle - Out of Range',
        Priority = 100,
        InstanceCount = 1,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            --local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiSurface', enemyIndex)
            local enemyThreat = SUtils.GetThreatAtPosition(aiBrain, {StartX, 0, StartZ}, 1, 'AntiSurface', {'Commander', 'Air', 'Experimental'}, enemyIndex)

            --If enemy base has more than 1750 anti-surface threat
            --T2 Arty, T1 PD, T2 PD, Bots, Tanks, Mobile Arty, Gunships, Bombers, ACU, SCUs.
            returnval = enemyThreat * 0.0429
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SBC, 'EnemyInT3ArtilleryRange', { 'LocationType', false } },
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            PlatoonFormManager = {
                'Sorian Frequent Land Attack T1',
                'Sorian Frequent Land Attack T2',
                'Sorian Frequent Land Attack T3',
                'Sorian Start Location Attack',
                'Sorian Early Attacks Small',
                'Sorian Early Attacks Medium',
                'Sorian T2/T3 Land Weak Enemy Response',
                'Sorian T1 Land Weak Enemy Response',
                'Sorian T1 Hunters',
                'Sorian T2 Hunters',
                'Sorian T4 Exp Land',
            }
        },
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Expansion Area Firebase Engineer - Cybran - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Aeon - HP',
                'Sorian T3 Expansion Area Firebase Engineer - UEF - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Seraphim - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Cybran - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Aeon - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - UEF - DP - HP',
                'Sorian T3 Expansion Area Firebase Engineer - Seraphim - DP - HP',
                'Sorian T3 Nuke Engineer - High Prio',
                'Sorian T3 Engineer Assist Build Nuke - High Prio',
                'Sorian T3 Engineer Assist Build Nuke Missile - High Prio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianNukeRush',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Nuke Rush Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'rush nuke' then
                return 100
            end
            local antis = 0
            local nukes = aiBrain:GetCurrentUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3)

            for k,v in ArmyBrains do
                local eStartX, eStartZ = v:GetArmyStartPos()
                local eUnits = aiBrain:GetNumUnitsAroundPoint(categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, {eStartX, 0, eStartZ}, 250, 'Enemy')
                if eUnits > antis then
                    antis = eUnits
                end
            end

            if nukes - antis >= 3 then
                return returnval
            end

            returnval = 70 + (nukes * 5) - (antis * 10)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH3' }},
            --{ SIBC, 'HaveLessThanUnitsWithCategory', { 1, 'NUKE SILO STRUCTURE TECH3' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH3 } },
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 1, categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            { SIBC, 'GreaterThanEconIncome',  { 100, 3000}},
            { SBC, 'MapGreaterThan', { 500, 500 }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T3 Nuke Engineer - High Prio',
                'Sorian T3 Engineer Assist Build Nuke - High Prio',
                'Sorian T3 Engineer Assist Build Nuke Missile - High Prio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianStopNukes',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Stop Nukes Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local antis = 99999
            local returnval = 1

            local nukes = aiBrain:GetCurrentUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3)

            for k,v in ArmyBrains do
                local eStartX, eStartZ = v:GetArmyStartPos()
                local eUnits = aiBrain:GetNumUnitsAroundPoint(categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, {eStartX, 0, eStartZ}, 250, 'Enemy')
                if eUnits < antis then
                    antis = eUnits
                end
            end

            returnval = (antis - nukes) * 20
            return returnval
        end,
        BuilderConditions = {
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH3' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            EngineerManager = {
                'Sorian T3 Nuke Engineer',
                'Sorian T3 Nuke Engineer - 10x10',
            }
        },
        AddBuilders = {}
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianT2ACUSnipe',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian T2 ACU Snipe Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local enemyIndex
            local returnval = 1
            if aiBrain:GetCurrentEnemy() then
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end

            local eUnits = aiBrain:GetUnitsAroundPoint(categories.ANTIMISSILE * categories.TECH2 * categories.STRUCTURE, Vector(0,0,0), 100000, 'Enemy')

            local count = 0

            for k,v in eUnits do
                if v:GetAIBrain():GetArmyIndex() == enemyIndex then
                    count = count + 1
                end
            end

            returnval = 100 - (count * 6)
            return returnval
        end,
        BuilderConditions = {
            { SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 3, 'ENGINEER TECH2' }},
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.ENERGYPRODUCTION * categories.TECH2 } },
            --{ SBC, 'TargetHasLessThanUnitsWithCategory', { 6, categories.ANTIMISSILE * categories.TECH2 * categories.STRUCTURE }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 10, categories.ANTIMISSILE * categories.TECH2 * categories.STRUCTURE, 'Enemy'}},
            { MABC, 'CanBuildFirebase', { 'LocationType', 256, 'Expansion Area', -1000, 5, 1, 'AntiSurface', 1, 'STRATEGIC', 20} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.2}},
            --{ SBC, 'MapGreaterThan', { 500, 500 }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {},
        AddBuilders = {
            EngineerManager = {
                'Sorian T2 Firebase Engineer - High Prio',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianHeavyAirStrategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian T1 Heavy Air Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'air' then
                return 100
            end
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end
            if aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * (categories.TECH2 + categories.TECH3)) > 0 then
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiAir', enemyIndex)
            local numEUnits = aiBrain:GetNumUnitsAroundPoint(categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, Vector(0,0,0), 100000, 'Enemy')

            returnval = 90 - enemyThreat - numEUnits
            return returnval
        end,
        BuilderConditions = {
            --{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 7 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY AIR TECH3' }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 5, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, 'Enemy'}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, 'FACTORY AIR TECH2, FACTORY AIR TECH3' }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, 'FACTORY AIR TECH1' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                'Sorian T2 Air Gunship',
                'Sorian T2 Air Gunship - Anti Navy',
                'Sorian T2 Air Gunship - Stomp Enemy',
                'Sorian T2FighterBomber',
                'Sorian T2 Air Gunship2',
                'Sorian T2FighterBomber2',
                'Sorian T3 Air Gunship',
                'Sorian T3 Air Gunship - Anti Navy',
                'Sorian T3 Air Bomber',
                'Sorian T3 Air Bomber - Stomp Enemy',
                'Sorian T3 Air Gunship2',
                'Sorian T3 Air Bomber2',
            },
            PlatoonFormManager = {
                'Sorian BomberAttackT1Frequent',
                'Sorian BomberAttackT1Frequent - Anti-Land',
                --'Sorian BomberAttackT1Frequent - Anti-Resource',
                'Sorian BomberAttackT2Frequent',
                'Sorian BomberAttackT2Frequent - Anti-Land',
                --'Sorian BomberAttackT2Frequent - Anti-Resource',
                'Sorian BomberAttackT3Frequent',
                'Sorian BomberAttackT3Frequent - Anti-Land',
                --'Sorian BomberAttackT3Frequent - Anti-Resource',
                'Sorian T1 Bomber Attack Weak Enemy Response',
                --'Sorian BomberAttack Mass Hunter',
            }
        },
        AddBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber - High Prio',
                'Sorian T2 Air Bomber - High Prio',
                'Sorian T3 Air Bomber - High Prio',
            },
            PlatoonFormManager = {
                'Sorian Bomber Attack - Large T1',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T2 Heavy Air Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'air' then
                return 100
            end
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end
            if aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * categories.TECH3) > 0 or
            aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * categories.TECH2) < 1 then
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiAir', enemyIndex)
            local numEUnits = aiBrain:GetNumUnitsAroundPoint(categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, Vector(0,0,0), 100000, 'Enemy')

            returnval = 90 - (enemyThreat * 0.5) - numEUnits
            return returnval
        end,
        BuilderConditions = {
            --{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 19 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
            --{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY AIR TECH3' }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 5, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, 'Enemy'}},
            { UCBC, 'FactoryLessAtLocation', { 'LocationType', 1, 'FACTORY AIR TECH3' }},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, 'FACTORY AIR TECH2' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                'Sorian T2 Air Gunship',
                'Sorian T2 Air Gunship - Anti Navy',
                'Sorian T2 Air Gunship - Stomp Enemy',
                'Sorian T2FighterBomber',
                'Sorian T2 Air Gunship2',
                'Sorian T2FighterBomber2',
                'Sorian T3 Air Gunship',
                'Sorian T3 Air Gunship - Anti Navy',
                'Sorian T3 Air Bomber',
                'Sorian T3 Air Bomber - Stomp Enemy',
                'Sorian T3 Air Gunship2',
                'Sorian T3 Air Bomber2',
            },
            PlatoonFormManager = {
                'Sorian BomberAttackT1Frequent',
                'Sorian BomberAttackT1Frequent - Anti-Land',
                --'Sorian BomberAttackT1Frequent - Anti-Resource',
                'Sorian BomberAttackT2Frequent',
                'Sorian BomberAttackT2Frequent - Anti-Land',
                --'Sorian BomberAttackT2Frequent - Anti-Resource',
                'Sorian BomberAttackT3Frequent',
                'Sorian BomberAttackT3Frequent - Anti-Land',
                --'Sorian BomberAttackT3Frequent - Anti-Resource',
                'Sorian T2/T3 Bomber Attack Weak Enemy Response',
                --'Sorian BomberAttack Mass Hunter',
            }
        },
        AddBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber - High Prio',
                'Sorian T2 Air Bomber - High Prio',
                'Sorian T3 Air Bomber - High Prio',
            },
            PlatoonFormManager = {
                'Sorian Bomber Attack - Large',
            }
        }
    },
    Builder {
        BuilderName = 'Sorian T3 Heavy Air Strategy',
        StrategyType = 'Intermediate',
        Priority = 100,
        InstanceCount = 1,
        StrategyTime = 300,
        PriorityFunction = function(self, aiBrain)
            local enemy, enemyIndex
            local returnval = 1
            --If activated by an ally
            if aiBrain.Focus == 'air' then
                return 100
            end
            if aiBrain:GetCurrentEnemy() then
                enemy = aiBrain:GetCurrentEnemy()
                enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()
            else
                return returnval
            end
            if aiBrain:GetCurrentUnits(categories.FACTORY * categories.AIR * categories.TECH3) < 1 then
                return returnval
            end

            local StartX, StartZ = enemy:GetArmyStartPos()

            local enemyThreat = aiBrain:GetThreatAtPosition({StartX, 0, StartZ}, 1, true, 'AntiAir', enemyIndex)
            local numEUnits = aiBrain:GetNumUnitsAroundPoint(categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, Vector(0,0,0), 100000, 'Enemy')

            returnval = 90 - (enemyThreat * 0.15) - numEUnits
            return returnval
        end,
        BuilderConditions = {
            --{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 55 }},
            { SBC, 'NoRushTimeCheck', { 600 }},
            --{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 5, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER, 'Enemy'}},
            { UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, 'FACTORY AIR TECH3' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                'Sorian T2 Air Gunship',
                'Sorian T2 Air Gunship - Anti Navy',
                'Sorian T2 Air Gunship - Stomp Enemy',
                'Sorian T2FighterBomber',
                'Sorian T2 Air Gunship2',
                'Sorian T2FighterBomber2',
                'Sorian T3 Air Gunship',
                'Sorian T3 Air Gunship - Anti Navy',
                'Sorian T3 Air Bomber',
                'Sorian T3 Air Bomber - Stomp Enemy',
                'Sorian T3 Air Gunship2',
                'Sorian T3 Air Bomber2',
            },
            PlatoonFormManager = {
                'Sorian BomberAttackT1Frequent',
                'Sorian BomberAttackT1Frequent - Anti-Land',
                --'Sorian BomberAttackT1Frequent - Anti-Resource',
                'Sorian BomberAttackT2Frequent',
                'Sorian BomberAttackT2Frequent - Anti-Land',
                --'Sorian BomberAttackT2Frequent - Anti-Resource',
                'Sorian BomberAttackT3Frequent',
                'Sorian BomberAttackT3Frequent - Anti-Land',
                --'Sorian BomberAttackT3Frequent - Anti-Resource',
                'Sorian T2/T3 Bomber Attack Weak Enemy Response',
                --'Sorian BomberAttack Mass Hunter',
            }
        },
        AddBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber - High Prio',
                'Sorian T2 Air Bomber - High Prio',
                'Sorian T3 Air Bomber - High Prio',
            },
            PlatoonFormManager = {
                'Sorian Bomber Attack - Large',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianParagonStrategy',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Paragon Strategy',
        StrategyType = 'Overall',
        Priority = 100,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            PlatoonFormManager = {
                'T1 Mass Extractor Upgrade Storage Based',
                'Sorian T1 Mass Extractor Upgrade Timeless Single',
                'Sorian T1 Mass Extractor Upgrade Timeless Two',
                'Sorian T1 Mass Extractor Upgrade Timeless LOTS',
                'Sorian T2 Mass Extractor Upgrade Timeless',
                'Sorian T2 Mass Extractor Upgrade Timeless Multiple',
                'Sorian Balanced T1 Land Factory Upgrade Initial',
                'Sorian BalancedT1AirFactoryUpgradeInitial',
                'Sorian Balanced T1 Land Factory Upgrade',
                'Sorian BalancedT1AirFactoryUpgrade',
                'Sorian Balanced T1 Sea Factory Upgrade',
                'Sorian Balanced T1 Land Factory Upgrade - T3',
                'Sorian BalancedT1AirFactoryUpgrade - T3',
                'Sorian Balanced T2 Land Factory Upgrade - initial',
                'Sorian Balanced T2 Air Factory Upgrade - initial',
                'Sorian Balanced T2 Land Factory Upgrade',
                'Sorian Balanced T2 Air Factory Upgrade',
                'Sorian Balanced T2 Sea Factory Upgrade',
                'Sorian Naval T1 Land Factory Upgrade Initial',
                'Sorian Naval T1 Air Factory Upgrade Initial',
                'Sorian Naval T1 Naval Factory Upgrade Initial',
                'Sorian Naval T1 Land Factory Upgrade',
                'Sorian Naval T1 AirFactory Upgrade',
                'Sorian Naval T1 Sea Factory Upgrade',
                'Sorian Naval T1 Land Factory Upgrade - T3',
                'Sorian Naval T1AirFactoryUpgrade - T3',
                'Sorian Naval T2 Land Factory Upgrade',
                'Sorian Naval T2 Air Factory Upgrade',
                'Sorian Naval T2 Sea Factory Upgrade',
            },
        },
        AddBuilders = {
            PlatoonFormManager = {
                'Sorian T1 Mass Extractor Upgrade Timeless Strategy',
                'Sorian T2 Mass Extractor Upgrade Timeless Strategy',
                'Sorian Balanced T1 Land Factory Upgrade Expansion Strategy',
                'Sorian BalancedT1AirFactoryUpgrade Expansion Strategy',
                'Sorian Balanced T1 Sea Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Land Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Air Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Sea Factory Upgrade Expansion Strategy',
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianParagonStrategyExp',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian Paragon Strategy Expansion',
        StrategyType = 'Overall',
        Priority = 100,
        InstanceCount = 1,
        BuilderConditions = {
            { SIBC, 'HaveGreaterThanUnitsWithCategory', { 0, 'ENERGYPRODUCTION EXPERIMENTAL STRUCTURE' }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            PlatoonFormManager = {
                'Sorian Balanced T1 Land Factory Upgrade Expansion',
                'Sorian BalancedT1AirFactoryUpgrade Expansion',
                'Sorian Balanced T1 Sea Factory Upgrade Expansion',
                'Sorian Balanced T2 Land Factory Upgrade Expansion',
                'Sorian Balanced T2 Air Factory Upgrade Expansion',
                'Sorian Balanced T2 Sea Factory Upgrade Expansion',
                'Sorian Naval T1 Land Factory Upgrade Initial',
                'Sorian Naval T1 Air Factory Upgrade Initial',
                'Sorian Naval T1 Naval Factory Upgrade Initial',
                'Sorian Naval T1 Land Factory Upgrade',
                'Sorian Naval T1 AirFactory Upgrade',
                'Sorian Naval T1 Sea Factory Upgrade',
                'Sorian Naval T1 Land Factory Upgrade - T3',
                'Sorian Naval T1AirFactoryUpgrade - T3',
                'Sorian Naval T2 Land Factory Upgrade',
                'Sorian Naval T2 Air Factory Upgrade',
                'Sorian Naval T2 Sea Factory Upgrade',
            },
        },
        AddBuilders = {
            PlatoonFormManager = {
                'Sorian Balanced T1 Land Factory Upgrade Expansion Strategy',
                'Sorian BalancedT1AirFactoryUpgrade Expansion Strategy',
                'Sorian Balanced T1 Sea Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Land Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Air Factory Upgrade Expansion Strategy',
                'Sorian Balanced T2 Sea Factory Upgrade Expansion Strategy',
            },
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'SorianTeamLevelAdjustment',
    BuildersType = 'StrategyBuilder',
    Builder {
        BuilderName = 'Sorian AI Outnumbered',
        StrategyType = 'Overall',
        Priority = 100,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SBC, 'AIOutnumbered', { true }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            FactoryManager = {
                'Sorian T1 Air Bomber',
                'Sorian T1 Air Bomber - Stomp Enemy',
                'Sorian T1Gunship',
                'Sorian T1 Air Fighter',
                'Sorian T1 Air Bomber 2',
                'Sorian T1Gunship2',
                'Sorian T1 Bot - Early Game Rush',
                'Sorian T1 Bot - Early Game',
                'Sorian T1 Light Tank - Tech 1',
                'Sorian T1 Mortar',
                'Sorian T1 Mortar - tough def',
            },
            StrategyManager = {
                'Sorian T1 Heavy Air Strategy',
                'Sorian Jester Rush Strategy',
            }
        },
        AddBuilders = {}
    },
    Builder {
        BuilderName = 'Sorian AI Outnumbers Enemies',
        StrategyType = 'Overall',
        Priority = 100,
        InstanceCount = 1,
        BuilderConditions = {
            { SBC, 'MapGreaterThan', { 1000, 1000 }},
            { SBC, 'AIOutnumbered', { false }},
        },
        BuilderType = 'Any',
        RemoveBuilders = {
            EngineerManager = {
                'Sorian T1 Mass Adjacency Defense Engineer',
                'Sorian T1 Base D Engineer - Perimeter',
                'Sorian T1 Defensive Point Engineer',
            }
        },
        AddBuilders = {}
    },
}

-- Kept for Mod Support
local BBTmplFile = '/lua/basetemplates.lua'
local BuildingTmpl = 'BuildingTemplates'
local BaseTmpl = 'BaseTemplates'
local ExBaseTmpl = 'ExpansionBaseTemplates'
local Adj2x2Tmpl = 'Adjacency2x2'
local IBC = '/lua/editor/instantbuildconditions.lua'
local OAUBC = '/lua/editor/otherarmyunitcountbuildconditions.lua'
local PCBC = '/lua/editor/platooncountbuildconditions.lua'
local SAI = '/lua/scenarioplatoonai.lua'
local PlatoonFile = '/lua/platoon.lua'