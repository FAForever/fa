
-------------------------------------------------------------------------------
-- /end-mission — forfeits the current session and opens the score screen.
-- Delegates to the same `EndGame` function the escape-menu button uses, so
-- campaign vs. skirmish branching stays consistent. Available in
-- single-player and replay.

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

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
