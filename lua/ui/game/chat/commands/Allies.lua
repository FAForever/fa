
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

-------------------------------------------------------------------------------
-- /allies (aka /team) — switch the send target to allies only.

---@type UIChatCommand
Command = {
    Name = 'allies',
    Aliases = { 'team' },
    Description = 'Send to allies only.',
    Execute = function(_, ctx)
        ctx.Controller.SetRecipient(ChatModel.RecipientAllies)
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
