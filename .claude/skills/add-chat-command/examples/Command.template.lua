
-------------------------------------------------------------------------------
-- /<name> [<args>] — one-line summary mirroring the Description field, plus
-- any constraints worth flagging to a future maintainer (sim callbacks used,
-- gating rules, surprising defaults).

---@type UIChatCommand
Command = {
    Name        = '<name>',
    Aliases     = { '<short>', '<other>' },          -- optional; remove if none
    Description = '<one-line summary shown by /help>',
    Params      = {
        { Name = '<arg1>', Type = 'String' },
        { Name = '<arg2>', Type = 'Int', Optional = true },
    },
    ShouldRegister = function()                      -- optional; remove if always-on
        return GetFocusArmy() ~= -1                  -- e.g. hide from observers
    end,
    Accept = function(args, ctx)
        -- Semantic checks against runtime state. Return (false, "/<name>: reason.")
        -- on rejection. The string is shown to the user as a local system line.
        return true
    end,
    Execute = function(args, ctx)
        -- Side effect. Prefer ctx.Controller.X over importing modules directly.
    end,
}

-------------------------------------------------------------------------------
--#region Debugging
-- Copy this block verbatim into every command file. Every builtin has it; it is
-- what makes saving the file hot-reload the command in a running game. Omitting
-- it is the most common mistake.

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
