--- Determines the available colors for players and the default color order for
-- matchmaking. See autolobby.lua and lobby.lua for more information.
GameColors = {

    CivilianArmyColor = "BurlyWood",

    -- Default color order used for lobbies/TMM if not otherwise specified. Tightly coupled
    -- with the ArmyColors and the PlayerColors tables.
    LobbyColorOrder = { 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }, -- rainbow-like color for Fearghal
    TMMColorOrder = { 11, 01, 12, 02, 14, 03, 15, 05, 08, 19, 07, 05, 13, 16, 17, 04 }, -- warm vs cold

    -- If you end up working with this file, suggestion to install the Color Highlight extension:
    -- - https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight
    -- and temporarily pre-append a -- to each color :)

    -- Faction colours
    ArmyColors = {
        "FFe80a0a", -- (01) Cybran red
        "ff901427", -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "ffb76518", -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "ff9fd802", -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "ff2e8b57", -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "ff436eee", -- (11) new blue1
        "FF2929e1", -- (12) UEF blue
        "FF5F01A7", -- (13) dark purple
        "ff9161ff", -- (14) purple
        "ff66ffcc", -- (15) aqua
        "ffffffff", -- (16) white
        "ff616d7e", -- (17) grey
        "ffff88ff", -- (18) pink
        "ffff32ff", -- (19) new fuschia
    },

    PlayerColors = {
        "FFe80a0a", -- (01) Cybran red
        "ff901427", -- (02) dark red
        "FFFF873E", -- (03) Nomads orange
        "ffb76518", -- (04) new brown
        "ffa79602", -- (05) Sera golden
        "fffafa00", -- (06) new yellow
        "ff9fd802", -- (07) Order Green
        "ff40bf40", -- (08) mid green
        "ff2e8b57", -- (09) new green
        "FF2F4F4F", -- (10) olive (dark green)
        "ff436eee", -- (11) new blue1
        "FF2929e1", -- (12) UEF blue
        "FF5F01A7", -- (13) dark purple
        "ff9161ff", -- (14) purple
        "ff66ffcc", -- (15) aqua
        "ffffffff", -- (16) white
        "ff616d7e", -- (17) grey
        "ffff88ff", -- (18) pink
        "ffff32ff", -- (19) new fuschia
    },

    TeamColorMode = {
        Self = "RoyalBlue",
        Enemy = "FFE80A0A",
        Ally = "DarkGreen",
        Neutral = "Goldenrod",
    },

    UnidentifiedColor = "FF808080",
}
