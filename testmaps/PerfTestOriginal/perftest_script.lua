-----------------------------------------------------------------
-- File     :  /maps/perftest/perftest_script.lua
-- Author(s):  Marc Scattergood
-- Summary  :  perftest Demo Map
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ScenarioFramework = import("/lua/scenarioframework.lua")
local ScenarioStrings = import("/lua/scenariostrings.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Cinematics = import("/lua/cinematics.lua")
local Utilities = import("/lua/utilities.lua")

function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    SetIgnoreArmyUnitCap('Player', true)
    SetIgnoreArmyUnitCap('UEF', true)
    SetIgnoreArmyUnitCap('Aeon', true)
    SetIgnoreArmyUnitCap('Cybran_2', true)
    SetIgnoreArmyUnitCap('Aeon1', true)
end

function OnStart(self)
    ForkThread(function()
        WaitSeconds(1)
        Cinematics.EnterNISMode()
        -- Populate all the armies on the map.
        ForkThread(GetInitalBaseStarted)
        ForkThread(StartPerfTest)
    end)
end

function StartPerfTest()
    LockInput()

    -- Intro Shot
    WaitSeconds(3)
    Utilities.UserConRequest('UI_RenderUnitBars false')
    Utilities.UserConRequest('Cam_NearZoom 6')

    -- Long wait to give stuff time to load up before running the perf test.
    WaitSeconds(25)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Intro_Shot'), 0.0)
    BeginLoggingStats('perftest.log')
    WaitSeconds(2)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_2'), 10.0)

    WaitSeconds(10.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_000'), 5.0)
    PerfTest1()
    SetArmyGroupState(P_GA_L4_P2, 'HoldFire')
    PerfTest2()
    WaitSeconds(60.0)

    PerfTest3()
    WaitSeconds(110.0)

    PerfTest4()
end

-- Small Battle Start - Should be a light load test
function PerfTest1()
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_3'), 0.0)

    SetArmyGroupState(U_MB_Base, 'Aggressive')
    SetArmyGroupState(P_GA_L1_P1, 'Aggressive') -- Assault
    SetArmyGroupState(P_GA_L2_P1, 'Aggressive') -- Naval

    ScenarioUtils.AssignOrders('SB_Patrol', P_GA_L1_P1)
    ScenarioUtils.AssignOrders('SBN_Patrol', P_GA_L2_P1)
    WaitSeconds(1)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_4'), 10.0)
    PerfTest1_HAI()
    WaitSeconds(60)
end

-- Naval Battle Start - Should be a medium load test
function PerfTest2()
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_5'), 0)

    -- Player Cybran Moves
    SetStateAndMove(P_NG_L1_P1, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L1_P2, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L1_P3, 'Agressive', -20, -55)

    SetStateAndMove(P_NG_L2_P1, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L2_P2, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L2_P3, 'Agressive', -20, -55)

    SetStateAndMove(P_NG_L3_P1, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L3_P2, 'Agressive', -20, -55)
    SetStateAndMove(P_NG_L3_P3, 'Agressive', -20, -55)

    SetStateAndMove(P_NG_L4_P4, 'Agressive', -20, -70)

    -- UEF Moves
    SetStateAndMove(U_NG_L1_P1, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L1_P2, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L1_P3, 'Agressive', 20, 55)

    SetStateAndMove(U_NG_L2_P1, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L2_P2, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L2_P3, 'Agressive', 20, 55)

    SetStateAndMove(U_NG_L3_P1, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L3_P2, 'Agressive', 20, 55)
    SetStateAndMove(U_NG_L3_P3, 'HoldFire', 20, 55)

    SetStateAndMove(U_NG_L4_P2, 'Agressive', 20, 70)

    ForkThread(AtlantisRising)
end

-- Big Battle Start - Heaviest Load Battle
function PerfTest3()
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_7'), 0)
    ForkThread(SpawnMainBattle)
end

function PerfTest4()
    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_11'), 0)
    PerfTest4_Mavor()
    WaitSeconds(30.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_12'), 0)
    PerfTest4_Nukes()
    WaitSeconds(16.0)

    Cinematics.CameraReset()
    WaitSeconds(22.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_13'), 0)
    WaitSeconds(40.0)

    EndLoggingStats()
end

function PerfTest4_Mavor()
    IssueAttack({P_EB1[1]}, UEF_Nukes[1])
    IssueAttack({P_EB1[1]}, UEF_Nukes[2])
    IssueAttack({P_EB1[1]}, UEF_Nukes[3])
    IssueAttack({P_EB1[1]}, UEF_Nukes[4])
end

function PerfTest4_Nukes()
    IssueNuke({A_Base_Nukes[1]}, ScenarioUtils.MarkerToPosition('ANuke_1'))
    IssueNuke({A_Base_Nukes[2]}, ScenarioUtils.MarkerToPosition('ANuke_2'))
    IssueNuke({A_Base_Nukes[3]}, ScenarioUtils.MarkerToPosition('ANuke_3'))
    IssueNuke({A_Base_Nukes[4]}, ScenarioUtils.MarkerToPosition('ANuke_4'))
    IssueNuke({A_Base_Nukes[5]}, ScenarioUtils.MarkerToPosition('ANuke_5'))
    IssueNuke({A_Base_Nukes[6]}, ScenarioUtils.MarkerToPosition('ANuke_6'))
end

function PerfTest1_HAI()
    IssueFerry({P_GA_L4_P1[1]}, ScenarioUtils.MarkerToPosition('Player_Ferry_3'))
    IssueFerry({P_GA_L4_P1[2]}, ScenarioUtils.MarkerToPosition('Player_Ferry_2'))
    IssueFerry({P_GA_L4_P1[3]}, ScenarioUtils.MarkerToPosition('Player_Ferry_1'))

    SetArmyGroupState(P_GA_L4_P2, 'Aggressive')
    SetArmyGroupState(P_GA_Artillery_P1, 'Aggressive')

    IssueAttack({P_GA_Artillery_P1[1]}, ScenarioUtils.MarkerToPosition('ART_Targ_1'))
    IssueAttack({P_GA_Artillery_P1[2]}, ScenarioUtils.MarkerToPosition('ART_Targ_2'))
    IssueAttack({P_GA_Artillery_P1[3]}, ScenarioUtils.MarkerToPosition('ART_Targ_3'))
    IssueAttack({P_GA_Artillery_P1[4]}, ScenarioUtils.MarkerToPosition('ART_Targ_4'))
    WaitSeconds(15.0)

    StartAttackMove(P_GA_L4_P1, ScenarioUtils.MarkerToPosition('SBP_P2'))
    StartAttackMove(P_GA_L4_P2, ScenarioUtils.MarkerToPosition('SBP_P2'))
end

function PerfTest3_Nukes()
    SetArmyGroupState(UEF_Nukes, 'Aggressive')

    IssueNuke({UEF_Nukes[1]}, ScenarioUtils.MarkerToPosition('Nuke_1'))
    IssueNuke({UEF_Nukes[2]}, ScenarioUtils.MarkerToPosition('Nuke_2'))
    IssueNuke({UEF_Nukes[3]}, ScenarioUtils.MarkerToPosition('Nuke_3'))
    IssueNuke({UEF_Nukes[4]}, ScenarioUtils.MarkerToPosition('Nuke_4'))
end

function GetInitalBaseStarted()
    -- Main Base
    P_MB_CMD = ScenarioUtils.CreateArmySubGroup('Player', 'Main_Base', 'CMD')
    P_MB_Flying = SpawnAndOrder('P_B_Patrol', 'Player', 'Main_Base', 'Flying')
    P_MB_Engineers = ScenarioUtils.CreateArmySubGroup('Player', 'Main_Base', 'Engineers')
    P_MB_Base = ScenarioUtils.CreateArmySubGroup('Player', 'Main_Base', 'EverythingElse')
    P_MB_Jets = SpawnAndOrder('P_F_Patrol', 'Player', 'Main_Base', 'JetFighters')

    ForkThread(GetAllArmiesGoing)
end

function GetAllArmiesGoing()
    WaitSeconds(3)
    -- Player Cybran

    -- Small Assault Group
    P_GA_L1_P1 = ScenarioUtils.CreateArmySubGroup('Player', 'Minor_Ground_Assault', 'AssaultGroup', 'PLTN_1')
    P_GA_L2_P1 = ScenarioUtils.CreateArmySubGroup('Player', 'Minor_Ground_Assault', 'NavalGroup', 'PLTN_1')
    P_GA_L3_P1 = ScenarioUtils.CreateArmySubGroup('Player', 'Minor_Ground_Assault', 'Transports', 'PLTN_1')
    P_GA_L4_P1 = ScenarioUtils.CreateArmySubGroup('Player', 'Minor_Ground_Assault', 'PlatoonSupport', 'PLTN_1')
    P_GA_L4_P2 = ScenarioUtils.CreateArmySubGroup('Player', 'Minor_Ground_Assault', 'PlatoonSupport', 'PLTN_2')
    P_GA_Artillery_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Minor_Ground_Assault', 'Artillery', 'PLTN_1')
    tt1 = {P_GA_L4_P2[1], P_GA_L4_P2[2]}
    tt2 = {P_GA_L4_P2[3], P_GA_L4_P2[4]}
    tt3 = {P_GA_L4_P2[5], P_GA_L4_P2[6]}
    IssueTransportLoad({tt1[1]}, P_GA_L4_P1[1])
    IssueTransportLoad({tt1[2]}, P_GA_L4_P1[1])
    IssueTransportLoad({tt2[1]}, P_GA_L4_P1[2])
    IssueTransportLoad({tt2[2]}, P_GA_L4_P1[2])
    IssueTransportLoad({tt3[1]}, P_GA_L4_P1[3])
    IssueTransportLoad({tt3[2]}, P_GA_L4_P1[3])
    WaitSeconds(2)

    -- Naval Group
    P_NG_L1_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'FrontLine', 'PLTN_1')
    P_NG_L1_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'FrontLine', 'PLTN_2')
    P_NG_L1_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'FrontLine', 'PLTN_3')
    P_NG_L2_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'SecondLine', 'PLTN_1')
    P_NG_L2_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'SecondLine', 'PLTN_2')
    P_NG_L2_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'SecondLine', 'PLTN_3')
    P_NG_L3_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'ThirdLine', 'PLTN_1')
    P_NG_L3_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'ThirdLine', 'PLTN_2')

    -- Aircraft Carrier
    P_NG_L3_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'ThirdLine', 'PLTN_3')

    -- Torpedo Group
    P_NG_L4_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'Flying_Group', 'PLTN_1')
    P_NG_L4_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'Flying_Group', 'PLTN_2')

    -- Carrier Group
    P_NG_L4_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'Flying_Group', 'PLTN_3')

    -- Guard Group
    P_NG_L4_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Naval_Group', 'Flying_Group', 'PLTN_4')
    IssueTransportLoad(P_NG_L4_P3, P_NG_L3_P3[1])

    for k,v in P_NG_L4_P4 do
        IssueGuard({v}, P_NG_L2_P1[1])
    end
    WaitSeconds(2)

    -- Main battle:
    P_MGA_L7_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'Destroyers', 'PLTN_1')

    -- Experimental Base
    P_EB1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Experimental_Base', 'Mavor')
    P_EB2 = ScenarioUtils.CreateArmySubGroup('Player', 'Experimental_Base', 'Walls')

    -- UEF Enemy

    -- UEF Main Base
    U_MB_B1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Civilian')
    U_MB_B2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Defenses')
    U_MB_B3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Factories')
    U_MB_B4 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Power')
    U_MB_B5 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Walls')
    UEF_Nukes = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Base', 'Nukes')
    WaitSeconds(2)

    -- Small Assault Group
    U_MB_Base = ScenarioUtils.CreateArmyGroup('UEF', 'UEF_Small_Base')

    WaitSeconds(2)

    -- Naval Group
    U_NG_L1_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'FrontLine', 'PLTN_1')
    U_NG_L1_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'FrontLine', 'PLTN_2')
    U_NG_L1_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'FrontLine', 'PLTN_3')
    U_NG_L2_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'SecondLine', 'PLTN_1')
    U_NG_L2_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'SecondLine', 'PLTN_2')
    U_NG_L2_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'SecondLine', 'PLTN_3')
    U_NG_L3_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'ThirdLine', 'PLTN_1')
    U_NG_L3_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'ThirdLine', 'PLTN_2')

    -- Experimental Sub
    U_NG_L3_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'ThirdLine', 'PLTN_3')

    IssueDive(U_NG_L3_P3)
    -- Sub Group
    U_NG_L4_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'AirGroup', 'PLTN_1')

    -- Active Attack Group
    U_NG_L4_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Naval_Group', 'AirGroup', 'PLTN_2')
    IssueTransportLoad(U_NG_L4_P1, U_NG_L3_P3[1])

    for k,v in U_NG_L4_P2 do
        IssueGuard({v}, U_NG_L2_P1[1])
    end
    WaitSeconds(1)

    ForkThread(UEF_Carrier_Dive)

    -- Aeon
    A_Base_Nukes = SpawnAndSetArmySubGroupState('HoldFire', 'Aeon', 'Base', 'Nukes')
    A_Base_CMD = SpawnAndOrder('A_CMD_Patrol', 'Aeon', 'Base', 'CMD')
    A_Base_Colossus = SpawnAndSetArmySubGroupState('Aggressive', 'Aeon1', 'Colossus', 'PLTN_1')
    A_Base_All = SpawnAndSetArmySubGroupState('HoldFire', 'Aeon', 'Base', 'EverythingElse')
    A_Base_Patrol = SpawnAndOrder('AFG_Patrol', 'Aeon', 'Base', 'AirPatrol')
    WaitSeconds(5)

    for k, v in A_Base_Nukes do
        BuildNukes(v, 5)
    end

    for k, v in UEF_Nukes do
        BuildNukes(v, 5)
    end

    ForkThread(SpawnCybranBase)
