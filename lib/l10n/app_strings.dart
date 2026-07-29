import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import 'package:provider/provider.dart';

/// Central translation class. All UI strings go here.
/// Usage: AppStrings.of(context).settingsTitle
class AppStrings {
  final String languageCode;
  const AppStrings(this.languageCode);

  static AppStrings of(BuildContext context) {
    final locale = Provider.of<LocaleService>(context, listen: false);
    return AppStrings(locale.languageCode);
  }

  static AppStrings listen(BuildContext context) {
    final locale = Provider.of<LocaleService>(context);
    return AppStrings(locale.languageCode);
  }

  bool get _isVi => languageCode == 'vi';

  // ── App General ───────────────────────────────────────────────
  String get appTitle => _isVi ? 'Nỗi Sợ Biển Sâu' : 'Deep Sea Fear';
  String get settings => _isVi ? 'Cài đặt' : 'Settings';
  String get language => _isVi ? 'Ngôn ngữ' : 'Language';
  String get back => _isVi ? 'Quay lại' : 'Back';

  // ── Settings Screen ────────────────────────────────────────────
  String get settingsTitle => _isVi ? 'CÀI ĐẶT' : 'SETTINGS';
  String get settingsThankyouTitle =>
      _isVi ? 'Lời Cảm Ơn' : 'Thank You';
  String get settingsThankyouBody => _isVi
      ? 'Cảm ơn bạn đã tải và trải nghiệm Nỗi Sợ Biển Sâu!\n\nApp được xây dựng với niềm đam mê về đại dương và những bí ẩn thâm sâu dưới đáy biển. Chúng tôi hy vọng hành trình khám phá này mang lại cho bạn những trải nghiệm thú vị và kiến thức bổ ích về thế giới đại dương huyền bí.'
      : 'Thank you for downloading and experiencing Deep Sea Fear!\n\nThis app was built with passion for the ocean and the mysteries hidden in its depths. We hope this journey of exploration brings you exciting experiences and fascinating knowledge about the mysterious world of the deep sea.';
  String get settingsContactTitle =>
      _isVi ? 'Thắc mắc & Liên hệ' : 'Questions & Contact';
  String get settingsContactBody =>
      _isVi ? 'Nếu bạn có thắc mắc, góp ý hoặc phát hiện lỗi, hãy liên hệ với chúng tôi qua email:'
          : 'If you have any questions, feedback or found a bug, please contact us via email:';
  String get settingsVersion => _isVi ? 'Phiên bản' : 'Version';
  String get settingsLanguageTitle =>
      _isVi ? 'Ngôn Ngữ Hiển Thị' : 'Display Language';

  // ── Dashboard / Cockpit ────────────────────────────────────────
  String get cockpitTitle => _isVi ? 'COCKPIT ĐIỀU KHIỂN' : 'COCKPIT CONTROL DECK';
  String get systemActive =>
      _isVi ? 'HỆ THỐNG TRẮC ĐỊA BIỂN SÂU: ĐANG HOẠT ĐỘNG' : 'DEEP SEA GEODESY SYSTEM: ACTIVE';
  String get commandModules =>
      _isVi ? 'COMMAND DECK SYSTEM MODULES' : 'COMMAND DECK SYSTEM MODULES';
  String get backToObserver =>
      _isVi ? 'TRỞ LẠI KÍNH QUAN SÁT' : 'BACK TO OBSERVER';
  
  // Dashboard Telemetry
  String get recordDepth => _isVi ? 'ĐỘ SÂU KỶ LỤC' : 'RECORD DEPTH';
  String get hullPressure => _isVi ? 'ÁP SUẤT VỎ TÀU' : 'HULL PRESSURE';
  String get safe => _isVi ? 'AN TOÀN' : 'SAFE';
  String get creatureDecoded => _isVi ? 'GIẢI MÃ SINH VẬT' : 'DECODED CREATURES';
  String get transmissionFreq => _isVi ? 'TẦN SỐ TRUYỀN' : 'TRANSMISSION FREQ';

  // Module Details
  String get moduleMapTitle => _isVi ? 'BẢN ĐỒ ĐẠI DƯƠNG' : 'OCEAN MAP';
  String get moduleMapDesc => _isVi ? 'Hệ thống quét hải đồ & lưu vực biển toàn cầu' : 'Global marine basin & chart scanning system';
  
