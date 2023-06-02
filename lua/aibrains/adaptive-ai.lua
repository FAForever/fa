local StandardBrain = import("/lua/aibrain.lua").AIBrain
local BaseAIBrainClass = import("/lua/aibrains/base-ai.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent

---@class EasyAIBrainManagers
---@field FactoryManager AIFactoryManager
---@field EngineerManager AIEngineerManager
---@field StructureManager AIStructureManager

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

---@class EasyAIBrain: AIBrain, AIBrainEconomyComponent
---@field GridReclaim AIGridReclaim
---@field GridBrain AIGridBrain
---@field GridRecon AIGridRecon
---@field BuilderManagers table<LocationType, AIBase>

---@class AIBrainAdaptive : BaseAIBrain, AIBrainEconomyComponent
AIBrain = Class(BaseAIBrainClass, EconomyComponent) {

    SkirmishSystems = true,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrainAdaptive
    ---@param planName string
    OnCreateAI = function(self, planName)
        BaseAIBrainClass.OnCreateAI(self, planName)
        EconomyComponent.OnCreateAI(self)

        -- load in base templates
        -- todo

        -- start initial base
        --local startX, startZ = self:GetArmyStartPos()
        --local main = BaseManager.CreateBaseManager(self, 'main', { startX, 0, startZ }, 60)
        --main:AddBaseTemplate('AIBaseTemplate - Easy main')
        --self.BuilderManagers = {
        --    MAIN = main
        --}

        self:IMAPConfiguration()
    end,

    --- Called after `BeginSession`, at this point all props, resources and initial units exist in the map
    ---@param self AIBrain
    OnBeginSession = function(self)
        StandardBrain.OnBeginSession(self)

        -- requires navigational mesh
        import("/lua/sim/NavUtils.lua").Generate()

        -- requires these markers to exist
        import("/lua/sim/MarkerUtilities.lua").GenerateExpansionMarkers()
        import("/lua/sim/MarkerUtilities.lua").GenerateRallyPointMarkers()

        -- requires these datastructures to understand the game
        self.GridReclaim = import("/lua/ai/gridreclaim.lua").Setup(self)
        self.GridBrain = import("/lua/ai/gridbrain.lua").Setup()
        self.GridRecon = import("/lua/ai/gridrecon.lua").Setup(self)
        LOG('Starting GridPresence')
        self.GridPresence = import("/lua/AI/GridPresence.lua").Setup(self)
    end,

    IMAPConfiguration = function(self)
        -- Used to configure imap values, used for setting threat ring sizes depending on map size to try and get a somewhat decent radius
        local maxmapdimension = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])

        self.IMAPConfig = {
            OgridRadius = 0,
            IMAPSize = 0,
            Rings = 0,
        }

        if maxmapdimension == 256 then
            self.IMAPConfig.OgridRadius = 22.5
            self.IMAPConfig.IMAPSize = 32
            self.IMAPConfig.Rings = 2
        elseif maxmapdimension == 512 then
            self.IMAPConfig.OgridRadius = 22.5
            self.IMAPConfig.IMAPSize = 32
            self.IMAPConfig.Rings = 2
        elseif maxmapdimension == 1024 then
            self.IMAPConfig.OgridRadius = 45.0
            self.IMAPConfig.IMAPSize = 64
            self.IMAPConfig.Rings = 1
        elseif maxmapdimension == 2048 then
            self.IMAPConfig.OgridRadius = 89.5
            self.IMAPConfig.IMAPSize = 128
            self.IMAPConfig.Rings = 0
        else
            self.IMAPConfig.OgridRadius = 180.0
            self.IMAPConfig.IMAPSize = 256
            self.IMAPConfig.Rings = 0
        end
    end,

    ---@param self BaseAIBrain
    ---@param loc Vector
    ---@return boolean
    PBMGetLocationRadius = function(self, loc)
        if not loc then
            return false
        end
        if self.HasPlatoonList then
            for k, v in self.PBM.Locations do
                if v.LocationType == loc then
                   return v.Radius
                end
            end
        elseif self.BuilderManagers[loc] then
            return self.BuilderManagers[loc].FactoryManager.Radius
        end
        return false
    end,

}
