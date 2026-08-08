import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../models/creature.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../services/ad_service.dart';
import '../l10n/app_strings.dart';
import 'detail_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'battle_screen.dart';
import 'video_screen.dart';
import '../widgets/cached_video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _particleController;
  
  double _currentDepth = 0.0;
  int _activeMediaTab = 0; // 0 for Image, 1 for Video
  final List<_BubbleParticle> _particles = [];
  final List<_MarineSnowParticle> _marineSnowParticles = [];
  final List<_BioluminescentJellyfish> _jellyfishes = [];
  final List<_SwimmingFish> _swimmingFishes = [];
  final List<_OceanCurrent> _oceanCurrents = [];
  final List<_FlyingBird> _flyingBirds = [];
  final _DeepSeaLeviathan _leviathan = _DeepSeaLeviathan();
  final _AbyssalEye _abyssalEye = _AbyssalEye();
  final List<_ActiveGlassCrack> _activeCracks = [];
  int _crackSpawnCooldown = 0;
  final math.Random _random = math.Random();
  bool _isActive = true;
  String _videoIcon = 'assets/images/icon/dra00.png';
  final List<String> _lavaIcons = const [
    'assets/images/icon/dra00.png',
    'assets/images/icon/dra11.png',
    'assets/images/icon/dra4.png',
  ];

  Future<void> _loadVideoIcon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int currentIndex = prefs.getInt('video_icon_index_v3') ?? 0;
      final int nextIndex = (currentIndex + 1) % _lavaIcons.length;
      await prefs.setInt('video_icon_index_v3', nextIndex);
      setState(() {
        _videoIcon = _lavaIcons[currentIndex];
      });
    } catch (e) {
      // Fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVideoIcon();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particleController.addListener(_updateParticles);

    // Initialize particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles();
      // Start initial ambient sound (shallow water)
      Provider.of<SoundService>(context, listen: false).playAmbient("shallow_water.mp3");
      // Enable banner display after splash screen
      Provider.of<AdService>(context, listen: false).enableBannerDisplay();
    });
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 40; i++) {
      _particles.add(
        _BubbleParticle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          radius: _random.nextDouble() * 3 + 1,
          speed: _random.nextDouble() * 0.8 + 0.2,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }

    // Khởi tạo các hạt Marine Snow (Tuyết biển) rơi từ trên xuống
    for (int i = 0; i < 35; i++) {
      _marineSnowParticles.add(
        _MarineSnowParticle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          radius: _random.nextDouble() * 2 + 0.8,
          speed: _random.nextDouble() * 0.4 + 0.15,
          opacity: _random.nextDouble() * 0.5 + 0.1,
          swaySpeed: _random.nextDouble() * 0.02 + 0.01,
          swayWidth: _random.nextDouble() * 12 + 4,
          swayOffset: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }

    // Khởi tạo sứa phát quang bơi tự do
    final List<Color> jellyColors = [
      const Color(0xFF00E5FF), // Cyan phát sáng
      const Color(0xFFD500F9), // Tím phát sáng
      const Color(0xFF00E676), // Xanh lá phát sáng
      const Color(0xFFFF4081), // Hồng neon
      const Color(0xFFFFD740), // Vàng hổ phách
    ];
    for (int i = 0; i < 7; i++) {
      _jellyfishes.add(
        _BioluminescentJellyfish(
          x: _random.nextDouble() * size.width,
          y: size.height * 0.1 + _random.nextDouble() * size.height * 0.8,
          size: _random.nextDouble() * 22 + 12, // Kích thước phong phú từ 12 đến 34
          speedY: _random.nextDouble() * 0.22 + 0.1,
          speedX: (_random.nextDouble() - 0.5) * 0.05,
          pulseOffset: _random.nextDouble() * 2 * math.pi,
          pulseSpeed: _random.nextDouble() * 1.3 + 0.7,
          glowColor: jellyColors[i % jellyColors.length],
        ),
      );
    }

    // Khởi tạo các đàn cá bơi lội và cá đơn lẻ
    final List<Color> fishColors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF4081), // Pink neon
      const Color(0xFF00E676), // Xanh lá phát sáng
      const Color(0xFFFFD740), // Vàng hổ phách
    ];

    // 1. Tạo các đàn cá (3 đàn)
    for (int school = 0; school < 3; school++) {
      final double schoolY = size.height * 0.15 + _random.nextDouble() * size.height * 0.7;
      final bool direction = _random.nextBool();
      final double schoolSpeed = _random.nextDouble() * 0.8 + 0.6;
      final Color schoolColor = fishColors[school % fishColors.length];
      final double schoolBaseX = direction ? -150.0 : size.width + 50.0;
      final double baseSize = _random.nextDouble() * 5 + 6; // 6 đến 11 pixels

      final int numFishInSchool = _random.nextInt(6) + 6; // 6 đến 11 con mỗi đàn
      for (int i = 0; i < numFishInSchool; i++) {
        final double offsetX = (_random.nextDouble() - 0.5) * 80;
        final double offsetY = (_random.nextDouble() - 0.5) * 40;
        _swimmingFishes.add(
          _SwimmingFish(
            x: schoolBaseX + offsetX,
            y: schoolY + offsetY,
            speed: schoolSpeed + (_random.nextDouble() - 0.5) * 0.15,
            size: baseSize + (_random.nextDouble() - 0.5) * 2,
            opacity: _random.nextDouble() * 0.3 + 0.5,
            isMovingRight: direction,
            color: schoolColor,
            wiggleOffset: _random.nextDouble() * 2 * math.pi,
            wiggleSpeed: _random.nextDouble() * 2 + 3,
            schoolId: school,
          ),
        );
      }
    }

    // 2. Tạo cá đơn lẻ (15 con)
    for (int i = 0; i < 15; i++) {
      final bool direction = _random.nextBool();
      _swimmingFishes.add(
        _SwimmingFish(
          x: _random.nextDouble() * size.width,
          y: size.height * 0.1 + _random.nextDouble() * size.height * 0.8,
          speed: _random.nextDouble() * 0.7 + 0.4,
          size: _random.nextDouble() * 8 + 8, // 8 đến 16 pixels
          opacity: _random.nextDouble() * 0.4 + 0.4,
          isMovingRight: direction,
          color: fishColors[_random.nextInt(fishColors.length)],
          wiggleOffset: _random.nextDouble() * 2 * math.pi,
          wiggleSpeed: _random.nextDouble() * 2 + 2,
          schoolId: -1,
        ),
      );
    }

    // Khởi tạo dòng hải lưu (5 dòng chạy ngang màn hình)
    for (int i = 0; i < 5; i++) {
      _oceanCurrents.add(
        _OceanCurrent(
          y: size.height * 0.15 + _random.nextDouble() * size.height * 0.7,
          speed: _random.nextDouble() * 1.5 + 1.2,
          thickness: _random.nextDouble() * 2.0 + 1.5,
          amplitude: _random.nextDouble() * 15 + 10,
          frequency: _random.nextDouble() * 0.008 + 0.005,
          opacity: _random.nextDouble() * 0.12 + 0.05,
          color: const Color(0xFF00F0FF),
        ),
      );
    }

    // Khởi tạo chim bay trên bầu trời
    // 1. Một đàn chim bay theo hình chữ V hoặc nhóm (6 con)
    final double flockBaseY = 80.0 + _random.nextDouble() * 80.0;
    final bool flockDirection = _random.nextBool();
    final double flockSpeed = _random.nextDouble() * 0.6 + 0.8;
    final double flockBaseX = flockDirection ? -200.0 : size.width + 50.0;
    
    for (int i = 0; i < 6; i++) {
      double offsetX;
      double offsetY;
      if (i == 0) {
        offsetX = 0;
        offsetY = 0;
      } else {
        final int side = i % 2 == 0 ? 1 : -1;
        final int rank = (i + 1) ~/ 2;
        offsetX = (flockDirection ? -1.0 : 1.0) * rank * 35.0;
        offsetY = side * rank * 18.0;
      }
      
      _flyingBirds.add(
        _FlyingBird(
          x: flockBaseX + offsetX,
          y: flockBaseY + offsetY,
          speedX: flockSpeed + (_random.nextDouble() - 0.5) * 0.1,
          size: 20.0 + _random.nextDouble() * 8.0,
          opacity: 0.6 + _random.nextDouble() * 0.35,
          isMovingRight: flockDirection,
          wingFlapPhase: _random.nextDouble() * 2 * math.pi,
          wingFlapSpeed: _random.nextDouble() * 3.0 + 4.0,
          flockId: 1,
        ),
      );
    }

    // 2. Chim đơn lẻ (4 con) bay ngẫu nhiên
    for (int i = 0; i < 4; i++) {
      final bool direction = _random.nextBool();
      _flyingBirds.add(
        _FlyingBird(
          x: _random.nextDouble() * size.width,
          y: 60.0 + _random.nextDouble() * 140.0,
          speedX: _random.nextDouble() * 0.7 + 0.5,
          size: 18.0 + _random.nextDouble() * 12.0,
          opacity: 0.55 + _random.nextDouble() * 0.35,
          isMovingRight: direction,
          wingFlapPhase: _random.nextDouble() * 2 * math.pi,
          wingFlapSpeed: _random.nextDouble() * 2.5 + 3.0,
          flockId: -1,
        ),
      );
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    
    // Sinking factor: tốc độ bọt khí thay đổi nhẹ khi cuộn
    double scrollSpeedFactor = 1.0;

    setState(() {
      // Cập nhật vết nứt kính lặn điện thoại động dưới áp suất cực lớn
      if (_currentDepth > 7000 && size.width > 0) {
        if (_crackSpawnCooldown > 0) {
          _crackSpawnCooldown--;
        }
        
        // Tạo vết nứt mới ngẫu nhiên nếu hết cooldown (tối đa 2 vết nứt đồng thời)
        if (_crackSpawnCooldown <= 0 && _activeCracks.length < 2) {
          _activeCracks.add(_generateSingleCrack(size, _random));
          _crackSpawnCooldown = 200 + _random.nextInt(200); // 3 đến 6 giây
        }
      }
      
      // Tiến trình cập nhật vòng đời vết nứt (Xuất hiện, Tồn tại, Biến mất)
      for (int i = _activeCracks.length - 1; i >= 0; i--) {
        final crack = _activeCracks[i];
        if (_currentDepth > 7000) {
          if (crack.age < crack.maxAge) {
            crack.age++;
            if (crack.lifeProgress < 1.0) {
              crack.lifeProgress += crack.scaleSpeed;
              if (crack.lifeProgress > 1.0) crack.lifeProgress = 1.0;
            }
          } else {
            crack.lifeProgress -= 0.015; // phai màu chậm
            if (crack.lifeProgress <= 0.0) {
              _activeCracks.removeAt(i);
            }
          }
        } else {
          crack.lifeProgress -= 0.04; // biến mất nhanh khi giảm áp suất
          if (crack.lifeProgress <= 0.0) {
            _activeCracks.removeAt(i);
          }
        }
      }

      if (_currentDepth <= 7000) {
        _crackSpawnCooldown = 0;
      }

      // 1. Cập nhật bọt khí (Bay lên)
      for (var particle in _particles) {
        particle.y -= particle.speed * scrollSpeedFactor;
        particle.x += math.sin(particle.y / 30) * 0.2;
        
        if (particle.y < -10) {
          particle.y = size.height + 10;
          particle.x = _random.nextDouble() * size.width;
        }
      }

      // 2. Cập nhật Tuyết biển (Rơi chậm xuống)
      for (var particle in _marineSnowParticles) {
        particle.y += particle.speed;
        particle.x += math.sin((particle.y * particle.swaySpeed) + particle.swayOffset) * 0.05;
        
        if (particle.y > size.height + 10) {
          particle.y = -10;
          particle.x = _random.nextDouble() * size.width;
        }
      }

      // 3. Cập nhật sứa phát quang (Trôi chậm, co bóp và uốn lượn ngang sinh động)
      for (var jelly in _jellyfishes) {
        jelly.y -= jelly.speedY;
        // Tạo chuyển động bơi lượn tự do qua lại bằng sóng Sin
        jelly.x += jelly.speedX + math.sin(jelly.y / 50.0 + jelly.pulseOffset) * 0.25;
        
        // Giới hạn màn hình và tái tạo sứa
        if (jelly.y < -50) {
          jelly.y = size.height + 50;
          jelly.x = _random.nextDouble() * size.width;
        }
        if (jelly.x < -50) {
          jelly.x = size.width + 50;
        } else if (jelly.x > size.width + 50) {
          jelly.x = -50;
        }
      }

      // Cập nhật cá con bơi lội
      for (var fish in _swimmingFishes) {
        if (fish.isMovingRight) {
          fish.x += fish.speed;
          if (fish.x > size.width + 100) {
            fish.x = -100;
            if (fish.schoolId == -1) {
              fish.y = size.height * 0.1 + _random.nextDouble() * size.height * 0.8;
            }
          }
        } else {
          fish.x -= fish.speed;
          if (fish.x < -100) {
            fish.x = size.width + 100;
            if (fish.schoolId == -1) {
              fish.y = size.height * 0.1 + _random.nextDouble() * size.height * 0.8;
            }
          }
        }

        // Tạo dao động lên xuống nhẹ cho cá
        if (fish.schoolId != -1) {
          fish.y += math.sin(_particleController.value * 2 * math.pi + fish.wiggleOffset) * 0.15;
        } else {
          fish.y += math.sin(_particleController.value * 1.5 * math.pi + fish.wiggleOffset) * 0.25;
        }
      }

      // Cập nhật pha dòng hải lưu để tạo chuyển động cuộn chảy
      for (var current in _oceanCurrents) {
        current.phase += current.speed * 0.015;
      }

      // Cập nhật chim bay trên trời
      for (var bird in _flyingBirds) {
        if (bird.isMovingRight) {
          bird.x += bird.speedX;
          if (bird.x > size.width + 250) {
            bird.x = -250;
            if (bird.flockId == -1) {
              bird.y = 60.0 + _random.nextDouble() * 140.0;
            }
          }
        } else {
          bird.x -= bird.speedX;
          if (bird.x < -250) {
            bird.x = size.width + 250;
            if (bird.flockId == -1) {
              bird.y = 60.0 + _random.nextDouble() * 140.0;
            }
          }
        }
        
        // Vỗ cánh và nhấp nhô
        bird.wingFlapPhase += bird.wingFlapSpeed * 0.02;
        bird.y += math.sin(_particleController.value * 2 * math.pi + bird.wingFlapPhase) * 0.15;
      }

      // 4. Cập nhật Thủy quái Leviathan khổng lồ ẩn hiện
      if (_currentDepth > 1500) {
        if (!_leviathan.isActive) {
          // Tỷ lệ xuất hiện ngẫu nhiên cực thấp ở vùng nước sâu (~1/1000 mỗi frame)
          if (_random.nextInt(1000) == 42) {
            final double startY = size.height * 0.3 + _random.nextDouble() * size.height * 0.4;
            final double sz = _random.nextDouble() * 150 + 200; // Chiều dài khổng lồ 200px - 350px
            final double spd = _random.nextDouble() * 0.5 + 0.3; // Bơi chậm chạp, nặng nề
            final bool right = _random.nextBool();
            final double startX = right ? -sz : size.width + sz;
            
            _leviathan.activate(startX, startY, right, sz, spd);
          }
        } else {
          // Di chuyển chậm chạp theo hướng bơi
          _leviathan.x += _leviathan.speedX;
          
          // Ra khỏi biên thì reset hoạt động
          final double margin = _leviathan.size + 150;
          if (_leviathan.isMovingRight && _leviathan.x > size.width + margin) {
            _leviathan.isActive = false;
          } else if (!_leviathan.isMovingRight && _leviathan.x < -margin) {
            _leviathan.isActive = false;
          }
        }
      } else {
        // Lặn lên vùng cạn thì biến mất bóng shadow ngay lập tức
        _leviathan.isActive = false;
      }

      // 5. Cập nhật Mắt quỷ dưới vực thẳm
      if (_currentDepth > 4500) {
        if (!_abyssalEye.isActive) {
          // Tỷ lệ xuất hiện ngẫu nhiên cực thấp khi lặn sâu (~1/1500 mỗi frame)
          if (_random.nextInt(1500) == 77) {
            final double startX = size.width * 0.25 + _random.nextDouble() * size.width * 0.5;
            final double startY = size.height * 0.25 + _random.nextDouble() * size.height * 0.5;
            final double eyeSize = _random.nextDouble() * 40 + 50; // Kích thước mắt từ 50px đến 90px
            _abyssalEye.activate(startX, startY, eyeSize);
          }
        } else {
          if (!_abyssalEye.isClosing) {
            if (_abyssalEye.openProgress < 1.0) {
              _abyssalEye.openProgress += 0.015; // Mở mắt từ từ
              if (_abyssalEye.openProgress >= 1.0) {
                _abyssalEye.openProgress = 1.0;
              }
            } else {
              // Mắt đang mở: giảm số tick chờ và đảo mắt ngẫu nhiên
              _abyssalEye.stayOpenTicks--;
              _abyssalEye.gazeX = math.sin(_particleController.value * 2 * math.pi) * 8.0;
              _abyssalEye.gazeY = math.cos(_particleController.value * 2 * math.pi) * 4.0;
              
              if (_abyssalEye.stayOpenTicks <= 0) {
                _abyssalEye.isClosing = true;
              }
            }
          } else {
            // Đóng mắt nhắm lại từ từ
            _abyssalEye.openProgress -= 0.02;
            if (_abyssalEye.openProgress <= 0.0) {
              _abyssalEye.openProgress = 0.0;
              _abyssalEye.isActive = false;
            }
          }
        }
      } else {
        _abyssalEye.isActive = false;
      }


    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    
    setState(() {
      // Độ sâu chỉ bắt đầu tăng khi đi qua mặt nước (offset 550px)
      if (currentOffset <= 550.0) {
        _currentDepth = 0.0;
      } else {
        double underwaterProgress = ((currentOffset - 550.0) / (maxScroll - 550.0)).clamp(0.0, 1.0);
        _currentDepth = underwaterProgress * 11000.0; // 0m to 11000m
      }
    });

    // Dynamically play ambient sounds based on depth zones
    if (!_isActive) return;
    final soundService = Provider.of<SoundService>(context, listen: false);
    if (_currentDepth < 1.0) {
      soundService.playAmbient("shallow_water.mp3");
      soundService.stopSecondaryAmbient();
    } else if (_currentDepth >= 1.0 && _currentDepth < 4000) {
      soundService.playAmbient("low_pressure.m4a");
      soundService.stopSecondaryAmbient();
    } else if (_currentDepth >= 4000 && _currentDepth < 9000) {
      soundService.playAmbient("deep_hum.mp3");
      soundService.stopSecondaryAmbient();
    } else {
      // Depth >= 9000m: Play BOTH deep_hum.mp3 and sonar_echo.mp3
      soundService.playAmbient("deep_hum.mp3");
      soundService.playSecondaryAmbient("sonar_echo.mp3");
    }
  }

  Future<T?> _navigateTo<T>(Widget screen) async {
    final soundService = Provider.of<SoundService>(context, listen: false);
    
    // Pause video player and set inactive state
    setState(() {
      _isActive = false;
    });

    // Pause ambient sounds
    await soundService.stopAmbient();
    await soundService.stopSecondaryAmbient();

    if (!mounted) return null;

    // Push screen and wait
    final result = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // Resume state and sound when returning
    if (mounted) {
      setState(() {
        _isActive = true;
      });
      _onScroll(); 
    }
    return result;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  _ActiveGlassCrack _generateSingleCrack(Size size, math.Random random) {
    // Chọn ngẫu nhiên cạnh màn hình làm điểm chịu lực va chạm nứt vỡ
    final int side = random.nextInt(4); // 0: Top, 1: Bottom, 2: Left, 3: Right
    double startX = 0;
    double startY = 0;
    
    if (side == 0) {
      startX = size.width * (0.15 + random.nextDouble() * 0.7);
      startY = 0;
    } else if (side == 1) {
      startX = size.width * (0.15 + random.nextDouble() * 0.7);
      startY = size.height;
    } else if (side == 2) {
      startX = 0;
      startY = size.height * (0.15 + random.nextDouble() * 0.7);
    } else {
      startX = size.width;
      startY = size.height * (0.15 + random.nextDouble() * 0.7);
    }
    
    final Offset origin = Offset(startX, startY);
    
    // Hướng lan truyền tia nứt gãy giống tia sét
    double baseAngle = 0.0;
    double angleSpread = math.pi * 0.45;
    
    if (side == 0) {
      baseAngle = math.pi / 2;
    } else if (side == 1) {
      baseAngle = -math.pi / 2;
    } else if (side == 2) {
      baseAngle = 0;
    } else {
      baseAngle = math.pi;
    }
    
    final int numMainCracks = random.nextInt(2) + 2; // Chỉ 2 đến 3 tia nứt chính (rất nhỏ gọn tinh tế!)
    final List<_GlassCrackLine> segments = [];
    final List<List<Offset>> allBranchPoints = [];
    
    for (int i = 0; i < numMainCracks; i++) {
      double angle = baseAngle - (angleSpread / 2) + (angleSpread * i / (numMainCracks - 1)) + (random.nextDouble() - 0.5) * 0.2;
      
      List<Offset> points = [origin];
      Offset current = origin;
      double currentAngle = angle;
      
      int numSegments = random.nextInt(3) + 3; // 3 đến 5 đoạn nhỏ
      for (int j = 0; j < numSegments; j++) {
        // Chiều dài đoạn nứt nhỏ gọn (6px đến 16px) để nét vỡ li ti giống thật
        double segLength = random.nextDouble() * 10.0 + 6.0;
        double nextX = current.dx + math.cos(currentAngle) * segLength;
        double nextY = current.dy + math.sin(currentAngle) * segLength;
        
        Offset nextPoint = Offset(nextX, nextY);
        points.add(nextPoint);
        
        double threshold = j / numSegments;
        segments.add(_GlassCrackLine(current, nextPoint, threshold));
        
        // Phân nhánh phụ ngoằn ngoèo kiểu tia sét
        if (random.nextDouble() < 0.35 && j > 0 && j < numSegments - 1) {
          double branchAngle = currentAngle + (random.nextBool() ? 1.0 : -1.0) * (0.4 + random.nextDouble() * 0.4);
          Offset branchCurrent = current;
          int numBranchSegs = random.nextInt(2) + 1; // 1 đến 2 phân đoạn phụ
          for (int k = 0; k < numBranchSegs; k++) {
            double bSegLength = random.nextDouble() * 8.0 + 4.0;
            double bNextX = branchCurrent.dx + math.cos(branchAngle) * bSegLength;
            double bNextY = branchCurrent.dy + math.sin(branchAngle) * bSegLength;
            Offset bNext = Offset(bNextX, bNextY);
            
            segments.add(_GlassCrackLine(branchCurrent, bNext, threshold + 0.2 * (k + 1)));
            branchCurrent = bNext;
            branchAngle += (random.nextDouble() - 0.5) * 0.2;
          }
        }
        
        current = nextPoint;
        currentAngle += (random.nextDouble() - 0.5) * 0.4;
      }
      allBranchPoints.add(points);
    }
    
    // Nối các vòng nứt đồng tâm mờ tạo cảm giác màn hình điện thoại rạn vỡ
    for (int i = 0; i < allBranchPoints.length - 1; i++) {
      var branch1 = allBranchPoints[i];
      var branch2 = allBranchPoints[i + 1];
      
      for (int j = 1; j < math.min(branch1.length, branch2.length); j++) {
        if (random.nextDouble() < 0.50) {
          double threshold = j / math.min(branch1.length, branch2.length);
          segments.add(_GlassCrackLine(branch1[j], branch2[j], threshold));
        }
      }
    }
    
    // Thêm các mảnh vỡ dăm li ti quanh tâm va chạm
    int crushedCount = random.nextInt(3) + 3;
    for (int i = 0; i < crushedCount; i++) {
      double angle = random.nextDouble() * 2 * math.pi;
      double len = random.nextDouble() * 4.0 + 2.0;
      double endX = origin.dx + math.cos(angle) * len;
      double endY = origin.dy + math.sin(angle) * len;
      segments.add(_GlassCrackLine(origin, Offset(endX, endY), 0.0));
    }
    
    return _ActiveGlassCrack(
      origin: origin,
      segments: segments,
      maxAge: 180.0 + random.nextDouble() * 120.0, // Tồn tại trong 3 đến 5 giây ở 60fps
      scaleSpeed: 0.06 + random.nextDouble() * 0.06, // Tốc độ rạn vỡ nhanh
    );
  }

  Color _getBackgroundColor() {
    // Stage 1: 0m to 500m (Sunlight zone - Bright Teal to Medium Teal Blue)
    // Stage 2: 500m to 2000m (Twilight zone - Medium Teal to Deep Navy)
    // Stage 3: 2000m to 5000m (Midnight zone - Deep Navy to Dark Abyss)
    // Stage 4: 5000m to 11000m (Hadal zone - Dark Abyss to Pitch Black)
    
    if (_currentDepth < 500.0) {
      double t = _currentDepth / 500.0;
      return Color.lerp(const Color(0xFF007799), const Color(0xFF005670), t)!;
    } else if (_currentDepth >= 500.0 && _currentDepth < 2000.0) {
      double t = (_currentDepth - 500.0) / 1500.0;
      return Color.lerp(const Color(0xFF005670), const Color(0xFF0D1F3D), t)!;
    } else if (_currentDepth >= 2000.0 && _currentDepth < 5000.0) {
      double t = (_currentDepth - 2000.0) / 3000.0;
      return Color.lerp(const Color(0xFF0D1F3D), const Color(0xFF030A16), t)!;
    } else {
      double t = ((_currentDepth - 5000.0) / 6000.0).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF030A16), const Color(0xFF010307), t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final soundService = Provider.of<SoundService>(context);
    final strings = AppStrings.listen(context);
    
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: Stack(
        children: [
          // Background Leviathan Shadow (Bóng thủy quái lướt qua dưới tầng nước sâu thẳm)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LeviathanShadowPainter(
                leviathan: _leviathan,
                animationValue: _particleController.value,
              ),
            ),
          ),
          // Background Abyssal Eye (Mắt quỷ biển sâu khổng lồ ẩn hiện phía sau)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _AbyssalEyePainter(
                eye: _abyssalEye,
                animationValue: _particleController.value,
              ),
            ),
          ),
          // 1. Main Deep Scroll Content
          dataService.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                  ),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Atmospheric Header
                    // Redesigned Sky-to-Sea Transition Header
                    SliverToBoxAdapter(
                      child: Container(
                        height: 640.0,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFB3E5FC), // Light Sky Blue (Sunlight)
                              Color(0xFF4FC3F7), // Mid Sky Blue
                              Color(0xFF0288D1), // Deep Sky Blue
                              Color(0xFF01579B), // Dark Horizon Blue (above water)
                              Color(0xFF007799), // Sea Surface Junction (Light Teal Blue)
                              Color(0x00007799), // Transparent Teal Blue right below waves
                              Color(0x00007799), // Transparent Teal Blue at bottom of header
                            ],
                            stops: [0.0, 0.35, 0.60, 0.80, 0.86, 0.88, 1.0],
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. The Sun
                            Positioned(
                              top: 70,
                              right: 40,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.yellow.shade300.withValues(alpha: 0.9),
                                      Colors.orange.shade300.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.15, 0.4, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // 2. Clouds
                            Positioned(
                              top: 110,
                              left: -20,
                              child: _buildCloud(170, 60, 0.85),
                            ),
                            Positioned(
                              top: 80,
                              right: 120,
                              child: _buildCloud(130, 45, 0.7),
                            ),
                            Positioned(
                              top: 170,
                              right: -30,
                              child: _buildCloud(190, 75, 0.8),
                            ),

                            // 3. Seagulls Flying in the Sky (Dynamic Flapping & Flocks)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _FlyingBirdsPainter(
                                    birds: _flyingBirds,
                                  ),
                                ),
                              ),
                            ),

                            // 4. Main App Title Panel
                             Positioned(
                              top: 310,
                              left: 24,
                              right: 24,
                              child: Column(
                                children: [
                                  Text(
                                    strings.homeTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 8.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black38,
                                          offset: Offset(2, 4),
                                          blurRadius: 10,
                                        ),
                                        Shadow(
                                          color: Color(0xFF00F0FF),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    strings.homeSubtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13.0,
                                      letterSpacing: 3.0,
                                      fontWeight: FontWeight.w500,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(1, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 5. Sea Surface Wave Layers (Animated)
                            // Wave Layer 1: Back Wave (Deep Teal Navy)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 510,
                              height: 80,
                              child: AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: WavePainter(
                                      color: const Color(0xFF005670).withValues(alpha: 0.7),
                                      wavePhase: _particleController.value * 2 * math.pi,
                                      waveAmplitude: 11.0,
                                      waveFrequency: 1.2,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Wave Layer 2: Middle Wave (Medium Cyan Teal)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 522,
                              height: 80,
                              child: AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: WavePainter(
                                      color: const Color(0xFF006B8B).withValues(alpha: 0.85),
                                      wavePhase: -_particleController.value * 2 * math.pi * 1.3 + 1.0,
                                      waveAmplitude: 8.5,
                                      waveFrequency: 1.7,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Wave Layer 3: Front Wave (Bright Ocean Teal)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 532,
                              height: 80,
                              child: AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: WavePainter(
                                      color: const Color(0xFF007799),
                                      wavePhase: _particleController.value * 2 * math.pi * 0.8 + 2.0,
                                      waveAmplitude: 6.0,
                                      waveFrequency: 2.1,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 6. Sunlight Shafts / Rays (Below the surface)
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 565,
                              height: 150,
                              child: CustomPaint(
                                painter: SunshaftsPainter(animationValue: _particleController.value),
                              ),
                            ),

                            // 7. Sinking Intro / Instructions
                             Positioned(
                              bottom: 12,
                              left: 24,
                              right: 24,
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.keyboard_double_arrow_down,
                                    color: Color(0xFF00F0FF),
                                    size: 32,
                                  ).animateGlowing(),
                                  const SizedBox(height: 8),
                                  Text(
                                    strings.startDivePrompt,
                                    style: const TextStyle(
                                      color: Color(0xFF00F0FF),
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    strings.scrollInstruction,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Media Tab Selector for Image vs Video
                    SliverToBoxAdapter(
                      child: _buildMediaTabSelector(),
                    ),
                    // List of Creature cards mapped by depth
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final creature = dataService.creatures[index];
                          return _buildCreatureItem(creature);
                        },
                        childCount: dataService.creatures.length,
                      ),
                    ),

                    // Bottom Mariana Trench zone
                    SliverToBoxAdapter(
                      child: _MarianaTrenchZone(
                        strings: strings,
                        depth: _isActive ? _currentDepth : 0.0,
                        onBackToSurface: () {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(seconds: 4),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                      ),
                    ),
                  ],
                ),

          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _UnderwaterEffectsPainter(
                bubbles: _particles,
                marineSnow: _marineSnowParticles,
                jellyfishes: _jellyfishes,
                fishes: _swimmingFishes,
                oceanCurrents: _oceanCurrents,
                waterSurfaceY: _scrollController.hasClients ? (550.0 - _scrollController.offset) : 550.0,
                depth: _currentDepth,
                animationValue: _particleController.value,
              ),
            ),
          ),

          // Swaying Seaweed / Abyssal Vines Overlay framing the left and right edges
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _SeaweedPainter(
                scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
                animationValue: _particleController.value,
                waterSurfaceY: _scrollController.hasClients ? (550.0 - _scrollController.offset) : 550.0,
              ),
            ),
          ),



          // Viewport Pressure Cracks Overlay (vết nứt kính)
          if (_currentDepth > 7000)
            IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: _PressureCracksPainter(
                  depth: _currentDepth,
                  animationValue: _particleController.value,
                  cracks: _activeCracks,
                ),
              ),
            ),


          // 3. Floating HUD: Depth Meter
          Positioned(
            right: 16.0,
            top: MediaQuery.of(context).padding.top + 16.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/icon/diving.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${_currentDepth.toStringAsFixed(0)} m",
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating HUD: Audio Ambient Controller
          Positioned(
            left: 8.0,
            top: MediaQuery.of(context).padding.top + 16.0,
            child: _BalloonHUDButton(
              animation: _particleController,
              phaseOffset: 0.0,
              gradientColors: soundService.isMuted
                  ? [const Color(0xFFFF3366), const Color(0xFF880E4F)]
                  : [const Color(0xFF00E5FF), const Color(0xFF006064)],
              borderColor: soundService.isMuted ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
              onTap: () => soundService.toggleMute(),
              child: Opacity(
                opacity: soundService.isMuted ? 0.4 : 1.0,
                child: Image.asset(
                  'assets/images/icon/medium-volume.png',
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ),

          // 4b. Floating HUD: Dashboard Control Console Button (Menu)
          Positioned(
            right: 8.0,
            top: MediaQuery.of(context).padding.top + 72.0,
            child: _BalloonHUDButton(
              animation: _particleController,
              phaseOffset: 1.5,
              gradientColors: const [Color(0xFF00B0FF), Color(0xFF2962FF)],
              borderColor: const Color(0xFF00F0FF),
              onTap: () => _navigateTo(const DashboardScreen()),
              child: Image.asset(
                'assets/images/icon/cruise.png',
                width: 36,
                height: 36,
              ),
            ),
          ),

          // 4c. Floating HUD: Settings Button (Symmetric top-right under depth meter)
          Positioned(
            left: 8.0,
            top: MediaQuery.of(context).padding.top + 115.0,
            child: _BalloonHUDButton(
              animation: _particleController,
              phaseOffset: 3.0,
              gradientColors: const [Color(0xFF00E676), Color(0xFF00796B)],
              borderColor: const Color(0xFF00F0FF),
              onTap: () => openSettings(context),
              child: Image.asset(
                'assets/images/icon/settings.png',
                width: 36,
                height: 36,
              ),
            ),
          ),

          // 4d. Floating HUD: Battle Mode Button (Left column below dashboard console)
          Positioned(
            left: 8.0,
            top: MediaQuery.of(context).padding.top + 215.0,
            child: _BalloonHUDButton(
              animation: _particleController,
              phaseOffset: 4.5,
              gradientColors: const [Color(0xFFFF3366), Color(0xFFC2185B)],
              borderColor: const Color(0xFFFF3366),
              onTap: () => _navigateTo(const BattleScreen()),
              child: Image.asset(
                'assets/images/icon/dragon.png',
                width: 36,
                height: 36,
              ),
            ),
          ),

          // 4e. Floating HUD: Creature Battle Videos Button (Right column below settings button)
          Positioned(
            right: 8.0,
            top: MediaQuery.of(context).padding.top + 215.0,
            child: _BalloonHUDButton(
              animation: _particleController,
              phaseOffset: 6.0,
              gradientColors: const [Color(0xFFE91E63), Color(0xFF9C27B0)],
              borderColor: const Color(0xFF00F0FF),
              onTap: () => _navigateTo(const VideoScreen()),
              scale: 1.55,
              isLava: true,
              child: Image.asset(
                _videoIcon,
                width: 36,
                height: 36,
              ),
            ),
          ),

          // 5. Floating HUD: Diver Overlay (sinks with scroll depth)
          _buildDiverOverlay(context),
        ],
      ),
    );
  }

  Widget _buildDiverOverlay(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    double scrollOffset = 0.0;
    if (_scrollController.hasClients) {
      scrollOffset = _scrollController.offset;
    }
    
    // Wave surface starts at 550px from the top of the header.
    // Its position on the screen is (550 - scrollOffset).
    double waterSurfaceScreenY = 550.0 - scrollOffset;
    
    double diverY;
    double opacity;
    
    if (waterSurfaceScreenY > 120.0) {
      // Water surface is still on screen (bottom half)
      // Position the diver just below the waves
      diverY = waterSurfaceScreenY + 25.0;
      
      // Fade in the diver as we scroll down towards the water
      opacity = (scrollOffset / 150.0).clamp(0.0, 1.0);
    } else {
      // Water surface has moved off-screen (above y=120)
      // Diver descends dynamically based on scroll progress
      double minDiverY = 120.0;
      double maxDiverY = screenHeight - 220.0;
      
      // Calculate progress of scroll after water has covered the screen
      double maxScroll = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 1.0;
      double underwaterScrollProgress = 0.0;
      if (maxScroll > 410.0) {
        underwaterScrollProgress = ((scrollOffset - 410.0) / (maxScroll - 410.0)).clamp(0.0, 1.0);
      }
      
      diverY = minDiverY + (maxDiverY - minDiverY) * underwaterScrollProgress;
      opacity = 1.0;
    }
    
    return Positioned(
      right: 8.0,
      top: diverY,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          child: FloatingCreature(
            duration: const Duration(seconds: 4),
            offset: 6.0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: [
                // Flashlight Beam extending leftwards
                Positioned(
                  right: 50.0, // starts near the diver's helmet
                  child: Container(
                    width: screenWidth * 0.42,
                    height: 100.0,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00F0FF).withValues(alpha: 0.12),
                          const Color(0xFF00F0FF).withValues(alpha: 0.01),
                          Colors.transparent,
                        ],
                        center: Alignment.centerRight,
                        radius: 0.95,
                      ),
                    ),
                  ),
                ),
                
                // Diver Image
                Image.asset(
                  'assets/images/creatures/diver_transparent.png',
                  width: screenWidth * 0.23,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloud(double width, double height, double opacity) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              left: width * 0.1,
              right: width * 0.1,
              child: Container(
                height: height * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(height * 0.5),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: width * 0.25,
              child: Container(
                width: height * 0.9,
                height: height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: width * 0.12,
              child: Container(
                width: height * 0.65,
                height: height * 0.65,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: width * 0.15,
              child: Container(
                width: height * 0.6,
                height: height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTabSelector() {
    final strings = AppStrings.of(context);
    final themeColor = const Color(0xFF00F0FF);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF030D1C).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeMediaTab = 0;
                  });
                  Provider.of<SoundService>(context, listen: false).playCreatureSound("sonar_echo.mp3");
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeMediaTab == 0
                        ? themeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    strings.languageCode == 'en' ? 'SCAN IMAGES' : 'HÌNH ẢNH',
                    style: TextStyle(
                      color: _activeMediaTab == 0 ? Colors.white : Colors.white30,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeMediaTab = 1;
                  });
                  Provider.of<SoundService>(context, listen: false).playCreatureSound("sonar_echo.mp3");
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeMediaTab == 1
                        ? themeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    strings.languageCode == 'en' ? 'LIVE TELEMETRY' : 'HÌNH ĐỘNG (VIDEO)',
                    style: TextStyle(
                      color: _activeMediaTab == 1 ? Colors.white : Colors.white30,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatureItem(Creature creature) {
    final dataService = Provider.of<DataService>(context, listen: false);
    final strings = AppStrings.of(context);
    final index = dataService.creatures.indexOf(creature);
    final screenWidth = MediaQuery.of(context).size.width;
    final themeColor = creature.isLocked ? const Color(0xFFFF3366) : const Color(0xFF00F0FF);
    final double itemHeight = 390.0;
    
    return Container(
      height: itemHeight,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Dây cáp độ sâu chạy dọc làm nền
          Positioned(
            left: 36.0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.04),
                    const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    const Color(0xFF00F0FF).withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // 2. Nút thắt hiển thị độ sâu phát sáng
          Positioned(
            left: 30.0,
            top: 30.0,
            child: Container(
              width: 13.0,
              height: 13.0,
              decoration: BoxDecoration(
                color: const Color(0xFF020813),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ).animateGlowing(),
          ),
          
          // 3. Số mét độ sâu
          Positioned(
            left: 56.0,
            top: 26.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${creature.minDepth}m",
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: themeColor.withValues(alpha: 0.6),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
                Text(
                  "⬇ ${creature.maxDepth}m",
                  style: TextStyle(
                    color: themeColor.withValues(alpha: 0.75),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  creature.isLocked 
                      ? (strings.languageCode == 'vi' ? "TÍN HIỆU LẠ" : "STRANGE SIGNAL") 
                      : (strings.languageCode == 'vi' ? "PHẠM VI SỐNG" : "HABITAT RANGE"),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // 5. ẢNH SINH VẬT PHÓNG ĐẠI CỰC ĐẠI (Đặt rộng hơn và dùng scale lớn để bù phần viền trong suốt)
          Positioned(
            left: 20.0,
            right: 20.0,
            top: 40.0,
            bottom: 50.0,
            child: Center(
              child: FloatingCreature(
                duration: Duration(seconds: 4 + (index % 3)),
                offset: 8.0 + (index % 4),
                child: GestureDetector(
                  onTap: () => _handleCardTap(creature),
                  child: Hero(
                    tag: 'creature_${creature.id}',
                    child: Transform.scale(
                      scale: (creature.id == 'godzilla' || creature.id == 'ghost_leviathan' || creature.id == 'lagiacrus') ? 1.25 : 1.75,
                      child: creature.isLocked
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                const Color(0xFF00F0FF).withValues(alpha: 0.28), // Hologram phát quang xanh
                                BlendMode.srcATop,
                              ),
                              child: Opacity(
                                opacity: 0.38,
                                child: creature.buildImage(
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(screenWidth),
                                ),
                              ),
                            )
                          : (_activeMediaTab == 1 && creature.videoUrl.isNotEmpty)
                              ? CachedCreatureVideoPlayer(
                                  videoUrl: creature.videoUrl,
                                  useTightMask: true,
                                  placeholder: creature.buildImage(
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => _buildErrorImage(screenWidth),
                                  ),
                                )
                              : creature.buildImage(
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => _buildErrorImage(screenWidth),
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 6. NÚT NHẤN KHÁM PHÁ / QUÉT TỐI GIẢN (Đặt căn giữa phía dưới)
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 20.0,
            child: GestureDetector(
              onTap: () => _handleCardTap(creature),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    creature.isLocked ? Icons.lock_outline : Icons.radar_outlined,
                    color: themeColor,
                    size: 20.0,
                  ),
                ).animateGlowing(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImage(double screenWidth) {
    return Container(
      width: screenWidth * 0.58,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Icon(Icons.broken_image, color: Colors.white24, size: 30),
    );
  }

  void _handleCardTap(Creature creature) {
    if (creature.isLocked) {
      _simulateWatchingAd(creature);
    } else {
      _navigateTo(DetailScreen(creature: creature));
    }
  }

  void _simulateWatchingAd(Creature creature) {
    final strings = AppStrings.of(context);
    final adService = Provider.of<AdService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF020813),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF3366))),
              const SizedBox(height: 20),
              Text(strings.loadingSponsor, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(strings.pleaseWait, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        );
      },
    );

    // Give a 1-second delay for premium visual loading before requesting ad
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      adService.showInterstitialAd(
        ignoreCooldown: true, // Allow unlocking regardless of cooldown
        onComplete: () {
          if (!mounted) return;
          Provider.of<DataService>(context, listen: false).unlockCreature(creature.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00F0FF),
              content: Text(
                "${strings.unlockSuccess} (${creature.getName(strings.languageCode)})",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );

          _navigateTo(DetailScreen(creature: creature));
        },
      );
    });
  }
}

// Custom paint components for particle bubble animation
class _BubbleParticle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;

  _BubbleParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

// Cấu trúc cho Tuyết biển (Marine Snow)
class _MarineSnowParticle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;
  double swaySpeed;
  double swayWidth;
  double swayOffset;

  _MarineSnowParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.swaySpeed,
    required this.swayWidth,
    required this.swayOffset,
  });
}

// Cấu trúc cho sứa phát quang (Bioluminescent Jellyfish)
class _BioluminescentJellyfish {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double pulseOffset;
  double pulseSpeed;
  Color glowColor;

  _BioluminescentJellyfish({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.pulseOffset,
    required this.pulseSpeed,
    required this.glowColor,
  });
}

class _SwimmingFish {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  bool isMovingRight;
  Color color;
  double wiggleOffset;
  double wiggleSpeed;
  int schoolId;

  _SwimmingFish({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.isMovingRight,
    required this.color,
    required this.wiggleOffset,
    required this.wiggleSpeed,
    this.schoolId = -1,
  });
}

class _OceanCurrent {
  double y;
  double speed;
  double thickness;
  double amplitude;
  double frequency;
  double opacity;
  Color color;
  double phase = 0.0;

  _OceanCurrent({
    required this.y,
    required this.speed,
    required this.thickness,
    required this.amplitude,
    required this.frequency,
    required this.opacity,
    required this.color,
  });
}

// Painter kết hợp hiệu ứng bọt khí, tuyết biển và sứa phát quang dưới vực sâu
class _UnderwaterEffectsPainter extends CustomPainter {
  final List<_BubbleParticle> bubbles;
  final List<_MarineSnowParticle> marineSnow;
  final List<_BioluminescentJellyfish> jellyfishes;
  final List<_SwimmingFish> fishes;
  final List<_OceanCurrent> oceanCurrents;
  final double waterSurfaceY;
  final double depth;
  final double animationValue;

  _UnderwaterEffectsPainter({
    required this.bubbles,
    required this.marineSnow,
    required this.jellyfishes,
    required this.fishes,
    required this.oceanCurrents,
    required this.waterSurfaceY,
    required this.depth,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ bọt khí (Chỉ xuất hiện khi dưới mặt nước)
    final Paint bubblePaint = Paint()..style = PaintingStyle.fill;
    for (var bubble in bubbles) {
      if (bubble.y >= waterSurfaceY) {
        Color color;
        // Bọt khí đổi sắc dịu đi khi lặn sâu
        if (depth < 1000) {
          color = const Color(0xFF00F0FF).withValues(alpha: bubble.opacity);
        } else if (depth < 4000) {
          color = const Color(0xFF00E5FF).withValues(alpha: bubble.opacity * 0.7);
        } else {
          color = const Color(0xFFE0F7FA).withValues(alpha: bubble.opacity * 0.4);
        }
        bubblePaint.color = color;
        canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, bubblePaint);
      }
    }

    // 2. Vẽ Tuyết biển (Marine Snow) - các mảnh hữu cơ rơi xuống
    final Paint snowPaint = Paint()..style = PaintingStyle.fill;
    for (var snow in marineSnow) {
      if (snow.y >= waterSurfaceY) {
        Color color;
        if (depth < 1000) {
          // Vùng cạn: các hạt bụi lơ lửng màu trắng mờ
          color = Colors.white.withValues(alpha: snow.opacity * 0.4);
        } else if (depth < 4000) {
          // Vùng hoàng hôn (twilight): ánh xanh dương nhẹ
          color = const Color(0xFF00E5FF).withValues(alpha: snow.opacity * 0.7);
        } else {
          // Vùng vực thẳm (abyss): các hạt lấp lánh nhẹ nhàng phát quang tự nhiên
          final double pulse = 0.6 + 0.4 * math.sin(animationValue * 2 * math.pi + snow.swayOffset);
          color = const Color(0xFFE0F7FA).withValues(alpha: snow.opacity * pulse * 0.9);
        }
        snowPaint.color = color;
        canvas.drawCircle(Offset(snow.x, snow.y), snow.radius, snowPaint);
      }
    }

    // 3. Vẽ sứa phát quang (Chỉ hiện rõ từ độ sâu 800m trở đi)
    if (depth > 800) {
      // Độ hiển thị tăng dần từ 800m đến 1500m
      final double visibility = ((depth - 800) / 700).clamp(0.0, 1.0);
      
      for (var jelly in jellyfishes) {
        if (jelly.y >= waterSurfaceY) {
          // Nhịp co bóp của sứa dựa trên sin
          final double pulse = math.sin(animationValue * jelly.pulseSpeed * 2 * math.pi + jelly.pulseOffset);
          final double scale = 1.0 + 0.15 * pulse;
          
          final double currentSize = jelly.size * scale;
          final double halfWidth = currentSize / 2;
          
          // Paint cho quầng sáng xung quanh sứa (Glow)
          final Paint glowPaint = Paint()
            ..color = jelly.glowColor.withValues(alpha: 0.12 * visibility)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
            
          // Paint vẽ viền sắc nét phát sáng
          final Paint linePaint = Paint()
            ..color = jelly.glowColor.withValues(alpha: 0.65 * visibility)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
            
          // Paint vẽ thân trong suốt
          final Paint fillPaint = Paint()
            ..color = jelly.glowColor.withValues(alpha: 0.3 * visibility)
            ..style = PaintingStyle.fill;

          // Vẽ quầng sáng nền
          canvas.drawCircle(Offset(jelly.x, jelly.y), currentSize * 1.6, glowPaint);
          
          // Vẽ mũ sứa (Bell/Cap)
          final Path bellPath = Path();
          bellPath.moveTo(jelly.x - halfWidth, jelly.y);
          // Bo cong hình vòm
          bellPath.cubicTo(
            jelly.x - halfWidth, jelly.y - currentSize,
            jelly.x + halfWidth, jelly.y - currentSize,
            jelly.x + halfWidth, jelly.y
          );
          // Viền nhún bèo uốn lượn dưới đáy mũ sứa
          final double rimWave = pulse * 2.0;
          bellPath.lineTo(jelly.x + halfWidth * 0.7, jelly.y + rimWave);
          bellPath.quadraticBezierTo(jelly.x + halfWidth * 0.4, jelly.y - 2 + rimWave, jelly.x + halfWidth * 0.1, jelly.y + rimWave);
          bellPath.quadraticBezierTo(jelly.x - halfWidth * 0.2, jelly.y - 2 + rimWave, jelly.x - halfWidth * 0.6, jelly.y + rimWave);
          bellPath.close();

          canvas.drawPath(bellPath, fillPaint);
          canvas.drawPath(bellPath, linePaint);

          // Vẽ xúc tu (3 dải dây uốn lượn rủ xuống)
          for (int t = -1; t <= 1; t++) {
            final double startX = jelly.x + (t * halfWidth * 0.4);
            final double startY = jelly.y;
            
            final Path tentaclePath = Path();
            tentaclePath.moveTo(startX, startY);
            
            // Xúc tu chuyển động dợn sóng
            final double controlY1 = startY + currentSize * 0.7;
            final double controlX1 = startX + math.sin(animationValue * 4 * math.pi + t + jelly.pulseOffset) * 8 * scale;
            
            final double controlY2 = startY + currentSize * 1.4;
            final double controlX2 = startX + math.cos(animationValue * 3 * math.pi + t) * 12 * scale;
            
            final double endY = startY + currentSize * 2.2;
            final double endX = startX + math.sin(animationValue * 2 * math.pi + t + jelly.pulseOffset) * 16 * scale;
            
            tentaclePath.cubicTo(controlX1, controlY1, controlX2, controlY2, endX, endY);
            
            final Paint tentaclePaint = Paint()
              ..color = jelly.glowColor.withValues(alpha: 0.45 * (1 - (t.abs() * 0.2)) * visibility)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke;
              
            canvas.drawPath(tentaclePath, tentaclePaint);
          }
        }
      }
    }

    // 4. Vẽ cá con bơi lội (Chỉ xuất hiện dưới mặt nước)
    for (var fish in fishes) {
      if (fish.y >= waterSurfaceY) {
        double depthFade = 1.0;
        if (depth > 2000.0) {
          depthFade = (1.0 - (depth - 2000.0) / 4000.0).clamp(0.15, 1.0);
        }
        _drawFish(canvas, fish, depthFade);
      }
    }

    // 5. Vẽ dòng hải lưu cuộn chảy (Chỉ xuất hiện dưới mặt nước)
    for (var current in oceanCurrents) {
      if (current.y >= waterSurfaceY) {
        final double depthFade = (depth > 2000.0)
            ? (1.0 - (depth - 2000.0) / 4000.0).clamp(0.2, 1.0)
            : 1.0;

        final Rect bounds = Rect.fromLTWH(0, 0, size.width, size.height);
        
        // Tạo shader gradient mờ dần ở hai rìa màn hình để hòa nhập mượt mà
        final shader = LinearGradient(
          colors: [
            current.color.withValues(alpha: 0.0),
            current.color.withValues(alpha: current.opacity * depthFade),
            current.color.withValues(alpha: current.opacity * depthFade),
            current.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ).createShader(bounds);

        final shaderGlow = LinearGradient(
          colors: [
            current.color.withValues(alpha: 0.0),
            current.color.withValues(alpha: current.opacity * 0.3 * depthFade),
            current.color.withValues(alpha: current.opacity * 0.3 * depthFade),
            current.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ).createShader(bounds);

        final Paint paint = Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = current.thickness
          ..strokeCap = StrokeCap.round;

        final Paint glowPaint = Paint()
          ..shader = shaderGlow
          ..style = PaintingStyle.stroke
          ..strokeWidth = current.thickness * 3.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        final Path path = Path();
        
        // Vẽ dòng hải lưu uốn lượn dạng sóng sine từ trái sang phải
        double startY = current.y + current.amplitude * math.sin(current.phase);
        path.moveTo(0, startY);
        
        for (double x = 4; x <= size.width; x += 8) {
          double cy = current.y + current.amplitude * math.sin(x * current.frequency + current.phase);
          path.lineTo(x, cy);
        }
        
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      }
    }

    // 6. Vẽ quầng tối nén áp suất (Ambient Pressure Vignette)
    if (depth > 500) {
      final double pressureProgress = ((depth - 500) / 10000.0).clamp(0.0, 1.0);
      final double vignetteOpacity = 0.15 + 0.50 * pressureProgress;
      
      final Paint pressurePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: vignetteOpacity * 0.4),
            Colors.black.withValues(alpha: vignetteOpacity),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pressurePaint);
    }
  }

  void _drawFish(Canvas canvas, _SwimmingFish fish, double visibility) {
    final double L = fish.size;
    final double H = L * 0.35;
    
    // Đuôi vẫy dựa trên thời gian
    final double wiggle = math.sin(animationValue * fish.wiggleSpeed * 2 * math.pi + fish.wiggleOffset) * (L * 0.15);
    
    final Paint paint = Paint()
      ..color = fish.color.withValues(alpha: fish.opacity * visibility)
      ..style = PaintingStyle.fill;

    final Paint glowPaint = Paint()
      ..color = fish.color.withValues(alpha: fish.opacity * 0.15 * visibility)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path path = Path();
    
    if (fish.isMovingRight) {
      // Thân cá bơi sang phải
      final double headX = fish.x + L / 2;
      final double tailX = fish.x - L / 2;
      final double centerY = fish.y;
      
      path.moveTo(tailX, centerY);
      path.quadraticBezierTo(fish.x, centerY - H, headX, centerY);
      path.quadraticBezierTo(fish.x, centerY + H, tailX, centerY);
      
      // Vây đuôi
      final double tailTipX = tailX - L * 0.25;
      path.lineTo(tailTipX, centerY - H * 0.7 + wiggle);
      path.quadraticBezierTo(tailX - L * 0.1, centerY + wiggle, tailTipX, centerY + H * 0.7 + wiggle);
      path.lineTo(tailX, centerY);
    } else {
      // Thân cá bơi sang trái
      final double headX = fish.x - L / 2;
      final double tailX = fish.x + L / 2;
      final double centerY = fish.y;
      
      path.moveTo(tailX, centerY);
      path.quadraticBezierTo(fish.x, centerY - H, headX, centerY);
      path.quadraticBezierTo(fish.x, centerY + H, tailX, centerY);
      
      // Vây đuôi
      final double tailTipX = tailX + L * 0.25;
      path.lineTo(tailTipX, centerY - H * 0.7 + wiggle);
      path.quadraticBezierTo(tailX + L * 0.1, centerY + wiggle, tailTipX, centerY + H * 0.7 + wiggle);
      path.lineTo(tailX, centerY);
    }
    
    path.close();
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UnderwaterEffectsPainter oldDelegate) {
    return true;
  }
}

class _FlyingBird {
  double x;
  double y;
  double speedX;
  double size;
  double opacity;
  bool isMovingRight;
  double wingFlapPhase;
  double wingFlapSpeed;
  int flockId;

  _FlyingBird({
    required this.x,
    required this.y,
    required this.speedX,
    required this.size,
    required this.opacity,
    required this.isMovingRight,
    required this.wingFlapPhase,
    required this.wingFlapSpeed,
    this.flockId = -1,
  });
}

class _FlyingBirdsPainter extends CustomPainter {
  final List<_FlyingBird> birds;
  _FlyingBirdsPainter({required this.birds});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    for (var bird in birds) {
      final double flap = math.sin(bird.wingFlapPhase);
      paint.color = Colors.white.withValues(alpha: bird.opacity);

      final double halfW = bird.size / 2;
      final double centerY = bird.y;
      final double centerX = bird.x;
      
      final path = Path();
      
      if (bird.isMovingRight) {
        // Cánh trái (phía sau)
        path.moveTo(centerX - halfW, centerY + flap * (halfW * 0.4));
        path.quadraticBezierTo(
          centerX - halfW * 0.5, 
          centerY - halfW * 0.3 - flap * (halfW * 0.6), 
          centerX, 
          centerY
        );
        // Cánh phải (phía trước)
        path.quadraticBezierTo(
          centerX + halfW * 0.5, 
          centerY - halfW * 0.3 - flap * (halfW * 0.6), 
          centerX + halfW, 
          centerY + flap * (halfW * 0.4)
        );
      } else {
        // Cánh phải (phía sau)
        path.moveTo(centerX + halfW, centerY + flap * (halfW * 0.4));
        path.quadraticBezierTo(
          centerX + halfW * 0.5, 
          centerY - halfW * 0.3 - flap * (halfW * 0.6), 
          centerX, 
          centerY
        );
        // Cánh trái (phía trước)
        path.quadraticBezierTo(
          centerX - halfW * 0.5, 
          centerY - halfW * 0.3 - flap * (halfW * 0.6), 
          centerX - halfW, 
          centerY + flap * (halfW * 0.4)
        );
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlyingBirdsPainter oldDelegate) => true;
}

// Glowing animation extensions for premium aesthetics
extension GlowingAnimation on Widget {
  Widget animateGlowing() {
    return _GlowingWrapper(child: this);
  }
}

class _GlowingWrapper extends StatefulWidget {
  final Widget child;
  const _GlowingWrapper({required this.child});

  @override
  State<_GlowingWrapper> createState() => _GlowingWrapperState();
}

class _GlowingWrapperState extends State<_GlowingWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

class FloatingCreature extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const FloatingCreature({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
    this.offset = 8.0,
  });

  @override
  State<FloatingCreature> createState() => _FloatingCreatureState();
}

class _FloatingCreatureState extends State<FloatingCreature> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -widget.offset, end: widget.offset).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class SeagullPainter extends CustomPainter {
  final Color color;
  SeagullPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Left wing
    path.moveTo(0, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.5);
    // Right wing
    path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height * 0.6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SeagullPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  final Color color;
  final double wavePhase;
  final double waveAmplitude;
  final double waveFrequency;

  WavePainter({
    required this.color,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.waveFrequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 4) {
      double relativeX = x / size.width;
      double y = waveAmplitude * math.sin((relativeX * waveFrequency * 2 * math.pi) + wavePhase);
      path.lineTo(x, y + size.height * 0.3);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveFrequency != waveFrequency;
  }
}

class SunshaftsPainter extends CustomPainter {
  final double animationValue;

  SunshaftsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();

    // Tính toán dao động nhẹ của các tia sáng
    final double sway1 = math.sin(animationValue * 2 * math.pi) * 12.0;
    final double sway2 = math.cos(animationValue * 2 * math.pi + 1.0) * 15.0;
    final double sway3 = math.sin(animationValue * 2 * math.pi + 2.0) * 10.0;

    // Ray 1
    path.moveTo(size.width * 0.2 + sway1, 0);
    path.lineTo(size.width * 0.45 + sway2, size.height);
    path.lineTo(size.width * 0.35 + sway2, size.height);
    path.lineTo(size.width * 0.15 + sway1, 0);
    path.close();

    // Ray 2
    path.moveTo(size.width * 0.5 + sway2, 0);
    path.lineTo(size.width * 0.8 + sway3, size.height);
    path.lineTo(size.width * 0.65 + sway3, size.height);
    path.lineTo(size.width * 0.4 + sway2, 0);
    path.close();

    // Ray 3
    path.moveTo(size.width * 0.75 + sway3, 0);
    path.lineTo(size.width * 0.98 + sway1, size.height * 0.8);
    path.lineTo(size.width * 0.9 + sway1, size.height * 0.8);
    path.lineTo(size.width * 0.7 + sway3, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SunshaftsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color color;
  ScannerCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double length = 16.0;
    final double padding = 16.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + length)
        ..lineTo(padding, padding)
        ..lineTo(padding + length, padding),
      paint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + length),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - length)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + length, size.height - padding),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - length, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerCornersPainter oldDelegate) => oldDelegate.color != color;
}

