
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

--- /unmute <target>: reverse of `/mute`. Re-shows new arrivals and history that landed while muted.
---@type UIChatCommand
Command = {
    Name = 'unmute',
    Description = 'Re-show messages from a previously muted player.',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Execute = function(args)
        ChatConfigController.SetMutedLive(args.target, false)
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
