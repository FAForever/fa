
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

--- /clear: wipes local chat history.
---@type UIChatCommand
Command = {
    Name = 'clear',
    Description = 'Clear the local chat history.',
    Execute = function()
        ChatModel.GetSingleton().History:Set({})
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-registers this command so saved edits take effect.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua").Register(newModule.Command)
end

--- Hot-reload hook: schedules the re-import so `OnReload` fires with the freshly-loaded module.
function __moduleinfo.OnDirty()
    ForkThread(function()
        WaitFrames(1)
        import(__moduleinfo.name)
    end)
end

--#endregion
