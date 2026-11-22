
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

--- /allies: switch send target to allies only.
---@type UIChatCommand
Command = {
    Name = 'allies',
    Aliases = { 'team' },
    Description = 'Send to allies only.',
    Execute = function(_, ctx)
        ctx.Controller.SetRecipient(ChatModel.RecipientAllies)
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
