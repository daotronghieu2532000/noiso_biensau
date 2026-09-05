import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingService {
  static const String _keyHasRated = 'rating_has_rated';
  static const String _keyLastShown = 'rating_last_shown';
  static const String _keyLaunchCount = 'rating_launch_count';
  static const String _keyFirstLaunchDate = 'rating_first_launch_date';

  /// Tăng số lần mở ứng dụng và lưu mốc ngày đầu mở app
  static Future<void> incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyLaunchCount) ?? 0;
    await prefs.setInt(_keyLaunchCount, current + 1);

    if (prefs.getInt(_keyFirstLaunchDate) == null) {
      await prefs.setInt(
          _keyFirstLaunchDate, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Kiểm tra điều kiện đủ để hiển thị popup đánh giá
  static Future<bool> shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Đã đánh giá rồi -> Không bao giờ hiển thị lại nữa
    bool hasRated = prefs.getBool(_keyHasRated) ?? false;
    if (hasRated) return false;

    // 2. Kiểm tra số ngày từ khi cài đặt (Tối thiểu 2 ngày) OR số lần mở app (>= 3 lần)
    int? firstLaunchMs = prefs.getInt(_keyFirstLaunchDate);
    int launchCount = prefs.getInt(_keyLaunchCount) ?? 0;

    bool passTimeCondition = false;
    if (firstLaunchMs != null) {
      DateTime firstLaunch =
          DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
      if (DateTime.now().difference(firstLaunch).inDays >= 2) {
        passTimeCondition = true;
      }
    }

    if (!passTimeCondition && launchCount < 3) {
      return false;
    }

    // 3. Nếu từng bấm "Để sau", khoảng cách giữa 2 lần hiển thị tối thiểu 7 ngày
    int? lastShownMs = prefs.getInt(_keyLastShown);
    if (lastShownMs != null) {
      DateTime lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      if (DateTime.now().difference(lastShown).inDays < 7) {
        return false;
      }
    }

    return true;
  }

  /// Đánh dấu đã đánh giá -> Không bao giờ hiện lại nữa
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRated, true);
  }

  /// Ghi nhận vừa hiển thị popup (để tính khoảng cách 7 ngày nếu bấm Để sau)
  static Future<void> recordPopupShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastShown, DateTime.now().millisecondsSinceEpoch);
  }

  /// Điều hướng tới trang App Store của ứng dụng Nối Số Biển Sâu
  static Future<void> launchAppStore() async {
    const urlStr =
        'https://apps.apple.com/vn/app/deep-see-submarine-simulator/id6773557703?l=vi';
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Hiển thị Popup Đánh giá Dialog
  static void showRatingPopup(BuildContext context) {
    recordPopupShown();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const RatingDialog(),
    );
  }
}

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 0;

  bool _isEnglish() {
    final locale = Platform.localeName.toLowerCase();
    return locale.startsWith('en');
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _isEnglish();

    final titleText = isEn
        ? 'Enjoying Deep Sea Simulator'
        : 'Hãy góp ý cho chúng tôi nhé';

    final subText = isEn
        ? 'Tap a star to rate us on the App Store.'
        : 'Chạm vào một ngôi sao để xếp hạng App.';

    final laterText = isEn ? 'Not Now' : 'Để sau';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF071325),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 28),
            // Logo App bo góc chuẩn phong cách Đáy Biển
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF020813),
                      child: const Icon(
                        Icons.sailing_rounded,
                        color: Color(0xFF00F0FF),
                        size: 42,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                titleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Mô tả phụ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hàng 5 ngôi sao tương tác
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  int starValue = index + 1;
                  bool isHighlighted = starValue <= _selectedStars;
                  return GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _selectedStars = starValue;
                      });
                    },
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      await RatingService.markAsRated();
                      await RatingService.launchAppStore();
                    },
                    child: AnimatedScale(
                      scale: isHighlighted ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isHighlighted
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isHighlighted
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        size: 34,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 26),

            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),

            // Nút "Để sau" / "Not Now"
            InkWell(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  laterText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
