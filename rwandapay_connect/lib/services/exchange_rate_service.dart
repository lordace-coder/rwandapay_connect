import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const double fallbackRate = 1300.0;
  static double? _cachedRate;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 2);

  static Future<double> getUsdToRwfRate() async {
    // Return cached rate if still valid
    if (_cachedRate != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedRate!;
      }
    }

    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['RWF'] as num).toDouble();
        _cachedRate = rate;
        _cacheTime = DateTime.now();
        return rate;
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Try backup API
    try {
      final response = await http
          .get(Uri.parse('https://www.frankfurter.app/latest?from=USD&to=RWF'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates']['RWF'] as num).toDouble();
        _cachedRate = rate;
        _cacheTime = DateTime.now();
        return rate;
      }
    } catch (_) {
      // Fall through to fallback
    }

    _cachedRate = fallbackRate;
    _cacheTime = DateTime.now();
    return fallbackRate;
  }

  static double calculateFee(double amountUsd) {
    final fee = amountUsd * 0.015; // 1.5%
    return fee < 1.0 ? 1.0 : fee; // minimum $1.00
  }

  static double convertToRwf(double amountUsd, double rate) {
    return amountUsd * rate;
  }
}
