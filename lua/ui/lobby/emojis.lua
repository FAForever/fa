local Prefs = import('/lua/user/prefs.lua')

emojis_textures = '/mods/Emojis/Packs/'
Packages = {} -- emojis' packages data

function UpdatePacks(id, state)
    Packages[id].info.isEnabled = state
    local packsStates = Prefs.GetFromCurrentProfile('emojipacks')
    packsStates[id] = state
    Prefs.SetToCurrentProfile("emojipacks", packsStates)
end

function ScanPackages()
    Packages = {}
    local data = DiskFindFiles(emojis_textures,'*\.dds')
    for _,pathdata in data do
        local SepPath = {}
        for v in string.gfind(pathdata,'[^/\.]+') do -- separating path
            table.insert(SepPath,v)
        end

        local package = SepPath[table.getn(SepPath)-2]--package name
        local emoji = SepPath[table.getn(SepPath)-1]--filename

        if not Packages[package] then
            Packages[package] = {}
            Packages[package].emojis = {}
            if DiskGetFileInfo(emojis_textures..package..'/_info.lua') then
                Packages[package].info = import(emojis_textures..package..'/_info.lua').info or
                 {
                    name = package,
                    description = "NONE",
                    author = "NONE",
                }
            end
        end
        table.insert(Packages[package].emojis, emoji)
    end
    local packsStates = Prefs.GetFromCurrentProfile('emojipacks') or {}
    for packname,pack in Packages do
        if packsStates[packname] ~= nil then
            pack.info.isEnabled = packsStates[packname]
        else
            packsStates[packname] = true
            pack.info.isEnabled = true
        end
    end
    Prefs.SetToCurrentProfile("emojipacks", packsStates)
end


ScanPackages()


function  isInEmojis(str)
    str = string.lower(str)
    for id, pack in Packages do
        if not pack.info.isEnabled then continue end
        local packprefix = id..'/'
        for _, emoji in pack.emojis do
            if packprefix..emoji == str then
                return true
            end
        end
    end
    return false
end

function CheckEmojis(text, dosearch)
    if not dosearch then
        return {{text = text}}
    end
    local wasEmoji = true
    local result_table = {}
    for v in string.gfind(text, "[^:]+") do
        if isInEmojis(v) then
            table.insert(result_table, {
                emoji = v
            })
            wasEmoji = true

        else
            if wasEmoji  then
                table.insert(result_table, {
                    text = v
                })
                wasEmoji = false
            else
                local len = table.getn(result_table)
                result_table[len].text = result_table[len].text .. ':' .. v
            end
        end
    end
    return result_table
end

function strcmp(str1,str2)
    local strlen
    if string.len(str1) > string.len(str2) then
        strlen = string.len(str2)
    else
        strlen = string.len(str1)
    end
    for ch = 1,strlen do
        if string.byte(str1,ch) > string.byte(str2,ch) then 
            return true
        elseif string.byte(str1,ch) < string.byte(str2,ch) then 
            return false
        end
    end
    if string.len(str1) > string.len(str2) then
        return true
    else
        return false
    end
end

function processInput(emojiText)
    local FoundEmojis = {}
    local isInserted = false
    local ind 
    for id, pack in Packages do
        if not pack.info.isEnabled then
            continue
        end
        for _, emoji in pack.emojis do
            isInserted = false
            if string.find(emoji, emojiText) then
                for i,FoundEmoji in FoundEmojis do
                    if strcmp(FoundEmoji.emoji,emoji) then
                        isInserted = true
                        ind = i
                        break
                    end
                end
                if isInserted then
                    table.insert(FoundEmojis, ind , {emoji = emoji,pack = id})
                else
                    table.insert(FoundEmojis,  {emoji = emoji,pack = id})
                end
            end
        end
    end
    return FoundEmojis
end