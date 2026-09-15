#!/usr/bin/env bash
# Validates the playbook against the rules in CLAUDE.md.
# Run it locally exactly as CI does:  bash scripts/validate.sh
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

FAILURES=0
pass() { printf 'ok    %s\n' "$*"; }
fail() { FAILURES=$((FAILURES + 1)); printf 'FAIL  %s\n' "$*"; }

READ_ONLY_AGENTS="read-only-explorer docs-researcher senior-reviewer"
WRITE_AGENTS="test-triager isolated-worker local-orchestrator"
ALL_AGENTS="$READ_ONLY_AGENTS $WRITE_AGENTS"
# Lookup roles run on Haiku, which does not support effort; judgment roles run on Sonnet at high.
HAIKU_AGENTS="read-only-explorer docs-researcher"
SKILLS="multi-session-coordination reference-doc-routing senior-code-review subagent-orchestration task-graph-orchestration worktree-lifecycle"

# The installer runs as a native program. Under Git Bash on Windows a POSIX
# temp path would not be the same location for Python, so hand it a native path.
native_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi
}

echo "== agent definitions =="
for name in $ALL_AGENTS; do
  f="agents/$name.md"
  if [[ ! -f "$f" ]]; then
    fail "missing $f"
    continue
  fi

  for key in name description model permissionMode tools disallowedTools; do
    grep -q "^$key:" "$f" || fail "$f: missing '$key' frontmatter"
  done

  grep -Eq "^name:[[:space:]]*$name[[:space:]]*$" "$f" || fail "$f: name does not match filename"
  if [[ " $HAIKU_AGENTS " == *" $name "* ]]; then
    grep -Eq '^model:[[:space:]]*haiku[[:space:]]*$' "$f" || fail "$f: lookup role must use model: haiku"
    grep -q '^effort:' "$f" && fail "$f: Haiku does not support effort; remove the effort field"
  else
    grep -Eq '^model:[[:space:]]*sonnet[[:space:]]*$' "$f" || fail "$f: judgment role must use model: sonnet"
    grep -Eq '^effort:[[:space:]]*high[[:space:]]*$' "$f" || fail "$f: judgment role must use effort: high"
  fi
  grep -Eq '^isolation:[[:space:]]*worktree' "$f" && fail "$f: must not set isolation: worktree"

  if [[ " $READ_ONLY_AGENTS " == *" $name "* ]]; then
    grep -Eq '^permissionMode:[[:space:]]*plan[[:space:]]*$' "$f" || fail "$f: read-only role must use permissionMode: plan"
    grep -Eq '^tools:.*(^|[ ,])(Edit|Write)([, ]|$)' "$f" && fail "$f: read-only role must not list Edit or Write"
  else
    grep -Eq '^permissionMode:[[:space:]]*default[[:space:]]*$' "$f" || fail "$f: write-capable role must use permissionMode: default"
  fi

  if [[ "$name" == "local-orchestrator" ]]; then
    grep -Eq '^tools:.*[ ,]Agent([, ]|$)' "$f" || fail "$f: local-orchestrator must list Agent in tools"
  else
    grep -Eq '^tools:.*[ ,]Agent([, ]|$)' "$f" && fail "$f: leaf role must not list Agent in tools"
    grep -Eq '^disallowedTools:.*(^|[ ,:])Agent([, ]|$)' "$f" || fail "$f: leaf role must list Agent in disallowedTools"
  fi
done
(( FAILURES == 0 )) && pass "six agent definitions conform"

echo "== skills =="
for name in $SKILLS; do
  f="skills/$name/SKILL.md"
  [[ -f "$f" ]] || { fail "missing $f"; continue; }
  grep -q '^name:' "$f" || fail "$f: missing 'name' frontmatter"
  grep -q '^description:' "$f" || fail "$f: missing 'description' frontmatter"
done
[[ -e references ]] && fail "a top-level references/ directory exists; every reference belongs inside its owning skill"
pass "skill frontmatter checked"

echo "== yaml frontmatter parses =="
python3 - <<'PY'
import glob, sys
try:
    import yaml
except ImportError:
    print("ok    pyyaml unavailable; skipped strict parse")
    sys.exit(0)
bad = 0
for f in sorted(glob.glob('agents/*.md') + glob.glob('skills/*/SKILL.md')):
    t = open(f, encoding='utf-8').read()
    if not t.startswith('---\n'):
        print(f"FAIL  {f}: no frontmatter"); bad += 1; continue
    try:
        yaml.safe_load(t[4:t.index('\n---\n', 3) + 1])
    except Exception as e:
        print(f"FAIL  {f}: {e}"); bad += 1
