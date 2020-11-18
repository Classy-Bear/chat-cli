import 'package:dio/dio.dart';

class UserAPI {
  final String _url;
  Dio _dio;

  UserAPI(this._url) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _url,
        connectTimeout: 5000,
        receiveTimeout: 3000,
      ),
    );
  }

  Future<Response> createUser(String user) async {
    Response response;
    try {
      response = await _dio.post('/users', data: {
        'user': user,
      });
    } on DioError catch (e) {
      response = e.response;
    }
    return response;
  }

  Future<Response> getAllUsers() async {
    Response response;
    try {
      response = await _dio.get('/users');
    } on DioError catch (e) {
      response = e.response;
    }
    return response;
  }

  Future<Response> getUserbyID(String id) async {
    Response response;
    try {
      response = await _dio.get('/users/$id');
      ;
    } on DioError catch (e) {
      response = e.response;
    }
    return response;
  }
}
