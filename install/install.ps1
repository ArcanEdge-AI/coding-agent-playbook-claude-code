param(
  [switch]$Full,
  [switch]$SupportOnly,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if ($Full -and $SupportOnly) {
  throw "Choose either -Full or -SupportOnly, not both. Full mode is the default for installs and updates."
}

$Mode = "full"
if ($SupportOnly) { $Mode = "support-only" }
if ($Full) { $Mode = "full" }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
$ClaudeHome = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"
$ManifestPath = Join-Path $ClaudeHome ".coding-agent-playbook-claude-code-managed-files.tsv"
$LegacyManifestPath = Join-Path $ClaudeHome ".claude-code-agent-playbook-managed-files.tsv"
$BackupRoot = Join-Path (Join-Path $ClaudeHome ".coding-agent-playbook-backups") $Timestamp

$script:ValidationFailures = 0

function Write-Step($Message) {
  Write-Host $Message
}

function Write-Failure($Message) {
  $script:ValidationFailures++
  Write-Warning $Message
}

function Invoke-InstallCommand {
  param([scriptblock]$Command, [string]$Display)
  if ($DryRun) {
    Write-Host "[dry-run] $Display"
  } else {
    & $Command
  }
}

function Get-FileSha256 {
  param([string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

# Backups are written under $ClaudeHome\.coding-agent-playbook-backups\<timestamp>\
# rather than beside the original, so the managed references, agents, and skills
# trees stay free of stale `*.bak.<timestamp>` files after every update.
function Backup-File {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return
  }

  $FullPath = [System.IO.Path]::GetFullPath($Path)
  $HomeFull = [System.IO.Path]::GetFullPath($ClaudeHome).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  if ($FullPath.StartsWith($HomeFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $Relative = $FullPath.Substring($HomeFull.Length)
  } else {
    $Relative = Split-Path -Leaf $FullPath
  }

  $Backup = Join-Path $BackupRoot $Relative
  $BackupParent = Split-Path -Parent $Backup
  Write-Step "Backing up $Path -> $Backup"
  Invoke-InstallCommand { New-Item -ItemType Directory -Force -Path $BackupParent | Out-Null } "New-Item -ItemType Directory -Force '$BackupParent'"
  Invoke-InstallCommand { Copy-Item -LiteralPath $Path -Destination $Backup -Force } "Copy-Item '$Path' '$Backup'"
}

function Copy-PlaybookFile {
  param([string]$Source, [string]$Destination)
  $Parent = Split-Path -Parent $Destination
  Invoke-InstallCommand { New-Item -ItemType Directory -Force -Path $Parent | Out-Null } "New-Item -ItemType Directory -Force '$Parent'"
  if (Test-Path -LiteralPath $Destination -PathType Leaf) {
    if ((Get-FileSha256 $Source) -eq (Get-FileSha256 $Destination)) {
      Write-Step "Unchanged $Destination"
      return
    }
  }

  Backup-File $Destination
  Write-Step "Installing $Destination"
  Invoke-InstallCommand { Copy-Item -LiteralPath $Source -Destination $Destination -Force } "Copy-Item '$Source' '$Destination'"
}

function Copy-PlaybookTree {
  param([string]$SourceDir, [string]$DestinationDir)
  if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    Write-Step "Skipping missing source directory: $SourceDir"
    return
  }

  Get-ChildItem -LiteralPath $SourceDir -Recurse -File | ForEach-Object {
    $RelativePath = $_.FullName.Substring((Resolve-Path $SourceDir).Path.Length).TrimStart('\','/')
    $Dest = Join-Path $DestinationDir $RelativePath
    Copy-PlaybookFile $_.FullName $Dest
  }
}

function Assert-SafeManifestRelativePath {
  param([string]$RelativePath)

  if ([string]::IsNullOrWhiteSpace($RelativePath) -or
      [System.IO.Path]::IsPathRooted($RelativePath) -or
      $RelativePath.Contains("`t") -or
      $RelativePath.Contains("`r") -or
      $RelativePath.Contains("`n")) {
    throw "Unsafe managed-file manifest path: '$RelativePath'"
  }

  $Segments = $RelativePath -split '[/\\]'
  if ($Segments | Where-Object { $_ -in @('', '.', '..') }) {
    throw "Unsafe managed-file manifest path: '$RelativePath'"
  }
}

function Get-ManagedDestination {
  param([System.Collections.IDictionary]$ManagedRoots, [string]$RootName, [string]$RelativePath)

  if (-not $ManagedRoots.Contains($RootName)) {
    throw "Unknown managed-file root '$RootName'."
  }

  Assert-SafeManifestRelativePath $RelativePath
  $DestinationRoot = [System.IO.Path]::GetFullPath($ManagedRoots[$RootName].Destination)
  $NativeRelativePath = $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
  $Destination = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot $NativeRelativePath))
  $RootPrefix = $DestinationRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar

  if (-not $Destination.StartsWith($RootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Managed-file destination escapes '$DestinationRoot': '$RelativePath'"
  }

  return $Destination
}

function Get-CurrentManifestEntries {
  param([System.Collections.IDictionary]$ManagedRoots)

  $Entries = @()
  foreach ($RootName in $ManagedRoots.Keys) {
    # Support-only mode leaves the user's own instructions alone, so the rules
    # tree is neither installed nor recorded as managed.
    if ($RootName -eq "rules" -and $Mode -eq "support-only") { continue }
    $SourceRoot = (Resolve-Path -LiteralPath $ManagedRoots[$RootName].Source).Path
    foreach ($File in Get-ChildItem -LiteralPath $SourceRoot -Recurse -File) {
      $RelativePath = $File.FullName.Substring($SourceRoot.Length).TrimStart('\', '/') -replace '\\', '/'
      Assert-SafeManifestRelativePath $RelativePath
      $Entries += [pscustomobject]@{
        Root = $RootName
        Path = $RelativePath
        Hash = Get-FileSha256 $File.FullName
      }
    }
  }

  # Order does not matter here; Write-InstallManifest sorts the emitted lines.
  return @($Entries)
}

function Read-InstallManifest {
  param([string]$Path, [System.Collections.IDictionary]$ManagedRoots)

  $Entries = @{}
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Write-Step "No previous managed-file manifest found; existing unlisted files will be preserved."
    return $Entries
  }

  $LineNumber = 0
  foreach ($Line in Get-Content -LiteralPath $Path) {
    $LineNumber++
    if ([string]::IsNullOrWhiteSpace($Line) -or $Line.StartsWith('#')) {
      continue
    }

    $Parts = $Line -split "`t"
    if ($Parts.Count -ne 3) {
      throw "Malformed managed-file manifest at ${Path}:$LineNumber"
    }

    $RootName, $RelativePath, $Hash = $Parts
    if (-not $ManagedRoots.Contains($RootName)) {
      throw "Unknown managed-file root '$RootName' at ${Path}:$LineNumber"
    }
    Assert-SafeManifestRelativePath $RelativePath
    if ($Hash -notmatch '^[a-fA-F0-9]{64}$') {
      throw "Invalid SHA-256 at ${Path}:$LineNumber"
    }

    $Key = "$RootName/$RelativePath"
    if ($Entries.ContainsKey($Key)) {
      throw "Duplicate managed-file manifest entry '$Key' at ${Path}:$LineNumber"
    }

    $Entries[$Key] = [pscustomobject]@{
      Root = $RootName
      Path = $RelativePath
      Hash = $Hash.ToLowerInvariant()
    }
  }

  return $Entries
}

function Assert-ManagedFilesMatch {
  param([array]$Entries, [System.Collections.IDictionary]$ManagedRoots)

  if ($DryRun) {
    Write-Step "[dry-run] Would verify $($Entries.Count) managed files against repository SHA-256 hashes."
    return
  }

  foreach ($Entry in $Entries) {
    $Destination = Get-ManagedDestination $ManagedRoots $Entry.Root $Entry.Path
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
      throw "Managed file was not installed: $Destination"
    }
    if ((Get-FileSha256 $Destination) -ne $Entry.Hash) {
      throw "Managed file does not match the repository source: $Destination"
    }
  }

  Write-Step "OK managed-file content: $($Entries.Count)/$($Entries.Count) exact SHA-256 matches"
}

function Retire-StaleManagedFiles {
  param([hashtable]$PreviousEntries, [array]$CurrentEntries, [System.Collections.IDictionary]$ManagedRoots)

  $CurrentKeys = @{}
  foreach ($Entry in $CurrentEntries) {
    $CurrentKeys["$($Entry.Root)/$($Entry.Path)"] = $true
  }

  foreach ($Key in @($PreviousEntries.Keys | Sort-Object)) {
    if ($CurrentKeys.ContainsKey($Key)) {
      continue
    }

    if ($PreviousEntries[$Key].Root -eq "rules" -and $Mode -eq "support-only") {
      Write-Step "Support-only mode: leaving instruction rules in place."
      continue
    }

    $Entry = $PreviousEntries[$Key]
    $Destination = Get-ManagedDestination $ManagedRoots $Entry.Root $Entry.Path
    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
      Write-Step "Formerly managed file already absent: $Destination"
      continue
    }

    if ((Get-FileSha256 $Destination) -ne $Entry.Hash) {
      Write-Warning "Preserving customized formerly managed file: $Destination"
      continue
    }

    Backup-File $Destination
    Write-Step "Retiring formerly managed file: $Destination"
    Invoke-InstallCommand { Remove-Item -LiteralPath $Destination -Force } "Remove-Item '$Destination'"
  }
}

function Write-InstallManifest {
  param([array]$Entries, [string]$Path)

  # Sort ordinally (byte order) to match install.sh's `LC_ALL=C sort`.
  # PowerShell's Sort-Object is case-insensitive and culture-aware, which would
  # place "model-routing.md" before "README.md" while the shell installer does
  # the reverse — leaving the two installers writing different manifests for
  # identical inputs, and each rewriting the other's file on every run.
  $Rows = [string[]]@($Entries | ForEach-Object { "$($_.Root)`t$($_.Path)`t$($_.Hash)" })
  if ($Rows.Count -gt 1) {
    [System.Array]::Sort($Rows, [System.StringComparer]::Ordinal)
  }
  $Lines = @('# coding-agent-playbook-claude-code managed files v1') + $Rows
  $Content = ($Lines -join "`n") + "`n"

  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    $Existing = (Get-Content -LiteralPath $Path -Raw) -replace "`r`n", "`n"
    if ($Existing -eq $Content) {
      Write-Step "Unchanged $Path"
      return
    }
  }

  $Parent = Split-Path -Parent $Path
  Invoke-InstallCommand { New-Item -ItemType Directory -Force -Path $Parent | Out-Null } "New-Item -ItemType Directory -Force '$Parent'"
  Backup-File $Path
  Write-Step "Writing managed-file manifest: $Path"
  if ($DryRun) {
    Write-Step "[dry-run] Would write $($Entries.Count) managed-file entries."
  } else {
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
  }
}