  String get moduleSimulatorTitle => _isVi ? 'MÔ PHỎNG LẶN' : 'DIVE SIMULATOR';
  String get moduleSimulatorDesc => _isVi ? 'Báo cáo độ bền cơ cấu vỏ tàu và dưỡng khí Oxy dưới vực sâu' : 'Deep sea hull structural integrity & oxygen reporting';
  
  String get moduleSonarTitle => _isVi ? 'SONAR DÒ QUÉT' : 'SONAR SCANNER';
  String get moduleSonarDesc => _isVi ? 'Thu nhận tín hiệu âm học sinh học, phát hiện sinh vật cổ đại' : 'Biological acoustic telemetry & ancient creature detection';
  
  String get moduleLogbookTitle => _isVi ? 'NHẬT KÝ THUYỀN TRƯỞNG' : 'CAPTAIN\'S LOGBOOK';
  String get moduleLogbookDesc => _isVi ? 'Giải mã lưu trữ phân tích hồ sơ sinh vật biển sâu' : 'Decoded archives & deep sea creature profiles analysis';

  // ── Home Screen ────────────────────────────────────────────────
  String get homeTitle => _isVi ? 'NỖI SỢ BIỂN SÂU' : 'DEEP SEA FEAR';
  String get homeSubtitle =>
      _isVi ? 'Khám phá vực thẳm' : 'Explore the abyss';
  String get startDivePrompt => _isVi ? 'BẮT ĐẦU LẶN XUỐNG' : 'START DESCENDING';
  String get scrollInstruction =>
      _isVi ? 'Cuộn để bắt đầu chìm vào thế giới nước sâu...' : 'Scroll to start sinking into the deep water...';
  String get deepestPointReached => _isVi
      ? 'Bạn đã chạm tới điểm sâu nhất của vỏ Trái Đất. Phía dưới này chỉ còn bóng tối tuyệt đối, áp suất nghiền nát vạn vật và những tiếng vọng kỳ bí chưa có lời giải đáp từ lòng đất thẳm.'
      : 'You have reached the deepest point of the Earth\'s crust. Below is only absolute darkness, crushing pressure, and mysterious, unexplained echoes from the deep earth.';
  String get backToSurface => _isVi ? 'TRỞ LẠI MẶT NƯỚC' : 'RETURN TO SURFACE';
  
  String get tapToScan => _isVi ? '[ BẤM ĐỂ QUÉT TÍN HIỆU ADS ]' : '[ TAP TO SCAN ADS SIGNAL ]';
  String get viewSpecs => _isVi ? '[ XEM THÔNG SỐ & SO SÁNH SIZE ] ➔' : '[ VIEW SPECS & SIZE COMPARISON ] ➔';
  
  String get unlockTitle => _isVi ? 'Mở Khóa Vực Sâu' : 'Unlock Deep Abyss';
  String get unlockBody => _isVi ? 'Bạn có muốn xem một video quảng cáo ngắn để mở khóa hồ sơ sinh vật này?' : 'Would you like to watch a short promotional video to unlock this creature profile?';
  String get cancel => _isVi ? 'HỦY' : 'CANCEL';
  String get watchAd => _isVi ? 'XEM QUẢNG CÁO' : 'WATCH AD';
  String get loadingSponsor => _isVi ? 'Đang kết nối nhà tài trợ...' : 'Connecting to sponsor...';
  String get pleaseWait => _isVi ? 'Vui lòng đợi 3 giây...' : 'Please wait 3 seconds...';
  String get unlockSuccess => _isVi ? 'Đã mở khóa thành công!' : 'Successfully unlocked!';

  // ── Logbook ────────────────────────────────────────────────────
  String get logbookTitle => _isVi ? 'NHẬT KÝ THUYỀN TRƯỞNG' : 'CAPTAIN\'S LOGBOOK';
  String get tabCreatures => _isVi ? 'HỒ SƠ SINH VẬT' : 'CREATURE FILES';
  String get tabMedals => _isVi ? 'HUÂN CHƯƠNG LẶN' : 'DIVING MEDALS';
  String get locked => _isVi ? 'ĐÃ KHÓA' : 'LOCKED';
  String get unlocked => _isVi ? 'ĐÃ MỞ' : 'UNLOCKED';

