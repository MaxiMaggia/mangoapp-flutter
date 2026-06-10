# run.ps1 - Lanza el emulador Pixel_7, espera a que bootee y corre la app.
# Uso:  .\run.ps1

$ErrorActionPreference = 'Stop'
$emulatorId = 'Pixel_7'

# Resolver la ruta de adb: primero el PATH, si no las ubicaciones tipicas del SDK.
function Resolve-Adb {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:ANDROID_HOME\platform-tools\adb.exe",
        "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    throw "No encontre adb.exe. Instala las platform-tools del Android SDK o agregalas al PATH."
}
$adb = Resolve-Adb
Write-Host "Usando adb: $adb" -ForegroundColor DarkGray

# 1. Si ya hay un emulador Android conectado, no lo lanzamos de nuevo.
$alreadyRunning = (& $adb devices) -match 'emulator-\d+\s+device'
if ($alreadyRunning) {
    Write-Host "Ya hay un emulador corriendo, lo reutilizo." -ForegroundColor Green
} else {
    Write-Host "Lanzando el emulador $emulatorId..." -ForegroundColor Cyan
    flutter emulators --launch $emulatorId
}

# 2. Esperar a que Android termine de bootear (sys.boot_completed = 1).
Write-Host "Esperando a que el emulador termine de arrancar..." -ForegroundColor Cyan
& $adb wait-for-device
do {
    Start-Sleep -Seconds 2
    $booted = (& $adb shell getprop sys.boot_completed 2>$null).Trim()
    Write-Host "  ...booteando (boot_completed=$booted)"
} until ($booted -eq '1')

Write-Host "Emulador listo. Arrancando la app..." -ForegroundColor Green

# 3. Correr la app en el primer device Android disponible.
flutter run -d android
