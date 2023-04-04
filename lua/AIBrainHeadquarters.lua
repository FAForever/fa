
local Factions = import('/lua/factions.lua').GetFactions(true)

---@class AIBrainHQComponent
---@field HQs table
AIBrainHQComponent = ClassSimple {

    ---@param self AIBrainHQComponent | AIBrain
    CreateBrainShared = function(self)
        local layers = { "LAND", "AIR", "NAVAL" }
        local techs = { "TECH2", "TECH3" }

        self.HQs = {}
        for _, facData in Factions do
            local faction = facData.Category
            self.HQs[faction] = {}
            for _, layer in layers do
                self.HQs[faction][layer] = {}
                for _, tech in techs do
                    self.HQs[faction][layer][tech] = 0
                end
            end
        end

        -- restrict all support factories by default
        AddBuildRestriction(self:GetArmyIndex(), (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)
    end,

    --- Adds a HQ so that the engi mod knows we have it
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    AddHQ = function(self, faction, layer, tech)
        self.HQs[faction][layer][tech] = self.HQs[faction][layer][tech] + 1
    end,

    --- Removes an HQ so that the engi mod knows we lost it for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    RemoveHQ = function(self, faction, layer, tech)
        self.HQs[faction][layer][tech] = math.max(0, self.HQs[faction][layer][tech] - 1)
    end,

    --- Completely re evaluates the support factory restrictions of the engi mod
    ---@param self AIBrain
    ReEvaluateHQSupportFactoryRestrictions = function(self)
        local layers = { "AIR", "LAND", "NAVAL" }
        local factions = { "UEF", "AEON", "CYBRAN", "SERAPHIM" }

        if categories.NOMADS then
            table.insert(factions, 'NOMADS')
        end

        for _, faction in factions do
            for _, layer in layers do
                self:SetHQSupportFactoryRestrictions(faction, layer)
            end
        end
    end,

    --- Manages the support factory restrictions of the engi mod
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    SetHQSupportFactoryRestrictions = function(self, faction, layer)

        -- localize for performance
        local army = self:GetArmyIndex()

        -- the pessimists we are, restrict everything!
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)

        -- lift t2 / t3 support factory restrictions
        if self.HQs[faction][layer]["TECH3"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)
        end

        -- lift t2 support factory restrictions
        if self.HQs[faction][layer]["TECH2"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        end
    end,

    --- Counts all HQs of specific faction, layer and tech for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    ---@return number
    CountHQs = function(self, faction, layer, tech)
        return self.HQs[faction][layer][tech]
    end,

    --- Counts all HQs of faction and tech, regardless of layer
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param tech HqTech
    ---@return number
    CountHQsAllLayers = function(self, faction, tech)
        local count = self.HQs[faction]["LAND"][tech]
        count = count + self.HQs[faction]["AIR"][tech]
        count = count + self.HQs[faction]["NAVAL"][tech]
        return count
    end,
}