end

function UEF_Carrier_Dive()
    WaitSeconds(30.0)
    IssueDive(U_NG_L3_P3)
end

function AtlantisRising()
    WaitSeconds(18.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_6'), 8)

    SetArmyGroupState(U_NG_L4_P2, 'Aggressive')
    SetArmyGroupState(P_NG_L4_P4, 'Aggressive')

    SetArmyGroupState(U_NG_L4_P1, 'Aggressive')
    SetArmyGroupState(P_NG_L4_P3, 'Aggressive')

    IssueDive(U_NG_L3_P3)

    if not U_NG_L3_P3[1].Dead then
        IssueTransportUnload(U_NG_L3_P3, P_NG_L2_P1[1]:GetPosition())
    end

    SetArmyGroupState(U_NG_L3_P3, 'Aggressive')
    WaitSeconds(12.0)

    if not P_NG_L3_P3[1].Dead then
        IssueTransportUnload(P_NG_L3_P3, U_NG_L2_P1[1]:GetPosition())
    end
end

function Major_Ground_Assault_Start()
    WaitSeconds(1.0)

    local MGA_CM1 = ScenarioUtils.MarkerToPosition('Main_Atk_1')
    local MGA_CM2 = ScenarioUtils.MarkerToPosition('Main_Atk_2')
    local MGA_CM3 = ScenarioUtils.MarkerToPosition('Main_Atk_3')
    local MGA_CM4 = ScenarioUtils.MarkerToPosition('Main_Atk_4')
    local MGA_CM5 = ScenarioUtils.MarkerToPosition('Main_Atk_5')
    local MGA_CM6 = ScenarioUtils.MarkerToPosition('Main_Atk_6')

    StartPassiveMove(P_MGA_L6_P1, MGA_CM1)
    StartPassiveMove(P_MGA_L6_P2, MGA_CM4)
    StartPassiveMove(P_MGA_L6_P3, MGA_CM6)

    StartPassiveMove(P_MGA_L7_P1, MGA_CM1)
    StartPassiveMove(U_MGA_L6_P1, MGA_CM1)
    WaitSeconds(15.0)

    StartAttackMove(P_MGA_L1_P1, MGA_CM2)
    StartAttackMove(P_MGA_L1_P2, MGA_CM4)
    StartAttackMove(P_MGA_L1_P3, MGA_CM4)
    StartAttackMove(P_MGA_L1_P4, MGA_CM6)

    StartAttackMove(P_MGA_L2_P1, MGA_CM2)
    StartAttackMove(P_MGA_L2_P2, MGA_CM6)

    StartAttackMove(P_MGA_L3_P1, MGA_CM2)
    StartAttackMove(P_MGA_L3_P2, MGA_CM4)
    StartAttackMove(P_MGA_L3_P3, MGA_CM4)
    StartAttackMove(P_MGA_L3_P4, MGA_CM6)

    StartAttackMove(P_MGA_L4_P1, MGA_CM2)
    StartAttackMove(P_MGA_L4_P2, MGA_CM4)
    StartAttackMove(P_MGA_L4_P3, MGA_CM6)

    StartAttackMove(P_MGA_L5_P1, MGA_CM2)
    StartAttackMove(P_MGA_L5_P2, MGA_CM6)

    StartAttackMove(U_MGA_L1_P1, MGA_CM1)
    StartAttackMove(U_MGA_L1_P2, MGA_CM1)
    StartAttackMove(U_MGA_L1_P3, MGA_CM3)
    StartAttackMove(U_MGA_L1_P4, MGA_CM3)
    StartAttackMove(U_MGA_L1_P5, MGA_CM5)

    StartAttackMove(U_MGA_L2_P1, MGA_CM1)
    StartAttackMove(U_MGA_L2_P2, MGA_CM3)
    StartAttackMove(U_MGA_L2_P3, MGA_CM3)
    StartAttackMove(U_MGA_L2_P4, MGA_CM5)

    StartAttackMove(U_MGA_L3_P1, MGA_CM1)
    StartAttackMove(U_MGA_L3_P2, MGA_CM3)
    StartAttackMove(U_MGA_L3_P3, MGA_CM5)

    StartAttackMove(U_MGA_L4_P1, MGA_CM1)
    StartAttackMove(U_MGA_L4_P2, MGA_CM5)

    StartAttackMove(U_MGA_L5_P1, MGA_CM1)
    StartAttackMove(U_MGA_L5_P2, MGA_CM3)
    StartAttackMove(U_MGA_L5_P3, MGA_CM3)
    StartAttackMove(U_MGA_L5_P4, MGA_CM5)

    SetArmyGroupState(P_MGA_L7_P1, 'Aggressive')
    SetArmyGroupState(U_MGA_L6_P1, 'Aggressive')

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_8'), 10)
    WaitSeconds(20.0)

    SetArmyGroupState(P_MGA_L6_P1, 'Aggressive')
    SetArmyGroupState(P_MGA_L6_P2, 'Aggressive')
    SetArmyGroupState(P_MGA_L6_P3, 'Aggressive')

    Warp(A_Base_Colossus[1], ScenarioUtils.MarkerToPosition('ColossusLanding'))
    SetArmyGroupState(A_Base_Colossus, 'Aggressive')
    SetArmyGroupState(P_MGA_Bombers, 'Aggressive')
    WaitSeconds(1.0)

    IssueClearCommands(A_Base_Colossus)
    IssueAggressiveMove(A_Base_Colossus, ScenarioUtils.MarkerToPosition('ColossusMoveTo'))
    WaitSeconds(3.0)

    IssueClearCommands(A_Base_Colossus)
    ScenarioUtils.AssignOrders('PMBBBP_Patrol', P_MGA_Bombers)
    IssuePatrol(P_MGA_Bombers, A_Base_Colossus[1]:GetPosition())
    IssuePatrol(U_MGA_Fighters1, A_Base_Colossus[1]:GetPosition())
    IssuePatrol(U_MGA_Fighters2, A_Base_Colossus[1]:GetPosition())
    WaitSeconds(15.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_9'), 0)

    PerfTest3_Nukes()
    WaitSeconds(8.0)

    Cinematics.CameraMoveToMarker(ScenarioUtils.GetMarker('Perf_Cam_10'), 0)
    WaitSeconds(20.0)
end

function SpawnMainBattle()
    -- Main Assault Group - Player
    P_MGA_L1_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FrontLine', 'PLTN_1')
    P_MGA_L1_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FrontLine', 'PLTN_2')
    P_MGA_L1_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FrontLine', 'PLTN_3')
    P_MGA_L1_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FrontLine', 'PLTN_4')
    P_MGA_L2_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'SecondLine', 'PLTN_1')
    P_MGA_L2_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'SecondLine', 'PLTN_2')
    P_MGA_L3_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'ThirdLine', 'PLTN_1')
    P_MGA_L3_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'ThirdLine', 'PLTN_2')
    P_MGA_L3_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'ThirdLine', 'PLTN_3')
    P_MGA_L3_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'ThirdLine', 'PLTN_4')
    P_MGA_L4_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FourthLine', 'PLTN_1')
    P_MGA_L4_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FourthLine', 'PLTN_2')
    P_MGA_L4_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'FourthLine', 'PLTN_3')
    P_MGA_L5_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'LastLine', 'PLTN_1')
    P_MGA_L5_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'LastLine', 'PLTN_2')
    P_MGA_L6_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'SpiderBots', 'PLTN_1')
    P_MGA_L6_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'SpiderBots', 'PLTN_2')
    P_MGA_L6_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'SpiderBots', 'PLTN_3')
    P_MGA_LB1 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'Small_Base_1')
    P_MGA_LB2 = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'Small_Base_2')
    P_MGA_Bombers = SpawnAndSetArmySubGroupState('HoldFire', 'Player', 'Major_Ground_Assault', 'Bombers', 'PLTN_1')

    -- Main Assault Group
    U_MGA_L1_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FirstLine_MT', 'PLTN_1')
    U_MGA_L1_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FirstLine_MT', 'PLTN_2')
    U_MGA_L1_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FirstLine_MT', 'PLTN_3')
    U_MGA_L1_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FirstLine_MT', 'PLTN_4')
    U_MGA_L1_P5 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FirstLine_MT', 'PLTN_5')
    U_MGA_L2_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'SecondLine_HT', 'PLTN_1')
    U_MGA_L2_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'SecondLine_HT', 'PLTN_2')
    U_MGA_L2_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'SecondLine_HT', 'PLTN_3')
    U_MGA_L2_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'SecondLine_HT', 'PLTN_4')
    U_MGA_L3_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'ThirdLine_MFA', 'PLTN_1')
    U_MGA_L3_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'ThirdLine_MFA', 'PLTN_2')
    U_MGA_L3_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'ThirdLine_MFA', 'PLTN_3')
    U_MGA_L4_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FourthLine_LAB', 'PLTN_1')
    U_MGA_L4_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FourthLine_LAB', 'PLTN_2')
    U_MGA_L5_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FifthLine_SAB', 'PLTN_1')
    U_MGA_L5_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FifthLine_SAB', 'PLTN_2')
    U_MGA_L5_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FifthLine_SAB', 'PLTN_3')
    U_MGA_L5_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'FifthLine_SAB', 'PLTN_4')
    U_MGA_L6_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'WaterAssault_MAW', 'PLTN_1')
    U_MGA_L7_P1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'TransportGroup', 'PLTN_1')
    U_MGA_L7_P2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'TransportGroup', 'PLTN_2')
    U_MGA_L7_P3 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'TransportGroup', 'PLTN_3')
    U_MGA_L7_P4 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'TransportGroup', 'PLTN_4')
    U_MGA_LB1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'Small_Base_1')
    U_MGA_LB2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'Small_Base_2')
    U_MGA_Fighters1 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'AirFighters', 'PLTN_1')
    U_MGA_Fighters2 = SpawnAndSetArmySubGroupState('HoldFire', 'UEF', 'UEF_Main_Assault', 'AirFighters', 'PLTN_2')

    IssueTransportLoad(U_MGA_L7_P2, U_MGA_L7_P1[1])
    IssueTransportLoad(U_MGA_L7_P4, U_MGA_L7_P3[1])
    WaitSeconds(2.0)

    Major_Ground_Assault_Start()
