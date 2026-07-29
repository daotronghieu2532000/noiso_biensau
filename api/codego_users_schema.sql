-- CODE GO API - USERS TABLE SCHEMA
-- File an toan cho public repository, khong chua du lieu nguoi dung that.

CREATE TABLE IF NOT EXISTS `codego_users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `mobile` varchar(20) DEFAULT NULL,
  `total_points` int(11) DEFAULT 0,
  `current_streak` int(11) DEFAULT 0,
  `longest_streak` int(11) DEFAULT 0,
  `level` int(11) DEFAULT 1,
  `country` varchar(2) DEFAULT 'VN',
  `device_token` varchar(255) DEFAULT NULL,
  `platform` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` int(11) NOT NULL,
  `updated_at` int(11) NOT NULL,
  `last_login` int(11) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_username` (`username`),
  KEY `idx_email` (`email`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_total_points` (`total_points`),
  KEY `idx_country` (`country`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample seed du lieu toi thieu de test local.
INSERT INTO `codego_users` (
  `username`, `email`, `password`, `name`, `avatar`, `mobile`,
  `total_points`, `current_streak`, `longest_streak`, `level`,
  `country`, `device_token`, `platform`, `is_active`,
  `created_at`, `updated_at`, `last_login`
) VALUES (
  'demo_user',
  'demo@example.com',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'Demo User',
  NULL,
  NULL,
  0,
  0,
  0,
  1,
  'VN',
  NULL,
  NULL,
  1,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(),
  NULL
);
