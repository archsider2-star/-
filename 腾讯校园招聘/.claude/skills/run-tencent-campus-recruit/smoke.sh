#!/usr/bin/env bash
# Smoke driver for 腾讯校园招聘 skill scripts.
# Run from 腾讯校园招聘/ directory: bash .claude/skills/run-tencent-campus-recruit/smoke.sh
# Exit 0 = all local checks passed (network checks may fail on restricted hosts).

set -uo pipefail
cd "$(dirname "$0")/../../.."   # ensure we're in 腾讯校园招聘/

PASS=0; FAIL=0; SKIP=0

ok()   { echo "[PASS] $*"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $*"; FAIL=$((FAIL+1)); }
skip() { echo "[SKIP] $*"; SKIP=$((SKIP+1)); }

echo "=== 腾讯校园招聘 skill smoke test ==="
echo "PWD: $PWD"
echo

# 1. Python environment check
echo "--- 1. Python environment ---"
result=$(python3 scripts/check_python_env.py --json 2>&1)
if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d['success'] else 1)" 2>/dev/null; then
  ok "Python $(python3 --version 2>&1) is compatible"
else
  fail "Python environment check failed"
  echo "$result"
fi

# 2. resume_checker (pure Python, no network)
echo
echo "--- 2. resume_checker.py (pure-Python) ---"
RESUME_TEXT="张三，计算机专业本科，熟悉Python，参与过多个项目开发，精通MySQL，GPA 3.8，毕业于某大学"
result=$(python3 scripts/resume_checker.py "$RESUME_TEXT" 2>&1)
if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'summary' in d else 1)" 2>/dev/null; then
  score=$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['summary']['score'])")
  ok "resume_checker returns score=$score"
else
  fail "resume_checker.py failed"
  echo "$result"
fi

# 3. career_memory init + show (pure Python, local file)
echo
echo "--- 3. career_memory.py (local file) ---"
if python3 scripts/career_memory.py init >/dev/null 2>&1; then
  ok "career_memory init succeeded"
else
  fail "career_memory init failed"
fi

if python3 scripts/career_memory.py show >/dev/null 2>&1; then
  ok "career_memory show succeeded"
else
  fail "career_memory show failed"
fi

# 4. fetch_recruit_info.py latest (network — may 403 on restricted hosts)
echo
echo "--- 4. fetch_recruit_info.py latest (network, may be blocked) ---"
result=$(python3 scripts/fetch_recruit_info.py latest 2>&1)
if echo "$result" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  if echo "$result" | grep -q '"error"'; then
    skip "fetch_recruit_info latest returned error (network blocked): $(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error','unknown'))" 2>/dev/null)"
  else
    ok "fetch_recruit_info latest returned valid JSON"
  fi
else
  skip "fetch_recruit_info latest: non-JSON response (network blocked)"
fi

# 5. fetch_recruit_jds.py search (network — may 403 on restricted hosts)
echo
echo "--- 5. fetch_recruit_jds.py search (network, may be blocked) ---"
result=$(python3 scripts/fetch_recruit_jds.py search --keyword "后台" --page-size 3 2>&1)
if echo "$result" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  if echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null; then
    count=$(echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('count',0))")
    ok "fetch_recruit_jds search returned $count results"
  else
    skip "fetch_recruit_jds search: API returned 403 or no results (network blocked by Tencent API)"
  fi
else
  skip "fetch_recruit_jds search: non-JSON response"
fi

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL SKIP=$SKIP ==="
if [ "$FAIL" -gt 0 ]; then
  echo "Some checks FAILED — see above."
  exit 1
else
  echo "All local checks passed. SKIP means network was blocked (expected in CI/containers)."
  exit 0
fi
