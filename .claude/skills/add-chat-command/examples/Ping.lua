
-------------------------------------------------------------------------------
-- /ping — prints "pong" as a local system line. No network traffic. Useful
-- as a smoke test that the command pipeline is alive end-to-end.
--
-- This is the minimal viable command: just Name, Description, Execute, and the
-- mandatory hot-reload block. No Params, no Accept, no ShouldRegister.

---@type UIChatCommand
Command = {
    Name        = 'ping',
    Description = 'Prints "pong" locally — smoke test for the chat command pipeline.',
    Execute = function(_, ctx)
        ctx.Controller.AppendLocalSystemMessage("pong")
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