class _SeaweedPainter extends CustomPainter {
  final double scrollOffset;
  final double animationValue;
  final double waterSurfaceY;

  _SeaweedPainter({
    required this.scrollOffset,
    required this.animationValue,
    required this.waterSurfaceY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scrollOffset < 250) return;

    final double screenWidth = size.width;
    final double screenHeight = size.height;

    double depthProgress = ((scrollOffset - 550.0) / 10000.0).clamp(0.0, 1.0);

    // Render 18 overlapping plants on the left, and 18 on the right
    final int plantCount = 18;

    for (int i = 0; i < plantCount; i++) {
      double yRatio = 0.08 + (i / (plantCount - 1)) * 0.84;
      double y = yRatio * screenHeight;
      
      // Determine type: 0: Leafy Seagrass, 1: Dense Fan Coral, 2: Caulerpa Feather-moss, 3: Anemone
      int leftType = i % 4;
      int rightType = (i + 2) % 4;

      // Draw left plant
      _drawPlant(canvas, 0, y, leftType, depthProgress, true, i);

      // Draw right plant
      _drawPlant(canvas, screenWidth, y, rightType, depthProgress, false, i + plantCount);
    }
  }

  void _drawPlant(Canvas canvas, double startX, double y, int type, double depthProgress, bool isLeft, int index) {
    // Sway calculation
    double phase = index * 0.9;
    double size = 7.0 + (index % 3) * 2.0; // variable size: 7 to 11 (nhỏ gọn tinh tế)
    double sway = math.sin(animationValue * 2 * math.pi + phase) * (size * 0.18);

    // Determine colors based on depth progress
    Color baseColor;
    Color detailColor;
    bool hasGlow = false;

    if (depthProgress < 0.2) {
      // Shallow: warm/natural colors
      if (type == 0) {
        baseColor = const Color(0xFF2E5E3B);
        detailColor = const Color(0xFF7CB342);
      } else if (type == 1) {
        baseColor = const Color(0xFFD32F2F);
        detailColor = const Color(0xFFF57C00);
      } else if (type == 2) {
        baseColor = const Color(0xFF1B5E20);
        detailColor = const Color(0xFF4CAF50);
      } else {
        baseColor = const Color(0xFFC2185B);
        detailColor = const Color(0xFFFFEE58);
      }
    } else if (depthProgress < 0.5) {
      // Twilight: deep blues & teals
      if (type == 0) {
        baseColor = const Color(0xFF0F4C5C);
        detailColor = const Color(0xFF00F0FF);
      } else if (type == 1) {
        baseColor = const Color(0xFF7A1C31); // Ripe plum red (Đỏ mận chín)
        detailColor = const Color(0xFFD81B60);
      } else if (type == 2) {
        baseColor = const Color(0xFF00796B);
        detailColor = const Color(0xFF00E5FF);
      } else {
        baseColor = const Color(0xFF0D47A1);
        detailColor = const Color(0xFF00E676);
      }
    } else {
      // Abyss: glowing neon bioluminescence
      hasGlow = true;
      if (type == 0) {
        baseColor = const Color(0xFF00B0FF); // Vibrant glowing cyan/blue
        detailColor = const Color(0xFFE0F7FA); // Soft cyan glow detail
      } else if (type == 1) {
        baseColor = const Color(0xFFFF1744); // Vibrant glowing hot pink/red
        detailColor = const Color(0xFFFF8A80); // Soft red glow detail
      } else if (type == 2) {
        baseColor = const Color(0xFF8A1C34); // Deep ripe plum red (Đỏ mận chín)
        detailColor = const Color(0xFFFF527B); // Glowing pinkish plum detail
      } else {
        baseColor = const Color(0xFF580C1E); // Deep plum purple
        detailColor = const Color(0xFFFFEA00); // Glowing bright yellow
      }
    }

    // Draw ambient glow behind the plant if in deep abyss (using a simple blurred circle)
    if (hasGlow) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = detailColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      // Draw a soft glowing sphere centered at the base of the plant
      double glowX = isLeft ? startX + size * 0.4 : startX - size * 0.4;
      canvas.drawCircle(Offset(glowX, y), size * 1.2, glowPaint);
    }

