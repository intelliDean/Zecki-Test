# ZecKit Local Development Demo

This guide walks you through testing the **ZecKit** toolkit using this sample repo.

## Prerequisites

- **ZecKit CLI**: Must be built in the core project folder:
  ```bash
  # From within the zeckit-sample-test directory
  cd ../ZecKit/cli
  cargo build --release
  ```
- **Docker**: Must be installed and running. ZecKit uses Docker Compose to orchestrate the devnet.
  ```bash
  # Verify Docker is running
  docker compose version
  ```

---

## Method 1: Local Application Development (Integrated)

The repository includes an `example-app/` directory. You can test your local `ZecKit` binary by running this app against it.

1.  **Navigate to the example app**:
    ```bash
    cd example-app
    ```

2.  **Run the application**:
    ```bash
    npm install
    npm start
    ```
    *This script connects to a running ZecKit devnet. Ensure you have run `zeckit up` in the background first.*

---

## Method 2: Seamless Dual-Linkage (For 'act' or Local Workflows)

This allows you to test the actual GitHub Actions YAML using your local code.

1.  **Activate Local Linkage**:
    ```bash
    ./link-local.sh
    ```
    *This creates a symlink to your local ZecKit project. The workflows are configured to detect and prioritize this link.*

2.  **Run with `act`**:
    ```bash
    act -W .github/workflows/ci.yml
    ```

3.  **Deactivate (Optional)**:
    If you want to revert to testing the remote repository version:
    ```bash
    rm .zeckit-action
    ```

---

## Method 3: Running the Example App Manually

If you want to iterate on the application code itself while the devnet is running:

1.  **Start the devnet** (in one terminal):
    ```bash
    ./test-local.sh zaino
    ```
    *Wait until you see "Starting E2E tests..."*

2.  **Run the app** (in a second terminal):
    ```bash
    cd example-app
    npm install   # Only needed once
    npm start
    ```

---

---

## Milestone 1 Verification: The Foundation

Milestone 1 focuses on the orchestration engine, health checks, and repository standards. Follow these steps to verify that the core ZecKit foundations are solid.

### 1. Local Orchestration & Health Checks
Prove that the CLI can spin up a healthy Zebra regtest cluster with one command.

1.  **Navigate to the ZecKit CLI folder**:
    ```bash
    cd ../ZecKit/cli
    ```

2.  **Start the devnet**:
    ```bash
    cargo run -- up --backend zaino
    ```

3.  **Verify Success**:
    - The terminal should show readiness signals: `✓ Zebra Miner ready`, `✓ Zebra Sync node ready`, etc.
    - The command should finish with: `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ZecKit Devnet ready  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`

### 2. CI Smoke Test Validation
Verify that the repository includes a "fail-fast" smoke test to detect unhealthy clusters in CI.

1.  **Check GitHub Actions**: Look for the **Smoke Test** workflow in the ZecKit repository.
2.  **Logic**: This job verifies that all 3 nodes (Zebra, Faucet, Indexer) are reachable and report basic metadata in < 5 minutes.

### 3. Repository Standards Check
Ensure the repository meets the official Zcash community bootstrapping requirements.

- **Legal**: Check for `LICENSE-MIT` and `LICENSE-APACHE`.
- **Onboarding**: Verify `CONTRIBUTING.md` exists.
- **Support**: Check `.github/ISSUE_TEMPLATE/bug_report.md`.
- **Technical**: Review `specs/technical-spec.md` and `specs/acceptance-tests.md`.

---
- **Docker Errors**: Ensure the Docker daemon is running.
  - Check status: `docker compose ps`
  - Restart services: `docker compose restart`
  - Deep clean (if volumes are corrupted): `docker system prune -a --volumes`
