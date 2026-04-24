
-------------------------------------------------------------------------------
-- /taunt <index> — broadcast a numbered taunt from the `taunts` table in
-- `/lua/ui/game/taunt.lua`. Same entry point as the legacy `/N` shortcut,
-- exposed here under a discoverable name so the command-hint popup lists it.
--
-- Out-of-range indices are still sent on the wire; receivers silently ignore
-- unknown entries in `taunt.RecieveTaunt`, matching the legacy behaviour.

---@type UIChatCommand
Command = {
    Name = 'taunt',
    Description = 'Play a numbered taunt for every player to hear.',
    Params = {
        { Name = 'index', Type = 'Int' },
    },
    Accept = function(args)
        if GetFocusArmy() == -1 then
            return false, "/taunt: observers can't taunt."
        end
        if args.index < 1 then
            return false, "/taunt: index must be at least 1."
        end
        return true
    end,
    Execute = function(args)
        import("/lua/ui/game/taunt.lua").SendTaunt(args.index)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
