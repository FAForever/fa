do
    local Prefs = import('/lua/user/prefs.lua')
    local options = Prefs.GetFromCurrentProfile('options')
    function Init()
        ConExecute("ui_RenderCustomNames " .. tostring(options.gui_render_custom_names))
        ConExecute("UI_ForceLifbarsOnEnemy " .. tostring(options.gui_render_enemy_lifebars))
    end
end