function Retire-LegacyManifest {
  param([string]$LegacyPath)

  if (-not (Test-Path -LiteralPath $LegacyPath -PathType Leaf)) {
    return
  }

  Backup-File $LegacyPath
  Write-Step "Retiring legacy managed-file manifest: $LegacyPath"
  Invoke-InstallCommand { Remove-Item -LiteralPath $LegacyPath -Force } "Remove-Item '$LegacyPath'"
}

$RulesDir = Join-Path $RepoRoot "rules"
$ReferencesDir = Join-Path $RepoRoot "references"
$AgentsDir = Join-Path $RepoRoot "agents"
$SkillsDir = Join-Path $RepoRoot "skills"
$CommandsDir = Join-Path $RepoRoot "commands"
$ManagedRoots = [ordered]@{
  agents = @{ Source = $AgentsDir; Destination = (Join-Path $ClaudeHome "agents") }
  commands = @{ Source = $CommandsDir; Destination = (Join-Path $ClaudeHome "commands") }
  references = @{ Source = $ReferencesDir; Destination = (Join-Path $ClaudeHome "references") }
  rules = @{ Source = $RulesDir; Destination = (Join-Path $ClaudeHome "rules") }
  skills = @{ Source = $SkillsDir; Destination = (Join-Path $ClaudeHome "skills") }
}

