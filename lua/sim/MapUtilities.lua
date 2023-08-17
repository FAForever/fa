--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

local MarkerUtilities = import("/lua/sim/markerutilities.lua")
local MapResourceCheckApplied = false

--- Attempts to spawn in extractors and hydrocarbons on each marker that is enabled in the game. Attempts 
--- to ring each extractor with storages and fabricators, similar to how the ringing feature works.
function MapResourceCheck()
    if MapResourceCheckApplied then
        WARN("Restart the session before running the resource check again.")
        return
    end

    MapResourceCheckApplied = true

    -- get an arbitrary brain
    local brain = ArmyBrains[GetCurrentCommandSource()]
    local army = brain:GetArmyIndex()
    SetIgnoreArmyUnitCap(army, true)

    -- get markers
    local mass = MarkerUtilities.GetMarkersByType("Mass")
    local hydro = MarkerUtilities.GetMarkersByType("Hydrocarbon")

    --- Helper function that attempts to build a unit there
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param id UnitId
    local function TryUnit(x, y, z, id)
        if brain:CanBuildStructureAt(id, {x, y, z}) then
            CreateUnitHPR(id, army, x, y, z, 0, 0, 0)
        end
    end

    ForkThread(
        function()
            local yield = coroutine.yield

            -- create resource structures if possible
            for k, marker in mass do 
                local x, y, z = marker.position[1], marker.position[2], marker.position[3]
                TryUnit(x, y, z, "ueb1103")
            end

            yield(2)

            for k, marker in hydro do
                local x, y, z = marker.position[1], marker.position[2], marker.position[3]
                TryUnit(x, y, z, "uab1102")
            end

            yield(2)

            -- try and cap with storages
            for k, marker in mass do 
                local x, y, z = marker.position[1], marker.position[2], marker.position[3]
                TryUnit(x + 2, y, z, "urb1106")
                TryUnit(x - 2, y, z, "urb1106")
                TryUnit(x, y, z + 2, "urb1106")
                TryUnit(x, y, z - 2, "urb1106")
            end

            yield(2)

            -- try and cap with fabricators
            for k, marker in mass do 
                local x, y, z = marker.position[1], marker.position[2], marker.position[3]
                TryUnit(x + 4, y, z,     "xsb1104")
                TryUnit(x - 4, y, z,     "xsb1104")
                TryUnit(x, y, z + 4,     "xsb1104")
                TryUnit(x, y, z - 4,     "xsb1104")
                TryUnit(x + 2, y, z + 2, "xsb1104")
                TryUnit(x - 2, y, z + 2, "xsb1104")
                TryUnit(x + 2, y, z - 2, "xsb1104")
                TryUnit(x - 2, y, z - 2, "xsb1104")
            end

            yield(2)
        end
    )
end

--- Keeps track of all marker debugging threads
local iMapArmyPerspective = 1
local DebugThreads = { }
local DebugSuspend = { }

--- Various threat identifiers and corresponding colors, shared between the UI and the sim
local ThreatInformation = import("/lua/shared/maputilities.lua").ThreatInformation

--- If the key of a threat identifier has a truthy value in this table it will be rendered
local ThreatRendering = { }

--- Changes the perspective of the threat values measured
---@param army number
function iMapSwitchPerspective(army)
    iMapArmyPerspective = army
end

--- Toggles rendering a threat circle
---@param identifier any
function iMapToggleThreat(identifier)
    ThreatRendering[identifier]= not ThreatRendering[identifier]
end

--- Toggles the visualisation of the iMAP grid that is used by the AI. The grid can be tweaked using 'iMapSwitchPerspective' and 'iMapToggleThreat'
function iMapToggleRendering()
    -- allows us to keep track of the thread
    local type = "iMAPThread"

    -- get the thread if it exists
    local thread = DebugThreads[type]
    if not thread then

        -- make the thread if it did not exist yet
        thread = ForkThread(
            function()

                -- by default, 16x16 iMAP
                local n = 16 
                local mx = ScenarioInfo.size[1]
                local mz = ScenarioInfo.size[2]

                -- smaller maps have a 8x8 iMAP
                if mx == mz and mx == 5 then
                    n = 8
                end

                local color = "ffffff"
                local a = Vector(0, 0, 0)
                local b = Vector(0, 0, 0)
                local GetTerrainHeight = GetTerrainHeight
                local DrawLine = DrawLine
                local sqrt = math.sqrt

                local function Line(x1, z1, x2, z2, color)
                    a[1] = x1
                    a[3] = z1
                    a[2] = GetTerrainHeight(x1, z1)

                    b[1] = x2 
                    b[3] = z2
                    b[2] = GetTerrainHeight(x2, z2)
                    DrawLine(a, b, color)
                end

                while true do

                    local brain = ArmyBrains[iMapArmyPerspective]

                    -- check if we should suspend ourselves
                    if DebugSuspend[type] then
                        SuspendCurrentThread()
                    end

                    -- distance per cell
                    local fx = 1 / n * mx
                    local fz = 1 / n * mz

                    -- draw iMAP information
                    for z = 1, n do
                        for x = 1, n do

                            -- draw cell
                            Line(fx * (x - 1), fz * (z - 1), fx * (x - 0), fz * (z - 1), color)
                            Line(fx * (x - 1), fz * (z - 1), fx * (x - 1), fz * (z - 0), color)
                            Line(fx * (x - 0), fz * (z - 0), fx * (x - 0), fz * (z - 1), color)
                            Line(fx * (x - 0), fz * (z - 0), fx * (x - 1), fz * (z - 0), color)

                            local cx = fx * (x - 0.5)
                            local cz = fz * (z - 0.5)

                            a[1] = cx
                            a[2] = GetTerrainHeight(cx, cz)
                            a[3] = cz

                            -- draw individual threat values of cell
                            for k, info in ThreatInformation do

                                -- DrawCircle(a, 0.25 * sqrt(1600), "000000")

                                if ThreatRendering[info.identifier] then
                                    local threat = brain:GetThreatAtPosition(a, 0, true, info.identifier)
                                    if threat > 0 then
                                        DrawCircle(a, 0.25 * sqrt(threat), info.color)
                                    end
                                end
                            end
                        end
                    end
                    WaitTicks(2)
                end
            end
        )

        -- store it and return
        DebugSuspend[type] = false
        DebugThreads[type] = thread 
        return
    end

    -- enable the thread if it should not be suspended
    DebugSuspend[type] = not DebugSuspend[type]
    if not DebugSuspend[type] then
        ResumeThread(thread)
    end

    -- keep track of it
    DebugThreads[type] = thread
end