
-- keep reference of original functions
local GlobalExitGame = _G.ExitGame
local GlobalExitApplication = _G.ExitApplication
local GlobalRestartSession = _G.RestartSession

local OnExitCallbacks = { }

--- Add a callback to be run when the game exits gracefully
---@param identifier string
---@param callback function
function AddOnExitCallback(identifier, callback)
    OnExitCallbacks[identifier] = callback
end

--- Remove a callback to be run when the game exits gracefully
---@param identifier string
function RemoveOnExitCallback(identifier)
    OnExitCallbacks[identifier] = nil
end

--- Run all on exit callbacks
local function RunOnExitCallbacks(type)
    for k, callback in OnExitCallbacks do
        local ok, msg = pcall(callback, type)
        if not ok then
            WARN(msg)
        end
    end
end

--- Exits the game, returning you to the main menu
_G.ExitGame = function()
    RunOnExitCallbacks('ExitGame')
    GlobalExitGame()
end

--- Exits the application as a whole
_G.ExitApplication = function()
    RunOnExitCallbacks('ExitApplication')
    GlobalExitApplication()
end

--- Restarts the session
_G.RestartSession = function()
    RunOnExitCallbacks('RestartSession')
    GlobalRestartSession()
end