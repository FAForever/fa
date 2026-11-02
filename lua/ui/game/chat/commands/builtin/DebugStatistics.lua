
--- /debug-statistics: cycle the engine's `ShowStats` overlay. Only registered with `/debug`.
---@type UIChatCommand
Command = {
    Name = 'debug-statistics',
    Description = 'Cycle the engine ShowStats overlay.',
    ShouldRegister = function()
        return HasCommandLineArg('/debug')
    end,
    Execute = function()
        ConExecute('ShowStats')
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
