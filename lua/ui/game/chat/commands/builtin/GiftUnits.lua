
-------------------------------------------------------------------------------
-- /gift-units <target> — transfer the current selection to an allied player.
-- Mirrors the Shift-click gift on the score panel: observers can't gift,
-- a lone ACU can't be gifted, and the sim side still re-checks alliance
-- and `ManualUnitShare` before transferring ownership.

---@type UIChatCommand
Command = {
    Name = 'gift-units',
    Description = 'Gift the current selection to an ally. If no target is given, the unit under the cursor is used.',
    Params = {
        { Name = 'target', Type = 'Player', Optional = true },
    },
    Accept = function(args)
        local focusArmy = GetFocusArmy()
        if focusArmy == -1 then
            return false, "/gift-units: observers can't gift units."
        end

        -- Fall back to the unit currently under the cursor. `armyIndex` on
        -- the rollover is zero-based, so bump it to match the armies-table
        -- convention the rest of the command uses.
        if args.target == nil then
            local info = GetRolloverInfo()
            if not info or not info.armyIndex then
                return false, "/gift-units: no target given and no unit under the cursor."
            end
            args.target = math.floor(info.armyIndex) + 1
        end

        if args.target == focusArmy then
            return false, "/gift-units: can't gift to yourself."
        end
        if not IsAlly(focusArmy, args.target) then
            return false, "/gift-units: target must be an ally."
        end

        local selection = GetSelectedUnits()
        if not selection or table.getn(selection) == 0 then
            return false, "/gift-units: no units selected."
        end
        if table.getn(selection) == 1 and EntityCategoryContains(categories.COMMAND, selection[1]) then
            return false, "/gift-units: can't gift your ACU."
        end

        return true
    end,
    Execute = function(args)
        -- `true` as the second arg tells the engine to pass the current
        -- selection through to the sim handler as `units`.
        SimCallback({
            Func = "GiveUnitsToPlayer",
            Args = { From = GetFocusArmy(), To = args.target },
        }, true)
    end,
}
