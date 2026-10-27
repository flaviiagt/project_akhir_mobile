/// Pengaturan blockchain (testnet). JANGAN menulis private key di kode.
/// Kunci diberikan saat menjalankan aplikasi:
///   flutter run --dart-define-from-file=dart_defines.json
/// (lihat BLOCKCHAIN.md). Pakai wallet khusus testnet, bukan wallet berisi uang asli.
const String kChainPrivateKey = String.fromEnvironment('CHAIN_PRIVATE_KEY');

/// Endpoint JSON-RPC jaringan. Bisa diganti lewat --dart-define=CHAIN_RPC_URL=...
/// kalau endpoint bawaan sedang bermasalah.
const String kChainRpcUrl = String.fromEnvironment(
  'CHAIN_RPC_URL',
  defaultValue: 'https://ethereum-sepolia-rpc.publicnode.com',
);

/// Ethereum Sepolia (testnet).
const int kChainId = 11155111;
const String kChainName = 'Ethereum Sepolia (testnet)';
const String kChainExplorerTx = 'https://sepolia.etherscan.io/tx/';
const String kChainExplorerAddress = 'https://sepolia.etherscan.io/address/';

/// Penanda di awal data transaksi: "STRIP1:" + 32 byte hash SHA-256.
const String kChainDataPrefix = 'STRIP1:';
