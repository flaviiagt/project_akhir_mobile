// Menyegel hash data pengguna ke blockchain (Ethereum Sepolia, testnet).
// Wallet penandatangan ada di server (secret), bukan di aplikasi, jadi
// pengguna tidak perlu wallet, saldo, atau mengerti blockchain.
//
//   supabase secrets set CHAIN_PRIVATE_KEY=0x...      (wallet khusus testnet!)
//   supabase secrets set CHAIN_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com   (opsional)
//   supabase functions deploy seal-record
import { ethers } from "npm:ethers@6";
import {
  adminClient,
  corsHeaders,
  json,
  logUsage,
  requireUser,
  underLimit,
} from "../_shared/common.ts";

const PREFIX = "STRIP1:"; // harus sama dengan kChainDataPrefix di aplikasi
const CHAIN_ID = 11155111;
const DAILY_LIMIT = 10;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method" }, 405);

  const admin = adminClient();
  const userId = await requireUser(req, admin);
  if (!userId) return json({ error: "auth" }, 401);

  let hash = "";
  try {
    hash = String((await req.json())?.hash ?? "").toLowerCase();
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  if (!/^[0-9a-f]{64}$/.test(hash)) return json({ error: "bad_request" }, 400);

  if (!(await underLimit(admin, userId, "seal", DAILY_LIMIT, 86400))) {
    return json({ error: "rate_limit" }, 429);
  }

  const pk = Deno.env.get("CHAIN_PRIVATE_KEY");
  if (!pk) return json({ error: "unavailable" }, 503);

  try {
    const rpc = Deno.env.get("CHAIN_RPC_URL") ??
      "https://ethereum-sepolia-rpc.publicnode.com";
    const provider = new ethers.JsonRpcProvider(rpc, CHAIN_ID, { staticNetwork: true });
    const wallet = new ethers.Wallet(pk, provider);

    if ((await provider.getBalance(wallet.address)) === 0n) {
      console.error("wallet testnet kosong:", wallet.address);
      return json({ error: "unavailable" }, 503);
    }

    // data transaksi = "STRIP1:" + 32 byte hash; 0 ETH ke wallet sendiri
    const data = ethers.hexlify(
      ethers.concat([ethers.toUtf8Bytes(PREFIX), "0x" + hash]),
    );
    const tx = await wallet.sendTransaction({ to: wallet.address, value: 0n, data });

    await logUsage(admin, userId, "seal");
    await admin.from("seal_records").insert({ user_id: userId, hash, tx_hash: tx.hash });
    return json({ txHash: tx.hash });
  } catch (e) {
    console.error("seal gagal:", String(e).slice(0, 300));
    return json({ error: "unavailable" }, 503);
  }
});
