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

function AddOrReplace-PlaybookSection {
  param([string]$Target, [string]$Title, [string]$Body)

  $StartMarker = "<!-- coding-agent-playbook-claude-code:start -->"
  $EndMarker = "<!-- coding-agent-playbook-claude-code:end -->"
  $LegacyStartMarker = "<!-- claude-code-agent-playbook:start -->"
  $LegacyEndMarker = "<!-- claude-code-agent-playbook:end -->"
  $Parent = Split-Path -Parent $Target
  $Existing = ""
  $Newline = "`n"
  # Trim trailing newlines so the section matches install.sh, whose $(cat ...)
  # strips them. Otherwise a blank line accumulates before the end marker.
  $NormalizedBody = (($Body -replace "`r`n", "`n") -replace "`r", "`n").TrimEnd("`n")

  if (Test-Path -LiteralPath $Target -PathType Leaf) {
    $Existing = Get-Content -LiteralPath $Target -Raw
    $Newline = if ($Existing.Contains("`r`n")) { "`r`n" } else { "`n" }
    $CurrentStartIndex = $Existing.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
    $CurrentEndIndex = $Existing.IndexOf($EndMarker, [System.StringComparison]::Ordinal)
    $LegacyStartIndex = $Existing.IndexOf($LegacyStartMarker, [System.StringComparison]::Ordinal)
    $LegacyEndIndex = $Existing.IndexOf($LegacyEndMarker, [System.StringComparison]::Ordinal)
    $HasAnyMarker = $CurrentStartIndex -ge 0 -or $CurrentEndIndex -ge 0 -or $LegacyStartIndex -ge 0 -or $LegacyEndIndex -ge 0

    if ($HasAnyMarker) {
      $CurrentPairValid = $CurrentStartIndex -ge 0 -and $CurrentEndIndex -gt $CurrentStartIndex -and
        $Existing.IndexOf($StartMarker, $CurrentStartIndex + $StartMarker.Length, [System.StringComparison]::Ordinal) -lt 0 -and
        $Existing.IndexOf($EndMarker, $CurrentEndIndex + $EndMarker.Length, [System.StringComparison]::Ordinal) -lt 0
      $LegacyPairValid = $LegacyStartIndex -ge 0 -and $LegacyEndIndex -gt $LegacyStartIndex -and
        $Existing.IndexOf($LegacyStartMarker, $LegacyStartIndex + $LegacyStartMarker.Length, [System.StringComparison]::Ordinal) -lt 0 -and
        $Existing.IndexOf($LegacyEndMarker, $LegacyEndIndex + $LegacyEndMarker.Length, [System.StringComparison]::Ordinal) -lt 0
      $CurrentPairAbsent = $CurrentStartIndex -lt 0 -and $CurrentEndIndex -lt 0
      $LegacyPairAbsent = $LegacyStartIndex -lt 0 -and $LegacyEndIndex -lt 0

      if ((-not $CurrentPairValid -and -not $CurrentPairAbsent) -or
          (-not $LegacyPairValid -and -not $LegacyPairAbsent) -or
          ($CurrentPairValid -and $LegacyPairValid)) {
        throw "Malformed Coding Agent Playbook — Claude Code Edition markers in $Target; no changes were made."
      }

      if ($CurrentPairValid) {
        $ActiveStartIndex = $CurrentStartIndex
        $ActiveEndIndex = $CurrentEndIndex
        $ActiveEndMarker = $EndMarker
      } else {
        $ActiveStartIndex = $LegacyStartIndex
        $ActiveEndIndex = $LegacyEndIndex
        $ActiveEndMarker = $LegacyEndMarker
        Write-Step "Migrating legacy Coding Agent Playbook markers in $Target"
      }

      if ($Newline -eq "`r`n") {
        $NormalizedBody = $NormalizedBody -replace "`n", "`r`n"
      }
      $Section = "$StartMarker$Newline# $Title$Newline$Newline$NormalizedBody$Newline$EndMarker"
      $Updated = $Existing.Substring(0, $ActiveStartIndex) + $Section + $Existing.Substring($ActiveEndIndex + $ActiveEndMarker.Length)
      if (-not $Updated.EndsWith($Newline)) { $Updated += $Newline }
      if ($Updated -eq $Existing) {
        Write-Step "Unchanged $Target"
        return
      }

      Backup-File $Target
      if ($DryRun) {
        Write-Step "[dry-run] Would replace the Coding Agent Playbook — Claude Code Edition section in $Target"
      } else {
        Set-Content -LiteralPath $Target -Value $Updated -Encoding UTF8 -NoNewline
      }
      return
    }
  }

  if ($Newline -eq "`r`n") {
    $NormalizedBody = $NormalizedBody -replace "`n", "`r`n"
  }
  $Section = "$StartMarker$Newline# $Title$Newline$Newline$NormalizedBody$Newline$EndMarker$Newline"
  Invoke-InstallCommand { New-Item -ItemType Directory -Force -Path $Parent | Out-Null } "New-Item -ItemType Directory -Force '$Parent'"
  Backup-File $Target

  if ($DryRun) {
    Write-Step "[dry-run] Would append $Title to $Target"
  } elseif (Test-Path -LiteralPath $Target -PathType Leaf) {
    $Separator = if ($Existing.Length -eq 0) { "" } else { "$Newline$Newline" }
    Set-Content -LiteralPath $Target -Value ($Existing + $Separator + $Section) -Encoding UTF8 -NoNewline
  } else {
    Set-Content -LiteralPath $Target -Value $Section -Encoding UTF8 -NoNewline
  }
}

