--- Determines the available colors for players and the default color order for 
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled 
    -- with the ArmyColors and the PlayerColors tables.
    LobbyColorOrder = {1, 7, 2, 9, 4, 8, 19, 12, 17, 6, 18, 11, 3, 13, 14, 10}, -- warm vs cold 
    TMMColorOrder = {1, 7, 2, 9, 4, 8, 19, 12, 17, 6, 18, 11, 3, 13, 14, 10}, -- warm vs cold 

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a # to each color :)

    -- Faction colours
    ArmyColors = {
        "ff436eee",      -- new blue1
        "FF2929e1",      -- UEF blue
        "FF5F01A7",      -- dark purple
        "ff9161ff",      -- purple
        "ffff88ff",      -- pink
        "ffff32ff",      -- new fuschia
        "FFe80a0a",      -- Cybran red
        "FFFF873E",      -- Nomads orange
        "ff901427",      -- dark red
        "ffb76518",      -- new brown
        "ffa79602",      -- Sera golden
        "fffafa00",      -- new yellow
        "ffffffff",      -- white
        "ff616d7e",      -- grey
        "FF2F4F4F",      -- olive (dark green)
        "ff2e8b57",      -- new green
        "ff40bf40",      -- mid green
        "ff9fd802",      -- Order Green
        "ff66ffcc",      -- aqua
    },

    PlayerColors = {
        "ff436eee",      -- new blue1
        "FF2929e1",      -- UEF blue
        "FF5F01A7",      -- dark purple
        "ff9161ff",      -- purple
        "ffff88ff",      -- pink
        "ffff32ff",      -- new fuschia
        "FFe80a0a",      -- Cybran red
        "FFFF873E",      -- Nomads orange
        "ff901427",      -- dark red
        "ffb76518",      -- new brown
        "ffa79602",      -- Sera golden
        "fffafa00",      -- new yellow
        "ffffffff",      -- white
        "ff616d7e",      -- grey
        "FF2F4F4F",      -- olive (dark green)
        "ff2e8b57",      -- new green
        "ff40bf40",      -- mid green
        "ff9fd802",      -- Order Green
        "ff66ffcc",      -- aqua
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