end

function SpawnCybranBase()
    -- Cybran Neutral
    -- Cybran Base
    C_Base = ScenarioUtils.CreateArmyGroup('Cybran_2', 'Neutral_Base')

    -- Patrolling Cybran Spyplane
    C_Spy_1 = SpawnAndOrder('C_Spy_Patrol', 'Cybran_2', 'CN_Spyplane', 'PLTN_1')

    -- Air Staging Platforms and planes
    C_Flight_Group_1 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Base_Planes', 'PLTN_1')
    C_Flight_Group_2 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Base_Planes', 'PLTN_2')
    C_Flight_Group_3 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Base_Planes', 'PLTN_3')
    C_Flight_Group_4 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Base_Planes', 'PLTN_4')
    C_Platform_1 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Air_Platforms', 'PLTN_1')
    C_Platform_2 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Air_Platforms', 'PLTN_2')
    C_Platform_3 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Air_Platforms', 'PLTN_3')
    C_Platform_4 = ScenarioUtils.CreateArmySubGroup('Cybran_2', 'Air_Platforms', 'PLTN_4')

    WaitSeconds(2.0)
end

function SetArmyGroupState(ArmyGroup, FireState)
    if ArmyGroup then
        for k, v in ArmyGroup do
            if not v.Dead then
                v:SetFireState(FireState)
            end
        end
    else
        error('*ERROR* Attempting to Set Fire State for non-existent group: ' .. arg[arg['n']], 2)
    end
