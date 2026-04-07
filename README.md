# ZecKit Sample Repository 🧪

> A production-ready template and reference implementation for the
> [ZecKit E2E GitHub Action](https://github.com/marketplace/actions/zeckit-e2e).

This repository demonstrates how to integrate automated Zcash E2E tests into your own project's CI pipeline using ZecKit.

---

## 🛠️ Prerequisites

Before running tests locally, ensure you have the following installed:

1.  **Rust**: [Install Rust](https://www.rust-lang.org/tools/install)
2.  **ZecKit CLI**:
    ```bash
    cargo install zeckit
    ```
3.  **Docker**: ZecKit uses Docker Compose to orchestrate Zcash nodes.

---

## ⚡ Quick Start (Local Setup)

Clone this repository and run the integrated test suite to verify your environment.

```bash
# 1. Clone the sample repo
git clone https://github.com/intelliDean/zeckit-sample-test.git
cd zeckit-sample-test

# 2. Start the Devnet & Run E2E Tests
./test-local.sh
```

The `test-local.sh` script automatically detects your installed `zeckit` binary, spins up a Zebra Devnet, and executes the integrated [Example App](./example-app).

---

## 🖥️ CLI Usage Reference

Manage your local ZecKit Devnet using these standard commands.

### Starting Devnet
To spin up a Zebra regtest cluster with the Zaino backend (recommended for speed):
```bash
zeckit up --backend zaino
```

To use the Lightwalletd (lwd) backend:
```bash
zeckit up --backend lwd
```

### Checking Status
Once healthy, you can verify the nodes using these endpoints:
- **Zebra Miner RPC**: `http://localhost:8232`
- **Faucet API**: `http://localhost:8080` (Check balance: `curl http://localhost:8080/stats`)
- **LWD/Indexer**: `http://localhost:9067`

### Running Smoke Tests
To verify the entire cluster can process shielded transactions:
```bash
zeckit test
```

### Stopping Devnet
To safely stop all containers and cleanup:
```bash
zeckit down
```

To stop **and** wipe all blockchain data (for a completely fresh start):
```bash
zeckit down --purge
```

---

## 🚀 GitHub Actions Integration

To add ZecKit to your own repository's CI, simply reference the action in your `.github/workflows/ci.yml`.

```yaml
- name: 🚀 Run ZecKit Devnet
  uses: intelliDean/ZecKit@main
  with:
    backend: 'lwd'   # 'lwd' or 'zaino'
    startup_timeout_minutes: '15'
```

### Key Action Inputs
| Input | Description | Default |
|---|---|---|
| `backend` | The light-client indexer: 'lwd' or 'zaino' | `zaino` |
| `startup_timeout_minutes` | Time to wait for cluster health. | `10` |
| `send_amount` | Amount in ZEC for the golden flow. | `0.05` |

---

## 📋 Additional Resources

- **[Detailed Test Demo](./test_demo.md)**: Walkthrough of various testing methods.
- **[Integrated App](./example-app)**: A functional Node.js application demonstrating ZecKit connectivity.

---

## 🔍 Diagnostic Artifacts

ZecKit automatically attaches diagnostic logs to your GitHub Action runs when they fail. This makes debugging "Insufficient Balance" or "Sync Timeouts" easy.

| Artifact | Purpose |
|---|---|
| `zebra.log` | Full output from the Zebra node |
| `faucet.log` | Health and shielding logs from the faucet |
| `run-summary.json` | JSON output containing TXIDs and final balances |

---

## 🛡️ License

ZecKit and this sample repository are licensed under both **MIT** and **Apache 2.0**.
