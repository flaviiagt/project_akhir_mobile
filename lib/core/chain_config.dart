

/// Endpoint JSON-RPC publik (hanya untuk membaca / verifikasi).
const String kChainRpcUrl = String.fromEnvironment(
  'CHAIN_RPC_URL',
  defaultValue: 'https://ethereum-sepolia-rpc.publicnode.com',
);

/// Ethereum Sepolia (testnet).
const int kChainId = 11155111;
const String kChainName = 'Ethereum Sepolia (testnet)';
const String kChainExplorerTx = 'https://sepolia.etherscan.io/tx/';

/// Penanda di awal data transaksi: "STRIP1:" + 32 byte hash SHA-256.
const String kChainDataPrefix = 'STRIP1:';
