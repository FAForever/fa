--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************
local EffectUtils = import('/lua/effectutilities.lua')
local CreateCybranBuildBeamsOpti = EffectUtils.CreateCybranBuildBeamsOpti
local CreateCybranEngineerBuildEffectsOpti = EffectUtils.CreateCybranEngineerBuildEffectsOpti
local SpawnBuildBotsOpti = EffectUtils.SpawnBuildBotsOpti

local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

local EntityFunctions = _G.moho.entity_methods
local EntityDestroy = EntityFunctions.Destroy
local EntityGetPosition = EntityFunctions.GetPosition
local EntityGetPositionXYZ = EntityFunctions.GetPositionXYZ

--- A class to managing the build bots. Make sure to call all the relevant functions.
---@class CConstructionTemplate
---@field BotBlueprintId? string
CConstructionTemplate = ClassSimple {

    BotBlueprintId = false,
    BotBone = 0,

    --- Prepares the values required to support bots
    ---@param self CConstructionTemplate
    OnCreate = function(self)
        -- cache the total amount of drones
        self.BuildBotTotal = self:GetBlueprint().BuildBotTotal or
            math.min(math.ceil((10 + self:GetBuildRate()) / 15), 10)
    end,

    --- When dying, destroy everything.
    ---@param self CConstructionTemplate
    DestroyAllBuildEffects = function(self)
        -- make sure we're not dead (then bots are destroyed by trashbag)
        if self.Dead then
            return
        end

        -- check if we ever had bots
        local bots = self.BuildBots
        if bots then
            -- check if we still have active bots
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When stopping to build, send the bots back after a bit.
    ---@param self CConstructionTemplate
    ---@param built Unit
    StopBuildingEffects = function(self, built)
        -- make sure we're not dead (then bots are destroyed by trashbag)
        if self.Dead then
            return
        end

        -- check if we had bots
        local bots = self.BuildBots
        if bots then

            -- check if we still have active bots
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When pausing, send the bots back after a bit.
    ---@param self CConstructionTemplate
    ---@param delay? number
    OnPaused = function(self, delay)
        -- delay until they move back
        delay = delay or (0.5 + 2) * Random()

        -- make sure thread is not running already
        if self.ReturnBotsThreadInstance then
            return
        end

        -- check if we have bots
        local bots = self.BuildBots
        if bots then
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When making build effects, try and make the bots.
    ---@param self CConstructionTemplate
    ---@param unitBeingBuilt Unit
    ---@param order string
    ---@param stationary boolean
    CreateBuildEffects = function(self, unitBeingBuilt, order, stationary)
        -- check if the unit still exists, this can happen when:
        -- pause during construction, constructing unit dies, unpause
        if unitBeingBuilt then

            -- Prevent an AI from (ab)using the bots for other purposes than building
            local builderArmy = self.Army
            local unitBeingBuiltArmy = unitBeingBuilt.Army
            if builderArmy == unitBeingBuiltArmy or ArmyBrains[builderArmy].BrainType == "Human" then
                SpawnBuildBotsOpti(self, self.BotBlueprintId, self.BotBone)
                if stationary then
                    CreateCybranEngineerBuildEffectsOpti(self, self.BuildEffectBones, self.BuildBots, self.BuildBotTotal
                        , self.BuildEffectsBag)
                end
                CreateCybranBuildBeamsOpti(self, self.BuildBots, unitBeingBuilt, self.BuildEffectsBag, stationary)
            end
        end
    end,

    --- When destroyed, destroy the bots too.
    ---@param self CConstructionTemplate
    OnDestroy = function(self)
        -- destroy bots if we have them
        if self.BuildBotsNext > 1 then

            -- doesn't need to trashbag: threads that are not infinite and stop get found by the garbage collector
            ForkThread(self.DestroyBotsThread, self, self.BuildBots, self.BuildBotTotal)
        end
    end,

    --- Destroys all the bots of a builder. Assumes the bots exist
    ---@param self CConstructionTemplate
    ---@param bots Unit[]
    ---@param count number
    DestroyBotsThread = function(self, bots, count)

        -- kill potential return thread
        if self.ReturnBotsThreadInstance then
            KillThread(self.ReturnBotsThreadInstance)
            self.ReturnBotsThreadInstance = nil
        end

        -- slowly kill the drones
        for k = 1, count do
            local bot = bots[k]
            if bot and not bot.Dead then
                WaitTicks(Random(1, 10) + 1)
                if bot and not bot.Dead then
                    bot:Kill()
                end
            end
        end
    end,

    --- Destroys all the bots of a builder. Assumes the bots exist
    ---@param self CConstructionTemplate
    ---@param delay number
    ReturnBotsThread = function(self, delay)

        -- hold up a bit in case we just switch target
        WaitSeconds(delay)

        -- cache for speed
        local bots = self.BuildBots
        local buildBotTotal = self.BuildBotTotal
        local threshold = delay

        -- lower bot elevation
        for k = 1, buildBotTotal do
            local bot = bots[k]
            if bot and not bot.Dead then
                bot:SetElevation(1)
            end
        end

        -- keep sending drones back
        while self.BuildBotsNext > 1 do

            -- instruct bots to move back
            IssueClearCommands(bots)
            IssueMove(bots, EntityGetPosition(self))

            -- check if they're there yet
            for l = 1, 4 do
                WaitTicks(3)

                local tx, ty, tz = EntityGetPositionXYZ(self)
                for k = 1, buildBotTotal do
                    local bot = bots[k]
                    if bot and not bot.Dead then
                        local bx, by, bz = EntityGetPositionXYZ(bot)
                        local distance = VDist2Sq(tx, tz, bx, bz)

                        -- if close enough, just remove it
                        threshold = threshold + 0.1
                        if distance < threshold then
                            -- destroy bot without effects
                            EntityDestroy(bot)

                            -- move destroyed bots up
                            for m = k, buildBotTotal do
                                bots[m] = bots[m + 1]
                            end
                        end
                    end
                end
            end
        end

        -- clean up state
        self.ReturnBotsThreadInstance = nil
        self.BeamEndBuilder = nil
        self.BeamEndBots = nil
    end,
}
