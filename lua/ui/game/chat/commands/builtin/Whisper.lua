
--- /whisper <target>: private-message a specific player.
---@type UIChatCommand
Command = {
    Name = 'whisper',
    Aliases = { 'w', 'pm' },
    Description = 'Whisper to a specific player (by nickname or army ID).',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/whisper: can't whisper yourself."
        end
        return true
    end,
    Execute = function(args, ctx)
        ctx.Controller.SetRecipient(args.target)
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
