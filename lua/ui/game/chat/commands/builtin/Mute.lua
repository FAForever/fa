
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

--- /mute <target>: hide messages from a player for the rest of this game.
---@type UIChatCommand
Command = {
    Name = 'mute',
    Description = 'Hide messages from a specific player for the rest of the game.',
    Params = {
        { Name = 'target', Type = 'Player' },
    },
    Accept = function(args)
        local armies = GetArmiesTable()
        if armies and args.target == armies.focusArmy then
            return false, "/mute: can't mute yourself."
        end
        return true
    end,
    Execute = function(args)
        ChatConfigController.SetMutedLive(args.target, true)
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
