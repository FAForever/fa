
-------------------------------------------------------------------------------
-- /save [name] — quick-save the current session. Without a name, uses the
-- localised default ("QuickSave" in English) so repeated saves overwrite the
-- same slot — matching the quick-save hotkey in `keyactions.lua`.
--
-- Accepts `Rest` so a multi-word name goes through as-is: `/save before boss`
-- saves to "before boss".

---@type UIChatCommand
Command = {
    Name = 'save',
    Description = 'Quick-save the current session (optional name).',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
    Params = {
        { Name = 'name', Type = 'Rest', Optional = true },
    },
    Execute = function(args)
        local name = args.name or LOC("<LOC QuickSave>QuickSave")
        import("/lua/ui/game/gamemain.lua").QuickSave(name)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
