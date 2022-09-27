--*****************************************************************************
--* File: lua/multiplayer/onlineprovider.lua
--* Author: Sam Demulling
--* Summary: 3rd party integration options.  This will receive and send commands
--* by hooking into stdin/out in the supremecommander app.
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************


-- Called from C++ code when we are launching from gpg.net.
function CreateLobby(autolaunch, protocol, port, playerName, uid, natTraversalProvider, hasSupcom)

    local lobbyfile
    if autolaunch then
        lobbyfile = '/lua/ui/lobby/autolobby.lua'
    else
        lobbyfile = '/lua/ui/lobby/lobby.lua'
    end

    lobby = import(lobbyfile)
    if not lobby then
        error("Could not load " .. repr(lobbyfile))
    end

    if hasSupcom == 0 then
        hasSupcom = false
    else
        hasSupcom = true
    end
    
    lobby.CreateLobby(protocol, port, playerName, uid, natTraversalProvider, GetFrame(0), ExitApplication, hasSupcom)
    return lobby
end
