
--- /gift-units <target>: transfer current selection to an ally. Sim re-checks alliance and `ManualUnitShare`.
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

        -- Fall back to the unit under the cursor. `armyIndex` is
        -- 0-based, the armies table is 1-based.
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
        -- `true` second arg passes the current selection to the sim
        -- handler as `units`.
        SimCallback({
            Func = "GiveUnitsToPlayer",
            Args = { From = GetFocusArmy(), To = args.target },
        }, true)
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
