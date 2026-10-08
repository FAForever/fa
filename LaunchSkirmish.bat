@echo on
echo === PREF PATCH SCRIPT START ===

set PREFS=%USERPROFILE%\AppData\Local\Gas Powered Games\Supreme Commander Forged Alliance\game.prefs
set SKIRM=%USERPROFILE%\AppData\Local\Gas Powered Games\Supreme Commander Forged Alliance\skirmishgame.prefs

echo Using PREFS: %PREFS%
echo Using SKIRM: %SKIRM%

echo Copying game.prefs to skirmishgame.prefs...
copy "%PREFS%" "%SKIRM%" /Y

echo Patching skirmishgame.prefs...
powershell -Command "(Get-Content '%SKIRM%') -replace '^\s*\[''sort-saves-by-date-v01''\]\s*=\s*(?:true|false)\s*,?\s*$', '' -replace '^active_mods\s*=\s*\{$', ('active_mods = {' + [Environment]::NewLine + '    [''sort-saves-by-date-v01''] = true,') -replace 'GameSpeed\s*=\s*''normal''', 'GameSpeed = ''adjustable''' -replace 'CheatsEnabled\s*=\s*''false''', 'CheatsEnabled = ''true''' -replace 'FogOfWar\s*=\s*''explored''', 'FogOfWar = ''none''' -replace '^\s*MapName\s*=\s*''[^'']*''', 'MapName= ''TestMPA''' -replace '^\s*MapPath\s*=\s*''/maps/[^'']*''', 'MapPath = ''/maps/testmpa.v0001/TestMPA_scenario.lua''' -replace '^\s*CurrentMapDir\s*=\s*''/maps/[^'']*''', 'CurrentMapDir = ''/maps/testmpa.v0001''' -replace '^\s*ScenarioFile\s*=\s*''/maps/[^'']*''', 'ScenarioFile = ''/maps/testmpa.v0001/TestMPA_scenario.lua''' -replace '^\s*LobbyOpt_ScenarioFile\s*=\s*''/maps/[^'']*''', 'LobbyOpt_ScenarioFile = ''/maps/testmpa.v0001/TestMPA_scenario.lua''' -replace '^\s*LastScenario\s*=\s*''/maps/[^'']*''', 'LastScenario = ''/maps/testmpa.v0001/TestMPA_scenario.lua''' | Set-Content '%SKIRM%'"

echo Launching game...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\ProgramData\FAForever\bin\Launch-WithLiveCallbackLogging.ps1" -GameExecutable "C:\ProgramData\FAForever\bin\ForgedAlliance.exe" -GameArguments "/log skirmish.log /EnableDiskWatch /prefs skirmishgame.prefs" -WorkingDirectory "C:\ProgramData\FAForever\bin" -LogPath "C:\ProgramData\FAForever\bin\skirmish.log" -OutputFile "C:\ProgramData\FAForever\bin\processed_times_skirmish.csv"

echo === DONE ===


