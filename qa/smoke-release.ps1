param([switch]$Checkpoint)

$ErrorActionPreference = 'Stop'
$source = Join-Path (Split-Path $PSScriptRoot) 'dist/Puteshestvie_v_KFU.exe'
$testRoot = Join-Path $env:TEMP ('kfu-release-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$standalone = Join-Path $testRoot 'standalone'
New-Item -ItemType Directory -Path $standalone | Out-Null
$executable = Join-Path $standalone 'Puteshestvie_v_KFU.exe'
Copy-Item -LiteralPath $source -Destination $executable

$previousAppData = $env:APPDATA
$previousCheckpoint = $env:KFU_QA_CHECKPOINT
$env:KFU_QA_CHECKPOINT = if ($Checkpoint) { "1" } else { "0" }
$env:APPDATA = Join-Path $testRoot 'userdata'
New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
Write-Host "Test folder: $testRoot"

try {
    $script = Join-Path $PSScriptRoot 'playthrough.gd'
    $log = Join-Path $testRoot 'playthrough.log'
    $arguments = '--headless --script "' + $script + '" --log-file "' + $log + '" --quit-after 300'
    $game = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $standalone -WindowStyle Hidden -PassThru -Wait
    Get-Content -LiteralPath $log
    $errors = Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR|ERROR:'
    if ($game.ExitCode -ne 0 -or $errors) { throw 'Release playthrough failed.' }
    if (@(Get-ChildItem -LiteralPath $standalone -Force).Count -ne 1) {
        throw 'Standalone folder contains files other than the EXE.'
    }
    if ($Checkpoint) {
        $save = Join-Path $env:APPDATA 'Godot/app_userdata/Puteshestvie v KFU/journey.cfg'
        if ((Get-Content -LiteralPath $save -Raw) -notmatch '(?m)^point=0\s*$') {
            throw 'The isolated build did not save the street checkpoint.'
        }
        Start-Process -FilePath $executable -WorkingDirectory $standalone -WindowStyle Normal
        Write-Host 'In the reopened game choose Continue. The student should be standing at the street flag.'
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:KFU_QA_CHECKPOINT = $previousCheckpoint
}
