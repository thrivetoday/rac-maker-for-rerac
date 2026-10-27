# Removes RAC Maker: its ReRAC build, the shortcuts and the preview launcher. Your maps (Documents\RAC Maker), your
# game data and your other ReRAC versions stay.
$ErrorActionPreference = 'Stop'
$default = Join-Path $env:LOCALAPPDATA 'rerac'
$root = $env:RERAC_DATA_ROOT
if (-not $root) {
  $loc = Join-Path $default 'location.json'
  if (Test-Path $loc) { try { $root = (Get-Content $loc -Raw | ConvertFrom-Json).data_root } catch { } }
}
if (-not $root) { $root = $default }
if (Get-Process rerac -ErrorAction SilentlyContinue) {
  Write-Host 'ReRAC is running. Close it first, then run uninstall.bat again.' -ForegroundColor Yellow
  Read-Host 'Press Enter to close'
  exit 1
}
Get-ChildItem (Join-Path $root 'versions\development') -Directory -Filter 'rerac-*-rac-maker-*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
$programs = [Environment]::GetFolderPath('Programs')
foreach ($f in @((Join-Path ([Environment]::GetFolderPath('Desktop')) 'RAC Maker.lnk'), (Join-Path $programs 'RAC Maker.lnk'), (Join-Path $programs 'ReRAC Launcher with RAC Maker.lnk'))) {
  if (Test-Path $f) { Remove-Item $f -Force }
}
$ldest = Join-Path $env:LOCALAPPDATA 'Programs\RAC Maker'
if (Test-Path $ldest) { Remove-Item $ldest -Recurse -Force }
Write-Host 'RAC Maker is removed. Your maps are still in Documents\RAC Maker.' -ForegroundColor Green
Read-Host 'Press Enter to close'
