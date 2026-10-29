import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FeedbackResult {
  final bool isSuccess;
  final String message;

  FeedbackResult({required this.isSuccess, required this.message});
}

class FeedbackService {
  static const String apiUrl = 'https://codego.io.vn/api/submit_feedback.php';

  /// Gửi đóng góp ý kiến, trải nghiệm đánh giá hoặc góc nhìn lên server
  static Future<FeedbackResult> submitFeedback({
    String? userName,
    String? userEmail,
    required int rating,
    required String feedbackType,
    String? title,
    required String content,
  }) async {
    try {
      final String osInfo = Platform.isIOS
          ? 'iOS ${Platform.operatingSystemVersion}'
          : Platform.isAndroid
              ? 'Android ${Platform.operatingSystemVersion}'
              : Platform.operatingSystem;

      final bodyData = {
        'user_name': userName?.trim().isNotEmpty == true ? userName!.trim() : 'Ẩn danh Thủy Thủ',
        if (userEmail != null && userEmail.trim().isNotEmpty) 'user_email': userEmail.trim(),
        'rating': rating.clamp(1, 5),
        'feedback_type': feedbackType,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'content': content.trim(),
        'device_info': '$osInfo — DeepSee v1.0.0',
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: json.encode(bodyData),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['success'] == true) {
          return FeedbackResult(
            isSuccess: true,
            message: decoded['message'] ?? 'Ý kiến đóng góp đã được gửi thành công!',
          );
        } else {
          return FeedbackResult(
            isSuccess: false,
            message: decoded['message'] ?? 'Không thể ghi nhận phản hồi, vui lòng thử lại.',
          );
        }
      } else {
        return FeedbackResult(
          isSuccess: false,
          message: 'Lỗi máy chủ (${response.statusCode}). Vui lòng thử lại sau.',
        );
      }
    } catch (e) {
      return FeedbackResult(
        isSuccess: false,
        message: 'Lỗi kết nối mạng: Vui lòng kiểm tra lại đường truyền internet.',
      );
    }
  }
}
