-- CODE GO API - SETUP VIDEOS DATABASE
-- Database name: codego (as configured in config.php)
-- Run this SQL file on your phpMyAdmin / MySQL server to create the videos table and populate the initial data.

-- 1. Create table
CREATE TABLE IF NOT EXISTS `videos` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `title_en` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `description_en` TEXT NOT NULL,
  `video_url` VARCHAR(2000) NOT NULL,
  `thumbnail_url` VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Clean table before insert (optional, to avoid duplicate keys)
TRUNCATE TABLE `videos`;

-- 3. Insert initial 9 videos with server URLs (urlencoded for space and special characters)
INSERT INTO `videos` (
  `title`, `title_en`, `description`, `description_en`, `video_url`, `thumbnail_url`
) VALUES 
('Hành Trình Băng Giá: Nơi Tận Cùng Thế Giới', 
 'Frozen Voyage: The End of the World', 
 'Thước phim từ trên boong tàu thám hiểm lịch sử, băng qua những rặng băng tuyết vĩnh cửu tại đại dương cô lập nhất thế giới.', 
 'Footage from the deck of a historic tall ship, navigating through endless ice walls in the planet\'s most remote and frozen ocean.', 
 'https://codego.io.vn/api/uploads/videos/Above%20the%20Deck...%20Into%20the%20Frozen%20End%20of%20the%20World%20%20Towering%20masts...%20Endless%20ice...%20And%20one%20of%20the%20planet\'s%20most%20remote%20oceans%20stretching%20to%20the%20horizon.%20This%20image%20appears%20to%20show%20the%20--mast%20of%20the%20historic%20tall%20.mp4', 
 'assets/images/creatures/ocean_arctic.png'),

('Sinh Vật Lạ Dưới Đáy Ấn Độ Dương', 
 'Strange Abyssal Creature in Indian Ocean', 
 'Các nhà khoa học kinh ngạc trước thước phim ghi lại một thực thể sống kỳ dị chưa từng được biết đến ở vùng sâu thẳm Ấn Độ Dương.', 
 'Scientists were shocked to capture footage of an unidentified strange creature during an expedition in the remote Indian Ocean depths.', 
 'https://codego.io.vn/api/uploads/videos/Cient%C3%ADficos%20quedaron%20impactados%20al%20registrar%20esta%20extra%C3%B1a%20criatura%20en%20las%20profundidades%20del%20oc%C3%A9ano.%20Una%20recente%20expedici%C3%B3n%20cient%C3%ADfica%20realizada%20por%20investigadores%20de%20Australia%20en%20una%20zona%20remota%20del%20Oc%C3%A9ano%20%C3%8Dndico%20.mp4', 
 'assets/images/creatures/anglerfish.png'),

('Nỗi Sợ Tột Cùng: Kraken Khởi Nguyên', 
 'Deepest Fears: The Genesis of Kraken', 
 'Một thước phim khoa học viễn tưởng ngắn miêu tả nỗi ám ảnh kinh hoàng nhất của nhân loại từ đáy vực sâu.', 
 'A sci-fi cinematic depiction showcasing humanity\'s deepest fears lurking within the dark abyss.', 
 'https://codego.io.vn/api/uploads/videos/Enjoy%20your%20deepest%20fears%E2%80%A6%20%23ai%20%23deepocean%20%23scifi%23kraken%23films.mp4', 
 'assets/images/creatures/kraken.png'),

('Quái Thú Miocene: Siêu Cá Voi Livyatan', 
 'Miocene Leviathan: Livyatan Melvillei', 
 'Tìm hiểu về loài cá voi săn mồi khổng lồ thời tiền sử từng thống trị đại dương, đối thủ truyền kiếp của Megalodon.', 
 'Explore the history of Livyatan melvillei, the massive predatory whale and apex prehistoric rival of Megalodon.', 
 'https://codego.io.vn/api/uploads/videos/Livyatan%20%20The%20Giant%20Killer%20Whale%20of%20the%20Miocene%20%20Livyatan%20melvillei%20was%20a%20massive%20predatory%20whale%20that%20lived%20about%201213%20million%20years%20ago%20in%20the%20Miocene%20seas%20off%20Peru.%20It%20was%20one%20of%20the%20top%20ocean%20predators%20of%20its%20t.mp4', 
 'assets/images/creatures/bg_shark.jpeg'),

