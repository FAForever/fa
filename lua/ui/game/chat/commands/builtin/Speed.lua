
--- /speed <n>: set sim speed via `WLD_GameSpeed`. Not registered in multiplayer (host vote/request flow).
---@type UIChatCommand
Command = {
    Name = 'speed',
    Description = 'Set the simulation speed.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Params = {
        { Name = 'value', Type = 'Int' },
    },
    Execute = function(args)
        ConExecute("WLD_GameSpeed " .. args.value)
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
