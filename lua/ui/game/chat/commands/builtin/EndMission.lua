
--- /end-mission: forfeit the current session and open the score screen.
---@type UIChatCommand
Command = {
    Name = 'end-mission',
    Description = 'Forfeit the current skirmish or mission and show the score screen.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Execute = function()
        import("/lua/ui/game/tabs.lua").EndGame()
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