    final Paint paint = Paint()..style = PaintingStyle.fill..color = baseColor;
    
    // Draw plant geometry (ONLY ONCE!)
    _paintPlantGeometry(canvas, startX, y, type, size, sway, isLeft, paint, isGlowLayer: false);
  }

  void _paintPlantGeometry(
    Canvas canvas, 
    double startX, 
    double y, 
    int type, 
    double size, 
    double sway, 
    bool isLeft, 
    Paint paint,
    {bool isGlowLayer = false}
  ) {
    // Phase for animation
    double phase = y / 50.0;

    if (type == 0) {
      // Type 0: Lush Eelgrass Cluster (Tapering green blades with central veins)
      final Paint fillPaint = Paint()..style = PaintingStyle.fill;
      final Paint veinPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isGlowLayer) {
        fillPaint.maskFilter = paint.maskFilter;
        veinPaint.maskFilter = paint.maskFilter;
      }

      int bladesCount = 5;
      for (int k = 0; k < bladesCount; k++) {
        double length = size * (0.8 + k * 0.12);
        double angle = (isLeft ? -0.42 : math.pi + 0.42) + (k - 2.0) * 0.16;
        double swayVal = math.sin(animationValue * 2 * math.pi + phase + k * 0.5) * 5.0;
        
        double endX = startX + math.cos(angle) * length + (isLeft ? swayVal : -swayVal);
        double endY = y + math.sin(angle) * length + swayVal * 0.3;
        
        double ctrlX = startX + math.cos(angle) * length * 0.5 + (isLeft ? swayVal * 0.6 : -swayVal * 0.6);
        double ctrlY = y + math.sin(angle) * length * 0.5 + swayVal * 0.2;

        // Normal direction offset for blade width
        double normalAngle = angle + math.pi / 2;
        double bladeWidth = isGlowLayer ? 3.2 : 1.4;
        double nx = math.cos(normalAngle) * bladeWidth;
        double ny = math.sin(normalAngle) * bladeWidth;

        Path path = Path();
        path.moveTo(startX, y);
        path.quadraticBezierTo(ctrlX + nx, ctrlY + ny, endX, endY);
        path.quadraticBezierTo(ctrlX - nx, ctrlY - ny, startX, y);
        path.close();

        fillPaint.color = isGlowLayer 
            ? paint.color.withValues(alpha: 0.25) 
            : (k % 2 == 0 ? paint.color : paint.color.withValues(alpha: 0.8));
        canvas.drawPath(path, fillPaint);

        // Draw central vein
        veinPaint.color = isGlowLayer 
            ? const Color(0xFF00F0FF).withValues(alpha: 0.4) 
            : const Color(0xFFC5E1A5);
        veinPaint.strokeWidth = isGlowLayer ? 1.2 : 0.6;
        
        Path veinPath = Path();
        veinPath.moveTo(startX, y);
        veinPath.quadraticBezierTo(ctrlX, ctrlY, endX, endY);
        canvas.drawPath(veinPath, veinPaint);
      }
    } 
    else if (type == 1) {
      // Type 1: Dense Coral Fan (San hô quạt đan xen - 5 NHÁNH ĐAN XUYÊN NHAU)
      final Paint coralPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = paint.color
        ..strokeWidth = isGlowLayer ? 2.8 : 1.1
        ..strokeCap = StrokeCap.round;

      if (isGlowLayer) {
        coralPaint.maskFilter = paint.maskFilter;
      }

      // Draw 5 overlapping and intersecting coral structures to create a dense, realistic colony
      // Branch 1 (Main Central Branch)
      _drawDenseCoral(canvas, startX, y, isLeft, size, sway, coralPaint);
      
      // Branch 2 (Intersecting Branch A - angled slightly upwards)
      _drawDenseCoral(canvas, startX, y - 3, isLeft, size * 0.85, sway + 2.0, coralPaint, angleOffset: -0.28);
      
      // Branch 3 (Intersecting Branch B - angled slightly downwards)
      _drawDenseCoral(canvas, startX, y + 3, isLeft, size * 0.78, sway - 2.0, coralPaint, angleOffset: 0.28);

      // Branch 4 (Intersecting Branch C - crossing upwards from below, steeper angle)
      _drawDenseCoral(canvas, startX, y + 6, isLeft, size * 0.70, sway + 3.5, coralPaint, angleOffset: -0.52);

      // Branch 5 (Intersecting Branch D - crossing downwards from above, steeper angle)
      _drawDenseCoral(canvas, startX, y - 6, isLeft, size * 0.65, sway - 3.5, coralPaint, angleOffset: 0.52);
    } 
    else if (type == 2) {
      // Type 2: Fern-like Feather Moss / Caulerpa Taxifolia (Rong rêu xanh cải tiến)
      // Grow upwards and outwards
      double stemAngle = isLeft ? -0.52 : math.pi + 0.52;
      double stemLength = size * 1.4;
      double swayVal = math.sin(animationValue * 2 * math.pi + phase) * 5.0;
      
      double endX = startX + math.cos(stemAngle) * stemLength + (isLeft ? swayVal : -swayVal);
      double endY = y + math.sin(stemAngle) * stemLength + swayVal * 0.25;
      
      double ctrlX = startX + math.cos(stemAngle) * stemLength * 0.6 + (isLeft ? swayVal * 0.5 : -swayVal * 0.5);
      double ctrlY = y + math.sin(stemAngle) * stemLength * 0.6 + swayVal * 0.15;

      // Draw main stem
      final Paint stemPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = paint.color
        ..strokeWidth = isGlowLayer ? 3.0 : 1.3
        ..strokeCap = StrokeCap.round;
      if (isGlowLayer) stemPaint.maskFilter = paint.maskFilter;
      
      Path stemPath = Path();
      stemPath.moveTo(startX, y);
      stemPath.quadraticBezierTo(ctrlX, ctrlY, endX, endY);
      canvas.drawPath(stemPath, stemPaint);

      // Draw leaflets symmetrically on both sides of the stem
      final Paint leafletPaint = Paint()..style = PaintingStyle.fill;
      if (isGlowLayer) leafletPaint.maskFilter = paint.maskFilter;

      final Paint bladderPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isGlowLayer ? paint.color.withValues(alpha: 0.4) : const Color(0xFF8CD47E);
      if (isGlowLayer) bladderPaint.maskFilter = paint.maskFilter;

      int leafletPairs = 10;
      for (int j = 1; j <= leafletPairs; j++) {
        double t = j / (leafletPairs + 1);
        
        // Find position on quadratic bezier stem
        double lx = (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * ctrlX + t * t * endX;
        double ly = (1 - t) * (1 - t) * y + 2 * (1 - t) * t * ctrlY + t * t * endY;

        // Tangent angle
        double dx = 2 * (1 - t) * (ctrlX - startX) + 2 * t * (endX - ctrlX);
        double dy = 2 * (1 - t) * (ctrlY - y) + 2 * t * (endY - ctrlY);
        double currentAngle = math.atan2(dy, dx);

        // Leaflet length gets smaller towards the tip
        double leafletLen = size * 0.25 * (1.1 - t * 0.3);

        // Draw left leaflet (pointing outward)
        _drawLeaflet(canvas, lx, ly, currentAngle - math.pi / 2 - 0.2, leafletLen, paint.color, leafletPaint, isGlowLayer);
        // Draw right leaflet (pointing outward)
        _drawLeaflet(canvas, lx, ly, currentAngle + math.pi / 2 + 0.2, leafletLen, paint.color, leafletPaint, isGlowLayer);

        // Draw air bladder at base of leaflet pair
        canvas.drawCircle(Offset(lx, ly), isGlowLayer ? 2.0 : 1.0, bladderPaint);
      }
    } 
    else {
      // Type 3: Tentacle Polyp Cluster (Khóm hải quỳ rực rỡ)
      int tentacleCount = 6;
      final Paint tentaclePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = paint.color
        ..strokeWidth = isGlowLayer ? 2.5 : 1.1
        ..strokeCap = StrokeCap.round;

      if (isGlowLayer) {
        tentaclePaint.maskFilter = paint.maskFilter;
      }

      for (int k = 0; k < tentacleCount; k++) {
        double baseAngle = -math.pi / 2.3 + (math.pi * 0.8 * k / (tentacleCount - 1));
        if (!isLeft) {
          baseAngle = math.pi - (math.pi * 0.8 * k / (tentacleCount - 1));
        }

        // Tentacle sway curve
        double tSway = math.sin(animationValue * 2 * math.pi + (k * 0.6)) * (size * 0.22);
        double tipX = startX + math.cos(baseAngle) * size + (isLeft ? tSway : -tSway);
        double tipY = y + math.sin(baseAngle) * size + tSway * 0.4;
        
        double ctrlX = startX + math.cos(baseAngle) * size * 0.4;
        double ctrlY = y + math.sin(baseAngle) * size * 0.4 + tSway;

        Path tPath = Path();
        tPath.moveTo(startX, y);
        tPath.quadraticBezierTo(ctrlX, ctrlY, tipX, tipY);
        canvas.drawPath(tPath, tentaclePaint);
        
        // Spore bead at the tip
        final Paint beadPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = isGlowLayer ? paint.color : const Color(0xFFFFEB3B);
        if (isGlowLayer) {
          beadPaint.maskFilter = paint.maskFilter;
        }
        canvas.drawCircle(Offset(tipX, tipY), isGlowLayer ? 2.5 : 1.2, beadPaint);
      }
    }
  }

  void _drawLeaflet(Canvas canvas, double lx, double ly, double angle, double length, Color baseColor, Paint paint, bool isGlowLayer) {
    double endX = lx + math.cos(angle) * length;
    double endY = ly + math.sin(angle) * length;
    
    Path path = Path();
    path.moveTo(lx, ly);
    
    // Create a small curved leaflet blade (narrower)
    double sideAngle1 = angle - 0.22;
    double sideAngle2 = angle + 0.22;
    double c1x = lx + math.cos(sideAngle1) * length * 0.45;
    double c1y = ly + math.sin(sideAngle1) * length * 0.45;
    double c2x = lx + math.cos(sideAngle2) * length * 0.45;
    double c2y = ly + math.sin(sideAngle2) * length * 0.45;
    
    path.quadraticBezierTo(c1x, c1y, endX, endY);
    path.quadraticBezierTo(c2x, c2y, lx, ly);
    path.close();

    paint.color = isGlowLayer ? baseColor.withValues(alpha: 0.3) : baseColor;
    canvas.drawPath(path, paint);
  }

  void _drawDenseCoral(Canvas canvas, double startX, double y, bool isLeft, double size, double sway, Paint paint, {double angleOffset = 0.0}) {
    double angle1 = (isLeft ? -0.55 : math.pi + 0.55) + angleOffset;
    double angle2 = (isLeft ? 0.0 : math.pi) + angleOffset;
    double angle3 = (isLeft ? 0.55 : math.pi - 0.55) + angleOffset;

    _drawRecursiveBranch(canvas, startX, y, angle1 + (sway * 0.03), size * 0.75, 3, paint);
    _drawRecursiveBranch(canvas, startX, y, angle2 + (sway * 0.03), size * 0.85, 3, paint);
    _drawRecursiveBranch(canvas, startX, y, angle3 + (sway * 0.03), size * 0.75, 3, paint);
  }

  void _drawRecursiveBranch(Canvas canvas, double x, double y, double angle, double length, int depth, Paint paint) {
    if (depth == 0) return;
    
    double endX = x + math.cos(angle) * length;
    double endY = y + math.sin(angle) * length;
    canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);

    // Recursive branches split
    _drawRecursiveBranch(canvas, endX, endY, angle - 0.35, length * 0.72, depth - 1, paint);
    _drawRecursiveBranch(canvas, endX, endY, angle + 0.35, length * 0.72, depth - 1, paint);
  }

  @override
  bool shouldRepaint(covariant _SeaweedPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.waterSurfaceY != waterSurfaceY;
  }
}

