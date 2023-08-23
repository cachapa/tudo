import 'dart:io';

import 'package:http/http.dart';

import '../util/build_info.dart';

class ApiClient extends BaseClient {
  final String? _token;
  final Client _client = Client();
  final _userAgent = BuildInfo.userAgent;

  ApiClient([this._token]);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var response = await _client.send(
      request
        ..headers.addAll({
          HttpHeaders.userAgentHeader: _userAgent,
          HttpHeaders.acceptLanguageHeader: BuildInfo.locale,
          if (_token != null) HttpHeaders.authorizationHeader: 'bearer $_token',
        }),
    );

    if (response.statusCode ~/ 100 != 2) {
      final body = (await Response.fromStream(response)).body;
      throw ApiError(response.statusCode, body);
    }

    return response;
  }
}

class ApiError {
  final int statusCode;
  final String body;

  ApiError(this.statusCode, this.body);

  @override
  String toString() => '$statusCode $body';
}
