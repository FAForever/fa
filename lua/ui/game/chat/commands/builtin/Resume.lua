
--- /resume: un-pause the local simulation. Symmetric with `/pause`.
---@type UIChatCommand
Command = {
    Name = 'resume',
    Description = 'Resume the simulation.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Execute = function()
        SessionResume()
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
