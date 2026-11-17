-- ==============================================================================
-- CODE GO API - THÊM 4 VIDEO TƯ LIỆU (3 TÀU LẶN + 1 XÁC TÀU TITANIC)
-- Bảng: `videos`
-- Hướng dẫn: Copy và chạy trong tab SQL của phpMyAdmin trên hosting `codego`
-- ==============================================================================

INSERT INTO `videos` (`title`, `title_en`, `description`, `description_en`, `video_url`, `thumbnail_url`) VALUES
(
  'Xác Tàu RMS Titanic: Ngủ Yên Ở Độ Sâu 3.800m', 
  'RMS Titanic Wreck: Resting at 3,800m Depth', 
  'Thước phim tư liệu cận cảnh mũi tàu RMS Titanic huyền thoại phủ đầy thạch nhũ rỉ sét dưới đáy Bắc Đại Tây Dương lạnh giá sau hơn một thế kỷ chìm sâu trong bóng đêm vĩnh hằng.', 
  'Close-up documentary footage of the iconic RMS Titanic bow draped in rusticles at the bottom of the freezing North Atlantic after over a century in eternal darkness.', 
  'https://codego.io.vn/api/uploads/videos/Titanic_shipwreck.mp4', 
  'assets/images/creatures/wreck_titanic.png'
),
(
  'Tàu Lặn Alvin (DSV-2): Khám Phá Titanic & Miệng Phun Thủy Nhiệt', 
  'DSV-2 Alvin: Exploring Titanic & Hydrothermal Vents', 
  'Hành trình của con tàu lặn nghiên cứu khoa học lừng danh Alvin với cánh tay robot kép, thực hiện hơn 5.000 chuyến lặn khám phá xác tàu Titanic và hệ sinh thái ống khói đen dưới đáy đại dương.', 
  'The journey of the legendary research submersible Alvin with dual robotic arms, completing over 5,000 dives to explore the Titanic wreck and deep-sea hydrothermal vent ecosystems.', 
  'https://codego.io.vn/api/uploads/videos/Submersible_collecting.mp4', 
  'assets/images/creatures/sub_alvin.png'
),
(
  'James Cameron: Đơn Độc Thám Hiểm Rãnh Mariana 10.908m', 
  'James Cameron: Solo Dive to the Mariana Trench 10,908m', 
  'Thước phim tư liệu thám hiểm ghi lại hành trình lịch sử của đạo diễn James Cameron trên chiếc Deepsea Challenger màu xanh neon, tự mình lặn xuống điểm sâu nhất Trái Đất để ghi lại những thước phim 3D chân thực về thế giới không ánh sáng.', 
  'Expedition documentary footage chronicling filmmaker James Cameron\'s historic solo dive aboard the lime-green Deepsea Challenger, descending to Earth\'s deepest point to capture real 3D footage of the lightless abyss.', 
  'https://codego.io.vn/api/uploads/videos/Submersible_descending.mp4', 
  'assets/images/creatures/sub_deepsea_challenger.png'
),
(
  'Kỳ Tích Trieste 1960: Chạm Đáy Vực Thẳm Challenger 10.911m', 
  'Bathyscaphe Trieste 1960: Conquering the Challenger Deep', 
  'Thước phim tư liệu lịch sử ghi lại khoảnh khắc huyền thoại khi Jacques Piccard và Don Walsh điều khiển tàu lặn Trieste vượt qua áp suất nghiền nát để chạm đáy 10.911m tại Rãnh Mariana lần đầu tiên trong lịch sử nhân loại.', 
  'Historic archival documentary footage capturing Jacques Piccard and Don Walsh piloting the bathyscaphe Trieste through crushing pressures to touch the bottom of the Mariana Trench (10,911m) for the first time in human history.', 
  'https://codego.io.vn/api/uploads/videos/Bathyscaphe_descending.mp4', 
  'assets/images/creatures/sub_trieste.png'
);
