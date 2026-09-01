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

echo "== agent definitions =="
for name in $ALL_AGENTS; do
  f="agents/$name.md"
  if [[ ! -f "$f" ]]; then
    fail "missing $f"
    continue
  fi

  for key in name description model effort permissionMode tools disallowedTools; do
    grep -q "^$key:" "$f" || fail "$f: missing '$key' frontmatter"
  done

  grep -Eq "^name:[[:space:]]*$name[[:space:]]*$" "$f" || fail "$f: name does not match filename"
  grep -Eq '^model:[[:space:]]*haiku[[:space:]]*$' "$f" || fail "$f: model must be the fail-closed 'haiku' alias"
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
for f in skills/*/SKILL.md; do
  grep -q '^name:' "$f" || fail "$f: missing 'name' frontmatter"
  grep -q '^description:' "$f" || fail "$f: missing 'description' frontmatter"
done
pass "skill frontmatter checked"

echo "== yaml frontmatter parses =="
python3 - <<'PY' || exit 1
import glob, sys
try:
    import yaml
except ImportError:
    print("ok    pyyaml unavailable; skipped strict parse")
    sys.exit(0)
bad = 0
for f in sorted(glob.glob('agents/*.md') + glob.glob('skills/*/SKILL.md')):
    t = open(f).read()
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

echo "== referenced repository paths exist =="
grep -rhoE '(references|skills|agents|claude-prompts|custom-instructions|install|assets|scripts)/[A-Za-z0-9._/-]+' \
  --include='*.md' . | sed 's/[.,)]*$//' | sort -u | while read -r p; do
  [[ -e "$p" ]] || echo "MISSING_PATH $p"
done > /tmp/playbook-missing-paths.txt
if [[ -s /tmp/playbook-missing-paths.txt ]]; then
  while read -r line; do fail "referenced path does not exist: ${line#MISSING_PATH }"; done < /tmp/playbook-missing-paths.txt
else
  pass "all referenced repository paths exist"
fi

echo "== installer syntax =="
bash -n install/install.sh && pass "install.sh parses" || fail "install.sh has a syntax error"

echo "== installer end-to-end (full mode) =="
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
if CLAUDE_CONFIG_DIR="$TMP_HOME/home" bash install/install.sh --full >/dev/null 2>&1; then
  pass "full install succeeds and exits 0"
else
  fail "full install failed"
fi

echo "== instruction body survives a re-install (awk escape regression) =="
# `awk -v` applies escape processing; passing the body that way corrupted any
# backslash on the replace path. Guard the fix with a body containing one.
CANARY='custom-instructions/global-coding-agent-instructions.md'
cp "$CANARY" "$TMP_HOME/canary.orig"
printf '\nRegex `\\d+`, path `C:\\Users\\me`, literal `\\n`, tab `\\t`.\n' >> "$CANARY"
CLAUDE_CONFIG_DIR="$TMP_HOME/home2" bash install/install.sh --full >/dev/null 2>&1
CLAUDE_CONFIG_DIR="$TMP_HOME/home2" bash install/install.sh --full >/dev/null 2>&1
sed -n '/coding-agent-playbook-claude-code:start/,/coding-agent-playbook-claude-code:end/p' \
  "$TMP_HOME/home2/CLAUDE.md" | sed '1,3d;$d' > "$TMP_HOME/installed-body.md"
if diff -q "$CANARY" "$TMP_HOME/installed-body.md" >/dev/null; then
  pass "instruction body is byte-identical after the replace path"
else
  fail "instruction body was altered on re-install"
fi
cp "$TMP_HOME/canary.orig" "$CANARY"

echo "== installer fails loudly on a missing managed file =="
CLONE="$TMP_HOME/clone"
mkdir -p "$CLONE"
cp -r agents references skills custom-instructions install "$CLONE/"
rm -rf "$CLONE/skills/senior-code-review"
if CLAUDE_CONFIG_DIR="$TMP_HOME/home3" bash "$CLONE/install/install.sh" --full >/dev/null 2>&1; then
  fail "installer exited 0 despite a missing managed file"
else
  pass "installer exits non-zero when a managed file is missing"
fi

echo "== cross-installer parity (skipped without pwsh) =="
if command -v pwsh >/dev/null 2>&1; then
  # Both installers must produce a byte-identical Claude Code home. They have
  # drifted before: PowerShell kept the source file's trailing newline (an extra
  # blank line before the end marker) and sorted the manifest case-insensitively
  # while the shell installer sorts byte-wise, so each rewrote the other's files.
  for mode in full support-only; do
    sh_home="$TMP_HOME/parity-sh-$mode"
    ps_home="$TMP_HOME/parity-ps-$mode"
    if [[ "$mode" == "full" ]]; then
      CLAUDE_CONFIG_DIR="$sh_home" bash install/install.sh --full >/dev/null 2>&1
      CLAUDE_CONFIG_DIR="$ps_home" pwsh -NoProfile -File install/install.ps1 -Full >/dev/null 2>&1
    else
      CLAUDE_CONFIG_DIR="$sh_home" bash install/install.sh --support-only >/dev/null 2>&1
      CLAUDE_CONFIG_DIR="$ps_home" pwsh -NoProfile -File install/install.ps1 -SupportOnly >/dev/null 2>&1
    fi
    if diff -r "$sh_home" "$ps_home" >/dev/null 2>&1; then
      pass "installers agree byte-for-byte ($mode mode)"
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
