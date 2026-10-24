import 'package:intl/intl.dart';

final NumberFormat _rupiah =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String formatRupiah(int value) => _rupiah.format(value);

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
