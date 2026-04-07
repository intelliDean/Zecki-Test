# ZecKit Local Testing & Verification 🧪

This guide provides a step-by-step walkthrough of how to test the **ZecKit** toolkit using this sample repository. 

---

## 🛠️ Prerequisites

Ensure you have the following installed:

1.  **ZecKit CLI**:
    ```bash
    cargo install zeckit
    ```
2.  **Docker**: Ensure your Docker daemon is active (`docker ps` should work).

---

## 🏁 Option 1: The One-Command Verification (Recommended)

This repository includes a script that automates the entire process: spinning up the devnet, running the faucet, and executing the [Example Node.js App](./example-app).

```bash
# Simply run:
./test-local.sh
```

**What it does:**
1.  **Auto-Detects CLI**: It checks your system for a globally-installed `zeckit` binary. 🗺️
2.  **Devnet Up**: Starts a Zebra regtest cluster with the Zaino backend. 🦓
3.  **Faucet Shielding**: Automatically moving miner rewards to the Orchard shielded pool. 🛡️
4.  **App Verification**: Installs dependencies for the `example-app` and executes a safe transaction. ✅

---

## 🏗️ Option 2: Testing Local ZecKit CLI Changes

If you are a core developer working on the ZecKit CLI itself and want to test your local source code before publishing:

1.  **Build your local CLI**:
    ```bash
    cd ../ZecKit/cli
    cargo build --release
    ```

2.  **Run the local test runner**:
    ```bash
    # test-local.sh automatically detects your local build in ../ZecKit
    # and prioritizes it over the system-installed version.
    ./test-local.sh
    ```

---

## 🚀 Option 3: Integration Testing (Your Own App)

To test your own application against the running ZecKit devnet:

1.  **Start the devnet** (Terminal 1):
    ```bash
    zeckit up
    ```

2.  **Run your application** (Terminal 2):
    Point your application's light-client server to the ZecKit endpoints:
    - **Host**: `127.0.0.1`
    - **Port**: `9067` (default for Zaino/LWD)

3.  **Shut down** (Terminal 1):
    ```bash
    zeckit down --purge
    ```

---

## 🛠️ Troubleshooting

If services fail to start, try these common fixes:
- **Port Conflict**: Ensure ports `8232`, `8080`, and `9067` are not being used by other apps.
- **Docker Cleanup**: If the devnet stops working after a machine crash, run:
  ```bash
  zeckit down --purge
  ```
- **Miner Health**: Check logs if the faucet isn't receiving funds:
  ```bash
  docker logs zeckit-zebra-miner-1
  ```