$GlobalInstructions = Join-Path $RepoRoot "custom-instructions\global-coding-agent-instructions.md"
$ReferencesDir = Join-Path $RepoRoot "references"
$AgentsDir = Join-Path $RepoRoot "agents"
$SkillsDir = Join-Path $RepoRoot "skills"
$TargetClaudeMd = Join-Path $ClaudeHome "CLAUDE.md"
$ManagedRoots = [ordered]@{
  references = @{ Source = $ReferencesDir; Destination = (Join-Path $ClaudeHome "references") }
  agents = @{ Source = $AgentsDir; Destination = (Join-Path $ClaudeHome "agents") }
  skills = @{ Source = $SkillsDir; Destination = (Join-Path $ClaudeHome "skills") }
}

Write-Step "Coding Agent Playbook — Claude Code Edition installer"
Write-Step "Mode: $Mode"
Write-Step "Repository: $RepoRoot"
Write-Step "CLAUDE_HOME: $ClaudeHome"
Write-Step "Managed-file manifest: $ManifestPath"

if (-not (Test-Path -LiteralPath $GlobalInstructions -PathType Leaf)) {
  throw "Missing global instructions: $GlobalInstructions"
}

$CurrentManifestEntries = Get-CurrentManifestEntries $ManagedRoots
$PreviousManifestPath = if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) { $ManifestPath } elseif (Test-Path -LiteralPath $LegacyManifestPath -PathType Leaf) { $LegacyManifestPath } else { $ManifestPath }
if ($PreviousManifestPath -eq $LegacyManifestPath) {
  Write-Step "Migrating legacy managed-file manifest: $LegacyManifestPath"
}
$PreviousManifestEntries = Read-InstallManifest $PreviousManifestPath $ManagedRoots