print("ok    frontmatter parses" if not bad else f"FAIL  {bad} file(s)")
sys.exit(1 if bad else 0)
PY
(( $? != 0 )) && FAILURES=$((FAILURES + 1))

echo "== markdown fences balanced =="
while IFS= read -r f; do
  n=$(grep -c '^```' "$f" || true)
  (( n % 2 != 0 )) && fail "$f: unbalanced code fences ($n)"
done < <(git ls-files '*.md')
pass "code fences checked"

echo "== referenced paths resolve =="
# Repository-relative paths must exist. A `references/...` path written inside a
# skill resolves against that skill's package root; outside skills/ it is a
# stale pointer to the former top-level directory.
PATH_ISSUES="$(mktemp)"
while IFS= read -r f; do
  grep -oE '(^|[^A-Za-z0-9_./-])(skills|agents|claude-prompts|custom-instructions|install|assets|scripts)/[A-Za-z0-9._/-]+' "$f" \
    | sed -E 's/^[^a-z]//; s/[.,:;)]*$//' | sort -u | while read -r p; do
      [[ -e "$p" ]] || echo "$f: referenced path does not exist: $p"
    done
  if [[ "$f" == skills/*/* ]]; then
    skill_root="${f%%/*}/$(cut -d/ -f2 <<<"$f")"
    grep -oE '(^|[^A-Za-z0-9_./-])references/[A-Za-z0-9._/-]+' "$f" \
      | sed -E 's/^[^a-z]//; s/[.,:;)]*$//' | grep -v '\.\.' | sort -u | while read -r p; do
        [[ -e "$skill_root/$p" ]] || echo "$f: skill-local resource does not resolve inside its package: $p"
      done
  else
    # Outside skills/, a `references/x.md` pointer in prose is a leftover from
    # the former top-level directory. Fenced blocks are skipped: a tree diagram
    # there shows paths relative to the skill package it draws. Fences nest, and
    # a longer fence encloses shorter ones, so track the opening length.
    awk '
      /^ {0,3}```/ {
        sub(/^ +/, "")
        match($0, /^`+/)
        if (!fenced) { fenced = 1; opened = RLENGTH }
        else if (RLENGTH >= opened && $0 ~ /^`+[[:space:]]*$/) { fenced = 0 }
        next
      }
      !fenced
    ' "$f" \
      | grep -oE '(^|[^A-Za-z0-9_./-])references/[A-Za-z0-9._/-]+' \
      | grep -v '\.\.' | sed -E 's/^[^a-z]//; s/[.,:;)]*$//' \
      | grep -vE '^references/$' | sort -u | while read -r p; do
        echo "$f: refers to a top-level references/ path that no longer exists: $p"
      done
  fi
done < <(git ls-files '*.md') > "$PATH_ISSUES"
if [[ -s "$PATH_ISSUES" ]]; then
  while read -r line; do fail "$line"; done < "$PATH_ISSUES"
else
  pass "all referenced paths resolve, and skill resources resolve inside their packages"
fi
rm -f "$PATH_ISSUES"

echo "== no vocabulary from another coding-agent environment =="
if grep -rnE 'CODEX_HOME|\.codex/|gpt-5\.6-luna|Luna/max|model_reasoning_effort|AGENTS\.md' \
    --include='*.md' --include='*.py' --include='*.sh' --include='*.ps1' --include='*.yml' . \
    | grep -v '^./.git/' | grep -v '^./scripts/validate.sh:'; then
  fail "the files above carry configuration or model vocabulary from another coding-agent environment"
else
  pass "no foreign environment vocabulary"
fi

echo "== support-only pointer has one source =="
# claude-prompts/setup-global-claude-support-system.md embeds the pointer for
# people who paste it; install/support-only-pointer.md is what the installer
# writes. They must be identical.
POINTER_IN_PROMPT="$(mktemp)"
sed -n '/^## Global Reference Documents and Subagent Support$/,/^```$/p' claude-prompts/setup-global-claude-support-system.md \
  | sed '1,2d;$d' > "$POINTER_IN_PROMPT"
if diff -q install/support-only-pointer.md "$POINTER_IN_PROMPT" >/dev/null; then
  pass "setup prompt pointer matches install/support-only-pointer.md"
else
  fail "the pointer in claude-prompts/setup-global-claude-support-system.md differs from install/support-only-pointer.md"
fi
rm -f "$POINTER_IN_PROMPT"

echo "== installer syntax =="
bash -n install/install.sh && pass "install.sh parses" || fail "install.sh has a syntax error"
python3 -c "import ast,sys; ast.parse(open(sys.argv[1],encoding='utf-8').read(), sys.argv[1])" install/install.py   && pass "install.py parses" || fail "install.py has a syntax error"
grep -q 'install.py' install/install.sh || fail "install.sh must launch install.py"
grep -q 'install.py' install/install.ps1 || fail "install.ps1 must launch install.py"

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
HOME1="$TMP_HOME/home"

echo "== installer end-to-end (full mode) =="
if CLAUDE_CONFIG_DIR="$(native_path "$HOME1")" bash install/install.sh --full > "$TMP_HOME/install1.log" 2>&1; then
  pass "full install succeeds and exits 0"
else
  fail "full install failed"; tail -20 "$TMP_HOME/install1.log"
fi
for p in CLAUDE.md .coding-agent-playbook-claude-code-managed-files.tsv \
    agents/local-orchestrator.md \
    skills/senior-code-review/SKILL.md \
    skills/subagent-orchestration/references/model-routing.md \
    skills/reference-doc-routing/references/engineering-design.md \
    skills/reference-doc-routing/references/templates/repository-CLAUDE.md \
    skills/task-graph-orchestration/references/templates/task-graph.md \
    skills/worktree-lifecycle/references/worktrees.md \
    skills/multi-session-coordination/references/templates/active-work-record.md; do
  [[ -f "$HOME1/$p" ]] || fail "not installed: $p"
done
[[ -e "$HOME1/references" ]] && fail "installer created a top-level references/ directory"
grep -q '^<!-- coding-agent-playbook-claude-code:start -->$' "$HOME1/CLAUDE.md" || fail "marked section missing from installed CLAUDE.md"
n=$(grep -c "^skills$(printf '\t')" "$HOME1/.coding-agent-playbook-claude-code-managed-files.tsv")
m=$(git ls-files skills | wc -l)
[[ "$n" == "$m" ]] && pass "manifest lists all $m skill files" || fail "manifest lists $n skill files, repository has $m"

echo "== a second identical install is a no-op =="
CLAUDE_CONFIG_DIR="$(native_path "$HOME1")" bash install/install.sh --full > "$TMP_HOME/install2.log" 2>&1
install2_status=$?
if (( install2_status != 0 )); then
  fail "second install exited $install2_status"; tail -10 "$TMP_HOME/install2.log"
elif grep -qE '^(Installing|Writing|Backing up|Retiring)' "$TMP_HOME/install2.log"; then
  fail "second install changed files:"; grep -E '^(Installing|Writing|Backing up|Retiring)' "$TMP_HOME/install2.log" | head -5
elif [[ -e "$HOME1/.coding-agent-playbook-backups" ]]; then
  fail "second install wrote backups"
else
  pass "repeat install reports every file unchanged and writes no backups"
fi

echo "== dry run creates nothing =="
DRY_HOME="$TMP_HOME/dry"
if CLAUDE_CONFIG_DIR="$(native_path "$DRY_HOME")" bash install/install.sh --full --dry-run > "$TMP_HOME/dry.log" 2>&1 \
    && [[ ! -e "$DRY_HOME" ]] \
    && grep -q '^\[dry-run\] Would install' "$TMP_HOME/dry.log" \
    && grep -q 'Dry run complete. No files were changed.' "$TMP_HOME/dry.log" \
    && ! grep -qE '^(Installing|Writing|Backing up|Retiring)' "$TMP_HOME/dry.log"; then
  pass "dry run exits 0, creates no files, and uses non-mutating wording"
else
  fail "dry run created files, mutated wording, or exited non-zero"; tail -10 "$TMP_HOME/dry.log"
fi

echo "== instruction body survives a re-install (backslash canary) =="
# A body containing backslashes once got corrupted on the replace path. Guard it.
CANARY='custom-instructions/global-coding-agent-instructions.md'
cp "$CANARY" "$TMP_HOME/canary.orig"
printf '\nRegex `\\d+`, path `C:\\Users\\me`, literal `\\n`, tab `\\t`.\n' >> "$CANARY"
CLAUDE_CONFIG_DIR="$(native_path "$TMP_HOME/home2")" bash install/install.sh --full >/dev/null 2>&1
CLAUDE_CONFIG_DIR="$(native_path "$TMP_HOME/home2")" bash install/install.sh --full >/dev/null 2>&1
sed -n '/coding-agent-playbook-claude-code:start/,/coding-agent-playbook-claude-code:end/p' \
  "$TMP_HOME/home2/CLAUDE.md" | sed '1,3d;$d' > "$TMP_HOME/installed-body.md"
if diff -q "$CANARY" "$TMP_HOME/installed-body.md" >/dev/null; then
  pass "instruction body is byte-identical after the replace path"
else
  fail "instruction body was altered on re-install"
fi
cp "$TMP_HOME/canary.orig" "$CANARY"

echo "== existing content outside the markers is preserved and backed up =="
HOME3="$TMP_HOME/home3"
mkdir -p "$HOME3"
printf '# My own notes\n\nKeep me.\n' > "$HOME3/CLAUDE.md"
CLAUDE_CONFIG_DIR="$(native_path "$HOME3")" bash install/install.sh --support-only > "$TMP_HOME/install3.log" 2>&1
if head -1 "$HOME3/CLAUDE.md" | grep -q '^# My own notes$' \
    && grep -q '^# Global Reference Documents and Subagent Support$' "$HOME3/CLAUDE.md" \
    && [[ -n "$(find "$HOME3/.coding-agent-playbook-backups" -name CLAUDE.md 2>/dev/null)" ]]; then
  pass "user content kept, pointer section appended, original backed up outside the managed trees"
else
  fail "support-only install did not preserve or back up existing CLAUDE.md"; tail -10 "$TMP_HOME/install3.log"
fi

echo "== formerly managed loose references are retired only when unchanged =="
LEG="$TMP_HOME/legacy"
mkdir -p "$LEG/references"
printf 'installed by an earlier release\n' > "$LEG/references/model-routing.md"
printf 'the user edited this one\n' > "$LEG/references/subagents.md"
unchanged_hash="$(sha256sum < "$LEG/references/model-routing.md" | cut -d' ' -f1)"
{
  printf '# coding-agent-playbook-claude-code managed files v1\n'
  printf 'references\tmodel-routing.md\t%s\n' "$unchanged_hash"
  printf 'references\tsubagents.md\t%s\n' "$(printf '0%.0s' $(seq 1 64))"
} > "$LEG/.coding-agent-playbook-claude-code-managed-files.tsv"
CLAUDE_CONFIG_DIR="$(native_path "$LEG")" bash install/install.sh --full > "$TMP_HOME/legacy.log" 2>&1
if [[ ! -e "$LEG/references/model-routing.md" ]] \
    && grep -q 'Retiring formerly managed file' "$TMP_HOME/legacy.log" \
    && [[ -n "$(find "$LEG/.coding-agent-playbook-backups" -name model-routing.md 2>/dev/null)" ]]; then
  pass "unchanged formerly managed file backed up and retired"
else
  fail "unchanged formerly managed file was not retired with a backup"; tail -10 "$TMP_HOME/legacy.log"
fi
if [[ -f "$LEG/references/subagents.md" ]] && grep -q 'Preserving customized formerly managed file' "$TMP_HOME/legacy.log"; then
  pass "customized formerly managed file preserved and reported"
else
  fail "customized formerly managed file was removed or not reported"
fi

echo "== installer fails loudly on a missing managed file =="
CLONE="$TMP_HOME/clone"
mkdir -p "$CLONE"
cp -r agents skills custom-instructions install "$CLONE/"
rm -rf "$CLONE/skills/senior-code-review"
if CLAUDE_CONFIG_DIR="$(native_path "$TMP_HOME/home4")" bash "$CLONE/install/install.sh" --full >/dev/null 2>&1; then
  fail "installer exited 0 despite a missing managed file"
else
  pass "installer exits non-zero when a managed file is missing"
fi
[[ -e "$TMP_HOME/home4" ]] && fail "installer wrote into the home before its source check failed"

echo "== launcher parity (skipped without pwsh) =="
if command -v pwsh >/dev/null 2>&1; then
  # Both launchers run install.py; this proves they pass the mode through and
  # end up with byte-identical homes.
  for mode in full support-only; do
    sh_home="$TMP_HOME/parity-sh-$mode"
    ps_home="$TMP_HOME/parity-ps-$mode"
    if [[ "$mode" == "full" ]]; then
      CLAUDE_CONFIG_DIR="$(native_path "$sh_home")" bash install/install.sh --full >/dev/null 2>&1
      CLAUDE_CONFIG_DIR="$(native_path "$ps_home")" pwsh -NoProfile -File install/install.ps1 -Full >/dev/null 2>&1
    else
      CLAUDE_CONFIG_DIR="$(native_path "$sh_home")" bash install/install.sh --support-only >/dev/null 2>&1
      CLAUDE_CONFIG_DIR="$(native_path "$ps_home")" pwsh -NoProfile -File install/install.ps1 -SupportOnly >/dev/null 2>&1
    fi
    if diff -r "$sh_home" "$ps_home" >/dev/null 2>&1; then
      pass "launchers produce byte-identical homes ($mode mode)"
    else
      fail "install.sh and install.ps1 produce different output ($mode mode)"
      diff -r "$sh_home" "$ps_home" 2>&1 | head -20
    fi
  done
else
  echo "skip  pwsh not installed; CI runs this check"
fi

echo
if (( FAILURES > 0 )); then
  echo "$FAILURES check(s) failed."
  exit 1
fi
echo "All checks passed."
