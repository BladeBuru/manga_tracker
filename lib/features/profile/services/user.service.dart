import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';

import '../../../core/network/http_service.dart';
import '../dto/user_information.dto.dart';

class UserService {
  HttpService httpService = getIt<HttpService>();

  Future<UserService> init() async {
    return this;
  }

  Future<UserInformationDto> getUserInformation() async {
    Uri url = Uri.https(dotenv.env['MT_API_URL']!, '/user/information');
    Response response = await httpService.getWithAuthTokens(url);
    Map<String, dynamic> data = jsonDecode(response.body);
    return UserInformationDto.fromJson(data);
  }
}
