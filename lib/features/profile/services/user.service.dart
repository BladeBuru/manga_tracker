import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';

import '../../../core/network/http_service.dart';
import '../../auth/exceptions/invalid_credentials.exception.dart';
import '../dto/user_information.dto.dart';

class UserService {
  final AuthService authService = getIt<AuthService>();
  final HttpService httpService = getIt<HttpService>();

  Future<UserService> init() async {
    return this;
  }

  Future<UserInformationDto> getUserInformation() async {
    Uri url = Uri.https(dotenv.env['MT_API_URL']!, '/user/information');
    Response response = await httpService.getWithAuthTokens(url);
    Map<String, dynamic> data = jsonDecode(response.body);
    return UserInformationDto.fromJson(data);
  }

  Future deleteAccount() async {
    final response = await httpService.deleteWithAuthTokens(
      Uri.https(dotenv.env['MT_API_URL']!, '/user/delete'),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        'Not authorized to access this resource',
      );
    } else {
      throw Exception(
        'HTTP Request failed with status: ${response.statusCode}.',
      );
    }
  }

  Future changePassword(password) async {
    final response = await httpService.putWithAuthTokens(
      Uri.https(dotenv.env['MT_API_URL']!, '/user/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == HttpStatus.ok) {
      return;
    } else if (response.statusCode == HttpStatus.forbidden) {
      throw InvalidCredentialsException(
        'Not authorized to access this resource',
      );
    } else {
      throw Exception(
        'HTTP Request failed with status: ${response.statusCode}.',
      );
    }
  }
}
