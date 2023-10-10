local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty
local TableInsert = table.insert

--- Table of stringified categories to help determine
local UnitTypeOrder = {
    'TACTICALMISSILEPLATFORM',
    'NUKE',
}

---@class AIPlatoonAdaptiveSilo : AIPlatoon
---@field Base AIBase
---@field Brain AdaptiveAIBrain
---@field BuilderType 'TACTICALMISSILEPLATFORM' | 'NUKE'
---@field Builder AIBuilder | nil
AIPlatoonAdaptiveSilo = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveSiloBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveSilo
        Main = function(self)
            if not self.Base then
                self:LogWarning("requires a base reference")
                self:ChangeState(self.Error)
            end

            if not self.Brain then
                self:LogWarning("requires a brain reference")
                self:ChangeState(self.Error)
            end

            local units, count = self:GetPlatoonUnits()
            local maxRadius
            for _, v in units do
                local weaponRadius = v.Blueprint.Weapon[1].MaxRadius
                if not maxRadius and weaponRadius and v.Blueprint.Weapon[1].MaxRadius > maxRadius then
                    self.MaxRadius = weaponRadius
                end
            end

            -- determine unit type
            local categoriesHashed = units[1].Blueprint.CategoriesHash
            for k, category in UnitTypeOrder do
                if categoriesHashed[category] then
                    self.BuilderType = category
                    break
                end
            end

            self:ChangeState(self.SearchingForTarget)
            return
        end,
    },

    SearchingForTarget = State {

        StateName = 'SearchingForTarget',

        --- The platoon searches for a target
        ---@param self AIPlatoonAdaptiveSilo
        Main = function(self)
            local units, count = self:GetPlatoonUnits()
            if count < 1 then
                self:LogWarning("multiple units is not supported")
                self:ChangeState(self.Error)
                return
            end
            local readyTmlLaunchers = {}
            local missileCount = 0
            for _, v in units do
                missileCount = v:GetTacticalSiloAmmoCount()
                if missileCount > 0 then
                    totalMissileCount = totalMissileCount + missileCount
                    TableInsert(readyTmlLaunchers, v)
                end
                
            end
            local atkPri = {
                categories.MASSEXTRACTION * categories.STRUCTURE * ( categories.TECH2 + categories.TECH3 ),
                categories.COMMAND,
                categories.STRUCTURE * categories.ENERGYPRODUCTION * ( categories.TECH2 + categories.TECH3 ),
                categories.MOBILE * categories.LAND * categories.EXPERIMENTAL,
                categories.STRUCTURE * categories.DEFENSE * categories.TACTICALMISSILEPLATFORM,
                categories.STRUCTURE * categories.DEFENSE * ( categories.TECH2 + categories.TECH3 ),
                categories.MOBILE * categories.NAVAL * ( categories.TECH2 + categories.TECH3 ),
                categories.STRUCTURE * categories.FACTORY * ( categories.TECH2 + categories.TECH3 ),
                categories.STRUCTURE * categories.RADAR * (categories.TECH2 + categories.TECH3)
            }

            local targetUnits = self.Brain:GetUnitsAroundPoint(categories.ALLUNITS, self.CenterPosition, 235, 'Enemy')
            local targetPosition

            for _, v in atkPri do
                for num, unit in targetUnits do
                    if not unit.Dead and EntityCategoryContains(v, unit) and self:CanAttackTarget('attack', unit) then
                        targetPosition = unit:GetPosition()
                        if not GetTerrainHeight(targetPosition[1], targetPosition[3]) < GetSurfaceHeight(targetPosition[1], targetPosition[3]) then
                            -- 6000 damage for TML
                            if EntityCategoryContains(categories.COMMAND, unit) then
                                local armorHealth = unit:GetHealth()
                                local shieldHealth
                                if unit.MyShield then
                                    shieldHealth = unit.MyShield:GetHealth()
                                else
                                    shieldHealth = 0
                                end
                                targetHealth = armorHealth + shieldHealth
                            else
                                targetHealth = unit:GetHealth()
                            end
                            
                            --RNGLOG('Target Health is '..targetHealth)
                            local missilesRequired = math.ceil(targetHealth / 6000)
                            local shieldMissilesRequired = 0
                            --RNGLOG('Missiles Required = '..missilesRequired)
                            --RNGLOG('Total Missiles '..totalMissileCount)
                            if (totalMissileCount >= missilesRequired and not EntityCategoryContains(categories.COMMAND, unit)) or (readyTmlLauncherCount >= missilesRequired) then
                                target = unit
                                
                                --enemyTMD = GetUnitsAroundPoint(aiBrain, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2, targetPosition, 25, 'Enemy')
                                enemyTmdCount = AIAttackUtils.AIFindNumberOfUnitsBetweenPointsRNG( aiBrain, self.CenterPosition, targetPosition, categories.STRUCTURE * categories.DEFENSE * categories.ANTIMISSILE * categories.TECH2, 30, 'Enemy')
                                enemyShield = GetUnitsAroundPoint(aiBrain, categories.STRUCTURE * categories.DEFENSE * categories.SHIELD, targetPosition, 25, 'Enemy')
                                if RNGGETN(enemyShield) > 0 then
                                    local enemyShieldHealth = 0
                                    --RNGLOG('There are '..RNGGETN(enemyShield)..'shields')
                                    for k, shield in enemyShield do
                                        if not shield or shield.Dead or not shield.MyShield then continue end
                                        enemyShieldHealth = enemyShieldHealth + shield.MyShield:GetHealth()
                                    end
                                    shieldMissilesRequired = math.ceil(enemyShieldHealth / 6000)
                                end

                                --RNGLOG('Enemy Unit has '..enemyTmdCount.. 'TMD along path')
                                --RNGLOG('Enemy Unit has '..RNGGETN(enemyShield).. 'Shields around it with a total health of '..enemyShieldHealth)
                                --RNGLOG('Missiles Required for Shield Penetration '..shieldMissilesRequired)

                                if enemyTmdCount >= readyTmlLauncherCount then
                                    --RNGLOG('Target is too protected')
                                    --Set flag for more TML or ping attack position with air/land
                                    target = false
                                    continue
                                else
                                    --RNGLOG('Target does not have enough defense')
                                    for k, tml in readyTmlLaunchers do
                                        local missileCount = tml:GetTacticalSiloAmmoCount()
                                        --RNGLOG('Missile Count in Launcher is '..missileCount)
                                        local tmlMaxRange = __blueprints[tml.UnitId].Weapon[1].MaxRadius
                                        --RNGLOG('TML Max Range is '..tmlMaxRange)
                                        local tmlPosition = tml:GetPosition()
                                        if missileCount > 0 and VDist2Sq(tmlPosition[1], tmlPosition[3], targetPosition[1], targetPosition[3]) < tmlMaxRange * tmlMaxRange then
                                            if (missileCount >= missilesRequired) and (enemyTmdCount < 1) and (shieldMissilesRequired < 1) and missilesRequired == 1 then
                                                --RNGLOG('Only 1 missile required')
                                                if tml.TargetBlackList then
                                                    if tml.TargetBlackList[targetPosition[1]][targetPosition[3]] then
                                                        --RNGLOG('TargetPos found in blacklist, skip')
                                                        continue
                                                    end
                                                end
                                                RNGINSERT(inRangeTmlLaunchers, tml)
                                                break
                                            else
                                                if tml.TargetBlackList then
                                                    if tml.TargetBlackList[targetPosition[1]][targetPosition[3]] then
                                                        --RNGLOG('TargetPos found in blacklist, skip')
                                                        continue
                                                    end
                                                end
                                                RNGINSERT(inRangeTmlLaunchers, tml)
                                                local readyTML = RNGGETN(inRangeTmlLaunchers)
                                                if (readyTML >= missilesRequired) and (readyTML > enemyTmdCount + shieldMissilesRequired) then
                                                    --RNGLOG('inRangeTmlLaunchers table number is enough for kill')
                                                    break
                                                end
                                            end
                                        end
                                    end
                                    --RNGLOG('Have Target and number of in range ready launchers is '..RNGGETN(inRangeTmlLaunchers))
                                    break
                                end
                            else
                                --RNGLOG('Not Enough Missiles Available')
                                target = false
                                self:ChangeState(self.Idling)
                            end
                        end
                        coroutine.yield(1)
                    end
                end
                if target then
                    --RNGLOG('We have target and can fire, breaking loop')
                    break
                end
            end
        end,
    },

    Waiting = State {

        StateName = 'Waiting',

        ---@param self AIPlatoonAdaptiveSilo
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
        end,
    },

    Idling = State {
        ---@param self AIPlatoonAdaptiveSilo
        Main = function(self)
        end,
    }

    -----------------------------------------------------------------
    -- brain events
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        -- trigger the on stop being built event of the brain
        for k = 1, table.getn(units) do
            local unit = units[k]
            unit.Brain:OnUnitStopBeingBuilt(unit, nil, unit.Layer)
        end
    end
end

---@param data { Behavior: 'AIPlatoonAdaptiveSiloBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveSiloBehavior)

        for _, silo in units do
            -- Disband if dead launchers. Will reform platoon on next PFM cycle
            if not silo or silo.Dead or silo:BeenDestroyed() then
                platoon:PlatoonDisbandNoAssign()
                return
            end
            if not platoon.Brain then
                platoon.Brain = silo.Brain
            end
            -- Add the terrain hit callback
            if not silo.terraincallbackset then
                silo:AddMissileImpactTerrainCallback(
                    function(unit, targetPos, impactPos)
                        if unit and not unit.Dead and targetPos then
                            if not unit.TargetBlackList then
                                unit.TargetBlackList = {}
                            end
                            unit.TargetBlackList[targetPos[1]] = {}
                            unit.TargetBlackList[targetPos[1]][targetPos[3]] = true
                            return true, "target position added to tml blacklist"
                        end
                    end
                )
                silo.terraincallbackset = true
            end
            silo:SetAutoMode(true)
            IssueClearCommands({silo})
        end

        -- TODO: to be removed until we have a better system to populate the platoons
        platoon:OnUnitsAddedToPlatoon()

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end
