import 'dart:io';

import 'package:http/http.dart';

import '../auth/auth_provider.dart';
import '../util/build_info.dart';

class ApiClient extends BaseClient {
  final AuthProvider _auth;
  final Client _client = Client();
  final _userAgent = BuildInfo.userAgent;

  ApiClient(this._auth);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var response = await _client.send(
      request
        ..headers.addAll({
          HttpHeaders.userAgentHeader: _userAgent,
          HttpHeaders.acceptLanguageHeader: BuildInfo.locale,
          HttpHeaders.authorizationHeader: 'bearer ${_auth.token}',
        }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
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
