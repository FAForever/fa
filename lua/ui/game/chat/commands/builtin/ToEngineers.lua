
--- /to-engineers: narrow selection to engineers. Errors rather than silently clearing on no-match.
---@type UIChatCommand
Command = {
    Name = 'to-engineers',
    Description = 'Narrow the current selection to engineers only.',
    Accept = function(args)
        local selection = GetSelectedUnits()
        if not selection or table.getn(selection) == 0 then
            return false, "/to-engineers: nothing selected."
        end
        local engineers = EntityCategoryFilterDown(categories.ENGINEER, selection)
        if table.getn(engineers) == 0 then
            return false, "/to-engineers: no engineers in selection."
        end
        args.engineers = engineers
        return true
    end,
    Execute = function(args)
        SelectUnits(args.engineers)
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