  // ── Ocean Map ──────────────────────────────────────────────────
  String get oceanMapTitle =>
      _isVi ? 'HỆ THỐNG BẢN ĐỒ RADAR' : 'RADAR MAP SYSTEM';
  String get radarActive =>
      _isVi ? 'TRẠNG THÁI: LIÊN KẾT HỆ THỐNG VỆ TINH RADAR HOẠT ĐỘNG'
          : 'STATUS: SATELLITE RADAR LINK ACTIVE';
  String get viewAbyss =>
      _isVi ? 'CHIÊM NGƯỠNG LÒNG VỰC SÂU' : 'VIEW THE ABYSS';
  String get signalLocked => _isVi ? 'SIGNAL LOCKED' : 'SIGNAL LOCKED';
  String get radarScan => _isVi ? 'QUÉT TÍN HIỆU ĐẠI DƯƠNG' : 'OCEAN SIGNAL SCAN';
  String get radarInstruction =>
      _isVi ? 'Vui lòng chạm vào các điểm radar nhấp nháy trên bản đồ vệ tinh để thu thập dữ liệu.'
          : 'Tap the blinking radar hotspots on the satellite map to collect ocean data.';

  // ── Sonar ──────────────────────────────────────────────────────
  String get sonarTitle => _isVi ? 'MÁY QUÉT SONAR' : 'SONAR SCANNER';

  // ── Simulator ─────────────────────────────────────────────────
  String get simulatorTitle =>
      _isVi ? 'MÔ PHỎNG LẶN' : 'DIVE SIMULATOR';
  String get depth => _isVi ? 'ĐỘ SÂU' : 'DEPTH';
  String get oxygen => _isVi ? 'OXY' : 'OXYGEN';
  String get hull => _isVi ? 'VỎ TÀU' : 'HULL';
  String get energy => _isVi ? 'NĂNG LƯỢNG' : 'ENERGY';
  String get startDive => _isVi ? 'BẮT ĐẦU LẶN' : 'START DIVE';
  String get ascending => _isVi ? 'ĐANG TRỒI LÊN...' : 'ASCENDING...';
  String get gameOver => _isVi ? 'NHIỆM VỤ THẤT BẠI' : 'MISSION FAILED';
  String get redive => _isVi ? 'LẶN LẠI' : 'RE-DIVE';

  // ── Detail Screen ──────────────────────────────────────────────
  String get realCreature => _isVi ? '🔬 SINH VẬT CÓ THẬT' : '🔬 REAL CREATURE';
  String get mythCreature => _isVi ? '🔥 HUYỀN THOẠI VỰC THẲM' : '🔥 ABYSS LEGEND';
  String get dangerLevel => _isVi ? 'MỨC ĐỘ NGUY HIỂM' : 'DANGER LEVEL';
  String get soundLabel => _isVi ? 'NGHE TIẾNG' : 'PLAY SOUND';
  String get stopSound => _isVi ? 'DỪNG PHÁT' : 'STOP';

  // ── Ad-Free Settings ──────────────────────────────────────────
  String get adFreeSectionTitle => _isVi ? 'TẮT QUẢNG CÁO' : 'REMOVE ADS';
  String get adFreeActiveTitle => _isVi ? 'ĐÃ TẮT QUẢNG CÁO' : 'ADS REMOVED';
  String get settingsAdFreeActiveBodyPrefix => _isVi
      ? 'Quảng cáo đã được tạm tắt thành công.\nThời gian còn lại: '
      : 'Ads have been temporarily disabled successfully.\nRemaining time: ';
  String get adFree30Mins => _isVi ? '30 Phút' : '30 Minutes';
  String get adFree2Hours => _isVi ? '2 Giờ' : '2 Hours';
  String get adFreeButtonLabel => _isVi ? 'Tắt ' : 'Remove ';
  String get adFreeSuccessMsg30Mins => _isVi
      ? 'Kích hoạt tắt quảng cáo trong 30 Phút thành công!'
      : 'Ads removed for 30 Minutes successfully!';
  String get adFreeSuccessMsg2Hours => _isVi
      ? 'Kích hoạt tắt quảng cáo trong 2 Giờ thành công!'
      : 'Ads removed for 2 Hours successfully!';
  String get adFreeFailedMsg => _isVi
      ? 'Không thể tải video quảng cáo. Vui lòng thử lại sau!'
      : 'Failed to load rewarded ad. Please try again later!';
}
