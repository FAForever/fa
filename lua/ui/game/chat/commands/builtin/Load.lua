
local Prefs = import("/lua/user/prefs.lua")

-------------------------------------------------------------------------------
-- /load [name] — load a save by name (default: the quick-save slot). The
-- path is built the same way `QuickSave` does in `gamemain.lua`, so an
-- omitted name lines up exactly with the slot `/save` writes to.
--
-- Load errors surface as the engine's standard failure dialog via
-- `LoadSavedGame`'s return values; the command stays silent on success
-- because the game is already transitioning out.

local function IsSingleplayer()
    return not SessionIsMultiplayer() and not SessionIsReplay()
end

---@type UIChatCommand
Command = {
    Name = 'load',
    Description = 'Load a saved game by name (defaults to the quick-save slot).',
    ShouldRegister = IsSingleplayer,
    Params = {
        { Name = 'name', Type = 'Rest', Optional = true },
    },
    Execute = function(args, ctx)
        local name = args.name or LOC("<LOC QuickSave>QuickSave")
        local saveType = import("/lua/ui/campaign/campaignmanager.lua").campaignMode
            and "CampaignSave" or "SaveGame"
        local path = GetSpecialFilePath(Prefs.GetCurrentProfile().Name, name, saveType)

        local ok, err = LoadSavedGame(path)
        if not ok and err then
            ctx.Controller.AppendLocalSystemMessage(
                string.format("/load: could not load '%s' (%s).", name, tostring(err))
            )
        end
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
