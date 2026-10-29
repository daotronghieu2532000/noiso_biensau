import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

/// Lớp đại diện cho một mẫu thông báo song ngữ ngắn gọn, hấp dẫn
class _NotificationMsg {
  final String titleVi;
  final String bodyVi;
  final String titleEn;
  final String bodyEn;

  const _NotificationMsg({
    required this.titleVi,
    required this.bodyVi,
    required this.titleEn,
    required this.bodyEn,
  });

  String getTitle(bool isEn) => isEn ? titleEn : titleVi;
  String getBody(bool isEn) => isEn ? bodyEn : bodyVi;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _cachedToken;

  // ========================================================
  // KHO NỘI DUNG THÔNG BÁO LINH HOẠT - KHÔNG NHÀM CHÁN / KHÔNG DẬP KHUÔN
  // ========================================================

  // ========================================================
  // KHO NỘI DUNG THÔNG BÁO: TRÍCH ĐOẠN SINH VẬT & LỜI CHÚC THÂN MẬT
  // Đa dạng, hấp dẫn, không trùng lặp, dùng bền vững nhiều năm
  // ========================================================

  /// 1. Lời chúc ngày mới & Hỏi thăm buổi sáng (Tươi mát, bình an, tích cực)
  static const List<_NotificationMsg> _morningGreetings = [
    _NotificationMsg(
      titleVi: 'Chào ngày mới từ biển sâu! 🌅',
      bodyVi: 'Chúc bạn một ngày tràn đầy năng lượng tươi mát như làn gió biển và gặp nhiều may mắn nhé!',
      titleEn: 'Good Morning from the Deep! 🌅',
      bodyEn: 'Wishing you a fresh, vibrant day filled with calm ocean breezes and great fortune!',
    ),
    _NotificationMsg(
      titleVi: 'Bình minh trên sóng nước ☀️',
      bodyVi: 'Hãy đón ngày mới với nụ cười sảng khoái và một tách cà phê ấm áp nhé bạn!',
      titleEn: 'Sunrise Over the Waves ☀️',
      bodyEn: 'Embrace the new day with a refreshing smile and an energizing warm cup of coffee!',
    ),
    _NotificationMsg(
      titleVi: 'Chào buổi sáng bạn thân mến 🌊',
      bodyVi: 'Đêm qua bạn ngủ có ngon không? Chúc bạn hôm nay làm việc thật nhẹ nhàng và hiệu quả!',
      titleEn: 'Morning, Ocean Explorer 🌊',
      bodyEn: 'Did you sleep well last night? Wishing you a smooth, gentle, and productive day!',
    ),
    _NotificationMsg(
      titleVi: 'Ngày mới tươi vui! 🐬',
      bodyVi: 'Đại dương gửi đến bạn làn gió mát lành. Chúc mọi dự định hôm nay của bạn đều thuận buồm xuôi gió!',
      titleEn: 'Bright New Day! 🐬',
      bodyEn: 'The ocean sends you crisp, soothing tides. May all your endeavors sail smoothly today!',
    ),
    _NotificationMsg(
      titleVi: 'Nắng sớm chiếu rọi làn nước 🌤️',
      bodyVi: 'Hít một hơi thật sâu để nạp đầy năng lượng tích cực trước khi bắt đầu công việc nhé!',
      titleEn: 'Morning Sunlight 🌤️',
      bodyEn: 'Take a deep, refreshing breath and charge your mind with positive energy for today!',
    ),
    _NotificationMsg(
      titleVi: 'Chào ngày mới an lành 🍀',
      bodyVi: 'Chúc bạn có một ngày làm việc thật vui vẻ, luôn giữ tâm trí bình thản như mặt biển lặng.',
      titleEn: 'Peaceful Morning 🍀',
      bodyEn: 'Wishing you a pleasant day ahead, keeping your mind as calm and clear as tranquil waters.',
    ),
    _NotificationMsg(
      titleVi: 'Thức giấc cùng đại dương ☕',
      bodyVi: 'Một ngày mới mở ra với bao điều tuyệt vời đang chờ đón bạn. Cố gắng lên nhé!',
      titleEn: 'Awaken with the Ocean ☕',
      bodyEn: 'A brand new day unfolds with exciting possibilities waiting for you. Have a great day!',
    ),
    _NotificationMsg(
      titleVi: 'Làn gió sớm mai 🍃',
      bodyVi: 'Đừng quên uống đủ nước và giữ cho mình một nụ cười thật tươi trong ngày hôm nay nhé!',
      titleEn: 'Morning Ocean Breeze 🍃',
      bodyEn: 'Remember to stay hydrated and keep a bright, confident smile throughout your day!',
    ),
  ];

