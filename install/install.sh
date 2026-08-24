#!/usr/bin/env bash
set -euo pipefail

MODE="full"
FULL_REQUESTED="0"
SUPPORT_ONLY_REQUESTED="0"
DRY_RUN="0"

for arg in "$@"; do
  case "$arg" in
    --full)
      FULL_REQUESTED="1"
      ;;
    --support-only)
      SUPPORT_ONLY_REQUESTED="1"
      ;;
    --dry-run)
      DRY_RUN="1"
      ;;
    -h|--help)
      cat <<'HELP'
Usage: bash install/install.sh [--full|--support-only] [--dry-run]

--full          Install instruction rules, references, skills, commands, and subagents. This is the default.
--support-only  Install everything except the instruction rules, for users who manage their own instructions.
--dry-run       Print actions without writing files.
HELP
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$FULL_REQUESTED" == "1" && "$SUPPORT_ONLY_REQUESTED" == "1" ]]; then
  echo "Choose either --full or --support-only, not both. Full mode is the default for installs and updates." >&2
  exit 1
fi

if [[ "$SUPPORT_ONLY_REQUESTED" == "1" ]]; then
  MODE="support-only"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
MANIFEST_PATH="$CLAUDE_HOME/.coding-agent-playbook-claude-code-managed-files.tsv"
BACKUP_ROOT="$CLAUDE_HOME/.coding-agent-playbook-backups/$TIMESTAMP"
LEGACY_MANIFEST_PATH="$CLAUDE_HOME/.claude-code-agent-playbook-managed-files.tsv"

VALIDATION_FAILURES=0

say() {
  printf '%s\n' "$*"
}

fail() {
  VALIDATION_FAILURES=$((VALIDATION_FAILURES + 1))
  printf '%s\n' "$*" >&2
}

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

sha256_file() {
  local path="$1"
  # Hash from stdin, never by filename argument: GNU coreutils escapes names
  # containing a backslash and prefixes the line with `\`, which corrupted the
  # digest for any Windows-style CLAUDE_CONFIG_DIR under Git Bash.
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum < "$path" | awk '{ print tolower($1) }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 < "$path" | awk '{ print tolower($1) }'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 < "$path" | awk '{ print tolower($NF) }'
  else
    say "No SHA-256 tool is available; install sha256sum, shasum, or openssl." >&2
    return 1
  fi
}