// Lớp lưu trữ trạng thái của Thủy quái Leviathan khổng lồ
class _DeepSeaLeviathan {
  double x = 0.0;
  double y = 0.0;
  double speedX = 0.0;
  double size = 0.0;
  double animationOffset = 0.0;
  bool isMovingRight = true;
  bool isActive = false;

  void activate(double startX, double startY, bool right, double sz, double spd) {
    x = startX;
    y = startY;
    isMovingRight = right;
    size = sz;
    speedX = spd * (right ? 1.0 : -1.0);
    animationOffset = math.Random().nextDouble() * 2 * math.pi;
    isActive = true;
  }
}

// Bộ vẽ bóng thủy quái khổng lồ ẩn hiện mờ ảo dưới lòng biển sâu (đặc trưng cho hội chứng thalassophobia)
class _LeviathanShadowPainter extends CustomPainter {
  final _DeepSeaLeviathan leviathan;
  final double animationValue;

  _LeviathanShadowPainter({required this.leviathan, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (!leviathan.isActive) return;

    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05) // Cực kỳ mờ ảo, ẩn hiện trong bóng tối
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28); // Nhòe cực mạnh để tạo chiều sâu nước xa xăm

    final Path path = Path();
    final double dirSign = leviathan.isMovingRight ? 1.0 : -1.0;
    final double headX = leviathan.x;
    final double headY = leviathan.y;
    final double length = leviathan.size;

