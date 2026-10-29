-- ========================================================
-- CÂU LỆNH SQL THÊM CỘT CÔNG TẮC VIDEO BÌA VÀO BẢNG `stories`
-- ========================================================

-- 1. Thêm 2 cột mới vào bảng `stories`:
--    - `is_cover_video`: 0 = hiển thị ảnh bìa tĩnh (cover_image), 1 = hiển thị video bìa (cover_video)
--    - `cover_video`: Đường dẫn URL video bìa
ALTER TABLE `stories` 
  ADD COLUMN `is_cover_video` TINYINT(1) DEFAULT 0 AFTER `is_vip`,
  ADD COLUMN `cover_video` VARCHAR(255) DEFAULT '' AFTER `is_cover_video`;

-- 2. Cập nhật sẵn đường dẫn video cho cả 10 câu chuyện (mặc định để is_cover_video = 0):
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/Rise%20of%20The%20Kraken%2C%20Coming%202027.%20%23creative%20%23vfx%20%23movie%20%23monster%20%23kraken.mp4' WHERE `story_id` = 'davy_jones';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/black_pearl_ghost_ship.mp4' WHERE `story_id` = 'black_pearl';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/bermuda_triangle_vortex.mp4' WHERE `story_id` = 'bermuda_triangle';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/cthulhu_awakening.mp4' WHERE `story_id` = 'cthulhu_abyss';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/mariana_trench_leviathan.mp4' WHERE `story_id` = 'mariana_trench';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/mary_celeste_ghost.mp4' WHERE `story_id` = 'mary_celeste';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/ourang_medan_distress.mp4' WHERE `story_id` = 'ourang_medan';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/the_bloop_leviathan.mp4' WHERE `story_id` = 'the_bloop';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/hms_terror_arctic.mp4' WHERE `story_id` = 'hms_terror';
UPDATE `stories` SET `cover_video` = 'https://codego.io.vn/api/uploads/videos/megalodon_hunt.mp4' WHERE `story_id` = 'megalodon';

-- ========================================================
-- HƯỚNG DẪN BẬT / TẮT CÔNG TẮC (SWITCH VIDEO / IMAGE):
-- ========================================================
-- Khi muốn truyện hiển thị VIDEO bìa:
-- UPDATE `stories` SET `is_cover_video` = 1 WHERE `story_id` = 'davy_jones';
--
-- Khi muốn truyện quay lại hiển thị ẢNH bìa:
-- UPDATE `stories` SET `is_cover_video` = 0 WHERE `story_id` = 'davy_jones';