Write-Step "Coding Agent Playbook — Claude Code Edition installer"
Write-Step "Mode: $Mode"
Write-Step "Repository: $RepoRoot"
Write-Step "CLAUDE_HOME: $ClaudeHome"
Write-Step "Managed-file manifest: $ManifestPath"

if (-not (Test-Path -LiteralPath $RulesDir -PathType Container)) {
  throw "Missing instruction rules directory: $RulesDir"
}

$CurrentManifestEntries = Get-CurrentManifestEntries $ManagedRoots
$PreviousManifestPath = if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) { $ManifestPath } elseif (Test-Path -LiteralPath $LegacyManifestPath -PathType Leaf) { $LegacyManifestPath } else { $ManifestPath }
if ($PreviousManifestPath -eq $LegacyManifestPath) {
  Write-Step "Migrating legacy managed-file manifest: $LegacyManifestPath"
}
$PreviousManifestEntries = Read-InstallManifest $PreviousManifestPath $ManagedRoots

if ($Mode -eq "full") {
  Copy-PlaybookTree $RulesDir $ManagedRoots['rules'].Destination
} else {
  Write-Step "Support-only mode: skipping $($ManagedRoots['rules'].Destination) (instruction rules not installed)."
}

Copy-PlaybookTree $ReferencesDir $ManagedRoots['references'].Destination
Copy-PlaybookTree $AgentsDir $ManagedRoots['agents'].Destination
Copy-PlaybookTree $SkillsDir $ManagedRoots['skills'].Destination
Copy-PlaybookTree $CommandsDir $ManagedRoots['commands'].Destination
Assert-ManagedFilesMatch $CurrentManifestEntries $ManagedRoots
Retire-StaleManagedFiles $PreviousManifestEntries $CurrentManifestEntries $ManagedRoots
Write-InstallManifest $CurrentManifestEntries $ManifestPath
Retire-LegacyManifest $LegacyManifestPath

