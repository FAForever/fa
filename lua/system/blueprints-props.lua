
---@param prop PropBlueprint
local function PostProcessProp(prop)
    if prop.Categories then
        if table.find(prop.Categories, 'INVULNERABLE') then
            prop.ScriptClass = 'PropInvulnerable'
            prop.ScriptModule = '/lua/sim/prop.lua'
        end
    end
end

--- Post-processes all props
---@param props PropBlueprint[]
function PostProcessProps(props)
    for _, prop in props do
        PostProcessProp(prop)
    end
end
