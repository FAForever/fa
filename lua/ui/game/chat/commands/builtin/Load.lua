
local Prefs = import("/lua/user/prefs.lua")

--- /load [name]: load a save. Default is the quick-save slot, matching `QuickSave`'s path.
---@type UIChatCommand
Command = {
    Name = 'load',
    Description = 'Load a saved game by name (defaults to the quick-save slot).',
    ShouldRegister = function()
        return not SessionIsMultiplayer()
    end,
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