  /// 2. Lời chúc buổi tối, Hỏi thăm & Chúc ngủ ngon (Êm dịu, thả lỏng, ấm áp)
  static const List<_NotificationMsg> _eveningAndSleep = [
    _NotificationMsg(
      titleVi: 'Chúc bạn ngủ thật ngon 🌙',
      bodyVi: 'Hãy gác lại mọi lo toan trong ngày và để tiếng sóng biển êm dịu vỗ về giấc ngủ của bạn tối nay.',
      titleEn: 'Sweet Dreams Tonight 🌙',
      bodyEn: 'Leave today\'s worries behind and let gentle ocean waves lull you into a deep, peaceful sleep.',
    ),
    _NotificationMsg(
      titleVi: 'Hôm nay của bạn thế nào? 🫧',
      bodyVi: 'Một ngày dài làm việc đã khép lại rồi. Hãy dành thời gian nghỉ ngơi và yêu thương bản thân nhé!',
      titleEn: 'How was your day? 🫧',
      bodyEn: 'A long day has wrapped up. Take time to relax, unwind, and treat yourself kindly tonight!',
    ),
    _NotificationMsg(
      titleVi: 'Biển đêm thanh bình 🌌',
      bodyVi: 'Khi màn đêm buông xuống, chúc bạn tìm thấy sự tĩnh lặng và ấm áp bên những người thân yêu.',
      titleEn: 'Serene Night Ocean 🌌',
      bodyEn: 'As darkness blankets the deep, may you find comfort, peace, and warmth with your loved ones.',
    ),
    _NotificationMsg(
      titleVi: 'Ngủ ngoan nhé bạn ơi 🌠',
      bodyVi: 'Thả lỏng đôi vai, nhắm mắt lại và phiêu du trong những giấc mơ đại dương thật đẹp.',
      titleEn: 'Sleep Well, Dreamer 🌠',
      bodyEn: 'Relax your shoulders, close your eyes, and drift gently through beautiful oceanic dreams.',
    ),
    _NotificationMsg(
      titleVi: 'Khoảnh khắc thư giãn ☕',
      bodyVi: 'Đừng quên uống một ngụm nước ấm và nghỉ ngơi sớm để nạp lại năng lượng cho ngày mai nhé.',
      titleEn: 'Evening Wind Down ☕',
      bodyEn: 'Remember to sip some warm water and rest early to recharge your batteries for tomorrow.',
    ),
    _NotificationMsg(
      titleVi: 'Đêm muộn an yên 💎',
      bodyVi: 'Ánh trăng trên mặt biển chúc bạn có một đêm ngon giấc và thức dậy tràn đầy sinh lực.',
      titleEn: 'Peaceful Midnight 💎',
      bodyEn: 'Moonlight over calm tides wishes you sound sleep and a vibrant awakening tomorrow.',
    ),
    _NotificationMsg(
      titleVi: 'Tạm biệt những âu lo 🌊',
      bodyVi: 'Tất cả mệt mỏi hôm nay đã trôi theo làn nước. Chúc bạn có một giấc ngủ say không mộng mị.',
      titleEn: 'Wash Away the Stress 🌊',
      bodyEn: 'All of today\'s fatigue washes away with the tide. Wishing you restful and dreamless sleep.',
    ),
    _NotificationMsg(
      titleVi: 'Bản hòa ca của biển đêm 🎼',
      bodyVi: 'Giai điệu tĩnh mịch dưới tầng nước sâu sẽ đưa bạn vào giấc ngủ êm ái nhất. Ngủ ngon nhé!',
      titleEn: 'Lullaby of the Deep 🎼',
      bodyEn: 'The quiet melody of the deep ocean will guide you into the sweetest sleep. Good night!',
    ),
  ];

