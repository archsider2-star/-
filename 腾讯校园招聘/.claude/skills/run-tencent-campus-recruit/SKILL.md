---
name: run-tencent-campus-recruit
description: Run, test, or smoke-check the 腾讯校园招聘 skill scripts. Use when asked to run, start, test, verify, or screenshot the tencent-campus-recruit skill, or to confirm that scripts like fetch_recruit_jds.py, resume_checker.py, or career_memory.py work correctly.
---

This is the **腾讯校园招聘** Claude Code skill — a collection of Python CLI scripts that interact with Tencent's public recruiting APIs (`join.qq.com`). There is no GUI or server; the driver is `smoke.sh`, a smoke script that exercises each script and reports pass/skip/fail.

All paths below are relative to `腾讯校园招聘/` (the unit root).

## Prerequisites

No extra `apt-get` packages needed. Python 3.10+ is required (standard on Ubuntu 20.04+).

Verify environment:

```bash
python3 scripts/check_python_env.py
```

Expected: `"success": true`, Python 3.10–3.13.

## Run (agent path) — smoke driver

Run from the `腾讯校园招聘/` directory:

```bash
bash .claude/skills/run-tencent-campus-recruit/smoke.sh
```

Expected output on a clean container:

```
=== Results: PASS=5 FAIL=0 SKIP=1 ===
All local checks passed. SKIP means network was blocked (expected in CI/containers).
```

The `SKIP` for `fetch_recruit_jds.py` is normal: Tencent's API returns HTTP 403 to non-browser HTTP clients (no cookies/session). `FAIL` means a pure-Python script broke.

## Run individual scripts

### Resume checker (pure-Python, always works)

```bash
python3 scripts/resume_checker.py "简历文本内容放这里"
```

Returns JSON with `summary.score` and per-rule `details`. Verified score=57 for a short sample.

### Career memory (local file, always works)

```bash
python3 scripts/career_memory.py init    # create career-memory/campus-recruit-memory.md
python3 scripts/career_memory.py show    # print current memory
python3 scripts/career_memory.py append  # interactive append
python3 scripts/career_memory.py forget  # delete memory
```

Memory file lives at `career-memory/campus-recruit-memory.md` relative to CWD.

### Fetch recruiting info (network, may 403)

```bash
python3 scripts/fetch_recruit_info.py latest
python3 scripts/fetch_recruit_info.py notices
python3 scripts/fetch_recruit_info.py flow "投递后多久有回复" --question-time "2026-05-21 12:00:00"
python3 scripts/fetch_recruit_info.py talks
python3 scripts/fetch_recruit_info.py families
```

### Fetch job descriptions (network, may 403)

```bash
python3 scripts/fetch_recruit_jds.py search --keyword 后台 --page-size 10
python3 scripts/fetch_recruit_jds.py all --max-pages 50 --page-size 100
python3 scripts/fetch_recruit_jds.py detail <post_id>
python3 scripts/fetch_recruit_jds.py match "Python 后台 深圳"
```

## Gotchas

- **`fetch_recruit_jds.py` returns 403 in containers/CI.** Tencent's `join.qq.com` API blocks requests with non-browser User-Agent or without a valid session cookie. The smoke script marks this as SKIP, not FAIL. On a real user machine with a browser session these calls succeed.
- **`fetch_recruit_info.py notices` returns 403** but `latest` returns empty JSON `{}` — both indicate blocked network, not a script bug.
- **`career_memory.py init` writes to CWD**, not the script's directory. Always run scripts from `腾讯校园招聘/` so `career-memory/campus-recruit-memory.md` lands in the right place.
- **No `requirements.txt`** — all scripts use only Python stdlib. No `pip install` needed.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ModuleNotFoundError` on any script | Scripts use only stdlib; check Python version with `python3 --version` (need 3.10+) |
| `fetch_recruit_jds.py` returns `{"success": false, ... "HTTP 403"}` | Expected on restricted networks; not a bug |
| `career_memory.py` writes file to wrong place | Run from `腾讯校园招聘/` directory, not from `scripts/` |
| smoke.sh exits 1 with FAIL | Check which step failed; `resume_checker.py` and `career_memory.py` should never fail |
