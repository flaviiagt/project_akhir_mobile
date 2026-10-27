// ignore_for_file: avoid_print
// Membuat wallet BARU khusus testnet.
// Jalankan dari folder proyek:  dart run tool/gen_wallet.dart
import 'dart:math';

import 'package:web3dart/web3dart.dart';

Future<void> main() async {
  final key = EthPrivateKey.createRandom(Random.secure());
  final address = await key.extractAddress();
  final hex = key.privateKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  print('ALAMAT      : ${address.hexEip55}');
  print('PRIVATE KEY : 0x$hex');
  print('');
  print('1) Isi saldo testnet Sepolia ke ALAMAT lewat faucet.');
  print('2) Salin PRIVATE KEY ke dart_defines.json (jangan di-commit).');
  print('Wallet ini khusus testnet. Jangan dipakai untuk uang asli.');
}
