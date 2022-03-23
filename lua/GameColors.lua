-- Default color order for TMM/etc is set in conjunction with these tables,
-- and is specified in the local ColorOrder in lobby.lua.  So, if you change
-- the colors/order in the ArnyColors and or PlayerColors tables, you should
-- probably change the ColorOrder table in lobby.lua accordingly.

GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled 
    -- with the ArmyColors and the PlayerColors tables.
    DefaultColorOrder = {2, 12, 1, 9, 6, 13, 25, 17, 23, 11, 3, 16, 24, 18, 19, 14},

    -- Faction colours
    ArmyColors = {
        "FF2929e1",      -- UEF blue
        "ff436eee",      -- new blue1
        "ff1a9ba2",      -- dark cyan
        "ff6fa8dc",      -- sky blue
        "ff8e7cc3",      -- light purple
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
        "FFD8B038",      -- golden brown
        "fffafa00",      -- new yellow
        "ffffffff",      -- white
        "ff616d7e",      -- grey
        "FF2F4F4F",      -- olive (dark green)
        "ff1c6404",      -- dark green
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
        "ff8e7cc3",      -- light purple
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
        "FFD8B038",      -- golden brown
        "fffafa00",      -- new yellow
        "ffffffff",      -- white
        "ff616d7e",      -- grey
        "FF2F4F4F",      -- olive (dark green)
        "ff1c6404",      -- dark green
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
