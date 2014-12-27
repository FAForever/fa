-- This is a hack to disable the call to InternalStartSteamDiscoveryService,
-- which only exists when using the steam executable.
InternalStartSteamDiscoveryService = function() end