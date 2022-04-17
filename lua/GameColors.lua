--- Determines the available colors for players and the default color order for 
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled 
    -- with the ArmyColors and the PlayerColors tables.
    LobbyColorOrder = { 12, 1, 13, 2, 16, 3, 11, 6, 14, 15, 17, 5, 4, 10, 9, 8, 7, 18, 19 }, -- warm vs cold 
    TMMColorOrder = { 12, 1, 13, 2, 16, 3, 11, 6, 14, 15, 17, 5, 4, 10, 9, 8, 7, 18, 19 }, -- warm vs cold 

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a # to each color :)

    -- Faction colours
    ArmyColors = {
        "e80a0a",      -- Cybran red
        "901427",      -- dark red
        "FF873E",      -- Nomads orange
        "b76518",      -- new brown
        "a79602",      -- Sera golden
        "fafa00",      -- new yellow
        "9fd802",      -- Order Green
        "40bf40",      -- mid green
        "2e8b57",      -- new green
        "2F4F4F",      -- olive (dark green)
        "66ffcc",      -- aqua
        "436eee",      -- new blue1
        "2929e1",      -- UEF blue
        "ff88ff",      -- pink
        "ff32ff",      -- new fuschia
        "9161ff",      -- purple
        "5F01A7",      -- dark purple
        "616d7e",      -- grey
        "ffffff",      -- white
    },

    PlayerColors = {
        "e80a0a",      -- Cybran red
        "901427",      -- dark red
        "FF873E",      -- Nomads orange
        "b76518",      -- new brown
        "a79602",      -- Sera golden
        "fafa00",      -- new yellow
        "9fd802",      -- Order Green
        "40bf40",      -- mid green
        "2e8b57",      -- new green
        "2F4F4F",      -- olive (dark green)
        "66ffcc",      -- aqua
        "436eee",      -- new blue1
        "2929e1",      -- UEF blue
        "ff88ff",      -- pink
        "ff32ff",      -- new fuschia
        "9161ff",      -- purple
        "5F01A7",      -- dark purple
        "616d7e",      -- grey
        "ffffff",      -- white
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
