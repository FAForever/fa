
-------------------------------------------------------------------------------
-- /to-engineers — narrow the current selection to just the engineers. If
-- nothing is selected, or none of the selected units are engineers, the
-- command reports an error rather than silently clearing the selection.

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

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
