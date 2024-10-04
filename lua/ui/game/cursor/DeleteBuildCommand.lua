--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

---@alias UIGestureDetectionCommandType 'off' | 'build' | 'engineering' | 'all'

---@type TrashBag
local ModuleTrash = TrashBag()

--- See also:  https://github.com/FAForever/FA-Binary-Patches/pull/22
local BuildCommandTypes = {
    [8] = true, -- BuildMobile
    [9] = true, -- BuildAssist
}

--- See also:  https://github.com/FAForever/FA-Binary-Patches/pull/22
local EngineeringCommandTypes = {
    [8] = true, -- BuildMobile
    [9] = true, -- BuildAssist
    [15] = true, -- Guard
    [19] = true, -- Reclaim
    [20] = true, -- Repair
    [21] = true, -- Capture
    [32] = true, -- Sacrifice
}

---@type UIGestureDetectionCommandType
local GestureDetectionCommandType = import("/lua/user/prefs.lua").GetOption('gesture_delete_commands')

---@type number
local GestureDetectionSuccessionThreshold = 3

--- Starts a basic gesture detection thread to delete a (build) command
local GestureDetectionThread = function()

    -- local scope for performance
    local WaitFrames = WaitFrames
    local GetHighlightCommand = GetHighlightCommand
    local GetGameTimeSeconds = GetGameTimeSeconds
    local DeleteCommand = DeleteCommand

    -- internal state
    local gestureStart = 0
    local gestureTargetId = nil
    local gestureSuccessive = 0
    local oldCommand = nil

    while true do
        WaitFrames(1)

        -- check for early exit
        if GestureDetectionCommandType == 'off' then
            return
        end

        -- retrieve a command
        local command = GetHighlightCommand()

        -- only register the event when we just started hovering over a command
        if command and not oldCommand then
            -- check for early exit
            if GestureDetectionCommandType == 'build' and not BuildCommandTypes[command.commandType] then
                gestureTargetId = nil
                continue
            elseif GestureDetectionCommandType == 'engineering' and not EngineeringCommandTypes[command.commandType] then
                gestureTargetId = nil
                continue
            end

            -- keep track of the gesture
            local gameTimeSeconds = GetGameTimeSeconds()
            if command.commandId == gestureTargetId and gameTimeSeconds - gestureStart < 0.5 then
                gestureSuccessive = gestureSuccessive + 1
                gestureStart = gameTimeSeconds
            else
                gestureStart = gameTimeSeconds
                gestureTargetId = command.commandId
                gestureSuccessive = 0
            end

            if gestureSuccessive == GestureDetectionSuccessionThreshold then
                DeleteCommand(gestureTargetId)
                gestureTargetId = 0
            end
        end

        oldCommand = command
    end
end

--- Starts the gesture detection thread. Function is idempotent.
StartGestureDetectionThread = function()
    ModuleTrash:Destroy()

    -- logic requires an active session
    if SessionIsActive() then
        return
    end

    ModuleTrash:Add(ForkThread(GestureDetectionThread))
end

--- Sets the gesture detection command type and attempts to restart the gesture detection thread.
---@param commandType UIGestureDetectionCommandType
SetGestureDetectionCommandType = function(commandType)
    GestureDetectionCommandType = commandType
    StartGestureDetectionThread()
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    newModule.StartGestureDetectionThread()
end

--- Called by the module manager when this module becomes dirty
function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()

    -- trigger a reload
    ForkThread(
        function()
            WaitSeconds(1.0)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
