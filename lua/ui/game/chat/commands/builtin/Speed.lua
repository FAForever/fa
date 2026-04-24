
-------------------------------------------------------------------------------
-- /speed <n> — set the simulation speed multiplier via the `WLD_GameSpeed`
-- console var. Range is engine-side (typically -10..+10); invalid values
-- are ignored by the engine rather than throwing.
--
-- Available in single-player and replay. Multiplayer speed changes go
-- through a vote/request flow on the host, not a direct console write, so
-- the command is unregistered there.

---@type UIChatCommand
Command = {
    Name = 'speed',
    Description = 'Set the simulation speed.',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Params = {
        { Name = 'value', Type = 'Int' },
    },
    Execute = function(args)
        ConExecute("WLD_GameSpeed " .. args.value)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