Write-Step ""
Write-Step "Validation:"
$CheckPaths = @(
  (Join-Path $ClaudeHome "commands\coordinate-work.md"),
  (Join-Path $ClaudeHome "references\model-routing.md"),
  (Join-Path $ClaudeHome "references\subagents.md"),
  (Join-Path $ClaudeHome "references\worktrees.md"),
  (Join-Path $ClaudeHome "references\multi-session-coordination.md"),
  (Join-Path $ClaudeHome "references\reference-doc-routing.md"),
  (Join-Path $ClaudeHome "references\templates\active-work-record.md"),
  (Join-Path $ClaudeHome "references\templates\task-graph.md"),
  (Join-Path $ClaudeHome "references\templates\worktree-manifest.md"),
  (Join-Path $ClaudeHome "agents\local-orchestrator.md"),
  (Join-Path $ClaudeHome "agents\read-only-explorer.md"),
  (Join-Path $ClaudeHome "agents\senior-reviewer.md"),
  (Join-Path $ClaudeHome "agents\docs-researcher.md"),
  (Join-Path $ClaudeHome "agents\test-triager.md"),
  (Join-Path $ClaudeHome "agents\isolated-worker.md"),
  (Join-Path $ClaudeHome "skills\subagent-orchestration\SKILL.md"),
  (Join-Path $ClaudeHome "skills\task-graph-orchestration\SKILL.md"),
  (Join-Path $ClaudeHome "skills\worktree-lifecycle\SKILL.md"),
  (Join-Path $ClaudeHome "skills\multi-session-coordination\SKILL.md"),
  (Join-Path $ClaudeHome "skills\reference-doc-routing\SKILL.md"),
  (Join-Path $ClaudeHome "skills\senior-code-review\SKILL.md")
)

foreach ($Path in $CheckPaths) {
  if ($DryRun -or (Test-Path -LiteralPath $Path)) {
    Write-Step "OK: $Path"
  } else {
    Write-Failure "Missing: $Path"
  }
}

Get-ChildItem -LiteralPath (Join-Path $ClaudeHome "skills") -Filter SKILL.md -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
  $Text = Get-Content -LiteralPath $_.FullName -Raw
  if ($Text -match "(?m)^name:" -and $Text -match "(?m)^description:") {
    Write-Step "OK frontmatter: $($_.FullName)"
  } else {
    Write-Failure "Check frontmatter: $($_.FullName)"
  }
}

