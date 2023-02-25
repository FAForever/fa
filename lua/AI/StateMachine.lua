local StateMachines = {}

local Identifier = 2
local function GetUniqueIdentifier()
    Identifier = Identifier + 1
    return Identifier
end

---@class AIStateMachine
---@field Identifier string
---@field StateTrash TrashBag
---@field Platoon Platoon
---@field Debug boolean
StateMachine = ClassSimple {

    Identifier = 'Default',
    Debug = false,

    ---@param self AIStateMachine
    ---@param platoon Platoon
    __init = function(self, platoon)
        self.Identifier = string.format("%s - %d", self.Identifier, GetUniqueIdentifier())
        self.StateTrash = TrashBag()
        self.Platoon = platoon
        self.StateName = ''

        -- prepare sync and inform UI that we exist
        self.StateSync = { Tick = GetGameTick() }
        self:ToSync('Created', self.Identifier)

        -- prepare unit identifiers for debugging
        local identifiers = {}
        local units = self.Platoon:GetPlatoonUnits()
        for k, unit in units do
            unit:SetStat(unit:GetStat('AIStateMachineIdentifier', ''), self.Identifier)
            identifiers[k] = unit:GetEntityId()
        end
        self:ToSync('UnitIdentifiers', identifiers)
    end,

    ---@param self AIStateMachine
    ---@param name string
    ToState = function(self, name)
        self.StateTrash:Destroy()

        local state = self[name]
        if state then
            self.StateName = name
            ChangeState(self, state)
        else
            self.StateName = 'Error'
            ChangeState(self, state)
        end
    end,

    --- Passes information to the sync to visualize in the UI
    ---@param self any
    ---@param key any
    ---@param value any
    ToSync = function(self, key, value)
        local tick = GetGameTick()
        local syncState = self.StateSync

        -- clean up state
        if syncState.Tick < tick then
            for k, v in syncState do
                syncState[k] = nil
            end

            syncState.Tick = tick
        end

        -- add info to our state
        syncState[key] = value

        -- retrieve sync
        local sync = Sync
        local syncStateMachines = sync.StateMachines or {}
        sync.StateMachines = syncStateMachines

        -- add this state machine to the sync
        syncStateMachines[self.Identifier] = syncState
    end,

    -- # Default states # --

    Start = State {
        ---@param self AIStateMachine
        Main = function(self)
            self:ToState('Error')
        end,
    },

    Blank = State {
        ---@param self AIStateMachine
        Main = function(self)
            self:ToState('Error')
        end,
    },

    Error = State {
        ---@param self AIStateMachine
        Main = function(self)
        end,
    },

    -- # Debug functionality # --

    --- Toggles the debug functionality
    ---@param self AIStateMachine
    ToggleDebug = function(self)
        self.Debug = not self.Debug
        self:ToSync('Debug', self.Debug)
    end,

    --- Enables the debug functionality, regardless of the previous state
    ---@param self AIStateMachine
    EnableDebug = function(self)
        self.Debug = true
        self:ToSync('Debug', self.Debug)
    end,

    --- Only logs the information when the field `self.Debug` is set to true
    ---@param self AIStateMachine
    ---@param info any
    DebugLog = function(self, info)
        if self.Debug then
            LOG(string.format("%s: %s", self.Identifier, reprs(info)))
        end
    end,

    --- Only draws the information when the field `self.Debug` is set to true
    ---@param self AIStateMachine
    ---@param position Vector
    ---@param diameter number
    ---@param color Color
    DebugDrawCircle = function(self, position, diameter, color)
        if self.Debug then
            DrawCircle(position, diameter, color)
        end
    end,

    --- Only draws the information when the field `self.Debug` is set to true
    ---@param self AIStateMachine
    ---@param a Vector
    ---@param b Vector
    ---@param color Color
    DebugDrawLine = function(self, a, b, color)
        if self.Debug then
            DrawLine(a, b, color)
        end
    end,

    --- Only draws the information when the field `self.Debug` is set to true
    ---@param self AIStateMachine
    ---@param a Vector
    ---@param b Vector
    ---@param color Color
    DebugDrawLinePop = function(self, a, b, color)
        if self.Debug then
            DrawLinePop(a, b, color)
        end
    end,
}