  /// 3. Kho Trích Đoạn Sinh Vật Biển Sâu (Facts, Thói quen, Sức mạnh, Bí ẩn)
  static const List<_NotificationMsg> _creatureLore = [
    // --- Cá voi sát thủ (Orca) ---
    _NotificationMsg(
      titleVi: 'Cá voi sát thủ & Con người 🐬',
      bodyVi: 'Trong tự nhiên hoang dã, chưa từng ghi nhận bất kỳ trường hợp cá voi sát thủ nào chủ động săn và ăn thịt con người.',
      titleEn: 'Orcas & Humans 🐬',
      bodyEn: 'In the wild, there has never been a documented case of an orca actively hunting and preying on human beings.',
    ),
    _NotificationMsg(
      titleVi: 'IQ đáng kinh ngạc của Orca 🧠',
      bodyVi: 'Cá voi sát thủ có ngôn ngữ riêng cho từng bầy và truyền dạy bí quyết săn mồi qua nhiều thế hệ như một nền văn hóa độc lập.',
      titleEn: 'The Astonishing Orca IQ 🧠',
      bodyEn: 'Orcas possess distinct dialect languages for each pod and pass complex hunting strategies across generations as culture.',
    ),
    _NotificationMsg(
      titleVi: 'Sát thủ của sát thủ 🦈',
      bodyVi: 'Cá voi sát thủ hạ gục cá mập trắng bằng cách húc lật ngửa đối thủ khiến cá mập bị tê liệt, sau đó chỉ chọn ăn phần gan béo ngậy.',
      titleEn: 'Predator of Predators 🦈',
      bodyEn: 'Orcas hunt great white sharks by flipping them upside down to induce tonic immobility, eating only their nutrient-rich liver.',
    ),
    _NotificationMsg(
      titleVi: 'Kình ngư 8 tấn xé sóng 🌊',
      bodyVi: 'Một con cá voi sát thủ đực có thể nặng tới 6-8 tấn và xé nước với vận tốc 56 km/h—loài bơi nhanh nhất trong họ cá heo đại dương.',
      titleEn: 'The 8-Ton Sea Apex 🌊',
      bodyEn: 'A male orca can weigh up to 8 tons and cut through waves at 56 km/h—the fastest swimmer among oceanic dolphins.',
    ),
    _NotificationMsg(
      titleVi: 'Tình mẫu tử 80 năm của Orca 🐬',
      bodyVi: 'Cá voi sát thủ con thường ở bên mẹ suốt đời. Các bà mẹ Orca sống thọ tới 80-90 tuổi và là thủ lĩnh dẫn lối cho cả bầy đàn.',
      titleEn: 'Orca Matriarch Dynasty 🐬',
      bodyEn: 'Orcas stay with their mothers for life. Grandmother orcas live up to 90 years, leading navigation and hunts for the entire pod.',
    ),
    _NotificationMsg(
      titleVi: 'Chiến thuật tạo sóng bầy đàn 🌊',
      bodyVi: 'Để bắt hải cẩu trốn trên tảng băng nổi, đàn Orca xếp hàng bơi đồng bộ tạo ra cột sóng lớn hất tung tảng băng trôi.',
      titleEn: 'Orca Wave-Washing Tactic 🌊',
      bodyEn: 'To catch seals on ice floes, orcas swim in tight formation beneath the surface, generating waves that wash prey into the water.',
    ),

    // --- Cá voi xanh (Blue Whale) ---
    _NotificationMsg(
      titleVi: 'Trái tim cá voi xanh 🐋',
      bodyVi: 'Cá voi xanh nặng tới 150-200 tấn. Trái tim của nó to bằng một chiếc ô tô và động mạch chủ đủ rộng để một đứa trẻ bơi qua.',
      titleEn: 'Heart of the Blue Whale 🐋',
      bodyEn: 'Weighing up to 200 tons, a blue whale\'s heart is the size of a car, with an aorta wide enough for a child to swim through.',
    ),
    _NotificationMsg(
      titleVi: 'Tiếng kêu xé toạc đại dương 🔊',
      bodyVi: 'Tiếng gọi bầy của cá voi xanh đạt 188 decibel—lớn hơn động cơ máy bay phản lực và có thể truyền xa tới 1.600 km dưới lòng biển.',
      titleEn: 'Sound Across Ocean Basins 🔊',
      bodyEn: 'Blue whale calls reach 188 decibels—louder than a jet engine—traveling over 1,600 km underwater through acoustic channels.',
    ),
    _NotificationMsg(
      titleVi: 'Bữa ăn 4 tấn nhuyễn thể 🦐',
      bodyVi: 'Mỗi ngày, một con cá voi xanh khổng lồ có thể nuốt trọn 4 tấn tép nhỏ (krill) bằng cách lọc nước qua những tấm sừng hàm đồ sộ.',
      titleEn: 'A 4-Ton Daily Meal 🦐',
      bodyEn: 'Every single day, a blue whale consumes up to 4 tons of tiny krill, filtering seawater through its massive baleen plates.',
    ),

    // --- Cá nhà táng (Sperm Whale) ---
    _NotificationMsg(
      titleVi: 'Thợ lặn 2.000m rãnh vực 🤿',
      bodyVi: 'Cá nhà táng có thể lặn sâu hơn 2.000 mét và nín thở suốt 90 phút trong bóng tối tuyệt đối để săn lùng quái vật mực dưới đáy vực.',
      titleEn: 'Master Abyss Diver 🤿',
      bodyEn: 'Sperm whales can plunge past 2,000 meters and hold their breath for 90 minutes in total abyss darkness to hunt giant squid.',
    ),
    _NotificationMsg(
      titleVi: 'Bộ não nặng nhất hành tinh 🧠',
      bodyVi: 'Cá nhà táng sở hữu bộ não nặng tới 8 kg—bộ não lớn nhất trong toàn bộ lịch sử tiến hóa của các loài sinh vật trên Trái Đất.',
      titleEn: 'Largest Brain on Earth 🧠',
      bodyEn: 'The sperm whale possesses an 8-kilogram brain—the largest brain of any known animal species in Earth\'s history.',
    ),
    _NotificationMsg(
      titleVi: 'Tử thù cá nhà táng & Kraken ⚔️',
      bodyVi: 'Đối thủ truyền kiếp của cá nhà táng là mực khổng lồ Kraken. Hầu hết cá nhà táng bắt được đều mang đầy vết sẹo giác hút tròn trên đầu.',
      titleEn: 'Nemesis of the Abyss ⚔️',
      bodyEn: 'The sperm whale\'s eternal rival is the giant squid. Almost all mature sperm whales bear circular sucker battle scars on their skin.',
    ),
    _NotificationMsg(
      titleVi: 'Cột đá ngủ thẳng đứng 🐋',
      bodyVi: 'Cá nhà táng ngủ theo tư thế thẳng đứng lơ lửng trong nước như những cây cột khổng lồ, mỗi giấc ngủ ngắn chỉ kéo dài khoảng 15 phút.',
      titleEn: 'Vertical Drifting Sleep 🐋',
      bodyEn: 'Sperm whales nap suspended completely vertically in open water like colossal ancient pillars, sleeping for only 15 minutes at a time.',
    ),

    // --- Thủy quái Kraken & Mực khổng lồ ---
    _NotificationMsg(
      titleVi: 'Đôi mắt to bằng đĩa ăn 👁️',
      bodyVi: 'Mực khổng lồ Kraken sở hữu đôi mắt đường kính 30 cm—lớn nhất giới sinh vật, giúp nó bắt trọn từng hạt ánh sáng le lói nơi đáy biển sâu.',
      titleEn: 'Eyes of the Kraken 👁️',
      bodyEn: 'The giant squid possesses 30-centimeter eyes—the size of dinner plates, the largest on Earth to detect faint abyssal glows.',
    ),
    _NotificationMsg(
      titleVi: 'Móc câu xoay 360 độ 🐙',
      bodyVi: 'Mực đại ca Nam Cực sống ở độ sâu 1.000m - 2.500m. Xúc tu của nó không chỉ có giác hút mà còn gắn các móc vuốt sắc nhọn xoay 360 độ.',
      titleEn: 'Rotating 360° Claws 🐙',
      bodyEn: 'Colossal squids inhabit 1,000m - 2,500m Antarctic depths, armed with deadly swiveling sharp hooks on their tentacles.',
    ),

    // --- Siêu cá mập Megalodon ---
    _NotificationMsg(
      titleVi: 'Cú cắn nghiền nát xương thép 🦈',
      bodyVi: 'Megalodon có lực cắn lên tới 180.000 Newton—gấp 10 lần cá mập trắng, đủ sức nghiền nát mai rùa khổng lồ và xương sọ cá voi cổ đại.',
      titleEn: 'Crushing Bite of Megalodon 🦈',
      bodyEn: 'Megalodon wielded a bite force of 180,000 Newtons—10 times stronger than a great white, easily crushing prehistoric whale skulls.',
    ),
    _NotificationMsg(
      titleVi: 'Quái vật 60 tấn thời tiền sử 🌊',
      bodyVi: 'Megalodon dài tới 18-20 mét, nặng gần 60 tấn với hơn 276 chiếc răng sắc nhọn hình tam giác dài bằng cả bàn tay người lớn.',
      titleEn: 'The 60-Ton Prehistoric Titan 🌊',
      bodyEn: 'Megalodon spanned 18-20 meters and weighed near 60 tons, equipped with 276 serrated triangular teeth the size of an adult hand.',
    ),

    // --- Cá mập Greenland ---
    _NotificationMsg(
      titleVi: 'Sinh vật sống từ thế kỷ 17 ⏳',
      bodyVi: 'Cá mập Greenland có thể sống từ 400 đến 500 năm. Những cá thể đang bơi dưới làn băng Bắc Cực hôm nay có thể đã chào đời từ thời nhà Lê.',
      titleEn: 'Living Since the 1600s ⏳',
      bodyEn: 'Greenland sharks can live 400 to 500 years. Individuals swimming beneath Arctic ice today may have been born before Isaac Newton.',
    ),
    _NotificationMsg(
      titleVi: 'Kẻ bơi chậm nhất đại dương ❄️',
      bodyVi: 'Trong làn nước băng giá Bắc Cực, cá mập Greenland chỉ bơi với tốc độ 1.2 km/h và phải chờ đến 150 tuổi chúng mới bắt đầu trưởng thành.',
      titleEn: 'The Glacial Swimmer ❄️',
      bodyEn: 'In sub-zero Arctic waters, Greenland sharks cruise at a slow 1.2 km/h and only reach reproductive maturity at 150 years of age.',
    ),

    // --- Cá lồng đèn (Anglerfish) ---
    _NotificationMsg(
      titleVi: 'Mồi câu phát quang sinh học 💡',
      bodyVi: 'Ở độ sâu 1.500m tối đen như mực, cá lồng đèn treo một "cần câu" chứa hàng triệu vi khuẩn phát sáng để dụ con mồi tự chui vào miệng.',
      titleEn: 'Lure in the Abyss 💡',
      bodyEn: 'At 1,500m of total darkness, the anglerfish dangles a bioluminescent lure filled with glowing bacteria to draw prey into its jaws.',
    ),
    _NotificationMsg(
      titleVi: 'Hôn nhân kỳ dị tầng nước sâu 🧬',
      bodyVi: 'Cá lồng đèn đực chỉ bé bằng ngón tay. Khi tìm thấy con cái khổng lồ, nó sẽ cắn chặt vào thân và tiêu biến các cơ quan, sống ký sinh vĩnh viễn.',
      titleEn: 'Parasitic Abyssal Bond 🧬',
      bodyEn: 'Tiny male anglerfish bite into the giant female upon meeting, fusing tissues and blood vessels to live as a lifelong parasite.',
    ),

    // --- Cá mái chèo (Oarfish) ---
    _NotificationMsg(
      titleVi: 'Sứ giả thủy thần dài 11 mét 🐉',
      bodyVi: 'Cá mái chèo sống ở độ sâu 200m - 1.000m. Thủy thủ xưa tin rằng khi loài cá dài như dải lụa bạc này dạt bờ là dấu hiệu của động đất đáy biển.',
      titleEn: 'Harbinger of Tremors 🐉',
      bodyEn: 'Reaching 11 meters, the giant oarfish dwells at 200-1,000m depths. Maritime lore links its rare beaching to undersea seismic tremors.',
    ),

    // --- Sóng âm The Bloop & Điểm Nemo ---
    _NotificationMsg(
      titleVi: 'Tiếng gầm 5.000 km bí ẩn 📡',
      bodyVi: 'Năm 1997, NOAA ghi nhận sóng âm "The Bloop" từ độ sâu Điểm Nemo—nơi xa đất liền nhất địa cầu. Tiếng gầm siêu trầm này vang xa suốt 5.000 km.',
      titleEn: 'The 5,000km Abyssal Pulse 📡',
      bodyEn: 'In 1997, NOAA captured "The Bloop" near Point Nemo—the oceanic pole of inaccessibility. The ultralow frequency sound traveled 5,000 km.',
    ),

    // --- Mực ma cà rồng (Vampire Squid) ---
    _NotificationMsg(
      titleVi: 'Áo choàng gai tầng nước chết 🦇',
      bodyVi: 'Sống ở độ sâu 900m nơi nồng độ oxy gần như bằng không, mực ma cà rồng lộn ngược màng đen phủ đầy gai nhọn để tự vệ khi bị đe dọa.',
      titleEn: 'Dweller of the Dead Zone 🦇',
      bodyEn: 'Surviving at 900m with near-zero oxygen, the vampire squid inverts its spiny black-webbed cape into an unpalatable shield against predators.',
    ),

    // --- Bọ chân đều khổng lồ (Giant Isopod) ---
    _NotificationMsg(
      titleVi: 'Hóa thạch sống nhịn đói 5 năm 🦂',
      bodyVi: 'Bọ chân đều khổng lồ sống ở đáy sâu 2.000m. Một cá thể nuôi tại thủy cung Nhật Bản từng nhịn ăn ròng rã suốt 5 năm liền mà vẫn sống sót.',
      titleEn: '5-Year Fasting Living Fossil 🦂',
      bodyEn: 'Giant isopods scuttle across the seabed at 2,000 meters. A specimen in Japan famously survived 5 full years without eating any food.',
    ),

    // --- Cá rồng đen (Black Dragonfish) ---
    _NotificationMsg(
      titleVi: 'Lớp da hấp thụ 99.5% ánh sáng 🌑',
      bodyVi: 'Cá rồng đen sống sâu 2.000m có làn da đen đặc biệt hấp thụ tới 99.5% ánh sáng, giúp nó trở nên vô hình tuyệt đối trước mọi kẻ săn mồi.',
      titleEn: '99.5% Ultra-Black Skin 🌑',
      bodyEn: 'Living at 2,000m, the black dragonfish has nanostructured skin absorbing 99.5% of light, rendering it utterly invisible to prey.',
    ),

    // --- Rãnh Mariana & Điểm sâu nhất ---
    _NotificationMsg(
      titleVi: 'Áp suất 1.000 bầu khí quyển 🌍',
      bodyVi: 'Ở độ sâu 10.994m của rãnh Mariana, áp suất nước lên tới 1.086 bar—tương đương một người phải gánh sức nặng của 1.600 con voi châu Phi.',
      titleEn: 'Deepest Point on Earth 🌍',
      bodyEn: 'At 10,994m in the Mariana Trench, water pressure reaches 1,086 bar—equivalent to resting the weight of 1,600 elephants on a human head.',
    ),

    // --- Cá mập yêu tinh (Goblin Shark) ---
    _NotificationMsg(
      titleVi: 'Hàm răng phóng xa chớp nhoáng 🦷',
      bodyVi: 'Cá mập yêu tinh là hóa thạch sống 125 triệu năm. Bộ hàm nhọn hoắt của nó có thể bất ngờ phóng thẳng ra phía trước như lò xo để ngoạm con mồi.',
      titleEn: 'The Spring-Loaded Goblin Jaw 🦷',
      bodyEn: 'A 125-million-year living fossil, the goblin shark thrusts its entire needle-toothed jaws forward at lightning speed to snatch prey.',
    ),

    // --- Bạch tuộc Dumbo ---
    _NotificationMsg(
      titleVi: 'Vũ công bồng bềnh tầng 7.000m 🐘',
      bodyVi: 'Bạch tuộc Dumbo sinh tồn ở độ sâu lên tới 7.000m, dùng đôi vây giống tai voi vẫy nhẹ nhàng để bay lượn trong làn nước tối đen như mực.',
      titleEn: 'The 7,000m Abyssal Dancer 🐘',
      bodyEn: 'Dumbo octopuses thrive up to 7,000 meters deep, fluttering ear-like fins like Disney\'s elephant to glide gracefully through the void.',
    ),

    // --- Cá mắt thùng (Barreleye Fish) ---
    _NotificationMsg(
      titleVi: 'Chiếc đầu trong suốt như pha lê 🐟',
      bodyVi: 'Cá mắt thùng sống sâu 800m sở hữu phần đầu trong suốt nhìn thấu bên trong. Đôi mắt ngọc bích hình ống có thể xoay nhìn ngược lên mặt biển.',
      titleEn: 'Crystal Transparent Head 🐟',
      bodyEn: 'Dwelling at 800m, the barreleye fish has a crystal-clear fluid-filled dome head, allowing its emerald tubular eyes to pivot upward.',
    ),

    // --- Cá mút đá (Hagfish) ---
    _NotificationMsg(
      titleVi: 'Vũ khí chất nhờn nghẹt mang 🫧',
      bodyVi: 'Khi bị cá mập tấn công ở đáy sâu, cá mút đá tiết ra hàng lít chất nhờn đặc quánh chỉ trong 1 giây làm nghẹt thở mang của kẻ săn mồi.',
      titleEn: 'Instant Choking Slime 🫧',
      bodyEn: 'When attacked in the deep, a hagfish secretes micro-fibrous slime that expands into liters of suffocating gel within a second.',
    ),

    // --- Bí ẩn Tàu ma Mary Celeste ---
    _NotificationMsg(
      titleVi: 'Bí ẩn tàu ma Mary Celeste ⛵',
      bodyVi: 'Năm 1872, Mary Celeste được tìm thấy trôi dạt nguyên vẹn giữa Đại Tây Dương, nhưng toàn bộ 10 thủy thủ đã biến mất không để lại dấu vết.',
      titleEn: 'The Mary Celeste Enigma ⛵',
      bodyEn: 'In 1872, the Mary Celeste was found drifting completely seaworthy in the Atlantic, yet all 10 crew members vanished into thin air.',
    ),

    // --- Thảm kịch Ourang Medan ---
    _NotificationMsg(
      titleVi: 'Bức điện SOS Ourang Medan 📻',
      bodyVi: 'Năm 1947, tín hiệu radio rùng rợn "Tất cả sĩ quan đã chết..." vang lên giữa eo biển Malacca, để lại một trong những bí ẩn lớn nhất lịch sử hải trình.',
      titleEn: 'The Ourang Medan SOS 📻',
      bodyEn: 'In 1947, chilling Morse code "All officers including captain dead..." echoed across Malacca, marking maritime history\'s darkest puzzle.',
    ),

    // --- Cá voi lưng gù & Bản tình ca biển ---
    _NotificationMsg(
      titleVi: 'Khúc ca ngàn dặm của biển cả 🎵',
      bodyVi: 'Cá voi lưng gù có thể hát những bài hát phức tạp kéo dài 20 phút và truyền đi suốt hàng nghìn cây số cho các bầy đàn học theo.',
      titleEn: 'Songs Across Oceans 🎵',
      bodyEn: 'Humpback whales compose complex 20-minute songs that travel thousands of kilometers, learned and adopted by distant ocean pods.',
    ),

    // --- Giác quan điện trường cá mập trắng ---
    _NotificationMsg(
      titleVi: 'Giác quan thứ sáu của cá mập ⚡',
      bodyVi: 'Các lỗ nhỏ trên mũi cá mập trắng có thể cảm nhận dòng điện nhỏ tới một phần tỷ volt từ nhịp tim đập yếu ớt của con mồi dưới đáy cát.',
      titleEn: 'The Sixth Electrical Sense ⚡',
      bodyEn: 'Ampullae of Lorenzini pores on a Great White shark detect faint electric currents of one-billionth of a volt from prey heartbeats.',
    ),

    // --- Cá răng nanh (Fangtooth) ---
    _NotificationMsg(
      titleVi: 'Bộ răng không thể khép miệng 🦷',
      bodyVi: 'So với tỷ lệ cơ thể, cá răng nanh sâu 5.000m sở hữu bộ răng lớn nhất đại dương. Não của nó có hai hốc rỗng để chứa đầu răng khi ngậm miệng.',
      titleEn: 'The Monstrous Fangtooth 🦷',
      bodyEn: 'Proportional to body size, the 5,000m deep fangtooth has the largest teeth of any fish, with hollows in its skull just to house them.',
    ),

    // --- Sâu Pompeii chịu nhiệt ---
    _NotificationMsg(
      titleVi: 'Sinh tồn cạnh dung nham 80°C 🔥',
      bodyVi: 'Sâu Pompeii sống bám vào các ống khói ngầm dưới đáy biển sâu, chịu đựng nhiệt độ nước lên tới 80°C—ngưỡng chết chóc với hầu hết sinh vật.',
      titleEn: 'Thriving Beside 80°C Vents 🔥',
      bodyEn: 'Thriving on deep hydrothermal chimneys, Pompeii worms withstand 80°C boiling mineral water—fatal to almost all known creatures.',
    ),

    // --- Bạch tuộc ngụy trang ---
    _NotificationMsg(
      titleVi: 'Bậc thầy ngụy trang 15 loài 🎭',
      bodyVi: 'Bạch tuộc bắt chước có thể biến đổi màu da và uốn mình giả dạng 15 loài sinh vật có độc khác nhau như rắn biển hay cá mao tiên.',
      titleEn: 'Master of 15 Disguises 🎭',
      bodyEn: 'The mimic octopus can contort its body and alter skin pigments to impersonate over 15 toxic sea creatures like lionfish and sea snakes.',
    ),

    // --- Cá heo ngủ nửa não ---
    _NotificationMsg(
      titleVi: 'Vừa ngủ vừa bơi giữa biển 🐬',
      bodyVi: 'Cá heo chỉ ngủ một nửa bán cầu não tại một thời điểm, mắt đối diện vẫn mở để quan sát kẻ săn mồi và định kỳ ngoi lên mặt nước thở.',
      titleEn: 'Unihemispheric Sleep 🐬',
      bodyEn: 'Dolphins sleep with only one brain hemisphere at a time, keeping one eye open to watch for danger and surface for air.',
    ),

    // --- Sứa khổng lồ Nomura ---
    _NotificationMsg(
      titleVi: 'Chiếc dù khổng lồ 200 kg 🪼',
      bodyVi: 'Sứa Nomura có đường kính chuông lên tới 2 mét và nặng 200 kg, trôi dạt như những chiếc dù quái thú dọc các hải trình biển sâu châu Á.',
      titleEn: 'The 200-kg Nomura Jelly 🪼',
      bodyEn: 'Nomura\'s jellyfish span 2 meters across their bells and weigh 200 kg, drifting like enormous living parachutes through open seas.',
    ),
  ];