if ($Mode -eq "full") {
  $Body = Get-Content -LiteralPath $GlobalInstructions -Raw
  AddOrReplace-PlaybookSection $TargetClaudeMd "Coding Agent Playbook — Claude Code Edition Global Instructions" $Body
} else {
  $PointerBody = @'
The primary global coding-agent behavior may already be configured in this CLAUDE.md file.

Supporting global reference documents live under the Claude Code home references directory:

- `references/README.md` — map of the available global reference docs
- `references/model-routing.md` — how Claude Code resolves a subagent's model, what overrides what, effort semantics, permission modes, tool boundaries, and nesting depth
- `references/subagents.md` — when to delegate, which role fits, how to write an assignment, and how to verify a result before accepting it
- `references/worktrees.md` — task-local worktree budgeting, the base-ref trap, integration, cleanup, and preservation
- `references/multi-session-coordination.md` — discovering, coordinating, sequencing, and integrating independent Claude Code sessions
- `references/reference-doc-routing.md` — choosing documents, judging their authority, and passing them on
- `references/templates/` — templates for repository CLAUDE.md, architecture, testing, access control, design system, release, API contracts, data model, active work, task graphs, and worktree manifests

Reusable Claude Code skills live under the Claude Code home skills directory:

- `skills/subagent-orchestration/SKILL.md`
- `skills/task-graph-orchestration/SKILL.md`
- `skills/worktree-lifecycle/SKILL.md`
- `skills/multi-session-coordination/SKILL.md`
- `skills/reference-doc-routing/SKILL.md`
- `skills/senior-code-review/SKILL.md`

Custom Claude Code subagents live under the Claude Code home agents directory:

- `agents/local-orchestrator.md`
- `agents/read-only-explorer.md`
- `agents/senior-reviewer.md`
- `agents/docs-researcher.md`
- `agents/test-triager.md`
- `agents/isolated-worker.md`

Reference documents are supporting context, not automatic truth. For repository tasks, delegate at least one bounded piece of execution to a subagent when subagents are available, and keep task framing, integration, validation, acceptance, and the final response with the root session. Direct root execution is right when subagents are unavailable, the user forbids delegation, the action needs authority that must stay with the root, or the task is too small to be worth delegating.

Pass an explicit `model` on every `Agent` dispatch; never leave it to default. Keep each child at or below the main session's tier (`opus` > `sonnet` > `haiku`) and record what the main session actually is rather than assuming Opus. Equal-tier routing is valid — delegating does not require stepping down. Bundled definitions pin `model: haiku` so an omitted-model dispatch fails closed. Note that `CLAUDE_CODE_SUBAGENT_MODEL` outranks the per-invocation `model`, and organization allowlists can substitute; verify rather than assume when attribution matters. `effort` comes from the agent definition and overrides session effort — it is a property of the role, not a ceiling inherited from the caller.

Claude Code allows nested subagents by default, up to three layers below the main conversation. This playbook uses two: the root session, one layer of direct workers or `local-orchestrator`, and a layer of leaves that cannot spawn. `local-orchestrator` may dispatch immediately — there is no capability flag to verify first. The cap holds because every leaf role omits `Agent` from `tools` and lists it in `disallowedTools`. Setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to `2` tightens the runtime default from 3 to 2 and is optional hardening, not a precondition; do not change it from inside a task. Keep every child at or below its parent in model, permissions, tools, scope, workspace, and authority.

Read-only roles run in `plan` mode, which means they cannot reliably run tests, linters, type checkers, or builds — those commands prompt or go to the classifier. Route suite execution to `test-triager`, which runs in `default` mode.

The auxiliary-worktree budget starts at zero and is separate from anything about subagent counts. Only the root may authorize `isolation: worktree`, create or adopt an auxiliary, change its purpose, move it, or remove it. One active auxiliary needs no added approval; two or more require user approval for the exact count and reasons. An isolated subagent's worktree branches from the repository default branch rather than the current `HEAD` unless `worktree.baseRef` is `"head"`, so record and verify the base ref before dispatching. Before the final response, remove each task-created auxiliary under verified gates or preserve it with exact path, owner, branch or HEAD, blocker, and next action. Task-local cleanup does not depend on scheduled automation, and the active host-managed workspace stays under the host lifecycle.

Verify implementation-relevant claims against primary evidence: current code, tests, schemas, configuration, logs, build output, typecheck output, runtime behavior, relevant session evidence, and authoritative external documentation.

When delegating to subagents or coordinating independent sessions, pass only the relevant document names, paths, or sections. Do not dump large documents or full session transcripts into prompts.

The root session remains accountable for the final plan, final diff, validation, and final response.
'@
  AddOrReplace-PlaybookSection $TargetClaudeMd "Global Reference Documents and Subagent Support" $PointerBody
}

Copy-PlaybookTree $ReferencesDir $ManagedRoots['references'].Destination
Copy-PlaybookTree $AgentsDir $ManagedRoots['agents'].Destination
Copy-PlaybookTree $SkillsDir $ManagedRoots['skills'].Destination
Assert-ManagedFilesMatch $CurrentManifestEntries $ManagedRoots
Retire-StaleManagedFiles $PreviousManifestEntries $CurrentManifestEntries $ManagedRoots
Write-InstallManifest $CurrentManifestEntries $ManifestPath
Retire-LegacyManifest $LegacyManifestPath

Write-Step ""
Write-Step "Validation:"
$CheckPaths = @(
  $TargetClaudeMd,
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
Write-Step "Install complete. Restart Claude Code or start a new session if needed so new instructions, skills, and subagents are loaded."