    // Vẽ hình dáng thân uốn lượn hình con rắn khổng lồ
    for (int i = 0; i <= 20; i++) {
      double segmentRatio = i / 20.0;
      double segmentX = headX - (dirSign * length * segmentRatio);
      
      // Dao động sóng của từng đốt thân để tạo dáng bơi chuyển động
      double segmentY = headY + math.sin(animationValue * 4 * math.pi - segmentRatio * 3.5 * math.pi + leviathan.animationOffset) * 22.0 * (1.0 - segmentRatio * 0.4);
      
      // Độ rộng/độ dày của thân (nhỏ dần về phía đuôi)
      double thickness = (36.0 * (1.0 - segmentRatio * 0.75));
      
      if (i == 0) {
        path.moveTo(segmentX, segmentY);
      } else {
        path.lineTo(segmentX, segmentY + thickness);
      }
    }

    // Vẽ ngược lại từ đuôi về đầu để đóng kín vòng Path
    for (int i = 20; i >= 0; i--) {
      double segmentRatio = i / 20.0;
      double segmentX = headX - (dirSign * length * segmentRatio);
      double segmentY = headY + math.sin(animationValue * 4 * math.pi - segmentRatio * 3.5 * math.pi + leviathan.animationOffset) * 22.0 * (1.0 - segmentRatio * 0.4);
      double thickness = (36.0 * (1.0 - segmentRatio * 0.75));
      
      path.lineTo(segmentX, segmentY - thickness);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeviathanShadowPainter oldDelegate) => true;
}

