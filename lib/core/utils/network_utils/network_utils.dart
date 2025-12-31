// import 'package:angelina_app/core/utils/constants/constants.dart';
// import 'package:dio/dio.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// class NetworkUtils {
//   static const String _baseURL = AppConstants.baseUrl;

//   static late Dio _dio;

//   static Future<void> init() async {
//     _dio = Dio();
//     _dio.options.baseUrl = _baseURL;
//     _dio.options.validateStatus = (v) => v! < 500;
//     _dio.interceptors.add(PrettyDioLogger());
//   }

//   static Future<Response<dynamic>> post(
//     String path, {
//     Object? data,
//     Map<String, dynamic>? headers,
//   }) async {
//     return _dio.post(path, data: data, options: Options(headers: headers));
//   }

//   static Future<Response<dynamic>> patch(
//     String path, {
//     Object? data,
//     Map<String, dynamic>? headers,
//   }) async {
//     return _dio.patch(path, data: data, options: Options(headers: headers));
//   }

//   static Future<Response<dynamic>> get(
//     String path, {
//     Map<String, dynamic>? headers,
//   }) async {
//     return _dio.get(path, queryParameters: headers);
//   }

//   static Future<Response<dynamic>> delete(
//     String path, {
//     Map<String, dynamic>? headers,
//     Object? data,
//   }) async {
//     return _dio.delete(path, queryParameters: headers, data: data);
//   }

//   static Future<Response<dynamic>> put(
//     String path, {
//     Object? data,
//     Map<String, dynamic>? headers,
//   }) async {
//     return _dio.put(path, data: data, options: Options(headers: headers));
//   }
// }
