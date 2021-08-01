import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:crypto/crypto.dart';
import '../data/spot_classes.dart';
import '../apiKey.dart' as apiKey;
import 'exceptions.dart';

class Spot {
  var public = apiKey.public;
  var secret = apiKey.secret;

  Future<dynamic> _private(String path, [Map<String, String?>? params]) async {
    final uri = Uri.https('api.binance.com', 'api$path', params);

    final response = await http.get(uri, headers: {
      'X-MBX-APIKEY': public,
      'Acess-Control-Alllow-Origin': '*',
    });

    final result = convert.jsonDecode(response.body);

    if (result is Map) if (result.containsKey("code"))
      throw BinanceApiException(result["msg"], result["code"]);

    return result;
  }

  Digest signRequest(Map params) {
    var queryString = Uri(
        queryParameters: params.map((key, value) =>
            MapEntry(key, value == null ? null : value.toString()))).query;
    var key = convert.utf8.encode(secret);
    var bytes = convert.utf8.encode(queryString);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);

    return digest;
  }

  Future<bool> _hasError(String path, String? pub, String? sec,
      [Map<String, String?>? params]) async {
    final uri = Uri.https('api.binance.com', 'api$path', params);

    final response = await http.get(uri, headers: {
      'X-MBX-APIKEY': pub!,
      'Acess-Control-Alllow-Origin': '*',
    });

    final result = convert.jsonDecode(response.body);

    if (result is Map) if (result.containsKey("code")) return true;

    return false;
  }

  /// Returns general info about the account from /v3/account
  ///
  /// https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#account-information-user_data
  Future<AccountInfo> accountInfo(
    int time, {
    int? recvWindow,
  }) async {
    final params = {'timestamp': '$time'};

    params['recvWindow'] = '60000';
    params['signature'] = '${signRequest(params)}';

    final response = await _private('/v3/account', params);

    return AccountInfo.fromMap(response);
  }

  Future<bool> accountExists(
    int time,
    String? pub,
    String? sec, {
    int? recvWindow,
  }) async {
    final params = {'timestamp': '$time'};

    params['recvWindow'] = '60000';
    params['signature'] = '${signRequest(params)}';

    bool error = await _hasError('/v3/account', pub, sec, params);

    if (error) return false;
    public = pub!;
    secret = sec!;

    return true;
  }
}