// Lớp lưu trữ trạng thái của Mắt Quỷ Biển Sâu Khổng Lồ
class _AbyssalEye {
  double x = 0.0;
  double y = 0.0;
  double size = 0.0;
  double openProgress = 0.0; // 0.0 -> 1.0 (mở mắt), giữ nguyên, rồi -> 0.0 (nhắm mắt)
  bool isActive = false;
  bool isClosing = false;
  double gazeX = 0.0;
  double gazeY = 0.0;
  int stayOpenTicks = 0;

  void activate(double startX, double startY, double sz) {
    x = startX;
    y = startY;
    size = sz;
    openProgress = 0.0;
    isActive = true;
    isClosing = false;
    gazeX = 0.0;
    gazeY = 0.0;
    stayOpenTicks = 240; // Giữ mắt mở khoảng 4 giây ở 60fps
  }
}

// Bộ vẽ Mắt Quỷ Biển Sâu Khổng Lồ
class _AbyssalEyePainter extends CustomPainter {
  final _AbyssalEye eye;
  final double animationValue;

  _AbyssalEyePainter({required this.eye, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (!eye.isActive || eye.openProgress <= 0.0) return;

    final double x = eye.x;
    final double y = eye.y;
    final double sz = eye.size;
    final double op = eye.openProgress;

    // Tạo hình bao của mí mắt (Clipped Eyelids)
    final Path eyePath = Path();
    eyePath.moveTo(x - sz, y);
    
    // Mí mắt trên
    eyePath.quadraticBezierTo(x, y - sz * 0.7 * op, x + sz, y);
    // Mí mắt dưới
    eyePath.quadraticBezierTo(x, y + sz * 0.7 * op, x - sz, y);
    eyePath.close();

    // 1. Quầng sáng phát quang đỏ rực mờ ngoài mí mắt
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFF2200).withValues(alpha: 0.16 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(eyePath, glowPaint);

    canvas.save();
    // Giới hạn tất cả vẽ bên trong bầu mắt (Clip)
    canvas.clipPath(eyePath);

    // 2. Vẽ võng mạc (Sclera eyeball background)
    final Rect eyeRect = Rect.fromCircle(center: Offset(x, y), radius: sz);
    final Paint scleraPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFF2C0000), // Đỏ thẫm trung tâm
          Colors.black,
        ],
        stops: const [0.2, 1.0],
      ).createShader(eyeRect);
    canvas.drawRect(eyeRect, scleraPaint);

    // 3. Vẽ gân máu đáng sợ (Spooky blood veins)
    final Paint veinPaint = Paint()
      ..color = const Color(0xFFFF1133).withValues(alpha: 0.35 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    // Vẽ gân bên trái
    canvas.drawLine(Offset(x - sz, y), Offset(x - sz * 0.4, y - sz * 0.1), veinPaint);
    canvas.drawLine(Offset(x - sz * 0.6, y - sz * 0.05), Offset(x - sz * 0.3, y - sz * 0.2), veinPaint);
    canvas.drawLine(Offset(x - sz * 0.5, y - sz * 0.08), Offset(x - sz * 0.35, y + sz * 0.1), veinPaint);
    
    // Vẽ gân bên phải
    canvas.drawLine(Offset(x + sz, y), Offset(x + sz * 0.4, y - sz * 0.1), veinPaint);
    canvas.drawLine(Offset(x + sz * 0.6, y - sz * 0.05), Offset(x + sz * 0.3, y - sz * 0.2), veinPaint);
    canvas.drawLine(Offset(x + sz * 0.5, y - sz * 0.08), Offset(x + sz * 0.35, y + sz * 0.1), veinPaint);

    // 4. Vẽ lòng tử (Iris) có dịch chuyển theo điểm nhìn
    final Offset irisCenter = Offset(x + eye.gazeX, y + eye.gazeY);
    final Paint irisPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFFFD600), // Vàng neon trung tâm
          const Color(0xFFFF3D00), // Cam phát sáng rìa
          Colors.transparent,
        ],
        stops: const [0.35, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: irisCenter, radius: sz * 0.45));
    canvas.drawCircle(irisCenter, sz * 0.45, irisPaint);

    // 5. Vẽ con ngươi dọc kiểu bò sát huyền bí (Cat-like Pupil)
    final Path pupilPath = Path();
    pupilPath.moveTo(irisCenter.dx, irisCenter.dy - sz * 0.35 * op);
    pupilPath.quadraticBezierTo(
      irisCenter.dx - sz * 0.08 * op, irisCenter.dy,
      irisCenter.dx, irisCenter.dy + sz * 0.35 * op,
    );
    pupilPath.quadraticBezierTo(
      irisCenter.dx + sz * 0.08 * op, irisCenter.dy,
      irisCenter.dx, irisCenter.dy - sz * 0.35 * op,
    );
    pupilPath.close();

    final Paint pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(pupilPath, pupilPaint);

    // 6. Vẽ điểm phản quang ánh sáng trên mắt (Eye specular highlight)
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * op)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(irisCenter.dx - sz * 0.1, irisCenter.dy - sz * 0.1), sz * 0.04, highlightPaint);

    canvas.restore();

    // 7. Vẽ viền mí mắt sắc nét phát sáng nhẹ
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFFF5500).withValues(alpha: 0.6 * op)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AbyssalEyePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.eye.openProgress != eye.openProgress ||
        oldDelegate.eye.gazeX != eye.gazeX ||
        oldDelegate.eye.gazeY != eye.gazeY;
  }
}

