
--- /save [name]: quick-save. Default name matches the quick-save hotkey so repeats overwrite the slot.
---@type UIChatCommand
Command = {
    Name = 'save',
    Description = 'Quick-save the current session (optional name).',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Params = {
        { Name = 'name', Type = 'Rest', Optional = true },
    },
    Execute = function(args)
        local name = args.name or LOC("<LOC QuickSave>QuickSave")
        import("/lua/ui/game/gamemain.lua").QuickSave(name)
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
