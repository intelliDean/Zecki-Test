/**
 * ZecKit Devnet "Happy Path" Example & Multi-Wallet E2E Verification
 * 
 * This script demonstrates how a downstream application interacts with the local
 * ZecKit Regtest Cluster. It verifies the faucet's stats, and then orchestrates
 * a multi-wallet transaction flow (Alice -> Bob) using dynamic wallets.
 */

const FAUCET_API = "http://127.0.0.1:8080";
const ZEBRA_RPC = "http://127.0.0.1:8232";

async function mineBlocks(count) {
    console.log(`   ⏳ Mining ${count} blocks for confirmation...`);
    try {
        await fetch(ZEBRA_RPC, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                jsonrpc: "2.0",
                id: "generate",
                method: "generate",
                params: [count]
            })
        });
        // Give indexers and wallets a moment to index the new blocks
        await new Promise(r => setTimeout(r, 4000));
    } catch (e) {
        console.warn(`   ⚠️ Manual mining trigger skipped/failed: ${e.message}`);
    }
}

async function runHappyPath() {
    console.log("==================================================");
    console.log("🔌 Connecting to ZecKit Devnet Faucet API...");
    console.log("==================================================\n");

    try {
        // 1. Check Faucet Status & Balance
        console.log("🔍 1. Checking Faucet Default Wallet Balance...");
        const statsResponse = await fetch(`${FAUCET_API}/stats`);

        if (!statsResponse.ok) {
            throw new Error(`Faucet API returned ${statsResponse.status}: Are you sure ZecKit Devnet is running?`);
        }

        const stats = await statsResponse.json();
        console.log(`✅ Success! Faucet Default Wallet has:`);
        console.log(`   - Transparent Balance: ${stats.transparent_balance} ZEC`);
        console.log(`   - Orchard Balance:    ${stats.orchard_balance} ZEC\n`);

        // 2. Spawn Wallet Alice
        console.log("👤 2. Spawning Wallet 'app-alice'...");
        const aliceCreateRes = await fetch(`${FAUCET_API}/wallets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ wallet_id: "app-alice" })
        });
        const aliceCreate = await aliceCreateRes.json();
        console.log(`   Status: ${aliceCreate.status}\n`);

        // 3. Get Alice's Address
        console.log("📬 3. Retrieving 'app-alice' Address...");
        const aliceAddrRes = await fetch(`${FAUCET_API}/wallets/app-alice/address`);
        const aliceAddr = await aliceAddrRes.json();
        console.log(`   Transparent Address: ${aliceAddr.transparent_address}`);
        console.log(`   Unified Address:     ${aliceAddr.unified_address.substring(0, 30)}...\n`);

        // 4. Fund Alice from Faucet Default Wallet
        const fundAmount = 0.5;
        console.log(`💸 4. Funding 'app-alice' with ${fundAmount} ZEC...`);
        const fundRes = await fetch(`${FAUCET_API}/send`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                address: aliceAddr.transparent_address,
                amount: fundAmount,
                memo: "Funding Alice transparently"
            })
        });
        const fundResult = await fundRes.json();
        if (!fundResult.txid) {
            throw new Error(`Funding transaction failed: ${JSON.stringify(fundResult)}`);
        }
        console.log(`   Sent. TXID: ${fundResult.txid}`);
        
        // Mine confirmation blocks
        await mineBlocks(5);

        // 5. Sync and Verify Alice's Balance
        console.log("🔄 5. Syncing and verifying 'app-alice' balance...");
        await fetch(`${FAUCET_API}/wallets/app-alice/sync`, { method: 'POST' });
        const aliceStatsRes = await fetch(`${FAUCET_API}/wallets/app-alice/stats`);
        const aliceStats = await aliceStatsRes.json();
        console.log(`   app-alice Transparent Balance: ${aliceStats.transparent_balance} ZEC`);
        if (aliceStats.transparent_balance <= 0) {
            throw new Error("app-alice did not receive the transparent funds.");
        }
        console.log("   ✓ Verified Alice transparent balance!\n");

        // 6. Shield Alice's Funds to Orchard
        console.log("🛡️ 6. Shielding Alice's transparent funds to Orchard...");
        const shieldRes = await fetch(`${FAUCET_API}/wallets/app-alice/shield`, { method: 'POST' });
        const shieldResult = await shieldRes.json();
        if (shieldResult.status !== "shielded") {
            throw new Error(`Shielding failed: ${JSON.stringify(shieldResult)}`);
        }
        console.log(`   Shielding TXID: ${shieldResult.txid}`);

        // Mine confirmation blocks
        await mineBlocks(5);

        // Sync Alice post-shield
        await fetch(`${FAUCET_API}/wallets/app-alice/sync`, { method: 'POST' });
        const aliceStatsPostShieldRes = await fetch(`${FAUCET_API}/wallets/app-alice/stats`);
        const aliceStatsPostShield = await aliceStatsPostShieldRes.json();
        console.log(`   app-alice Orchard Balance: ${aliceStatsPostShield.orchard_balance} ZEC`);
        if (aliceStatsPostShield.orchard_balance <= 0) {
            throw new Error("app-alice Orchard balance is 0 after shielding.");
        }
        console.log("   ✓ Verified Alice Orchard balance!\n");

        // 7. Spawn Wallet Bob
        console.log("👤 7. Spawning Wallet 'app-bob'...");
        const bobCreateRes = await fetch(`${FAUCET_API}/wallets`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ wallet_id: "app-bob" })
        });
        const bobCreate = await bobCreateRes.json();
        console.log(`   Status: ${bobCreate.status}\n`);

        // 8. Get Bob's Unified Address
        console.log("📬 8. Retrieving 'app-bob' address...");
        const bobAddrRes = await fetch(`${FAUCET_API}/wallets/app-bob/address`);
        const bobAddr = await bobAddrRes.json();
        console.log(`   Unified Address: ${bobAddr.unified_address.substring(0, 30)}...\n`);

        // 9. Send Shielded Funds from Alice to Bob
        const sendAmount = 0.1;
        console.log(`💸 9. Sending ${sendAmount} ZEC (shielded) from Alice to Bob...`);
        const sendRes = await fetch(`${FAUCET_API}/wallets/app-alice/send`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                address: bobAddr.unified_address,
                amount: sendAmount,
                memo: "Secret transfer from Alice"
            })
        });
        const sendResult = await sendRes.json();
        if (!sendResult.txid) {
            throw new Error(`Secret transfer failed: ${JSON.stringify(sendResult)}`);
        }
        console.log(`   Sent. TXID: ${sendResult.txid}`);

        // Mine confirmation blocks
        await mineBlocks(5);

        // 10. Sync Bob and Verify Balance
        console.log("🔄 10. Syncing and verifying 'app-bob' balance...");
        await fetch(`${FAUCET_API}/wallets/app-bob/sync`, { method: 'POST' });
        const bobStatsRes = await fetch(`${FAUCET_API}/wallets/app-bob/stats`);
        const bobStats = await bobStatsRes.json();
        console.log(`    app-bob Orchard Balance: ${bobStats.orchard_balance} ZEC`);
        if (bobStats.orchard_balance <= 0) {
            throw new Error("app-bob did not receive the shielded funds.");
        }
        
        console.log("\n🎉 Run completed successfully! The regtest network successfully processed the multi-wallet transfer.");
        console.log("   Alice successfully sent Orchard shielded funds to Bob.");

    } catch (e) {
        console.error("\n❌ ERROR:", e.message);
        process.exit(1);
    }
}

runHappyPath();
