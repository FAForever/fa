#! /bin/sh

# Change this to the location of your run proton run script (you will have copied this into your client folder https://wiki.faforever.com/en/FAQ/Client-Setup)
RunProton="$HOME/Applications/FAF/downlords-faf-client-1.6.0/run"
$RunProton $HOME/.faforever/bin/ForgedAlliance.exe /init init_dev.lua /showlog /log "dev.log" /EnableDiskWatch /nomovie

# /init               Define what initialisation file to use
# /EnableDiskWatch    Allows the game to reload files when it sees they're changed on disk
# /showlog            Opens the moho log by default
# /log                Informs the game where to store the log
# /nomovie            Removes super laggy starting/launching movies (will require you to hit escape on startup)
