--- Determines the available colors for players and the default color order for 
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled 
    -- with the ArmyColors and the PlayerColors tables.
    LobbyColorOrder = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 },
    TMMColorOrder = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 },

    -- Faction colours
    ArmyColors = {
        "ff436eee",      -- new blue1               -- 1
        "FFe80a0a",      -- Cybran red              -- 2 
        "FF2929e1",      -- UEF blue                -- 3
        "ff901427",      -- dark red                -- 4
        "ff9161ff",      -- purple                  -- 5
        "FFFF873E",      -- Nomads orange           -- 6
        "ff66ffcc",      -- aqua                    -- 7
        "fffafa00",      -- new yellow              -- 8
        "ffff88ff",      -- pink                    -- 9
        "ffff32ff",      -- new fuschia             -- 10
        "FF5F01A7",      -- dark purple             -- 11
        "ffa79602",      -- Sera golden             -- 12
        "ffb76518",      -- new brown               -- 13
        "FF2F4F4F",      -- olive (dark green)      -- 14
        "ff2e8b57",      -- new green               -- 15
        "ff40bf40",      -- mid green               -- 16
        "ff9fd802",      -- Order Green             -- 17
        "ff616d7e",      -- grey                    -- 18
        "ffffffff",      -- white                   -- 19
    },

    PlayerColors = {
        "ff436eee",      -- new blue1               -- 1
        "FFe80a0a",      -- Cybran red              -- 2 
        "FF2929e1",      -- UEF blue                -- 3
        "ff901427",      -- dark red                -- 4
        "ff9161ff",      -- purple                  -- 5
        "FFFF873E",      -- Nomads orange           -- 6
        "ff66ffcc",      -- aqua                    -- 7
        "fffafa00",      -- new yellow              -- 8
        "ffff88ff",      -- pink                    -- 9
        "ffff32ff",      -- new fuschia             -- 10
        "FF5F01A7",      -- dark purple             -- 11
        "ffa79602",      -- Sera golden             -- 12
        "ffb76518",      -- new brown               -- 13
        "FF2F4F4F",      -- olive (dark green)      -- 14
        "ff2e8b57",      -- new green               -- 15
        "ff40bf40",      -- mid green               -- 16
        "ff9fd802",      -- Order Green             -- 17
        "ff616d7e",      -- grey                    -- 18
        "ffffffff",      -- white                   -- 19
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
