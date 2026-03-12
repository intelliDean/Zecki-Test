# ZecKit Sample Repo

> Reference implementation showing how to wire the
> [ZecKit E2E GitHub Action](https://github.com/marketplace/actions/zeckit-e2e)
> into a project's CI pipeline.

Move the contents of this folder to a new repository and push to GitHub.
The workflows run immediately without any extra configuration beyond a
`GITHUB_TOKEN` with `read:packages` scope (which every repo already has).

> **Note:** Workflows currently reference `intelliDean/ZecKit@m3-implementation`
> (the fork branch under review). Update all `uses:` lines to
> `zecdev/ZecKit@v1` after the PR is merged.

---

## Workflows

### [`ci.yml`](.github/workflows/ci.yml) — Normal CI

Runs on every push / PR to `main`.

| Job | Backend | `continue-on-error` | Merge-blocking |
|---|---|---|---|
| `e2e-lwd` | lightwalletd | no | **YES** |
| `e2e-zaino` | zaino | yes | no — experimental |
| `ci-gate` | — | — | Blocks on `e2e-lwd`; surfaces zaino signal in step summary |

### [`failure-drill.yml`](.github/workflows/failure-drill.yml) — Artifact Verification

Manual `workflow_dispatch` only. Injects two deterministic failures and
asserts that diagnostic artifacts are produced in both cases.

| Drill | Injected condition | Artifact of interest |
|---|---|---|
| `send-overflow` | `send_amount: 999.0` ZEC | `faucet-stats.json` (actual vs requested balance) |
| `startup-timeout` | `startup_timeout_minutes: 1` with lwd | Partial `lightwalletd.log` + `zebra.log` |

---

## Quick Start

```bash
# 1. Copy this folder to a new repo
cp -r sample/ /path/to/new-repo && cd /path/to/new-repo

# 2. Push to GitHub
git init && git add . && git commit -m "chore: add ZecKit E2E CI"
git remote add origin git@github.com:YOUR_ORG/YOUR_REPO.git
git push -u origin main
```

CI kicks off automatically on push. No secrets need to be added —
`GITHUB_TOKEN` is provided by GitHub Actions for every run.

---

## How to Configure Inputs

```yaml
- uses: intelliDean/ZecKit@m3-implementation   # → zecdev/ZecKit@v1 after merge
  with:
    backend:                 lwd          # 'lwd' or 'zaino'
    startup_timeout_minutes: '15'         # default 10
    block_wait_seconds:      '90'         # default 75
    send_amount:             '0.1'        # ZEC, default 0.05
    send_address:            ''           # empty = self-send (safe default)
    send_memo:               'My test'
    upload_artifacts:        on-failure   # 'always' | 'on-failure' | 'never'
    ghcr_token:              ${{ secrets.GITHUB_TOKEN }}
```

Full reference → [ZecKit docs/github-action.md](https://github.com/intelliDean/ZecKit/blob/m3-implementation/docs/github-action.md)

---

## Artifacts

When `upload_artifacts` is `always` or `on-failure` (default), a ZIP named
`zeckit-e2e-logs-<run_number>` is attached to the workflow run (retained 14 days).

| File | What it shows |
|---|---|
| `run-summary.json` | Backend, txids, balances, `test_result` |
| `faucet-stats.json` | Wallet balances at end of run |
| `zebra.log` | Full Zebra node output |
| `zaino.log` | Zaino indexer output |
| `lightwalletd.log` | Lightwalletd output |
| `faucet.log` | Faucet (Axum + Zingolib) output |
| `containers.log` | `docker ps -a` at teardown |
| `networks.log` | `docker network ls` at teardown |

```bash
# Download via CLI
gh run download <run-id> -n zeckit-e2e-logs-<run-number>
```

---

## Running the Failure Drill

1. Go to **Actions → Failure Drill – Artifact Collection Verification**
2. Click **Run workflow** → choose `both`, `send-overflow`, or `startup-timeout`
3. After completion, confirm both jobs show ✅ on **"Assert artifact was uploaded"**

A red ✗ on the *assert* step (not the E2E itself) means artifact collection
is broken. Check the action version and `upload_artifacts` input.

---

## Common Issues

| Symptom | Fix |
|---|---|
| lightwalletd job times out | Increase `startup_timeout_minutes` to `15`–`20` |
| Zaino experimental job fails | Check `e2e-zaino` logs; does not block CI |
| Artifacts not uploaded | Ensure `ghcr_token` has `read:packages` scope |
| Drill assert fails | Artifact collection broken; check action version |

Full troubleshooting → [docs/github-action.md](https://github.com/intelliDean/ZecKit/blob/m3-implementation/docs/github-action.md#common-failure-modes--troubleshooting)
# Zecki-Test
