import 'package:dio/dio.dart';

class UsersAPI {
  final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000/users',
      connectTimeout: 5000,
      receiveTimeout: 3000,
    ),
  );

  UsersAPI();

  Future<Response> getUserbyID(id) async {
    Response user;
    try {
      user = await _dio.get('/$id');
    } on DioError catch (e) {
      user = e.response;
    }
    return user;
  }

  Future<Response> getAllUsers() async {
    Response user;
    try {
      user = await _dio.get('');
    } on DioError catch (e) {
      user = e.response;
    }
    return user;
  }

  Future<Response> createUser(user) async {
    Response response;
    try {
      response = await _dio.post('', data: {
        'user': user
      });
    } on DioError catch (e) {
      response = e.response;
    }
    return response;
  }
}
