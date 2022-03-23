#! /bin/sh

# arguments are not taken into account, does anyone know why?
./ForgedAlliance.exe "/init" "init_dev.lua" "/EnableDiskWatch" "/showlog" "/log" "dev.log" "/RunWithTheWind"

# /init               Define what initialisation file to use
# /EnableDiskWatch    Allows the game to reload files when it sees they're changed on disk
# /showlog            Opens the moho log by default
# /log                Informs the game where to store the log
# /RunWithTheWind     Ensures single player games are compatible with the console commander `wld_RunWithTheWind` 