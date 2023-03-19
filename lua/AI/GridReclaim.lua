
local Grid = import("/lua/ai/grid.lua").Grid

local Debug = false
function EnableDebugging()
    if ScenarioInfo.GameHasAIs or CheatsEnabled() then
        Debug = true
    end
end

function DisableDebugging()
    if ScenarioInfo.GameHasAIs or CheatsEnabled() then
        Debug = false
    end
end

---@type GridReclaimUIDebugCell
local DebugCellData = {
    ReclaimCount = -1,
    TotalEnergy = -1,
    TotalMass = -1,
    X = -1,
    Z = -1,
}

---@type GridReclaimUIDebugUpdate
local DebugUpdateData = {
     Memory = -1,
     Processed = -1,
     Time = -1,
     Updates = -1,
}

---@class AIGridReclaimCell : AIGridCell
---@field TotalMass number
---@field TotalEnergy number
---@field ReclaimCount number
---@field Reclaim table<EntityId, Prop>

---@class AIGridReclaim : AIGrid
---@field Cells AIGridReclaimCell[][]
---@field UpdateList table<string, AIGridReclaimCell>
---@field Brains table<number, AIBrain>
GridReclaim = Class (Grid) {

    ---@param self AIGridReclaim
    __init = function(self)
        Grid.__init(self)

        local cellCount = self.CellCount
        local cells = self.Cells

        for k = 1, cellCount do
            for l = 1, cellCount do
                local cell = cells[k][l]
                cell.TotalMass = 0
                cell.TotalEnergy = 0
                cell.ReclaimCount = 0
                cell.Reclaim = { }
            end
        end

        self.UpdateList = { }
        self.Brains = { }

        self:Update()
        self:DebugUpdate()
    end,

    ---@param self AIGridReclaim
    Update = function(self)
        ForkThread(
            self.UpdateThread,
            self
        )
    end,

    ---@param self AIGridReclaim
    UpdateThread = function(self)
        while true do
            WaitTicks(6)

            local start
            if Debug then
                start = GetSystemTimeSecondsOnlyForProfileUse()

                -- reset accumulative fields
                DebugUpdateData.Processed = 0
                DebugUpdateData.Updates = 0
            end

            -- update cells
            for id, cell in self.UpdateList do
                self.UpdateList[id] = nil

                local count = 0
                local totalMass = 0
                local totalEnergy = 0

                for id, reclaim in cell.Reclaim do
                    count = count + 1
                    local fraction = reclaim.ReclaimLeft or 0
                    totalMass = totalMass + fraction * (reclaim.MaxMassReclaim or 0)
                    totalEnergy = totalEnergy + fraction * (reclaim.MaxEnergyReclaim or 0)
                end

                cell.TotalMass = totalMass
                cell.TotalEnergy = totalEnergy
                cell.ReclaimCount = count

                -- inform ai brains of changes
                for k, brain in self.Brains do
                    if brain.OnReclaimUpdate then
                        brain:OnReclaimUpdate(self, cell)
                    end
                end

                -- update accumulative fields
                if Debug then
                    DebugUpdateData.Processed = DebugUpdateData.Processed + cell.ReclaimCount
                    DebugUpdateData.Updates = DebugUpdateData.Updates + 1

                    self:DebugCellUpdate(cell.X, cell.Z)
                end
            end

            if Debug then
                -- DebugUpdateData.Memory = import("/lua/system/utils.lua").ToBytes(self, { Reclaim = true }) / (1024 * 1024)
                DebugUpdateData.Tick = GetGameTick()
                DebugUpdateData.Time = GetSystemTimeSecondsOnlyForProfileUse() - start

                Sync.GridReclaimUIDebugUpdate = DebugUpdateData
            end
        end
    end,

    -------------------------------
    -- Reclaim related functions --

    --- Called by a prop as it is destroyed
    ---@param self AIGridReclaim
    ---@param prop Prop
    OnReclaimDestroyed = function(self, prop)
        local position = prop.CachePosition or prop:GetPosition()
        local bx, bz = self:ToCellIndices(position[1], position[3])

        local cell = self.Cells[bx][bz]
        cell.Reclaim[prop.EntityId] = nil

        self.UpdateList[cell.Identifier] = cell

        self:DebugPropDestroyed(prop)
    end,

    --- Called by a prop as the reclaim value is adjusted
    ---@param self AIGridReclaim
    ---@param prop Prop
    OnReclaimUpdate = function(self, prop)
        local position = prop.CachePosition or prop:GetPosition()
        local bx, bz = self:ToCellIndices(position[1], position[3])

        local cell = self.Cells[bx][bz]
        cell.Reclaim[prop.EntityId] = prop

        self.UpdateList[cell.Identifier] = cell

        self:DebugPropUpdated(prop)
    end,

    -------------------------------
    -- AIBrain related functions --

    --- Called by a brain to initialize logic that runs for just that brain
    ---@param self AIGridReclaim
    ---@param brain AIBrain
    RegisterBrain = function(self, brain)
        self.Brains[brain:GetArmyIndex()] = brain
    end,

    ---------------------
    -- Debug functions --

    --- Contains various debug logic
    ---@param self AIGridReclaim
    DebugUpdate = function(self)
        ForkThread(
            self.DebugUpdateThread,
            self
        )
    end,

    --- Allows us to scan the map
    ---@param self AIGridReclaim
    DebugUpdateThread = function(self)
        while true do
            WaitTicks(1)

            -- mouse scanning
            if Debug then
                local mouse = GetMouseWorldPos()
                local bx, bz = self:ToCellIndices(mouse[1], mouse[3])
                local cell = self.Cells[bx][bz]

                local totalMass = cell.TotalMass
                if totalMass and totalMass > 0 then
                    self:DrawCell(bx, bz, math.log(totalMass) - 1, '00610B')
                end

                local totalEnergy = cell.TotalEnergy
                if totalEnergy and totalEnergy > 0 then
                    self:DrawCell(bx, bz, math.log(totalEnergy) - 1, 'B4C400')
                end

                self:DrawCell(bx, bz, 0, 'ffffff')

                DebugCellData.ReclaimCount = cell.ReclaimCount
                DebugCellData.TotalEnergy = cell.TotalEnergy
                DebugCellData.TotalMass = cell.TotalMass
                DebugCellData.X = cell.X
                DebugCellData.Z = cell.Z
                Sync.GridReclaimUIDebugCell = DebugCellData
            end
        end
    end,

    --- Debugging logic when a cell is updated
    ---@param self AIGridReclaim
    ---@param bx number
    ---@param bz number
    DebugCellUpdate = function(self, bx, bz)
        if Debug then
            self:DrawCell(bx, bz, 1, '48FF00')
        end
    end,

    --- Debugging logic when a prop is destroyed
    ---@param self AIGridReclaim
    ---@param prop Prop
    DebugPropDestroyed = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, 'ff0000')
        end
    end,

    --- Debugging logic when a prop is updated
    ---@param self AIGridReclaim
    ---@param prop Prop
    DebugPropUpdated = function(self, prop)
        if Debug then
            DrawCircle(prop.CachePosition, 2, '0000ff')
        end
    end,
}

---@type AIGridReclaim
GridReclaimInstance = false

---@param brain AIBrain
Setup = function(brain)
    if not GridReclaimInstance then
        GridReclaimInstance = GridReclaim() --[[@as AIGridReclaim]]
    end

    if brain then
        GridReclaimInstance:RegisterBrain(brain)
    end
end
