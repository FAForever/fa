--****************************************************************************
--**
--**  File     :  /lua/modules/AIChatSorian.lua
--**  Author(s): Mike Robbins aka Sorian
--**
--**  Summary  : AI Chat Functions
--**  Version  : 0.1
--****************************************************************************
local Chat = import("/lua/ui/game/chat.lua")
local ChatTo = import("/lua/lazyvar.lua").Create()

---@param group any
---@param text string
---@param sender any
function AIChat(group, text, sender)
    if text then
        if import("/lua/ui/game/taunt.lua").CheckForAndHandleTaunt(text, sender) then
            return
        end
        ChatTo:Set(group)
        msg = { to = ChatTo(), Chat = true }
        msg.text = text
        msg.aisender = sender
        local armynumber = GetArmyData(sender)
        if ChatTo() == 'allies' then
            AISendChatMessage(FindAllies(armynumber), msg)
        elseif ChatTo() == 'enemies' then
            AISendChatMessage(FindEnemies(armynumber), msg)
        elseif type(ChatTo()) == 'number' then
            AISendChatMessage({ChatTo()}, msg)
        else
            AISendChatMessage(nil, msg)
        end
    end
end

---@param army Army
---@return number[]
function FindAllies(army)
    local t = GetArmiesTable()
    local result = {}
    for k,v in t.armiesTable do
        if IsAlly(k, army) and v.human then
            table.insert(result, k)
        end
    end
    return result
end

---@param army Army
---@return number[]
function FindEnemies(army)
    local t = GetArmiesTable()
    local result = {}
    for k,v in t.armiesTable do
        if IsEnemy(k, army) and v.human then
            table.insert(result, k)
        end
    end
    return result
end

---@param towho any
---@param msg any
function AISendChatMessage(towho, msg)
    local t = GetArmiesTable()
    local focus = t.focusArmy
    if msg.Chat then
        if towho then
            for k,v in towho do
                if v == focus then
                    import("/lua/ui/game/chat.lua").ReceiveChat(msg.aisender, msg)
                end
            end
        else
            import("/lua/ui/game/chat.lua").ReceiveChat(msg.aisender, msg)
        end
    elseif msg.Taunt then
        import("/lua/ui/game/taunt.lua").RecieveAITaunt(msg.aisender, msg)
    end
end

---@param army string
---@return number|nil
function GetArmyData(army)
    local armies = GetArmiesTable()
    local result
    if type(army) == 'string' then
        for i, v in armies.armiesTable do
            if v.nickname == army then
                result = i
                break
            end
        end
    end
    return result
end