class _GlassCrackLine {
  final Offset start;
  final Offset end;
  final double threshold;

  _GlassCrackLine(this.start, this.end, this.threshold);
}

class _ActiveGlassCrack {
  final Offset origin;
  final List<_GlassCrackLine> segments;
  double lifeProgress = 0.0; // 0.0 -> 1.0 (lan truyền), giữ nguyên, rồi -> 0.0 (phai mờ)
  double age = 0.0;
  final double maxAge;
  final double scaleSpeed;

  _ActiveGlassCrack({
    required this.origin,
    required this.segments,
    required this.maxAge,
    required this.scaleSpeed,
  });
}

// Bộ vẽ Vết Rạn Nứt Kính Tàu Lặn do Áp Suất Cực Lớn - Phiên Bản Kính Cường Lực Điện Thoại Tinh Tế Động
class _PressureCracksPainter extends CustomPainter {
  final double depth;
  final double animationValue;
  final List<_ActiveGlassCrack> cracks;

  _PressureCracksPainter({
    required this.depth,
    required this.animationValue,
    required this.cracks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (depth <= 7000 || cracks.isEmpty) return;

    // Nhấp nháy rung nhẹ áp suất vỏ tàu
    final double flicker = 0.88 + 0.12 * math.sin(animationValue * 30 * math.pi);

    for (var activeCrack in cracks) {
      final double progress = activeCrack.lifeProgress;
      if (progress <= 0.0) continue;

      // Định nghĩa các loại Paint siêu mảnh dựa trên tiến trình phai màu của vết nứt cụ thể
      // 1. Lớp bóng khúc xạ tối (Độ dày nứt kính) - màu đen siêu mảnh
      final Paint shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.45 * progress)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      // 2. Lớp khúc xạ phát sáng ánh xanh mờ dịu
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF00F0FF).withValues(alpha: 0.18 * progress * flicker)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;

      // 3. Lõi nứt rực sáng trắng phản xạ ánh sáng (Core) - cực kỳ sắc bén mảnh dẻ
      final Paint corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.82 * progress * flicker)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round;