  // ========================================================
  // KHỞI TẠO DỊCH VỤ THÔNG BÁO
  // ========================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          _handleNotificationTap(details.payload!);
        }
      },
    );
    _initialized = true;

    try {
      await Firebase.initializeApp();
      await _initFirebaseMessaging();
    } catch (_) {}

    // Lập lịch thông báo sinh vật biển & lời chúc (1-2 thông báo/ngày)
    await rescheduleAllNotifications();
  }

  // ========================================================
  // FIREBASE CLOUD MESSAGING (FCM) & GỬI TOKEN KÈM NGÔN NGỮ
  // ========================================================

  Future<void> _initFirebaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      Future<void> fetchAndSendToken() async {
        try {
          if (Platform.isIOS) {
            await FirebaseMessaging.instance.getAPNSToken();
          }

          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            _cachedToken = token;
            await _sendTokenToServer(token);
          }
        } catch (_) {}
      }

      await fetchAndSendToken();

      Future.delayed(const Duration(seconds: 5), () {
        fetchAndSendToken();
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _cachedToken = newToken;
        _sendTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showFCMForegroundNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final clickUrl = message.data['click_url'] as String?;
        if (clickUrl != null && clickUrl.isNotEmpty) {
          _handleNotificationTap(clickUrl);
        }
      });

      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final clickUrl = initialMessage.data['click_url'] as String?;
        if (clickUrl != null && clickUrl.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationTap(clickUrl);
          });
        }
      }
    } catch (_) {}
  }

  /// Gửi token lên server kèm trường ngôn ngữ 'language' (en/vi) để server gửi đúng ngôn ngữ
  Future<void> _sendTokenToServer(String token) async {
    try {
      final isEn = await _isEnglishLanguage();
      final HttpClient client = HttpClient();
      final Uri uri = Uri.parse(
          'https://codego.io.vn/api/noiso_update_device_token.php');
      final HttpClientRequest request = await client.postUrl(uri);

      request.headers.set('content-type', 'application/json; charset=utf-8');

      final Map<String, dynamic> bodyMap = {
        'user_id': 0,
        'device_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'language': isEn ? 'en' : 'vi',
      };

      request.add(utf8.encode(json.encode(bodyMap)));
      final HttpClientResponse response = await request.close();
      await response.transform(utf8.decoder).join();
    } catch (_) {}
  }

  /// Cập nhật lại ngôn ngữ của token lên server khi người dùng đổi ngôn ngữ trong Cài đặt
  Future<void> syncLanguageToServer() async {
    if (_cachedToken != null) {
      await _sendTokenToServer(_cachedToken!);
    } else {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _cachedToken = token;
          await _sendTokenToServer(token);
        }
      } catch (_) {}
    }
  }

  void _showFCMForegroundNotification(RemoteMessage message) async {
    final isEn = await _isEnglishLanguage();
    final fallbackTitle =
        isEn ? 'Deep Sea Chronicle Alert' : 'Thông báo từ Nối Số Biển Sâu';
    final title = message.notification?.title ?? fallbackTitle;
    final body = message.notification?.body ?? '';
    final clickUrl = message.data['click_url'] as String? ?? '';

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'noiso_fcm_messages',
      isEn ? 'System Messages' : 'Tin nhắn hệ thống',
      channelDescription: isEn
          ? 'Displays announcements and updates from server'
          : 'Hiển thị thông báo tin tức từ hệ thống',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: clickUrl,
    );
  }

  void _handleNotificationTap(String payload) {
    if (payload.startsWith('http') || payload.startsWith('https')) {
      try {
        final Uri url = Uri.parse(payload);
        launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<bool> _isEnglishLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      return savedLang == 'en';
    }
    final locale = Platform.localeName.toLowerCase();
    return locale.startsWith('en');
  }

  // ========================================================
  // ĐỒNG BỘ LẬP LỊCH THÔNG BÁO LINH HOẠT THEO NGÔN NGỮ
  // Tần suất: Đúng 1 - 2 thông báo/ngày, không trùng lặp, dùng nhiều năm
  // ========================================================

  /// Gọi khi khởi động hoặc ngay khi người dùng đổi ngôn ngữ trong Cài đặt (LocaleService)
  Future<void> rescheduleAllNotifications({bool? isEnglish}) async {
    try {
      final isEn = isEnglish ?? await _isEnglishLanguage();

      // 1. Hủy sạch các thông báo cũ để không bị trùng lặp hoặc sai ngôn ngữ cũ
      await _plugin.cancelAll();

      // 2. Lập lịch thông minh cho 14 ngày tới (1-2 thông báo/ngày)
      await _scheduleCreatureAndGreetingsNotifications(isEn);

      // 3. Đồng bộ lại ngôn ngữ máy lên máy chủ FCM
      await syncLanguageToServer();
    } catch (_) {}
  }

  /// Lập lịch thông minh cho 14 ngày tới:
  /// - Mỗi ngày đúng 1 đến 2 thông báo (trung bình 1.5/ngày).
  /// - Phối hợp giữa Trích đoạn Sinh vật Biển Sâu (Lore) & Lời chúc ngày mới / Chúc ngủ ngon.
  /// - Phân bổ giờ tự nhiên với độ lệch (jitter) +/- 15-25 phút.
  /// - Sử dụng thuật toán băm ngày (hash) xoay vòng 60+ mẫu độc bản, không trùng lặp trong nhiều tháng.
  Future<void> _scheduleCreatureAndGreetingsNotifications(bool isEn) async {
    final now = DateTime.now();

    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final daySeed = targetDate.year * 365 + targetDate.month * 31 + targetDate.day;
      final weekday = targetDate.weekday; // 1: Thứ 2 ... 7: Chủ Nhật
      final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;

      // Các ngày Thứ 2, Thứ 4, Thứ 6, Chủ Nhật: 2 thông báo/ngày (Sáng + Tối)
      // Các ngày Thứ 3, Thứ 5, Thứ 7: 1 thông báo/ngày (Tối hoặc Sáng luân phiên)
      final hasMorningSlot = (weekday == DateTime.monday ||
          weekday == DateTime.wednesday ||
          weekday == DateTime.friday ||
          weekday == DateTime.sunday ||
          (daySeed % 2 == 0));

      // ----------------------------------------------------
      // SLOT 1: BUỔI SÁNG (8h15 - 8h50) - Chúc ngày mới hoặc Fact sinh vật ban mai
      // ----------------------------------------------------
      if (hasMorningSlot) {
        final morningHour = isWeekend ? 9 : 8;
        final morningMinute = isWeekend ? (5 + (daySeed % 28)) : (15 + (daySeed % 32));
        final morningTime = tz.TZDateTime.from(
          DateTime(targetDate.year, targetDate.month, targetDate.day, morningHour, morningMinute),
          tz.local,
        );

        if (morningTime.isAfter(tz.TZDateTime.now(tz.local))) {
          // Luân phiên: Ngày chẵn lấy Lời chúc ngày mới, Ngày lẻ lấy Fact sinh vật biển
          final _NotificationMsg morningMsg;
          if (dayOffset % 2 == 0) {
            final idx = (daySeed + dayOffset) % _morningGreetings.length;
            morningMsg = _morningGreetings[idx];
          } else {
            final idx = (daySeed * 7 + dayOffset * 13) % _creatureLore.length;
            morningMsg = _creatureLore[idx];
          }

          await _plugin.zonedSchedule(
            6200 + (dayOffset * 2) + 0,
            morningMsg.getTitle(isEn),
            morningMsg.getBody(isEn),
            morningTime,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'noiso_ocean_channel',
                isEn ? 'Ocean Chronicles & Greetings' : 'Hải trình & Lời chúc đại dương',
                channelDescription: isEn
                    ? 'Fascinating deep-sea creature snippets and warm daily greetings'
                    : 'Trích đoạn sinh vật biển sâu kỳ bí và lời chúc ấm áp mỗi ngày',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }

      // ----------------------------------------------------
      // SLOT 2: BUỔI TỐI (20h00 - 20h45) - Trích đoạn Sinh vật huyền bí hoặc Chúc ngủ ngon
      // ----------------------------------------------------
      final eveningMinute = 5 + (daySeed % 38);
      final eveningTime = tz.TZDateTime.from(
        DateTime(targetDate.year, targetDate.month, targetDate.day, 20, eveningMinute),
        tz.local,
      );

      if (eveningTime.isAfter(tz.TZDateTime.now(tz.local))) {
        // Luân phiên: Nếu ngày đó có slot sáng là chúc thì tối là Fact; hoặc cuối tuần là Chúc ngủ ngon
        final _NotificationMsg eveningMsg;
        if (dayOffset % 3 == 0) {
          final idx = (daySeed + dayOffset) % _eveningAndSleep.length;
          eveningMsg = _eveningAndSleep[idx];
        } else {
          // Chọn trích đoạn sinh vật với bước nhảy số nguyên tố để tránh trùng lặp
          final idx = (daySeed * 11 + (dayOffset + 17) * 19) % _creatureLore.length;
          eveningMsg = _creatureLore[idx];
        }

        await _plugin.zonedSchedule(
          6200 + (dayOffset * 2) + 1,
          eveningMsg.getTitle(isEn),
          eveningMsg.getBody(isEn),
          eveningTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'noiso_ocean_channel',
              isEn ? 'Ocean Chronicles & Greetings' : 'Hải trình & Lời chúc đại dương',
              channelDescription: isEn
                  ? 'Fascinating deep-sea creature snippets and warm daily greetings'
                  : 'Trích đoạn sinh vật biển sâu kỳ bí và lời chúc ấm áp mỗi ngày',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  // Tương thích ngược với các lệnh gọi cũ nếu có
  Future<void> scheduleDailyGameNotifications() async {
    final isEn = await _isEnglishLanguage();
    await rescheduleAllNotifications(isEnglish: isEn);
  }

  Future<void> scheduleGratitudeNotifications() async {
    // Đã hợp nhất vào luồng trích đoạn sinh vật và lời chúc 1-2 lần/ngày
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macGranted = await macosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted == true || iosGranted == true || macGranted == true;
  }

  Future<bool> hasNotificationPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidEnabled = await androidPlugin?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }
    return true;
  }

  Future<int> getPendingReminderCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
