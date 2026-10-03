@echo off
setlocal

rem Paste either a FAF replay ID or URL, for example:
rem 27860635
rem https://replay.faforever.com/27860635
rem This never writes the normal game.prefs.

rem Use FAF's replay runtime. Its fa_path.lua selects the replay's FAF build
rem without altering the normal client runtime or game.prefs.
set "FAF_BIN=C:\ProgramData\FAForever\replaydata\bin"
set "SOURCE_PREFS=%LOCALAPPDATA%\Gas Powered Games\Supreme Commander Forged Alliance\game.prefs"
set "PREFS_DIR=%LOCALAPPDATA%\Gas Powered Games\Supreme Commander Forged Alliance"
set "PREFS_NAME=custom-replay-mods.prefs"
set "PREFS=%PREFS_DIR%\%PREFS_NAME%"
set "REPLAY=%~dp0custom-replay.scfareplay"
set "RESOLVER_FILE=%~dp0custom-replay-source.txt"
set "INIT_FILE_RECORD=%~dp0custom-replay-init.txt"
set "REPLAY_INPUT="

if not exist "%FAF_BIN%\ForgedAlliance.exe" (
    echo FAF executable not found: "%FAF_BIN%"
    pause
    exit /b 1
)

if not exist "%SOURCE_PREFS%" (
    echo Source preferences not found: "%SOURCE_PREFS%"
    pause
    exit /b 1
)

set /p "REPLAY_INPUT=Paste FAF replay ID or URL: "
if not defined REPLAY_INPUT (
    echo No replay ID or URL was entered.
    pause
    exit /b 1
)

rem Prefer a replay already cached by FAF. If it is not cached, download it.
set "SOURCE_REPLAY="
if exist "%RESOLVER_FILE%" del "%RESOLVER_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$match = [regex]::Match($env:REPLAY_INPUT, '\d{6,}'); if (-not $match.Success) { throw 'No valid FAF replay ID was found.' }; $id = $match.Value; $folders = @('C:\ProgramData\FAForever\replays', $env:LOCALAPPDATA + '\FAForever\FAForever Client\cache'); $files = @(); foreach ($folder in $folders) { if (Test-Path -LiteralPath $folder) { $candidate = Get-ChildItem -LiteralPath $folder -Filter ($id + '*.fafreplay') -File -ErrorAction SilentlyContinue | Select-Object -First 1; if ($candidate) { $files += $candidate } } }; $file = $files[0]; if ($file) { $filePath = $file.FullName } else { $filePath = Join-Path $env:TEMP ($id + '.fafreplay'); Invoke-WebRequest -UseBasicParsing -Uri ('https://replay.faforever.com/' + $id) -OutFile $filePath -ErrorAction Stop }; if ((Get-Item -LiteralPath $filePath).Length -eq 0) { throw 'The replay download was empty.' }; [IO.File]::WriteAllText($env:RESOLVER_FILE, [IO.Path]::GetFullPath($filePath), [Text.Encoding]::ASCII)"
if errorlevel 1 (
    echo Replay was not found locally and could not be downloaded.
    pause
    exit /b 1
)
set /p "SOURCE_REPLAY=" < "%RESOLVER_FILE%"
if not defined SOURCE_REPLAY (
    echo Replay was not found locally and could not be downloaded.
    pause
    exit /b 1
)

rem Match the replay's featured mod instead of always launching FAF Beta.
if exist "%INIT_FILE_RECORD%" del "%INIT_FILE_RECORD%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$bytes = [IO.File]::ReadAllBytes($env:SOURCE_REPLAY); $headerLength = [Array]::IndexOf($bytes, [byte]10); if ($headerLength -lt 1) { throw 'Replay JSON header was not found.' }; $featuredMod = (ConvertFrom-Json ([Text.Encoding]::UTF8.GetString($bytes, 0, $headerLength))).featured_mod; if ($featuredMod -eq 'faf') { $init = 'init_faf.lua' } elseif ($featuredMod -eq 'fafbeta') { $init = 'init_fafbeta.lua' } else { throw ('Unsupported replay featured mod: ' + $featuredMod) }; [IO.File]::WriteAllText($env:INIT_FILE_RECORD, $init, [Text.Encoding]::ASCII)"
if errorlevel 1 (
    echo Failed to determine the replay's FAF game type.
    pause
    exit /b 1
)
set /p "REPLAY_INIT=" < "%INIT_FILE_RECORD%"

