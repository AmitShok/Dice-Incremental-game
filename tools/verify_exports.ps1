param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path $PSScriptRoot -Parent
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
function Invoke-GodotCheck([string]$Name, [string[]]$Arguments) {
    $stdout = Join-Path $OutputDirectory "$Name.log"
    $stderr = Join-Path $OutputDirectory "$Name-errors.log"
    $process = Start-Process -FilePath $Godot -ArgumentList $Arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(60000)) {
        Stop-Process -Id $process.Id
        throw "$Name timed out. See $stdout and $stderr"
    }
    if ($process.ExitCode -ne 0 -or (Select-String -Path $stderr -Pattern 'SCRIPT ERROR:|^ERROR:' -Quiet)) {
        throw "$Name failed. See $stdout and $stderr"
    }
    Write-Output "$Name passed"
}
Invoke-GodotCheck 'source-checks' @('--headless','--audio-driver','Dummy','--path',('"'+$projectDirectory+'"'),'--script','res://tests/test_runner.gd','--','--test')
foreach ($target in @(@('Windows Desktop','windows','D-infinity.exe','D-infinity.pck'), @('Web','web','index.html','index.pck'))) {
    $folder = Join-Path $OutputDirectory $target[1]
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $binary = Join-Path $folder $target[2]
    $pack = Join-Path $folder $target[3]
    Invoke-GodotCheck ($target[1]+'-export') @('--headless','--audio-driver','Dummy','--path',('"'+$projectDirectory+'"'),'--export-release',('"'+$target[0]+'"'),('"'+$binary+'"'))
    # Use the packaged resources, not the source project. Release templates do not support --script.
    Invoke-GodotCheck ($target[1]+'-checks') @('--headless','--audio-driver','Dummy','--main-pack',('"'+$pack+'"'),'--script','res://tests/test_runner.gd','--','--test')
    $previousOutput = $env:DICE_TEST_OUTPUT
    try {
        $env:DICE_TEST_OUTPUT = $folder
        Invoke-GodotCheck ($target[1]+'-visual') @('--audio-driver','Dummy','--main-pack',('"'+$pack+'"'),'--script','res://tests/visual_runner.gd','--','--test')
        Invoke-GodotCheck ($target[1]+'-resize') @('--audio-driver','Dummy','--main-pack',('"'+$pack+'"'),'--script','res://tests/resize_runner.gd','--','--test')
        Invoke-GodotCheck ($target[1]+'-touch') @('--audio-driver','Dummy','--main-pack',('"'+$pack+'"'),'--script','res://tests/touch_runner.gd','--','--test')
        Invoke-GodotCheck ($target[1]+'-touch-phone') @('--audio-driver','Dummy','--main-pack',('"'+$pack+'"'),'--script','res://tests/touch_runner.gd','--','--test','--phone')
    } finally { $env:DICE_TEST_OUTPUT = $previousOutput }
}
