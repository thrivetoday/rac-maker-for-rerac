# RAC Maker installer: puts the RAC Maker build of ReRAC next to your other ReRAC versions, prepares the object
# pictures once, and adds "RAC Maker" to the desktop and the Start menu. Your game data and saves are not touched.
$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $MyInvocation.MyCommand.Path
$build = Get-ChildItem -Path $kit -Directory -Filter 'rerac-*-rac-maker-*' | Select-Object -First 1

function Fail($text) {
  Write-Host ''
  Write-Host $text -ForegroundColor Yellow
  Write-Host ''
  Read-Host 'Press Enter to close'
  exit 1
}

if (-not $build) { Fail 'The RAC Maker files are missing next to install.bat. Unzip the whole download first, then run install.bat again.' }

# The ReRAC data folder, as the launcher finds it: RERAC_DATA_ROOT, else the folder it was moved to, else the default.
$default = Join-Path $env:LOCALAPPDATA 'rerac'
$root = $env:RERAC_DATA_ROOT
if (-not $root) {
  $loc = Join-Path $default 'location.json'
  if (Test-Path $loc) { try { $root = (Get-Content $loc -Raw | ConvertFrom-Json).data_root } catch { } }
}
if (-not $root) { $root = $default }
$data = Join-Path $root 'games\rac1\data'
if (-not (Test-Path (Join-Path $data 'extract-info.json'))) {
  Fail ("Ratchet & Clank is not set up in ReRAC yet.`n`nInstall ReRAC with the ReRAC Launcher (https://github.com/re-rac/rerac-launcher) and let it set up the game from your own disc image, then run install.bat again.`n`n(Looked in $data)")
}
if (Get-Process rerac -ErrorAction SilentlyContinue) { Fail 'ReRAC is running. Close the game first, then run install.bat again.' }

Write-Host 'Installing RAC Maker...'
$dest = Join-Path $root ('versions\development\' + $build.Name)
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
Copy-Item $build.FullName $dest -Recurse
$exe = Join-Path $dest 'rerac.exe'

# The maps folder, the editor's own rule: Documents\RAC Maker (an older C:\Users\<you>\Documents\RAC Maker wins when
# only that one exists).
$known = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'RAC Maker'
$legacy = Join-Path $env:USERPROFILE 'Documents\RAC Maker'
$maps = if (-not (Test-Path $known) -and (Test-Path $legacy)) { $legacy } else { $known }
New-Item -ItemType Directory -Force $maps | Out-Null

# The object pictures (once; the editor would otherwise make them on its first start, with no window for half a minute).
if (-not (Test-Path (Join-Path $data 'catalog\catalog.json'))) {
  Write-Host 'Preparing the object pictures from your game (about 30 seconds)...'
  $p = Start-Process -FilePath $exe -ArgumentList @('--data-dir', "`"$data`"", '--build-catalog') -WorkingDirectory $dest -Wait -PassThru -WindowStyle Hidden
  if ($p.ExitCode -ne 0) { Write-Host 'The object pictures could not be prepared now; RAC Maker will try again when it starts.' -ForegroundColor Yellow }
}

# The shortcut opens the editor on your newest map (a new "My first map" the first time); its main menu has all of them.
$newest = Get-ChildItem $maps -Filter *.json -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$map = if ($newest) { $newest.FullName } else { Join-Path $maps 'My first map.json' }
$shell = New-Object -ComObject WScript.Shell
$places = @([Environment]::GetFolderPath('Desktop'), (Join-Path ([Environment]::GetFolderPath('Programs')) ''))
foreach ($dir in $places) {
  $lnk = $shell.CreateShortcut((Join-Path $dir 'RAC Maker.lnk'))
  $lnk.TargetPath = $exe
  $lnk.Arguments = "--data-dir `"$data`" --edit `"$map`""
  $lnk.WorkingDirectory = $dest
  $lnk.IconLocation = "$exe,0"
  $lnk.Description = 'RAC Maker: make your own Ratchet & Clank levels (ReRAC)'
  $lnk.Save()
}

# The preview launcher with the RAC Maker tile (optional): next to the build, in the Start menu.
$launcher = Get-ChildItem -Path $kit -File -Filter '*Launcher*.exe' | Select-Object -First 1
if ($launcher) {
  $ldest = Join-Path $env:LOCALAPPDATA 'Programs\RAC Maker'
  New-Item -ItemType Directory -Force $ldest | Out-Null
  Copy-Item $launcher.FullName (Join-Path $ldest 'ReRAC Launcher with RAC Maker.exe') -Force
  $lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Programs')) 'ReRAC Launcher with RAC Maker.lnk'))
  $lnk.TargetPath = Join-Path $ldest 'ReRAC Launcher with RAC Maker.exe'
  $lnk.WorkingDirectory = $ldest
  $lnk.Save()
}

Write-Host ''
Write-Host 'RAC Maker is installed.' -ForegroundColor Green
Write-Host '  Start it with "RAC Maker" on your desktop (or in the Start menu).'
Write-Host "  Your maps are saved in $maps"
Write-Host '  Press F1 in the editor for help. To remove it, run uninstall.bat (your maps stay).'
Write-Host ''
Read-Host 'Press Enter to close'