      for (var segment in activeCrack.segments) {
        // Chỉ vẽ đoạn nứt nếu nó đã được mở (threshold <= progress)
        if (segment.threshold <= progress) {
          canvas.drawLine(segment.start, segment.end, shadowPaint);
          canvas.drawLine(segment.start, segment.end, glowPaint);
          canvas.drawLine(segment.start, segment.end, corePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PressureCracksPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
        oldDelegate.depth != depth ||
        oldDelegate.cracks.length != cracks.length;
  }
}

class _MarianaTrenchZone extends StatefulWidget {
  final VoidCallback onBackToSurface;
  final AppStrings strings;
  final double depth;

  const _MarianaTrenchZone({
    required this.onBackToSurface,
    required this.strings,
    required this.depth,
  });

  @override
  State<_MarianaTrenchZone> createState() => _MarianaTrenchZoneState();
}

class _MarianaTrenchZoneState extends State<_MarianaTrenchZone> with AutomaticKeepAliveClientMixin<_MarianaTrenchZone> {
  VideoPlayerController? _forwardController;
  VideoPlayerController? _reverseController;
  bool _isShowingForward = true;
  double _videoOpacity = 0.0;
  bool _isForwardError = false;
  bool _isReverseError = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  @override
  void didUpdateWidget(covariant _MarianaTrenchZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.depth != oldWidget.depth) {
      _handleDepthChange();
    }
  }

  void _handleDepthChange() {
    final bool isVisible = widget.depth >= 10500;
    if (isVisible) {
      if (_isShowingForward) {
        if (_forwardController != null && !_forwardController!.value.isPlaying && !_isForwardError) {
          _forwardController!.play();
        }
      } else {
        if (_reverseController != null && !_reverseController!.value.isPlaying && !_isReverseError) {
          _reverseController!.play();
        }
      }
    } else {
      if (_forwardController != null && _forwardController!.value.isPlaying) {
        _forwardController!.pause();
      }
      if (_reverseController != null && _reverseController!.value.isPlaying) {
        _reverseController!.pause();
      }
    }
  }

  Future<void> _initVideos() async {
    // 1. Khởi tạo video chạy xuôi
    try {
      _forwardController = VideoPlayerController.asset('assets/images/creatures/dark.mp4');
      await _forwardController!.initialize();
      if (mounted) {
        await _forwardController!.setLooping(false);
        await _forwardController!.setVolume(1.0);
        _forwardController!.addListener(_forwardListener);
        
        if (widget.depth >= 10500) {
          await _forwardController!.play();
        }
        
        setState(() {
          _videoOpacity = 0.18;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo video xuôi: $e");
      if (mounted) {
        setState(() {
          _isForwardError = true;
        });
      }
    }

    // 2. Khởi tạo video chạy ngược (dark_reverse.mp4)
    try {
      _reverseController = VideoPlayerController.asset('assets/images/creatures/dark_reverse.mp4');
      await _reverseController!.initialize();
      if (mounted) {
        await _reverseController!.setLooping(false);
        await _reverseController!.setVolume(1.0);
        _reverseController!.addListener(_reverseListener);
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo video ngược: $e");
      if (mounted) {
        setState(() {
          _isReverseError = true;
        });
      }
    }
  }

  void _forwardListener() {
    if (_forwardController == null || !mounted) return;
    
    final value = _forwardController!.value;
    if (value.isInitialized && 
        (!value.isPlaying && value.position >= value.duration - const Duration(milliseconds: 200))) {
      _switchToReverse();
    }
  }

  void _reverseListener() {
    if (_reverseController == null || !mounted) return;

    final value = _reverseController!.value;
    if (value.isInitialized && 
        (!value.isPlaying && value.position >= value.duration - const Duration(milliseconds: 200))) {
      _switchToForward();
    }
  }

  Future<void> _switchToReverse() async {
    if (!_isShowingForward || _reverseController == null || !_reverseController!.value.isInitialized) return;
    
    // Check if we are still at the bottom depth before playing
    if (widget.depth < 10500) {
      await _forwardController?.pause();
      await _reverseController?.pause();
      return;
    }

    // 1. Phát trước video ngược ở chế độ ẩn
    await _reverseController!.seekTo(Duration.zero);
    await _reverseController!.play();
    
    // 2. Chờ 100ms để bộ giải mã phần cứng render xong các frame đầu tiên
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Check again after delay to handle scrolling up during wait
    if (widget.depth < 10500) {
      await _forwardController?.pause();
      await _reverseController?.pause();
      return;
    }

    if (mounted) {
      setState(() {
        _isShowingForward = false; // Tráo đổi khung hình tức thì
      });
    }
    
    // 3. Tạm dừng video xuôi và tua về đầu chuẩn bị cho lượt tiếp theo
    await _forwardController?.pause();
    await _forwardController?.seekTo(Duration.zero);
  }

  Future<void> _switchToForward() async {
    if (_isShowingForward || _forwardController == null || !_forwardController!.value.isInitialized) return;

    // Check if we are still at the bottom depth before playing
    if (widget.depth < 10500) {
      await _forwardController?.pause();
      await _reverseController?.pause();
      return;
    }

    // 1. Phát trước video xuôi ở chế độ ẩn
    await _forwardController!.seekTo(Duration.zero);
    await _forwardController!.play();

    // 2. Chờ 100ms để bộ giải mã render xong các frame đầu tiên
    await Future.delayed(const Duration(milliseconds: 100));

    // Check again after delay to handle scrolling up during wait
    if (widget.depth < 10500) {
      await _forwardController?.pause();
      await _reverseController?.pause();
      return;
    }

    if (mounted) {
      setState(() {
        _isShowingForward = true; // Tráo đổi khung hình tức thì
      });
    }

    // 3. Tạm dừng video ngược và tua về đầu chuẩn bị
    await _reverseController?.pause();
    await _reverseController?.seekTo(Duration.zero);
  }

  @override
  void dispose() {
    _forwardController?.removeListener(_forwardListener);
    _forwardController?.dispose();
    _reverseController?.removeListener(_reverseListener);
    _reverseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    final bool isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    final bool isVideoVisible = widget.depth >= 10500 && isCurrentRoute;

    // Toggle play/pause based on route visibility to prevent background battery/CPU drain when screen is covered
    if (isCurrentRoute) {
      if (widget.depth >= 10500) {
        if (_isShowingForward) {
          if (_forwardController != null && !_forwardController!.value.isPlaying && !_isForwardError) {
            _forwardController!.play();
          }
        } else {
          if (_reverseController != null && !_reverseController!.value.isPlaying && !_isReverseError) {
            _reverseController!.play();
          }
        }
      }
    } else {
      if (_forwardController != null && _forwardController!.value.isPlaying) {
        _forwardController!.pause();
      }
      if (_reverseController != null && _reverseController!.value.isPlaying) {
        _reverseController!.pause();
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 60.0),
      height: 320.0,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30.0,
            spreadRadius: 5.0,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [

          // 2. Video Player xuôi
          if (isVideoVisible && _forwardController != null && _forwardController!.value.isInitialized && !_isForwardError)
            Offstage(
              offstage: !_isShowingForward,
              child: Opacity(
                opacity: _videoOpacity,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _forwardController!.value.size.width,
                      height: _forwardController!.value.size.height,
                      child: VideoPlayer(_forwardController!),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Video Player ngược
          if (isVideoVisible && _reverseController != null && _reverseController!.value.isInitialized && !_isReverseError)
            Offstage(
              offstage: _isShowingForward,
              child: Opacity(
                opacity: _videoOpacity,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _reverseController!.value.size.width,
                      height: _reverseController!.value.size.height,
                      child: VideoPlayer(_reverseController!),
                    ),
                  ),
                ),
              ),
            ),

          // 4. Nút bấm cuộn lên bề mặt tối giản ở góc dưới
          Positioned(
            right: 20.0,
            bottom: 20.0,
            child: IconButton(
              onPressed: widget.onBackToSurface,
              icon: const Icon(Icons.arrow_upward),
              color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalloonHUDButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Animation<double> animation;
  final double phaseOffset;
  final Color borderColor;
  final double scale;
  final bool isLava;

  const _BalloonHUDButton({
    required this.child,
    required this.onTap,
    required this.gradientColors,
    required this.animation,
    required this.phaseOffset,
    required this.borderColor,
    this.scale = 1.0,
    this.isLava = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          // Calculate sway offset based on animation value
          final double animationValue = animation.value;
          final double swayOffset = math.sin(animationValue * 2 * math.pi * 2.5 + phaseOffset) * 10.0;
          
          return SizedBox(
            width: 60,
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Swaying string (drawn behind/below the balloon) - only show if not lava
                if (!isLava)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomPaint(
                      painter: _BalloonStringPainter(
                        swayOffset: swayOffset,
                        balloonSize: 48.0,
                        knotColor: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                // Balloon body or Lava item
                Positioned(
                  top: 0,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Icon Container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: isLava
                              ? const BoxDecoration(
                                  color: Colors.transparent,
                                )
                              : BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                ),
                          alignment: Alignment.center,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        ),
                        // Glowing Lava Bar at the bottom of the icon
                        if (isLava)
                          Positioned(
                            bottom: -2,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 10,
                              child: CustomPaint(
                                painter: _LavaPainter(
                                  animationValue: animation.value,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalloonStringPainter extends CustomPainter {
  final double swayOffset;
  final double balloonSize;
  final Color knotColor;

  _BalloonStringPainter({
    required this.swayOffset,
    required this.balloonSize,
    required this.knotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double knotY = balloonSize;
    
    // 1. Draw the balloon knot (little triangle at the bottom center of the balloon)
    final Paint knotPaint = Paint()
      ..color = knotColor
      ..style = PaintingStyle.fill;
    
    final Path knotPath = Path()
      ..moveTo(centerX - 3.5, knotY - 1)
      ..lineTo(centerX + 3.5, knotY - 1)
      ..lineTo(centerX, knotY + 4)
      ..close();
    canvas.drawPath(knotPath, knotPaint);

    // 2. Draw the black & white swaying string
    final double startX = centerX;
    final double startY = knotY + 3;
    final double endX = centerX + swayOffset;
    final double endY = knotY + 45;
    
    // Control point for a natural curves
    final double cpX = centerX + swayOffset * 0.35;
    final double cpY = knotY + 22;

    // Evaluate quadratic bezier points and draw alternating black & white segments
    const int segments = 22;
    for (int i = 0; i < segments; i++) {
      final double t1 = i / segments;
      final double t2 = (i + 1) / segments;
      
      final Offset p1 = _getQuadraticPoint(startX, startY, cpX, cpY, endX, endY, t1);
      final Offset p2 = _getQuadraticPoint(startX, startY, cpX, cpY, endX, endY, t2);

      // Thicker black outline line
      final Paint blackPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, blackPaint);

      // Draw white stripes on alternate segments to create a striped rope effect
      if (i % 2 == 0) {
        final Paint whitePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, whitePaint);
      }
    }
  }

  Offset _getQuadraticPoint(double x0, double y0, double x1, double y1, double x2, double y2, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    
    final double x = uu * x0 + 2 * u * t * x1 + tt * x2;
    final double y = uu * y0 + 2 * u * t * y1 + tt * y2;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _BalloonStringPainter oldDelegate) {
    return oldDelegate.swayOffset != swayOffset || oldDelegate.knotColor != knotColor;
  }
}

class _LavaPainter extends CustomPainter {
  final double animationValue;

  _LavaPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Wave calculations using sine waves shifting over time (boiling/rippling effect)
    final double angle = animationValue * 2 * math.pi;
    
    // Generate organic wavy path
    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, h * 0.55);
    
    // Create multiple organic liquid wave points
    final double y1 = h * 0.5 + math.sin(angle * 4.0) * 1.5;
    final double y2 = h * 0.35 + math.cos(angle * 2.5) * 2.2;
    final double y3 = h * 0.55 + math.sin(angle * 5.0) * 1.2;
    
    path.quadraticBezierTo(w * 0.25, y1, w * 0.5, y2);
    path.quadraticBezierTo(w * 0.75, y3, w, h * 0.45);
    path.lineTo(w, h);
    path.close();

    // 1. Draw Deep Orange Glowing Shadow
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF3D00).withValues(alpha: 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 + math.sin(angle * 3.0) * 1.5);
    canvas.drawPath(path, glowPaint);

    // 2. Draw Yellow Hot Center Glow
    final Paint coreGlow = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path, coreGlow);

    // 3. Draw Liquid Gradient Body
    final Paint lavaPaint = Paint()
      ..style = PaintingStyle.fill;
    
    final rect = Rect.fromLTWH(0, 0, w, h);
    // Flow shift shifts the gradient sideways for a fluid moving effect
    final double shift = math.sin(angle * 1.5) * 0.15;
    lavaPaint.shader = LinearGradient(
      colors: const [
        Color(0xFFFF1744), // Molten red
        Color(0xFFFF3D00), // Lava orange
        Color(0xFFFF9100), // Bright orange
        Color(0xFFFFEA00), // Glowing yellow
        Color(0xFFFF3D00), // Lava orange
      ],
      begin: Alignment(-1.0 + shift, 0.0),
      end: Alignment(1.0 + shift, 0.0),
    ).createShader(rect);

    canvas.drawPath(path, lavaPaint);
  }

  @override
  bool shouldRepaint(covariant _LavaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}