end

function SpawnAndSetArmySubGroupState(FireState, ...)
    local units
    units = ScenarioUtils.CreateArmySubGroup(unpack(arg))

    if units then
        for k, v in units do
            if not v.Dead then
                v:SetFireState(FireState)
            end
        end
    else
        error('*ERROR* Attempting to spawn non-existent group: ' .. arg[arg['n']], 2)
    end

    return units
end

function SpawnAndOrder(orderQueue, ...)
    local units
    units = ScenarioUtils.CreateArmySubGroup(unpack(arg))

    if units then
        ScenarioUtils.AssignOrders(orderQueue, units)
    else
        error('*ERROR* Attempting to order non-existent group: ' .. arg[arg['n']], 2)
    end

    return units
end

function BuildNukes(unit, NumToBuild)
    if unit then
        unit:GiveNukeSiloAmmo(NumToBuild)
    else
        error('*ERROR*Attempting to build nukes in a non-existent unit: '.. arg[arg['n']], 2)
    end
end

function SetStateAndMove(ArmyGroup, NewFireState, xOff, zOff)
    if ArmyGroup then
        for k, v in ArmyGroup do
            if not v.Dead then
                v:SetFireState(NewFireState)
                local x, y, z = unpack(v:GetPosition())
                IssueAggressiveMove({v}, {x + xOff, y, z + zOff})
            end
        end
    else
        error('*ERROR* Attempting to Set Fire State for non-existent group: ' .. arg[arg['n']], 2)
    end
end

function StartAttackMove(units, MoveTo)
    if units then
        for k, v in units do
            if not v.Dead then
                v:SetFireState('Aggressive')
            end
         end
    else
        error('*ERROR* Attempting to Set Fire State for non-existent group: ' .. arg[arg['n']], 2)
    end

    IssueAggressiveMove(units, MoveTo)

end

function StartPassiveMove(units, MoveTo)
    if units then
        for k, v in units do
            if not v.Dead then
                v:SetFireState('HoldFire')
            end
        end
    else
        error('*ERROR* Attempting to Set Fire State for non-existent group: ' .. arg[arg['n']], 2)
    end

    IssueMove(units, MoveTo)
end
