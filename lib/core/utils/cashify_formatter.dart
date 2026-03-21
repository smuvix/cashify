import 'package:intl/intl.dart';

import '../../features/settings/domain/entities/user_settings_entity.dart';
import '../constants/currencies.dart';

class CashifyFormatter {
  CashifyFormatter(this._settings);

  final UserSettingsEntity _settings;

  String amountWithSymbol(double amount) {
    final symbol = symbolFor(_settings.currency);
    final sign = amount < 0 ? '-' : '';
    final absAmount = amount.abs();
    final fmt = NumberFormat('#,##0.00');
    return '$sign$symbol ${fmt.format(absAmount)}';
  }

  String amountWithCode(double amount) {
    final fmt = NumberFormat('#,##0.00');
    return '${fmt.format(amount)} ${_settings.currency}';
  }

  String amountCompact(double amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    final code = _settings.currency;
    if (abs >= 1_000_000_000) {
      return '$sign${(abs / 1_000_000_000).toStringAsFixed(1)}B $code';
    } else if (abs >= 1_000_000) {
      return '$sign${(abs / 1_000_000).toStringAsFixed(1)}M $code';
    }
    return amountWithCode(amount);
  }

  String date(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(dt.year, dt.month, dt.day);

    if (input == today) return 'Today';
    if (input == today.subtract(const Duration(days: 1))) return 'Yesterday';

    try {
      return DateFormat(_settings.dateFormat).format(dt);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(dt);
    }
  }

  String dateShort(DateTime dt) => DateFormat('d MMM').format(dt);

  String dateTime(DateTime dt) =>
      '${date(dt)}, ${DateFormat('HH:mm').format(dt)}';

  static String symbolFor(String code) =>
      kCurrencies[code.toUpperCase()]?.symbol ?? code;

  static String nameFor(String code) =>
      kCurrencies[code.toUpperCase()]?.name ?? code;
}
