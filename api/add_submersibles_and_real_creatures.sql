-- ==============================================================================
-- CODE GO API - THÊM DỮ LIỆU TÀU LẶN THÁM HIỂM VÀ XÁC TÀU ĐẮM LỊCH SỬ
-- Mục đích: Bổ sung 3 Tàu Lặn (submersible) và 1 Xác Tàu (shipwreck) vào bảng `creatures`
-- Sử dụng: Chạy file SQL này trên phpMyAdmin hoặc MySQL console của database `codego`
-- ==============================================================================

-- 1. XÁC TÀU RMS TITANIC (Độ sâu 3.800m - Xác tàu đắm nổi tiếng nhất lịch sử)
INSERT INTO `creatures` (
  `id`, `name`, `name_en`, `scientific_name`, `type`, 
  `min_depth`, `max_depth`, `danger_level`, 
  `size_human_ratio`, `size_human_ratio_en`, 
  `human_size_meters`, `creature_size_meters`, 
  `image_url`, `video_url`, `ambient_sound`, 
  `description`, `description_en`, `is_locked`
) VALUES (
  'wreck_titanic', 
  'Xác Tàu RMS Titanic', 
  'RMS Titanic Shipwreck', 
  'Olympic-class ocean liner wreck (1912)', 
  'shipwreck', 
  3800, 
  3840, 
  2, 
  'Đại hạm khổng lồ (Dài 269m, nằm gãy đôi dưới đáy thẳm)', 
  'Colossal ocean liner (269m long, resting in two pieces)', 
  1.8, 
  269.0, 
  'assets/images/creatures/wreck_titanic.png', 
  'https://codego.io.vn/api/uploads/videos/Titanic_shipwreck.mp4',
  'deep_hum.mp3', 
  'Xác con tàu du lịch huyền thoại chìm năm 1912 sau khi đâm vào tảng băng trôi. Hiện nay mũi tàu và đuôi tàu nằm cô độc ở độ sâu 3,800 mét dưới đáy Đại Tây Dương, được bao phủ bởi những thạch nhũ rỉ sét do vi khuẩn ăn sắt Halomonas titanicae tạo thành giữa bóng đêm vĩnh hằng.', 
  'The iconic shipwreck of the luxury ocean liner that sank in 1912 after striking an iceberg. Resting 3,800 meters beneath the North Atlantic, the massive bow and stern are draped in icicle-like rusticles formed by iron-eating bacteria in eternal darkness.', 
  1
) ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `name_en` = VALUES(`name_en`),
  `scientific_name` = VALUES(`scientific_name`),
  `type` = VALUES(`type`),
  `min_depth` = VALUES(`min_depth`),
  `max_depth` = VALUES(`max_depth`),
  `danger_level` = VALUES(`danger_level`),
  `size_human_ratio` = VALUES(`size_human_ratio`),
  `size_human_ratio_en` = VALUES(`size_human_ratio_en`),
  `human_size_meters` = VALUES(`human_size_meters`),
  `creature_size_meters` = VALUES(`creature_size_meters`),
  `image_url` = VALUES(`image_url`),
  `video_url` = VALUES(`video_url`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `description` = VALUES(`description`),
  `description_en` = VALUES(`description_en`),
  `is_locked` = VALUES(`is_locked`);


-- 2. TÀU LẶN ALVIN DSV-2 (Độ sâu 4.500m - Con tàu lặn huyền thoại tìm ra Titanic)
INSERT INTO `creatures` (
  `id`, `name`, `name_en`, `scientific_name`, `type`, 
  `min_depth`, `max_depth`, `danger_level`, 
  `size_human_ratio`, `size_human_ratio_en`, 
  `human_size_meters`, `creature_size_meters`, 
  `image_url`, `video_url`, `ambient_sound`, 
  `description`, `description_en`, `is_locked`
) VALUES (
  'sub_alvin', 
  'Tàu Lặn Alvin (DSV-2)', 
  'DSV-2 Alvin Submersible', 
  'Deep Submergence Vehicle (WHOI)', 
  'submersible', 
  4500, 
  6500, 
  1, 
  'To lớn (Dài 7.1m, trang bị cánh tay robot kép)', 
  'Submersible (7.1m long with dual mechanical arms)', 
  1.8, 
  7.1, 
  'assets/images/creatures/sub_alvin.png', 
  'https://codego.io.vn/api/uploads/videos/Submersible_collecting.mp4',
  'sonar_echo.mp3', 
  'Con tàu lặn nghiên cứu khoa học lừng danh nhất lịch sử của Viện Hải dương học Woods Hole. Alvin đã thực hiện hơn 5,000 chuyến lặn, nổi tiếng với sứ mệnh tìm thấy xác tàu RMS Titanic năm 1986 và phát hiện hệ sinh thái miệng phun thủy nhiệt biển sâu lần đầu tiên trên Trái Đất.', 
  'The legendary deep-ocean research submersible operated by Woods Hole Oceanographic Institution. Alvin has completed over 5,000 dives, famously exploring the Titanic wreck in 1986 and discovering deep-sea hydrothermal vent ecosystems.', 
  0
) ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `name_en` = VALUES(`name_en`),
  `scientific_name` = VALUES(`scientific_name`),
  `type` = VALUES(`type`),
  `min_depth` = VALUES(`min_depth`),
  `max_depth` = VALUES(`max_depth`),
  `danger_level` = VALUES(`danger_level`),
  `size_human_ratio` = VALUES(`size_human_ratio`),
  `size_human_ratio_en` = VALUES(`size_human_ratio_en`),
  `human_size_meters` = VALUES(`human_size_meters`),
  `creature_size_meters` = VALUES(`creature_size_meters`),
  `image_url` = VALUES(`image_url`),
  `video_url` = VALUES(`video_url`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `description` = VALUES(`description`),
  `description_en` = VALUES(`description_en`),
  `is_locked` = VALUES(`is_locked`);


-- 3. DEEPSEA CHALLENGER (Độ sâu 10.908m - Tàu lặn đơn của đạo diễn James Cameron)
INSERT INTO `creatures` (
  `id`, `name`, `name_en`, `scientific_name`, `type`, 
  `min_depth`, `max_depth`, `danger_level`, 
  `size_human_ratio`, `size_human_ratio_en`, 
  `human_size_meters`, `creature_size_meters`, 
  `image_url`, `video_url`, `ambient_sound`, 
  `description`, `description_en`, `is_locked`
) VALUES (
  'sub_deepsea_challenger', 
  'Deepsea Challenger (James Cameron)', 
  'Deepsea Challenger Submersible', 
  'Vertical Submersible (Acheron Project)', 
  'submersible', 
  10890, 
  10908, 
  1, 
  'Dài thẳng đứng 7.3m, khoang lái thép hình cầu hẹp 1.09m', 
  '7.3m vertical spear, 1.09m spherical pilot sphere', 
  1.8, 
  7.3, 
  'assets/images/creatures/sub_deepsea_challenger.png', 
  'https://codego.io.vn/api/uploads/videos/Submersible_descending.mp4',
  'sonar_echo.mp3', 
  'Cỗ máy lặn thẳng đứng màu xanh neon mang tính cách mạng được thiết kế riêng cho đạo diễn James Cameron. Năm 2012, ông đã tự lái một mình xuống độ sâu kỷ lục 10,908m tại Rãnh Mariana, chịu áp lực nước hơn 1,000 atmosphere để thu thập mẫu vật và quay phim 3D biển sâu.', 
  'The revolutionary lime-green vertical submersible piloted solo by director James Cameron in 2012 to the bottom of the Mariana Trench (10,908m), enduring crushing pressures exceeding 1,000 atmospheres to film and collect abyssal specimens.', 
  1
) ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `name_en` = VALUES(`name_en`),
  `scientific_name` = VALUES(`scientific_name`),
  `type` = VALUES(`type`),
  `min_depth` = VALUES(`min_depth`),
  `max_depth` = VALUES(`max_depth`),
  `danger_level` = VALUES(`danger_level`),
  `size_human_ratio` = VALUES(`size_human_ratio`),
  `size_human_ratio_en` = VALUES(`size_human_ratio_en`),
  `human_size_meters` = VALUES(`human_size_meters`),
  `creature_size_meters` = VALUES(`creature_size_meters`),
  `image_url` = VALUES(`image_url`),
  `video_url` = VALUES(`video_url`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `description` = VALUES(`description`),
  `description_en` = VALUES(`description_en`),
  `is_locked` = VALUES(`is_locked`);


-- 4. TÀU LẶN TRIESTE (Độ sâu 10.911m - Chuyến lặn lịch sử năm 1960 của loài người)
INSERT INTO `creatures` (
  `id`, `name`, `name_en`, `scientific_name`, `type`, 
  `min_depth`, `max_depth`, `danger_level`, 
  `size_human_ratio`, `size_human_ratio_en`, 
  `human_size_meters`, `creature_size_meters`, 
  `image_url`, `video_url`, `ambient_sound`, 
  `description`, `description_en`, `is_locked`
) VALUES (
  'sub_trieste', 
  'Tàu Lặn Trieste (1960)', 
  'Bathyscaphe Trieste', 
  'Bathyscaphe Trieste (US Navy)', 
  'submersible', 
  10911, 
  10916, 
  1, 
  'Khổng lồ (Dài 18m, phao chứa 85,000 lít xăng)', 
  'Massive (18m long with 85,000L gasoline float)', 
  1.8, 
  18.0, 
  'assets/images/creatures/sub_trieste.png', 
  'https://codego.io.vn/api/uploads/videos/Bathyscaphe_descending.mp4',
  'sonar_echo.mp3', 
  'Kỳ tích vĩ đại đầu tiên của nhân loại chạm đáy Vực sâu Challenger (10,911m) thuộc Rãnh Mariana vào ngày 23/1/1960 bởi Jacques Piccard và Don Walsh. Tàu sử dụng phao xăng để tạo lực nổi và một khoang cầu thép Krupp dày 12.7 cm để bảo vệ phi hành đoàn trước sức ép 1.1 tấn/cm².', 
  'The historic bathyscaphe that first carried humans—Jacques Piccard and Don Walsh—to the lowest point on Earth, Challenger Deep (10,911m), on January 23, 1960. It used a massive gasoline float for buoyancy and a 12.7cm-thick forged Krupp steel sphere.', 
  0
) ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `name_en` = VALUES(`name_en`),
  `scientific_name` = VALUES(`scientific_name`),
  `type` = VALUES(`type`),
  `min_depth` = VALUES(`min_depth`),
  `max_depth` = VALUES(`max_depth`),
  `danger_level` = VALUES(`danger_level`),
  `size_human_ratio` = VALUES(`size_human_ratio`),
  `size_human_ratio_en` = VALUES(`size_human_ratio_en`),
  `human_size_meters` = VALUES(`human_size_meters`),
  `creature_size_meters` = VALUES(`creature_size_meters`),
  `image_url` = VALUES(`image_url`),
  `video_url` = VALUES(`video_url`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `description` = VALUES(`description`),
  `description_en` = VALUES(`description_en`),
  `is_locked` = VALUES(`is_locked`);