# Roles that must stay read-only: plan permission mode, and no Edit or Write.
$ReadOnlyAgents = @("read-only-explorer", "docs-researcher", "senior-reviewer")

$ExpectedAgentNames = @(
  "local-orchestrator",
  "read-only-explorer",
  "senior-reviewer",
  "docs-researcher",
  "test-triager",
  "isolated-worker"
)

foreach ($AgentName in $ExpectedAgentNames) {
  $AgentPath = Join-Path $ClaudeHome "agents\$AgentName.md"
  if (-not (Test-Path -LiteralPath $AgentPath -PathType Leaf)) {
    continue
  }

  $Text = Get-Content -LiteralPath $AgentPath -Raw
  if ($Text -match "(?m)^name:" -and
      $Text -match "(?m)^description:" -and
      $Text -match "(?m)^model:" -and
      $Text -match "(?m)^effort:" -and
      $Text -match "(?m)^permissionMode:" -and
      $Text -match "(?m)^tools:") {
    Write-Step "OK Claude Code frontmatter: $AgentPath"
  } else {
    Write-Failure "Check Claude Code frontmatter: $AgentPath"
  }

  if ($Text -match "(?m)^name:\s*$([regex]::Escape($AgentName))\s*$" -and
      $Text -match "(?m)^model:\s*haiku\s*$") {
    Write-Step "OK Claude Code agent name and model: $AgentPath"
  } else {
    Write-Failure "Check Claude Code agent name or fail-closed Haiku model: $AgentPath"
  }

  $ToolsMatch = [regex]::Match($Text, "(?m)^tools:\s*(.+)$")
  $HasAgentTool = $ToolsMatch.Success -and ($ToolsMatch.Groups[1].Value -match "(?:^|,\s*)Agent(?:\s*,|$)")
  if ($AgentName -eq "local-orchestrator") {
    if ($HasAgentTool) {
      Write-Step "OK depth-1 Agent tool: $AgentPath"
    } else {
      Write-Failure "local-orchestrator.md must list Agent: $AgentPath"
    }
  } elseif ($HasAgentTool) {
    Write-Failure "Execution worker or leaf must not list Agent: $AgentPath"
  }

  if ($ReadOnlyAgents -contains $AgentName) {
    if ($Text -match "(?m)^permissionMode:\s*plan\s*$") {
      Write-Step "OK read-only permission mode: $AgentPath"
    } else {
      Write-Failure "Read-only role must use permissionMode: plan: $AgentPath"
    }

    if ($ToolsMatch.Success -and ($ToolsMatch.Groups[1].Value -match "(?:^|,\s*)(Edit|Write)(?:\s*,|\s*$)")) {
      Write-Failure "Read-only role must not list Edit or Write: $AgentPath"
    } else {
      Write-Step "OK read-only tool boundary: $AgentPath"
    }
  } elseif ($Text -match "(?m)^permissionMode:\s*(acceptEdits|auto|dontAsk|bypassPermissions)\s*$") {
    Write-Failure "Write-capable role must use permissionMode: default unless a maintainer approved otherwise: $AgentPath"
  }

  if ($Text -match "(?m)^isolation:\s*worktree\s*$") {
    Write-Failure "Bundled agents must not enable worktree isolation globally: $AgentPath"
  }
}

if ($Mode -eq "full") {
  foreach ($Rule in @(Get-ChildItem -LiteralPath $RulesDir -Filter *.md -File | Sort-Object Name)) {
    $InstalledRule = Join-Path (Join-Path $ClaudeHome "rules") $Rule.Name
    if (Test-Path -LiteralPath $InstalledRule -PathType Leaf) {
      Write-Step "OK rule: $InstalledRule"
    } else {
      Write-Failure "Missing installed rule: $InstalledRule"
    }
  }
}

Write-Step ""
if (Test-Path -LiteralPath $BackupRoot -PathType Container) {
  Write-Step "Backups for this run: $BackupRoot"
}

if ($script:ValidationFailures -gt 0) {
  Write-Step ""
  Write-Warning "Install finished with $($script:ValidationFailures) validation failure(s). Review the messages above."
  exit 1
}

Write-Step ""
Write-Step "Install complete. Restart Claude Code or start a new session if needed so new rules, skills, commands, and subagents are loaded."
