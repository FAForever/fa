--- Determines the available colors for players and the default color order for 
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled 
    -- with the ArmyColors and the PlayerColors tables.
    DefaultColorOrder = {2, 11, 1, 8, 5, 12, 22, 15, 20, 10, 3, 14, 21, 7, 16, 13},

    -- Faction colours
    ArmyColors = {
        "FF2929e1",      -- UEF blue
        "ff436eee",      -- new blue1
        "ff1a9ba2",      -- dark cyan
        "ff6fa8dc",      -- sky blue
        "ff9161ff",      -- purple
        "FF5F01A7",      -- dark purple
        "ff920092",      -- rich purple
        "ff901427",      -- dark red
        "ffff88ff",      -- pink
        "ffff32ff",      -- new fuschia
        "FFe80a0a",      -- Cybran red
        "FFFF873E",      -- Nomads orange
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
        "FF2929e1",      -- UEF blue
        "ff436eee",      -- new blue1
        "ff1a9ba2",      -- dark cyan
        "ff6fa8dc",      -- sky blue
        "ff9161ff",      -- purple
        "FF5F01A7",      -- dark purple
        "ff920092",      -- rich purple
        "ff901427",      -- dark red
        "ffff88ff",      -- pink
        "ffff32ff",      -- new fuschia
        "FFe80a0a",      -- Cybran red
        "FFFF873E",      -- Nomads orange
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