('Hải Long vs Bạch Tuộc Khổng Lồ', 
 'Sea Dragon vs Giant Octopus', 
 'Thước phim gây sốc quay từ trực thăng cận cảnh cuộc chiến sinh tử giữa một sinh vật giống rồng biển và bạch tuộc khổng lồ.', 
 'Shocking footage captured from a helicopter of an epic battle between a sea dragon-like beast and a giant octopus.', 
 'https://codego.io.vn/api/uploads/videos/Lo%20que%20vimos%20desde%20el%20helic%C3%B3ptero%20nos%20dej%C3%B3%20sin%20alienti!%20%20Una%20criatura%20extra%C3%B1a%20tipo%20drag%C3%B3n%20marino%20luchando%20contra%20un%20pulpo%20gigante%20en%20el%20Pac%C3%ADfico.%20Inolvidable!%20%20%23Misterio%20%23Terror%20%23Mar%20%23impactante%20-------------------.mp4', 
 'assets/images/creatures/leviathan.png'),

('Sự Trỗi Dậy Của Kraken: Cơn Thịnh Nộ', 
 'Rise of the Kraken: The Fury', 
 'Kỹ xảo điện ảnh đỉnh cao tái hiện khoảnh khắc quái thú xúc tu khổng lồ thức tỉnh phá hủy hạm đội tàu bè.', 
 'High-end VFX cinematic showing the legendary multi-tentacled sea monster awakening to crush fleets.', 
 'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%20%23creative%20%23vfx%20%23movie%20%23kraken%23monster.mp4', 
 'assets/images/creatures/bg_kraken.jpeg'),

('Kraken Trỗi Dậy 2027: Teaser Khởi Động', 
 'Rise of the Kraken 2027: Teaser Launch', 
 'Đoạn phim giới thiệu điện ảnh đặc biệt, hứa hẹn mở ra kỷ nguyên thức tỉnh đầy kinh hoàng của thủy quái Kraken.', 
 'Special teaser trailer illustrating the upcoming terrifying cinematic return of the Kraken in 2027.', 
 'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%2C%20Coming%202027.%20%23creative%20%23vfx%20%23movie%20%23monster%20%23kraken.mp4', 
 'assets/images/creatures/bg_dark_abyss.jpeg'),

('Hồ Sơ Cthulhu: Tà Thần Vực Thẳm', 
 'Cthulhu Dossier: The Cosmic Threat', 
 'Giai thoại đầy kinh hoàng và chân thực về sự trỗi dậy của Tà Thần Cthulhu từ thành phố chìm sâu R\'lyeh.', 
 'The chilling and disturbing legend of the great cosmic entity Cthulhu awakening from the sunken city of R\'lyeh.', 
 'https://codego.io.vn/api/uploads/videos/S%C3%AD%2C%20conozco%20la%20historia%20de%20Cthulhu%2C%20una%20de%20las%20criaturas%20m%C3%A1s%20ic%C3%B3nicas%20creadas%20por%20el%20escritor%20H.%20P.%20Lovecraft.%20Aqu%C3%AD%20te%20la%20cuento%20de%20forma%20clara%20v%C3%A0%20perturbadora%2C%20como%20suele%20gustar%20en%20tus%20contenidos-%20%20Qui%C3%A9n%20es%20Cthulhu.mp4', 
 'assets/images/creatures/Cthulhu.png'),

('Phác Họa Kraken: Quy Trình AI', 
 'Sketching Kraken: AI Design Workflow', 
 'Thước phim phác thảo nghệ thuật về cấu trúc sinh học và chuyển động thực tế của thủy quái Kraken bằng trí tuệ nhân tạo.', 
 'An artistic workflow visualization detailing the biological structure and motion of the Kraken using advanced AI.', 
 'https://codego.io.vn/api/uploads/videos/V%C3%ADdeo%20Kraken%20100_%20IA%20Workflow%20de%20Nano%20b.mp4', 
 'assets/images/creatures/bg_bermuda.jpeg');