rem Build isolated preferences with exactly the requested active mods.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$source = [IO.File]::ReadAllText($env:SOURCE_PREFS); $match = [regex]::Match($source, '(?ms)^active_mods\s*=\s*\{.*?^\}'); if (-not $match.Success) { throw 'active_mods block was not found in game.prefs.' }; $enabled = @('reui-reclaim-1.2.1','reui-Minimap-1.1.0','EconomyMiddle-1.1.0','RIGOMATE-a1e2-c4t4-scfa-ssbmod-v0240','ReUI.Construction-1.3.0','toggle-split-screen-1.0.0','eco-ui-tools-4z0t-v11','reui-1.3.1','dynamic-selection-info-v03','redux-icons-2K-02','reui-economy-1.2.0','10435673f-91bc-4a2b-932b-9d71b83bbe8ddd','ui-mod-tools-4z0t-v13','zcbf6277-24e3-437a-b968-Common-v1'); $block = 'active_mods = {' + [Environment]::NewLine + (($enabled | ForEach-Object { '    [''' + $_ + '''] = true,' }) -join [Environment]::NewLine) + [Environment]::NewLine + '}'; [IO.File]::WriteAllText($env:PREFS, $source.Substring(0, $match.Index) + $block + $source.Substring($match.Index + $match.Length))"
if errorlevel 1 (
    echo Failed to create isolated replay preferences.
    pause
    exit /b 1
)

rem Convert either legacy Base64/deflate or current Zstandard FAF replay data.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Convert-FAFReplay.ps1" -SourceReplay "%SOURCE_REPLAY%" -OutputReplay "%REPLAY%"
if errorlevel 1 (
    echo Failed to convert the FAF replay.
    pause
    exit /b 1
)

rem FAF normally generates Neroxis maps before launching a replay. Reproduce
rem that client step when the replay references a generated map not yet present.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$header = (([IO.File]::ReadAllText($env:SOURCE_REPLAY)) -split [char]10, 2)[0]; $mapName = (ConvertFrom-Json $header).mapname; $mapsPath = $env:USERPROFILE + '\Documents\My Games\Gas Powered Games\Supreme Commander Forged Alliance\maps'; $mapPath = Join-Path $mapsPath $mapName; if ($mapName -like 'neroxis_map_generator_*' -and -not (Test-Path -LiteralPath $mapPath)) { $version = [regex]::Match($mapName, '^neroxis_map_generator_(\d+\.\d+\.\d+)_').Groups[1].Value; $java = 'C:\Program Files\FAF Python Client\natives\jre\bin\java.exe'; $generator = 'C:\ProgramData\FAForever\map_generator\MapGenerator_' + $version + '.jar'; if (-not (Test-Path -LiteralPath $java) -or -not (Test-Path -LiteralPath $generator)) { throw 'The required Neroxis map generator is not installed.' }; & $java -jar $generator --map-name $mapName --out-path $mapsPath; if (-not (Test-Path -LiteralPath $mapPath)) { throw 'Neroxis map generation did not create the expected map folder.' } }"
if errorlevel 1 (
    echo Failed to prepare the replay map.
    pause
    exit /b 1
)

pushd "%FAF_BIN%"
"%FAF_BIN%\ForgedAlliance.exe" /init "%REPLAY_INIT%" /prefs "%PREFS_NAME%" /replay "%REPLAY%" /log "%~dp0custom-replay.log"
popd
endlocal