# Backups are written under $CLAUDE_HOME/.coding-agent-playbook-backups/<timestamp>/
# rather than beside the original. Writing `*.bak.<timestamp>` files into
# references/, agents/, and skills/ left the managed trees cluttered after every
# update and put unmanaged files inside directories Claude Code scans.
backup_file() {
  local path="$1"
  [[ -f "$path" ]] || return 0

  local relative backup
  case "$path" in
    "$CLAUDE_HOME"/*) relative="${path#"$CLAUDE_HOME"/}" ;;
    *) relative="$(basename "$path")" ;;
  esac
  backup="$BACKUP_ROOT/$relative"

  say "Backing up $path -> $backup"
  run mkdir -p "$(dirname "$backup")"
  run cp -p "$path" "$backup"
}

copy_file() {
  local src="$1"
  local dest="$2"
  run mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    say "Unchanged $dest"
    return
  fi
  backup_file "$dest"
  say "Installing $dest"
  run cp "$src" "$dest"
}

copy_tree() {
  local src_dir="$1"
  local dest_dir="$2"
  if [[ ! -d "$src_dir" ]]; then
    say "Skipping missing source directory: $src_dir"
    return
  fi

  while IFS= read -r -d '' src; do
    local rel="${src#$src_dir/}"
    local dest="$dest_dir/$rel"
    copy_file "$src" "$dest"
  done < <(find "$src_dir" -type f -print0)
}

validate_manifest_relative_path() {
  local rel="$1"
  if [[ -z "$rel" || "$rel" == /* || "$rel" == *$'\t'* || "$rel" == *$'\r'* || "$rel" == *$'\n'* ]]; then
    say "Unsafe managed-file manifest path: '$rel'" >&2
    return 1
  fi

  case "/$rel/" in
    *'/../'*|*'/./'*|*'//'*)
      say "Unsafe managed-file manifest path: '$rel'" >&2
      return 1
      ;;
  esac
}

destination_for_manifest_entry() {
  local root="$1"
  local rel="$2"
  validate_manifest_relative_path "$rel"

  case "$root" in
    references) printf '%s\n' "$CLAUDE_HOME/references/$rel" ;;
    agents) printf '%s\n' "$CLAUDE_HOME/agents/$rel" ;;
    skills) printf '%s\n' "$CLAUDE_HOME/skills/$rel" ;;
    rules) printf '%s\n' "$CLAUDE_HOME/rules/$rel" ;;
    commands) printf '%s\n' "$CLAUDE_HOME/commands/$rel" ;;
    *)
      say "Unknown managed-file root '$root'." >&2
      return 1
      ;;
  esac
}

build_current_manifest() {
  local output="$1"
  local root src_dir src rel hash

  printf '# coding-agent-playbook-claude-code managed files v1\n' > "$output"
  # Alphabetical root order, matching install.ps1's Sort-Object Root, Path, so
  # both installers write byte-identical manifests.
  for root in agents commands references rules skills; do
    # Support-only mode leaves the user's own instructions alone, so the
    # rules tree is neither installed nor recorded as managed.
    [[ "$root" == "rules" && "$MODE" == "support-only" ]] && continue
    case "$root" in
      references) src_dir="$REFERENCES_DIR" ;;
      agents) src_dir="$AGENTS_DIR" ;;
      skills) src_dir="$SKILLS_DIR" ;;
      rules) src_dir="$RULES_DIR" ;;
      commands) src_dir="$COMMANDS_DIR" ;;
    esac

    while IFS= read -r src; do
      rel="${src#$src_dir/}"
      validate_manifest_relative_path "$rel"
      hash="$(sha256_file "$src")"
      printf '%s\t%s\t%s\n' "$root" "$rel" "$hash" >> "$output"
    done < <(find "$src_dir" -type f -print | LC_ALL=C sort)
  done
}

validate_install_manifest() {
  local path="$1"
  [[ -f "$path" ]] || {
    say "No previous managed-file manifest found; existing unlisted files will be preserved."
    return
  }

  local duplicates
  duplicates="$(awk -F '\t' '!/^#/ && NF == 3 { print $1 "\t" $2 }' "$path" | LC_ALL=C sort | uniq -d)"
  if [[ -n "$duplicates" ]]; then
    say "Duplicate entries in managed-file manifest $path:" >&2
    say "$duplicates" >&2
    return 1
  fi

  local line_number=0 root rel hash extra
  while IFS=$'\t' read -r root rel hash extra || [[ -n "$root$rel$hash$extra" ]]; do
    line_number=$((line_number + 1))
    [[ -z "$root" || "$root" == \#* ]] && continue

    if [[ -n "$extra" || -z "$rel" || -z "$hash" ]]; then
      say "Malformed managed-file manifest at $path:$line_number" >&2
      return 1
    fi
    case "$root" in
      references|agents|skills|rules|commands) ;;
      *)
        say "Unknown managed-file root '$root' at $path:$line_number" >&2
        return 1
        ;;
    esac
    validate_manifest_relative_path "$rel"
    if [[ ! "$hash" =~ ^[a-fA-F0-9]{64}$ ]]; then
      say "Invalid SHA-256 at $path:$line_number" >&2
      return 1
    fi
  done < "$path"
}

manifest_contains_key() {
  local path="$1"
  local root="$2"
  local rel="$3"
  awk -F '\t' -v root="$root" -v rel="$rel" '
    $1 == root && $2 == rel { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$path"
}

verify_managed_files() {
  local current_manifest="$1"
  local count
  count="$(awk -F '\t' '!/^#/ && NF == 3 { count++ } END { print count + 0 }' "$current_manifest")"

  if [[ "$DRY_RUN" == "1" ]]; then
    say "[dry-run] Would verify $count managed files against repository SHA-256 hashes."
    return
  fi

  local root rel expected_hash extra destination actual_hash
  while IFS=$'\t' read -r root rel expected_hash extra || [[ -n "$root$rel$expected_hash$extra" ]]; do
    [[ -z "$root" || "$root" == \#* ]] && continue
    destination="$(destination_for_manifest_entry "$root" "$rel")"
    if [[ ! -f "$destination" ]]; then
      say "Managed file was not installed: $destination" >&2
      return 1
    fi
    actual_hash="$(sha256_file "$destination")"
    if [[ "$actual_hash" != "$expected_hash" ]]; then
      say "Managed file does not match the repository source: $destination" >&2
      return 1
    fi
  done < "$current_manifest"

  say "OK managed-file content: $count/$count exact SHA-256 matches"
}

retire_stale_managed_files() {
  local previous_manifest="$1"
  local current_manifest="$2"
  [[ -f "$previous_manifest" ]] || return 0

  local root rel expected_hash extra destination actual_hash
  while IFS=$'\t' read -r root rel expected_hash extra || [[ -n "$root$rel$expected_hash$extra" ]]; do
    [[ -z "$root" || "$root" == \#* ]] && continue
    if [[ "$root" == "rules" && "$MODE" == "support-only" ]]; then
      say "Support-only mode: leaving instruction rules in place."
      continue
    fi
    if manifest_contains_key "$current_manifest" "$root" "$rel"; then
      continue
    fi

    destination="$(destination_for_manifest_entry "$root" "$rel")"
    if [[ ! -f "$destination" ]]; then
      say "Formerly managed file already absent: $destination"
      continue
    fi

    actual_hash="$(sha256_file "$destination")"
    expected_hash="$(printf '%s' "$expected_hash" | tr '[:upper:]' '[:lower:]')"
    if [[ "$actual_hash" != "$expected_hash" ]]; then
      say "Preserving customized formerly managed file: $destination"
      continue
    fi

    backup_file "$destination"
    say "Retiring formerly managed file: $destination"
    run rm -f -- "$destination"
  done < "$previous_manifest"
}

write_install_manifest() {
  local current_manifest="$1"
  local destination="$2"

  if [[ -f "$destination" ]] && cmp -s "$current_manifest" "$destination"; then
    say "Unchanged $destination"
    return
  fi

  run mkdir -p "$(dirname "$destination")"
  backup_file "$destination"
  say "Writing managed-file manifest: $destination"
  run cp "$current_manifest" "$destination"
}

retire_legacy_manifest() {
  local legacy_path="$1"
  [[ -f "$legacy_path" ]] || return 0

  backup_file "$legacy_path"
  say "Retiring legacy managed-file manifest: $legacy_path"
  run rm -f -- "$legacy_path"
}

RULES_DIR="$REPO_ROOT/rules"
REFERENCES_DIR="$REPO_ROOT/references"
AGENTS_DIR="$REPO_ROOT/agents"
SKILLS_DIR="$REPO_ROOT/skills"
COMMANDS_DIR="$REPO_ROOT/commands"

say "Coding Agent Playbook — Claude Code Edition installer"
say "Mode: $MODE"
say "Repository: $REPO_ROOT"
say "CLAUDE_HOME: $CLAUDE_HOME"
say "Managed-file manifest: $MANIFEST_PATH"

if [[ ! -d "$RULES_DIR" ]]; then
  say "Missing instruction rules directory: $RULES_DIR" >&2
  exit 1
fi

CURRENT_MANIFEST="$(mktemp "${TMPDIR:-/tmp}/coding-agent-playbook-claude-code-manifest.XXXXXX")"
trap 'rm -f "$CURRENT_MANIFEST"' EXIT
build_current_manifest "$CURRENT_MANIFEST"
PREVIOUS_MANIFEST_PATH="$MANIFEST_PATH"
if [[ ! -f "$MANIFEST_PATH" && -f "$LEGACY_MANIFEST_PATH" ]]; then
  PREVIOUS_MANIFEST_PATH="$LEGACY_MANIFEST_PATH"
  say "Migrating legacy managed-file manifest: $LEGACY_MANIFEST_PATH"
fi
validate_install_manifest "$PREVIOUS_MANIFEST_PATH"

if [[ "$MODE" == "full" ]]; then
  copy_tree "$RULES_DIR" "$CLAUDE_HOME/rules"
else
  say "Support-only mode: skipping $CLAUDE_HOME/rules (instruction rules not installed)."
fi

copy_tree "$REFERENCES_DIR" "$CLAUDE_HOME/references"
copy_tree "$AGENTS_DIR" "$CLAUDE_HOME/agents"
copy_tree "$SKILLS_DIR" "$CLAUDE_HOME/skills"
copy_tree "$COMMANDS_DIR" "$CLAUDE_HOME/commands"
verify_managed_files "$CURRENT_MANIFEST"
retire_stale_managed_files "$PREVIOUS_MANIFEST_PATH" "$CURRENT_MANIFEST"
write_install_manifest "$CURRENT_MANIFEST" "$MANIFEST_PATH"
retire_legacy_manifest "$LEGACY_MANIFEST_PATH"

say ""
say "Validation:"
[[ "$DRY_RUN" == "1" ]] && say "Dry run only; validation checks are informational."

for path in \
  "$CLAUDE_HOME/commands/coordinate-work.md" \
  "$CLAUDE_HOME/references/model-routing.md" \
  "$CLAUDE_HOME/references/subagents.md" \
  "$CLAUDE_HOME/references/worktrees.md" \
  "$CLAUDE_HOME/references/multi-session-coordination.md" \
  "$CLAUDE_HOME/references/reference-doc-routing.md" \
  "$CLAUDE_HOME/references/templates/active-work-record.md" \
  "$CLAUDE_HOME/references/templates/task-graph.md" \
  "$CLAUDE_HOME/references/templates/worktree-manifest.md" \
  "$CLAUDE_HOME/agents/local-orchestrator.md" \
  "$CLAUDE_HOME/agents/read-only-explorer.md" \
  "$CLAUDE_HOME/agents/senior-reviewer.md" \
  "$CLAUDE_HOME/agents/docs-researcher.md" \
  "$CLAUDE_HOME/agents/test-triager.md" \
  "$CLAUDE_HOME/agents/isolated-worker.md" \
  "$CLAUDE_HOME/skills/subagent-orchestration/SKILL.md" \
  "$CLAUDE_HOME/skills/task-graph-orchestration/SKILL.md" \
  "$CLAUDE_HOME/skills/worktree-lifecycle/SKILL.md" \
  "$CLAUDE_HOME/skills/multi-session-coordination/SKILL.md" \
  "$CLAUDE_HOME/skills/reference-doc-routing/SKILL.md" \
  "$CLAUDE_HOME/skills/senior-code-review/SKILL.md"; do
  if [[ -e "$path" || "$DRY_RUN" == "1" ]]; then
    say "OK: $path"
  else
    fail "Missing: $path"
  fi
done

for skill in "$CLAUDE_HOME/skills"/*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  if grep -q '^name:' "$skill" && grep -q '^description:' "$skill"; then
    say "OK frontmatter: $skill"
  else
    fail "Check frontmatter: $skill"
  fi
done

# Roles that must stay read-only: plan permission mode, and no Edit or Write.
READ_ONLY_AGENTS=" read-only-explorer docs-researcher senior-reviewer "

for agent_name in \
  local-orchestrator \
  read-only-explorer \
  senior-reviewer \
  docs-researcher \
  test-triager \
  isolated-worker; do
  agent="$CLAUDE_HOME/agents/$agent_name.md"
  [[ -f "$agent" ]] || continue
  if grep -q '^name:' "$agent" \
    && grep -q '^description:' "$agent" \
    && grep -q '^model:' "$agent" \
    && grep -q '^effort:' "$agent" \
    && grep -q '^permissionMode:' "$agent" \
    && grep -q '^tools:' "$agent"; then
    say "OK Claude Code frontmatter: $agent"
  else
    fail "Check Claude Code frontmatter: $agent"
  fi

  if [[ "$READ_ONLY_AGENTS" == *" $agent_name "* ]]; then
    if grep -Eq '^permissionMode:[[:space:]]*plan[[:space:]]*$' "$agent"; then
      say "OK read-only permission mode: $agent"
    else
      fail "Read-only role must use permissionMode: plan: $agent"
    fi

    if grep -Eq '^tools:.*(^|[ ,])(Edit|Write)([, ]|$)' "$agent"; then
      fail "Read-only role must not list Edit or Write: $agent"
    else
      say "OK read-only tool boundary: $agent"
    fi
  elif grep -Eq '^permissionMode:[[:space:]]*(acceptEdits|auto|dontAsk|bypassPermissions)[[:space:]]*$' "$agent"; then
    fail "Write-capable role must use permissionMode: default unless a maintainer approved otherwise: $agent"
  fi

  if grep -Eq "^name:[[:space:]]*$agent_name[[:space:]]*$" "$agent" \
    && grep -Eq '^model:[[:space:]]*haiku[[:space:]]*$' "$agent"; then
    say "OK Claude Code agent name and model: $agent"
  else
    fail "Check Claude Code agent name or fail-closed Haiku model: $agent"
  fi

  if [[ "$agent_name" == "local-orchestrator" ]]; then
    if grep -Eq '^tools:.*[ ,]Agent([, ]|$)' "$agent"; then
      say "OK depth-1 Agent tool: $agent"
    else
      fail "local-orchestrator.md must list Agent: $agent"
    fi
  elif grep -Eq '^tools:.*[ ,]Agent([, ]|$)' "$agent"; then
    fail "Execution worker or leaf must not list Agent: $agent"
  fi

  if grep -Eq '^isolation:[[:space:]]*worktree[[:space:]]*$' "$agent"; then
    fail "Bundled agents must not enable worktree isolation globally: $agent"
  fi
done

if [[ "$MODE" == "full" ]]; then
  for rule in "$RULES_DIR"/*.md; do
    installed="$CLAUDE_HOME/rules/$(basename "$rule")"
    if [[ -f "$installed" ]]; then
      say "OK rule: $installed"
    else
      fail "Missing installed rule: $installed"
    fi
  done
fi

say ""
if [[ -d "$BACKUP_ROOT" ]]; then
  say "Backups for this run: $BACKUP_ROOT"
fi

if (( VALIDATION_FAILURES > 0 )); then
  say ""
  fail "Install finished with $VALIDATION_FAILURES validation failure(s). Review the messages above."
  exit 1
fi

say ""
say "Install complete. Restart Claude Code or start a new session if needed so new rules, skills, commands, and subagents are loaded."
