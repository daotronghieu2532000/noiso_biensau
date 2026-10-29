-- ===================================================================
-- CODE GO / NỖI SỢ BIỂN SÂU - BẢNG ĐÓNG GÓP Ý KIẾN, TRẢI NGHIỆM & GÓC NHÌN
-- File: api/setup_feedbacks.sql
-- Mục đích: Lưu trữ toàn bộ phản hồi, đánh giá sao, góc nhìn cá nhân và góp ý của người dùng
-- ===================================================================

CREATE TABLE IF NOT EXISTS `user_feedbacks` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_name` VARCHAR(150) DEFAULT 'Ẩn danh Thủy Thủ',
  `user_email` VARCHAR(150) DEFAULT NULL,
  `rating` TINYINT(1) NOT NULL DEFAULT 5 COMMENT 'Đánh giá từ 1 đến 5 sao',
  `feedback_type` VARCHAR(50) NOT NULL DEFAULT 'experience' COMMENT 'experience (trải nghiệm), opinion (góc nhìn), suggestion (góp ý), bug_report (báo lỗi)',
  `title` VARCHAR(255) DEFAULT NULL COMMENT 'Tiêu đề tóm tắt nếu có',
  `content` TEXT NOT NULL COMMENT 'Nội dung chi tiết ý kiến, góc nhìn hoặc trải nghiệm',
  `device_info` VARCHAR(255) DEFAULT NULL COMMENT 'Thông tin thiết bị, hệ điều hành và phiên bản app',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT 'Địa chỉ IP người gửi',
  `status` ENUM('new', 'reviewed', 'resolved', 'archived') NOT NULL DEFAULT 'new' COMMENT 'Trạng thái xử lý của ban quản trị',
  `admin_notes` TEXT DEFAULT NULL COMMENT 'Ghi chú nội bộ của admin khi duyệt phản hồi',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm gửi phản hồi',
  PRIMARY KEY (`id`),
  KEY `idx_rating` (`rating`),
  KEY `idx_feedback_type` (`feedback_type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Lưu trữ ý kiến đóng góp, trải nghiệm đánh giá và góc nhìn cá nhân của người dùng';

-- Mẫu dữ liệu mẫu ban đầu (để kiểm tra hiển thị admin nếu cần)
INSERT INTO `user_feedbacks` (`user_name`, `user_email`, `rating`, `feedback_type`, `title`, `content`, `device_info`, `status`) VALUES
('Thuyền Trưởng Alex', 'alex.navigator@ocean.net', 5, 'experience', 'Cảm giác lặn cực kỳ sống động', 'Hiệu ứng âm thanh sonar và tiếng cá voi ở độ sâu 3000m quá đỉnh, tạo cảm giác rợn gáy chân thực!', 'iOS 18.0 - iPhone 15 Pro Max', 'reviewed'),
('Nhà Nghiên Cứu Hải Dương', 'marine.bio@deepsea.org', 5, 'opinion', 'Góc nhìn về quái vật Kraken', 'Tôi nghĩ có thể bổ sung thêm phân tích về cơ chế phát quang sinh học của mực khổng lồ Architeuthis dux để ứng dụng phong phú hơn nữa.', 'Android 14 - Samsung Galaxy S24 Ultra', 'new'),
('Thủy thủ ẩn danh', NULL, 4, 'suggestion', 'Ý tưởng thêm sinh vật rãnh Mariana', 'Mong ban biên tập thêm nhiều video tư liệu thực tế từ tàu ngầm Trieste và lặn thám hiểm Challenger Deep.', 'iOS 17.5 - iPad Air', 'new');
