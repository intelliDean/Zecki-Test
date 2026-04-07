# ZecKit Devnet Startup Guide 🚀

This guide describes how to manage your local ZecKit Devnet using the CLI.

---

## ⚡ Quick Start

To spin up a Zebra regtest cluster with the Zaino backend (recommended for speed):
```bash
zeckit up --backend zaino
```

To use the Lightwalletd (lwd) backend:
```bash
zeckit up --backend lwd
```

---

## 📊 Service Status

Once the devnet is healthy, you can verify the status of the nodes using these standard endpoints:

- **Zebra Miner RPC**: `http://localhost:8232`
- **Faucet API**: `http://localhost:8080`
- **LWD/Indexer**: `http://localhost:9067`

### Checking Faucet Balance
The faucet automatically shields mining rewards. Check its available Orchard balance:
```bash
curl http://localhost:8080/stats
```

### Checking Current Block Height
```bash
curl -s http://localhost:8232 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"1.0","id":"1","method":"getblockcount","params":[]}' | jq .result
```

---

## 🛑 Stopping Devnet

To safely stop all containers and cleanup the network:
```bash
zeckit down
```

To stop **and** wipe all blockchain data (for a completely fresh start):
```bash
zeckit down --purge
```

---

## 🧪 Running Smoke Tests

To verify that the entire cluster is functional and can process shielded transactions:
```bash
# Performs a full end-to-end golden flow (Shield -> Send -> Balance Check)
zeckit test
```
