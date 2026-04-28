
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

--- Normalises a resource-kind token to 'mass' or 'energy'. Returns nil on no match.
local function NormalizeType(token)
    local lower = string.lower(token or '')
    if lower == 'mass' or lower == 'm' then
        return 'mass'
    elseif lower == 'energy' or lower == 'e' then
        return 'energy'
    end
    return nil
end

--- /gift-resources <percent> <type> [target]: gift a fraction of mass or energy to an ally.
---@type UIChatCommand
Command = {
    Name = 'gift-resources',
    Description = 'Gift a percentage (1-100) of your mass or energy to an ally.',
    Params = {
        { Name = 'percent', Type = 'Int' },
        { Name = 'type',    Type = 'String' },
        { Name = 'target',  Type = 'Player', Optional = true },
    },
    Accept = function(args, ctx)
        local focusArmy = GetFocusArmy()
        if focusArmy == -1 then
            return false, "/gift-resources: observers can't gift resources."
        end

        if args.percent < 1 or args.percent > 100 then
            return false, "/gift-resources: percent must be between 1 and 100."
        end

        local kind = NormalizeType(args.type)
        if not kind then
            return false, "/gift-resources: type must be 'mass' or 'energy'."
        end
        args.type = kind

        if args.target == nil then
            local recipient = ctx.Model.Recipient()
            if type(recipient) ~= 'number' then
                return false, "/gift-resources: no target given and no player selected as chat recipient."
            end
            args.target = recipient
        end

        if args.target == focusArmy then
            return false, "/gift-resources: can't gift to yourself."
        end
        if not IsAlly(focusArmy, args.target) then
            return false, "/gift-resources: target must be an ally."
        end

        return true
    end,
    Execute = function(args)
        local fraction = args.percent / 100
        SimCallback({
            Func = "GiveResourcesToPlayer",
            Args = {
                From   = GetFocusArmy(),
                To     = args.target,
                Mass   = args.type == 'mass'   and fraction or 0,
                Energy = args.type == 'energy' and fraction or 0,
            },
        })
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
