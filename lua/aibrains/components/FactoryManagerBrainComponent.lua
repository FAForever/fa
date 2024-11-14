--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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
--******************************************************************************************************

local Factions = import('/lua/factions.lua').GetFactions(true)

---@alias ResearchFactoryTech "TECH2" | "TECH3"
---@alias ResearchFactoryLayer "AIR" | "LAND" | "NAVY"
---@alias ResearchFactoryFaction "UEF" | "AEON" | "CYBRAN" | "SERAPHIM" | "NOMADS"

-- upvalue scope for performance
local categories = categories
local AddBuildRestriction = AddBuildRestriction
local RemoveBuildRestriction = RemoveBuildRestriction

local MathMax = math.max

---@type ResearchFactoryLayer[]
local ResearchFactoryLayers = { "LAND", "AIR", "NAVAL" }

---@type ResearchFactoryTech[]
local ResearchFactoryTechs = { "TECH2", "TECH3" }

--- Keeps track of and manages the research factory (HQ) functionality.
---@class FactoryManagerBrainComponent
---@field ResearchFactories table
FactoryManagerBrainComponent = ClassSimple {

    ---@param self FactoryManagerBrainComponent | AIBrain
    CreateBrainShared = function(self)
        local info = {}
        for _, facData in Factions do
            local factionCategory = facData.Category

            local byFaction = {}
            for _, layer in ResearchFactoryLayers do
                local byLayer = {}
                for _, tech in ResearchFactoryTechs do
                    byLayer[tech] = 0
                end
                byFaction[layer] = byLayer
            end

            info[factionCategory] = byFaction
        end

        self.ResearchFactories = info

        -- restrict all support factories by default
        AddBuildRestriction(self:GetArmyIndex(), (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)
    end,

    --- Adds a HQ so that the engi mod knows we have it
    ---@param self FactoryManagerBrainComponent | AIBrain
    ---@param faction ResearchFactoryFaction
    ---@param layer ResearchFactoryLayer
    ---@param tech ResearchFactoryTech
    AddHQ = function(self, faction, layer, tech)
        local byLayer = self.ResearchFactories[faction][layer]
        if not byLayer then
            -- WARN("")
            return
        end

        byLayer[tech] = byLayer[tech] + 1
    end,

    --- Removes an HQ so that the engi mod knows we lost it for the engi mod.
    ---@param self FactoryManagerBrainComponent | AIBrain
    ---@param faction ResearchFactoryFaction
    ---@param layer ResearchFactoryLayer
    ---@param tech ResearchFactoryTech
    RemoveHQ = function(self, faction, layer, tech)
        local byLayer = self.ResearchFactories[faction][layer]
        if not byLayer then
            -- WARN("")
            return
        end

        byLayer[tech] = MathMax(0, byLayer[tech] - 1)
    end,

    --- Completely re evaluates the support factory restrictions of the engi mod
    ---@param self FactoryManagerBrainComponent | AIBrain
    ReEvaluateHQSupportFactoryRestrictions = function(self)
        for _, facData in Factions do
            local factionCategory = facData.Category
            for _, layer in ResearchFactoryLayers do
                self:SetHQSupportFactoryRestrictions(factionCategory, layer)
            end
        end
    end,

    --- Manages the support factory restrictions of the engi mod
    ---@param self FactoryManagerBrainComponent | AIBrain
    ---@param faction ResearchFactoryFaction
    ---@param layer ResearchFactoryLayer
    SetHQSupportFactoryRestrictions = function(self, faction, layer)

        -- localize for performance
        local army = self:GetArmyIndex()
        local byLayer = self.ResearchFactories[faction][layer]
        if not byLayer then
            -- WARN("")
            return
        end

        -- the pessimists we are, restrict everything!
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)

        -- lift t2 / t3 support factory restrictions
        if byLayer["TECH3"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)
        end

        -- lift t2 support factory restrictions
        if byLayer["TECH2"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        end
    end,

    --- Counts all HQs of specific faction, layer and tech for the engi mod.
    ---@param self FactoryManagerBrainComponent | AIBrain
    ---@param faction ResearchFactoryFaction
    ---@param layer ResearchFactoryLayer
    ---@param tech ResearchFactoryTech
    ---@return number
    CountHQs = function(self, faction, layer, tech)
        return self.ResearchFactories[faction][layer][tech]
    end,

    --- Counts all HQs of faction and tech, regardless of layer
    ---@param self FactoryManagerBrainComponent | AIBrain
    ---@param faction ResearchFactoryFaction
    ---@param tech ResearchFactoryTech
    ---@return number
    CountHQsAllLayers = function(self, faction, tech)
        local byFaction = self.ResearchFactories[faction]
        local count = 0
        for _, layer in ResearchFactoryLayers do
            count = count + byFaction[layer][tech]
        end

        return count
    end,
}
