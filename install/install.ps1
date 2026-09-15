param(
  [switch]$Full,
  [switch]$SupportOnly,
  [switch]$DryRun
)

# Thin launcher: finds a Python 3 interpreter and runs install/install.py with
# the equivalent arguments. The Python file is the only installer
# implementation; keep this launcher free of install logic.

$ErrorActionPreference = "Stop"

if ($Full -and $SupportOnly) {
  throw "Choose either -Full or -SupportOnly, not both. Full mode is the default for installs and updates."
}

$Installer = Join-Path $PSScriptRoot "install.py"
$InstallerArgs = @($Installer)
if ($Full) { $InstallerArgs += "--full" }
if ($SupportOnly) { $InstallerArgs += "--support-only" }
if ($DryRun) { $InstallerArgs += "--dry-run" }

$Launchers = @(
  @{ Command = "py"; Prefix = @("-3") },
  @{ Command = "python3"; Prefix = @() },
  @{ Command = "python"; Prefix = @() }
)

foreach ($Launcher in $Launchers) {
  $Command = Get-Command $Launcher.Command -ErrorAction SilentlyContinue
  if (-not $Command) { continue }

  $PrefixArgs = @($Launcher.Prefix)
  & $Command.Source @PrefixArgs @InstallerArgs
  exit $LASTEXITCODE
}

throw "Python 3.8 or newer is required. Install Python 3 or run install/install.py with an available Python 3 interpreter."
