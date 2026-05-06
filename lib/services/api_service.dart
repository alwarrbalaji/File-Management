// lib/services/api_service.dart
// ---------------------------------------------------------------------------
// All network communication with the Spring Boot backend lives here.
// Uses Dio for efficient HTTP calls and multipart uploads.
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file_item.dart';

// ============================================================================
//  ⚙️  CONFIGURATION — Get your computer's local IP address
//      Run `ipconfig` (Windows) or `ip a` (Linux/macOS) to find it.
//      Make sure your phone and PC are on the same WiFi network.
//      Port 8080 is the default Spring Boot server port.
// ============================================================================
String _kBaseUrl = 'http://192.168.31.152:8080'; // ← REPLACE WITH YOUR PC IP
// ============================================================================

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  // ── Dio client ────────────────────────────────────────────────────────────
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5), // large downloads
      sendTimeout: const Duration(minutes: 5), // large uploads
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(
      LogInterceptor(
        requestBody: false, // set true while debugging uploads
        responseBody: false,
        logPrint: (o) => debugPrintApiLog(o.toString()),
      ),
    );

  void debugPrintApiLog(String msg) {
    // ignore: avoid_print
    print('[ApiService] $msg');
  }

  // ── 1. GET /api/files — fetch file list ───────────────────────────────────
  Future<List<FileItem>> listFiles() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/files');
      final data = response.data;
      if (data == null) throw const ApiException('Empty response from server');

      return data
          .whereType<Map<String, dynamic>>()
          .map(FileItem.fromJson)
          .toList()
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── 2. POST /api/files/upload — upload a file ─────────────────────────────
  Future<void> uploadFile(
    File file, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken, // Added to allow cancelling uploads
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      await _dio.post(
        '/api/files/upload',
        data: formData,
        cancelToken: cancelToken,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const ApiException('Upload cancelled by user');
      }
      throw _mapDioError(e);
    }
  }

  // ── 3. GET /api/files/download/{filename} — download a file ──────────────
  Future<File> downloadFile(
    String filename, {
    required void Function(double progress) onProgress,
    CancelToken? cancelToken, // Added to allow cancelling downloads
  }) async {
    try {
      // Save to the device Downloads directory (or app cache as fallback)
      final dir = await _resolveDownloadDir();
      final savePath = '${dir.path}/$filename';

      // Encode the filename to safely handle spaces and special characters
      final encodedFilename = Uri.encodeComponent(filename);

      await _dio.download(
        '/api/files/download/$encodedFilename',
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      return File(savePath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const ApiException('Download cancelled by user');
      }
      throw _mapDioError(e);
    }
  }

  // ── 4. DELETE /api/files/delete/{filename} — delete a file ───────────────
  Future<void> deleteFile(String filename) async {
    try {
      final encodedFilename = Uri.encodeComponent(filename);
      await _dio.delete('/api/files/delete/$encodedFilename');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Resolve the best download directory depending on the platform.
  Future<Directory> _resolveDownloadDir() async {
    // Try the public Downloads folder first (Android only)
    if (Platform.isAndroid) {
      try {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) return dir;
      } catch (_) {}
    }

    // Fall back to the app's external storage directory
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) return extDir;

    // Ultimate fallback: app documents directory (always accessible)
    return getApplicationDocumentsDirectory();
  }

  /// Convert Dio errors into readable [ApiException]s.
  ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Connection timed out. Check that the server is running '
          'and your phone is on the same WiFi network.',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          'Cannot reach the server at $_kBaseUrl. '
          'Verify the IP address in api_service.dart and that '
          'the Spring Boot app is running.',
        );

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        String msg = e.response?.statusMessage ?? 'Unknown server error';
        
        // Attempt to extract the error message from Spring Boot's JSON response
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          msg = responseData['message'] as String;
        }

        return ApiException('Server returned $code: $msg', statusCode: code);

      default:
        return ApiException(e.message ?? 'An unexpected error occurred');
    }
  }
}