-- ========================================================
-- BỔ SUNG 5 CÂU CHUYỆN THỦY THỦ MỚI VÀO DATABASE (ID 6 ĐẾN 10)
-- TÀU MA MARY CELESTE, OURANG MEDAN, THE BLOOP, HMS TERROR, MEGALODON
-- ========================================================

INSERT INTO `stories` (`story_id`, `title`, `title_en`, `subtitle`, `subtitle_en`, `author`, `read_time_minutes`, `cover_image`, `ambient_sound`, `is_vip`, `content_json`) VALUES
(
  'mary_celeste',
  'Bí Ẩn Tàu Ma Mary Celeste: Bữa Ăn Dở Dang Giữa Đại Dương',
  'The Mystery of Mary Celeste: The Untouched Ocean Feast',
  'Chiếc thuyền buồm trôi dạt vô định giữa Đại Tây Dương với chiếc bàn ăn còn nguyên hơi ấm',
  'A ghost brigantine adrift in the Atlantic with an untouched warm meal upon the table',
  'Thuyền Trưởng David Morehouse',
  8,
  'assets/images/creatures/bg_mary_celeste.jpg',
  'assets/sounds/shallow_water.mp3',
  0,
  '[
  {
    "type": "log_entry",
    "header": "HẢI TRÌNH NGÀY 04 THÁNG 12 NĂM 1872 • TỌA ĐỘ 38°20''B - 17°15''T • CÁCH ĐẢO AZORES 600 HẢI LÝ",
    "header_en": "LOG ENTRY DECEMBER 4, 1872 • COORD 38°20''N - 17°15''W • 600 NAUTICAL MILES OFF THE AZORES",
    "text": "Nhật ký cứu nạn tàu buôn Dei Gratia. Chúng tôi phát hiện một cánh buồm song song lảo đảo trong làn sương chiều. Đó là Mary Celeste — con tàu hai cột buồm kiên cố của người bạn cũ Benjamin Briggs. Cánh buồm giương xiêu vẹo hứng gió vụng về, không có bất kỳ hiệu lệnh phản hồi nào từ cột cờ hay boong lái.",
    "text_en": "Salvage log of merchant brigantine Dei Gratia. We sighted an erratic sail swaying through the twilight sea fog. It was Mary Celeste — the sturdy brigantine of my old friend Captain Benjamin Briggs. Her sails fluttered clumsily before the breeze, with no signal answering from helm or mast."
  },
  {
    "type": "paragraph",
    "text": "Khi toán thủy thủ đổ bộ trèo thang dây lên boong tàu Mary Celeste, một sự tĩnh lặng đến lạnh gáy bao trùm lấy không gian. Không có dấu hiệu của một cuộc giao chiến hay cướp biển. Mọi thứ trên tàu vẫn nguyên vẹn một cách kỳ lạ: 1.701 thùng cồn công nghiệp trong khoang hàng vẫn xếp ngay ngắn, nước ngọt và lương thực đủ dùng cho sáu tháng không hề suy chuyển.",
    "text_en": "When our boarding party climbed aboard the Mary Celeste, a spine-chilling stillness gripped the air. There were no marks of mutiny, violence, or piracy. Everything remained unnervingly undisturbed: 1,701 barrels of industrial alcohol stacked neatly below decks, and six months worth of freshwater and provisions untouched."
  },
  {
    "type": "whisper",
    "text": "“Thưa thuyền trưởng... Trong cabin của ngài Briggs, ấm trà vẫn còn âm ấm, tẩu thuốc của ông ấy vẫn còn tàn tro chưa nguội hẳn. Họ không bỏ chạy... Họ dường như vừa bị thứ gì đó bốc hơi khỏi mặt đất chỉ vài phút trước!”",
    "text_en": "“Captain... In Briggs''s cabin, the tea kettle was still lukewarm, his tobacco pipe still holding fresh ash. They didn''t flee in panic... It is as if they were plucked clean out of thin air only minutes ago!”"
  },
  {
    "type": "image",
    "url": "assets/images/creatures/bg_mary_celeste.jpg",
    "caption": "Tàu ma Mary Celeste trôi dạt vô định giữa làn sương mù Đại Tây Dương với boong tàu vắng bóng người",
    "caption_en": "The ghost brigantine Mary Celeste drifting deserted amidst the eerie Atlantic fog"
  },
  {
    "type": "paragraph",
    "text": "Điều gây kinh hãi tột cùng nằm ở chiếc bàn ăn trong phòng thuyền trưởng: ba chiếc đĩa súp vẫn chưa nguội hẳn, đồ chơi của cô con gái nhỏ Sophia hai tuổi còn vương trên tấm thảm len, và chiếc máy khâu của người vợ Sarah vẫn cắm dở một đường chỉ lụa. Chiếc xuồng cứu sinh duy nhất đã biến mất, nhưng chiếc la bàn điều hướng bị đập nát một cách cuồng loạn, và cuốn nhật ký hải trình dừng lại đột ngột ở ngày 25 tháng 11 mà không ghi lại bất kỳ tai ương nào.",
    "text_en": "The ultimate horror lay upon the captain''s dining table: three breakfast bowls remained untouched, two-year-old Sophia''s toys lay on the wool rug, and Sarah''s sewing machine was threaded mid-stitch. The sole yawl was gone, but the marine binnacle compass was violently smashed, and the logbook abruptly ceased on November 25th with no mention of storm or crisis."
  },
  {
    "type": "quote",
    "text": "Biển cả không bao giờ nuốt chửng chỉ có thân xác. Đôi khi, nó mở ra một khe nứt của thời gian và lấy đi toàn bộ linh hồn, để lại cỗ quan tài gỗ trôi nổi thách thức lý trí con người.",
    "text_en": "The ocean does not merely swallow flesh and bone. At times, it splits open a fissure in reality and devours souls entirely, leaving a wooden coffin drifting to mock human reason."
  },
  {
    "type": "video",
    "url": "https://codego.io.vn/api/uploads/videos/mary_celeste_ghost.mp4",
    "caption": "Tái hiện khoảnh khắc rùng rợn khi thủy thủ tàu cứu hộ bước vào boong tàu bỏ hoang Mary Celeste",
    "caption_en": "Cinematic visual of rescuers stepping aboard the deserted Mary Celeste"
  },
  {
    "type": "paragraph",
    "text": "Dưới khoang lái ngập hơn một thước nước biển trong vắt, chúng tôi tìm thấy chiếc đồng hồ bấm giờ hàng hải bị ai đó tháo rời từng bánh răng, xếp thành hình một vòng tròn đồng tâm quái dị trên mặt bàn bản đồ. Không có vết máu, không có di thư. Mười con người — gồm cả phụ nữ và trẻ thơ — như thể đã tự nguyện bước chân xuống mặt nước phẳng lặng như gương rồi chìm vào cõi hư vô không dấu vết.",
    "text_en": "In the flooded hold beneath three feet of crystal clear bilge water, we discovered the chronometer stripped into individual brass cogs, arranged into bizarre concentric circles across the chart table. No bloodstains, no farewell notes. Ten souls — including mother and child — seemingly stepped calmly into the mirror-like ocean and vanished into oblivion."
  },
  {
    "type": "climax_quote",
    "header": "DÒNG GHI CHÚ BẰNG BÚT CHÌ TRÊN BẢN ĐỒ BIỂN MARY CELESTE",
    "header_en": "FAINT PENCIL SCRAWL FOUND BEHIND THE MARITIME CHART",
    "text": "“Gió đã tắt hoàn toàn... nhưng có thứ gì đó đang gọi tên con gái ta từ dưới đáy nước. Cả đoàn tàu đều nghe thấy nó. Chúng ta không thể cưỡng lại việc bước ra ngoài lan can...”",
    "text_en": "“The wind is utterly dead... yet something whispers Sophia''s name from beneath the water. The entire crew hears the cadence. We cannot resist walking to the rail...”"
  },
  {
    "type": "paragraph",
    "text": "Tòa án Hàng hải Hoàng gia Anh tại Gibraltar đã mở phiên điều trần kéo dài suốt ba tháng với hàng trăm câu hỏi thẩm vấn, nhưng không một học giả hay chuyên gia hàng hải nào có thể đưa ra lời giải thích hợp lý. Mary Celeste mãi mãi là một vết sẹo bí ẩn không đáy của lịch sử hàng hải nhân loại.",
    "text_en": "The British Vice-Admiralty Court at Gibraltar conducted a grueling three-month inquiry, yet no naval scholar could fathom how ten living people vanished into calm seas without leaving a shred of clothing or debris. Mary Celeste remains an abyssal scar on the annals of nautical history."
  },
  {
    "type": "epilogue_warning",
    "header": "HỒ SƠ TÒA ÁN HÀNG HẢI GIBRALTAR SỐ 1873-MC",
    "header_en": "GIBRALTAR ADMIRALTY ARCHIVE FILE NO. 1873-MC",
    "text": "Mọi giả thuyết về cướp biển, ngộ độc cồn hay sóng độc đều bất khả thi trước sự nguyên vẹn của hàng hóa. Đừng bao giờ dừng thuyền lắng nghe tiếng thì thầm khi mặt biển không có một ngọn gió.",
    "text_en": "All theories of piracy, alcohol fumes, or rogue waves fail against the immaculate order of the cargo. Never anchor to listen when the sea whispers during a dead calm."
  }
]'
) ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `title_en` = VALUES(`title_en`),
  `subtitle` = VALUES(`subtitle`),
  `subtitle_en` = VALUES(`subtitle_en`),
  `author` = VALUES(`author`),
  `read_time_minutes` = VALUES(`read_time_minutes`),
  `cover_image` = VALUES(`cover_image`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `is_vip` = VALUES(`is_vip`),
  `content_json` = VALUES(`content_json`);

INSERT INTO `stories` (`story_id`, `title`, `title_en`, `subtitle`, `subtitle_en`, `author`, `read_time_minutes`, `cover_image`, `ambient_sound`, `is_vip`, `content_json`) VALUES
(
  'ourang_medan',
  'Tàu Ma SS Ourang Medan: Nụ Cười Kinh Hoàng Dưới Eo Biển',
  'Ghost Ship Ourang Medan: The Frozen Scream of Malacca',
  'Bức điện tín tử thần SOS và toàn bộ thủy thủ đoàn chết trong tư thế trợn tròn mắt hướng lên trời',
  'The fatal SOS telegram and an entire crew frozen in terror pointing at the sky',
  'Sĩ Quan Cứu Hộ Silver Star',
  8,
  'assets/images/creatures/bg_ourang_medan.jpg',
  'assets/sounds/static_crackle.mp3',
  1,
  '[
  {
    "type": "log_entry",
    "header": "BỨC ĐIỆN TÍN KHẨN CẤP THÁNG 6 NĂM 1947 • TẦNG SÓNG MORSE 600M • EO BIỂN MALACCA",
    "header_en": "EMERGENCY MORSE INTERCEPT JUNE 1947 • 600-METER BAND • STRAIT OF MALACCA",
    "text": "Các đài thu tín hiệu vô tuyến tại Sumatra và Malaysia đồng loạt bắt được tín hiệu cấp cứu đứt quãng từ tàu chở hàng Hà Lan SS Ourang Medan: “S.O.S... Thuyền trưởng và tất cả sĩ quan đã chết gục trong phòng hải đồ và buồng lái... Có khả năng toàn bộ thủy thủ đoàn đã chết...” Sau đó là một chuỗi mã Morse hỗn loạn, rồi kết thúc bằng hai từ rùng rợn: “TÔI CHẾT.”",
    "text_en": "Radio stations across Sumatra and British Malaya intercepted jagged SOS distress signals from Dutch freighter SS Ourang Medan: “S.O.S... Captain and all officers are dead in chartroom and bridge... Probably whole crew dead...” Followed by frantic erratic Morse clicks, concluding with two chilling words: “I DIE.”"
  },
  {
    "type": "paragraph",
    "text": "Tàu buôn Mỹ Silver Star là con tàu gần nhất chuyển hướng tiếp cận mục tiêu. Giữa làn sương mù dày đặc và nước biển phẳng lặng như dầu luộc của eo biển Malacca, chiếc tàu khổng lồ Ourang Medan hiện ra trôi dạt lầm lũi trong bóng đêm, các cột đèn hoa tiêu chập chờn le lói mà không hề phát ra một tiếng động cơ nào.",
    "text_en": "The American merchant ship Silver Star diverted course to investigate. Through thick sulfurous fog and oil-slick waters of the Malacca Strait, the hulking silhouette of Ourang Medan emerged drifting in silence, navigation lamps flickering weakly with her boilers completely dead."
  },
  {
    "type": "whisper",
    "text": "“Đừng chạm vào họ! Nhìn đôi mắt của họ xem... Mọi người trên con tàu này đều chết trong cùng một giây, và họ đang nhìn chằm chằm vào khoảng không phía trên buồng lái!”",
    "text_en": "“Do not touch them! Look at their eyes... Everyone on this vessel died in the very same instant, and they are all staring upward above the wheelhouse!”"
  },
  {
    "type": "image",
    "url": "assets/images/creatures/bg_ourang_medan.jpg",
    "caption": "Tàu hơi nước SS Ourang Medan trôi dạt trong màn sương đêm ma quái với ánh đèn hoa tiêu le lói",
    "caption_en": "The steam freighter SS Ourang Medan adrift in ghostly night mist with faint lanterns"
  },
  {
    "type": "paragraph",
    "text": "Toán cứu hộ bước lên boong tàu và chứng kiến một cơn ác mộng sống động: xác các thủy thủ nằm la liệt trên sàn gỗ, lưng ưỡn cong, hai cánh tay giương lên như đang cản một thực thể vô hình trên không trung. Miệng họ há hốc trong một tiếng thét câm lặng, đôi mắt mở trừng trừng đầy kinh hãi, khuôn mặt co giật thành một nụ cười quái đản hướng về phía mặt trời chói chang.",
    "text_en": "The boarding team stepped onto the main deck into a living nightmare: corpses littered the teak decking, backs arched in spasms, arms outstretched as if shielding themselves from an invisible entity in the sky. Their jaws hung wide in a silent scream, eyes bulging in stark terror, faces frozen into gruesome rictus grins."
  },
  {
    "type": "quote",
    "text": "Có những thứ trỗi dậy từ đáy rãnh biển sâu mà đôi mắt trần của con người không thể chịu đựng nổi. Chỉ một cái nhìn lướt qua cũng đủ khiến trái tim ngừng đập và khối óc đông đặc vì kinh hãi.",
    "text_en": "There are entities ascending from abyssal trenches that mortal eyes were never forged to behold. A single fleeting gaze freezes the human heart and shatters the mind."
  },
  {
    "type": "video",
    "url": "https://codego.io.vn/api/uploads/videos/ourang_medan_distress.mp4",
    "caption": "Thước phim trinh sát ghi lại hiện trường kinh dị của thủy thủ đoàn tàu ma SS Ourang Medan",
    "caption_en": "Reconnaissance footage documenting the frozen corpses aboard SS Ourang Medan"
  },
  {
    "type": "paragraph",
    "text": "Trong buồng vô tuyến, nhân viên điện đài vẫn ngồi ngay ngắn trên ghế, ngón tay trỏ vẫn còn đặt trên cần phát tín hiệu Morse. Ngay cả con chó cảnh giới của tàu cũng chết trong tư thế nhe nanh giận dữ về phía khoảng không vô định. Điều kỳ quặc nhất là nhiệt độ trong khoang tàu lạnh buốt như hầm đông băng dù ngoài trời là cái nóng nhiệt đới 40°C, và trên xác chết hoàn toàn không hề có một vết thương hay vết máu nào.",
    "text_en": "Inside the radio shack, the radio operator sat upright in his chair, index finger still resting upon the telegraph key. Even the ship''s mastiff dog lay dead, teeth bared aggressively at empty space. Most unnerving was the frigid air inside the holds, chilling as a meat locker despite the blistering 40°C equatorial heat, with not a single drop of blood or wound on any corpse."
  },
  {
    "type": "climax_quote",
    "header": "NHẬT KÝ SĨ QUAN CỨU HỘ SILVER STAR KHI DÂY CÁP ĐỨT TUNG",
    "header_en": "LOG OF SILVER STAR FIRST OFFICER BEFORE THE EXPLOSION",
    "text": "“Chúng tôi vừa buộc cáp kéo Ourang Medan thì dưới khoang hàng số 4 bốc lên làn khói màu tím sẫm tanh nồng! Nhiệt độ vỏ thép tăng vọt trong tích tắc! Cắt cáp ngay! Con tàu đang phát nổ từ bên trong đáy biển!”",
    "text_en": "“We had barely secured the tow line when dense violet vapors billowed from Cargo Hold No. 4! The steel hull superheated in seconds! Cut the cable! She is detonating from deep within the abyss!”"
  },
  {
    "type": "paragraph",
    "text": "Toán cứu hộ vừa kịp rút lui về tàu Silver Star thì một vụ nổ kinh hoàng xé toạc thân tàu Ourang Medan làm đôi. Ngọn lửa màu xanh lục bốc cao hàng chục mét rồi kéo toàn bộ con tàu ma cùng mọi bằng chứng chìm thẳng xuống độ sâu hàng ngàn mét dưới đáy eo biển Malacca.",
    "text_en": "The rescue party barely scrambled back to Silver Star when a monstrous underwater explosion tore Ourang Medan in two. Green flames roared dozens of meters into the air, dragging the ghost ship and every horrific mystery into the depths of the Malacca abyss."
  },
  {
    "type": "epilogue_warning",
    "header": "TÀI LIỆU BẢO MẬT CƠ QUAN TÌNH BÁO HẢI QUÂN HOA KỲ (ONI)",
    "header_en": "US OFFICE OF NAVAL INTELLIGENCE CLASSIFIED MEMO",
    "text": "Hồ sơ chính thức về SS Ourang Medan đã bị niêm phong. Bất kỳ tàu hàng nào phát hiện tín hiệu Morse lặp lại chuỗi ký tự ''I DIE'' ở tọa độ Malacca phải lập tức tắt radio và tăng tốc rời khỏi khu vực.",
    "text_en": "The official registry of SS Ourang Medan was purged. Any vessel intercepting the repeating Morse code sequence ''I DIE'' around Malacca coordinates must immediately power down radio transmitters and steam away at maximum speed."
  }
]'
) ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `title_en` = VALUES(`title_en`),
  `subtitle` = VALUES(`subtitle`),
  `subtitle_en` = VALUES(`subtitle_en`),
  `author` = VALUES(`author`),
  `read_time_minutes` = VALUES(`read_time_minutes`),
  `cover_image` = VALUES(`cover_image`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `is_vip` = VALUES(`is_vip`),
  `content_json` = VALUES(`content_json`);

INSERT INTO `stories` (`story_id`, `title`, `title_en`, `subtitle`, `subtitle_en`, `author`, `read_time_minutes`, `cover_image`, `ambient_sound`, `is_vip`, `content_json`) VALUES
(
  'the_bloop',
  'Tiếng Gầm Nam Thái Bình Dương: Thực Thể Thủy Quái The Bloop',
  'South Pacific Roar: The Bloop Abyssal Leviathan',
  'Âm thanh sinh học siêu trầm chấn động 5.000 km đại dương của loài thủy quái vượt kích thước cá voi xanh',
  'The ultra-low frequency biological shockwave heard across 5,000 km of deep ocean',
  'Tiến Sĩ Christopher Fox',
  9,
  'assets/images/creatures/bg_the_bloop.jpg',
  'assets/sounds/The_BLOOP.mp3',
  0,
  '[
  {
    "type": "log_entry",
    "header": "DỮ LIỆU THỦY ÂM HẢI QUÂN SOSUS • MÙA HÈ NĂM 1997 • TỌA ĐỘ 50°N - 100°T • ĐỘ SÂU 4.300M",
    "header_en": "SOSUS HYDROPHONE ARRAY LOG • SUMMER 1997 • COORD 50°S - 100°W • DEPTH 4,300M",
    "text": "Mạng lưới cảm biến thủy âm quân sự dưới đáy biển Thái Bình Dương đồng loạt ghi nhận một xung sóng âm siêu trầm cực mạnh. Tần số dao động nhanh chóng tăng vọt từ phổ hạ âm dưới 40Hz kéo dài suốt 1,1 phút. Tín hiệu này vang dội qua khoảng cách hơn 5.000 km, kích hoạt cảm biến từ tận trạm xích đạo đến bờ biển Nam Cực.",
    "text_en": "The military deep-sea acoustic sensor array (SOSUS) across the Pacific detected an ultra-low frequency shockwave. The frequency rose steadily from sub-40Hz infrasound over 1.1 minutes. The sound propagated over 5,000 km, triggering hydrophones from the equator to the Antarctic ice sheet."
  },
  {
    "type": "paragraph",
    "text": "Khi các nhà khoa học âm học của Cục Quản lý Khí quyển và Đại dương Quốc gia (NOAA) phân tích dạng sóng phổ đồ, họ bàng hoàng nhận ra đây không phải là tiếng nổ tàu ngầm, cũng không phải động đất kiến tạo đáy biển. Đường cong biến thiên âm thanh mang đặc trưng sinh học hoàn hảo — giống hệt tiếng gọi bầy của động vật biển có vú, nhưng lớn hơn tiếng gầm của một con cá voi xanh trưởng thành gấp hàng trăm lần.",
    "text_en": "When acousticians at NOAA examined the spectrographic frequency curve, they were stunned. It was neither a submarine blast nor an undersea seismic fracture. The harmonic harmonic modulation was unmistakably biological — identical to the vocal call of marine animals, yet hundreds of times louder than the mightiest blue whale."
  },
  {
    "type": "whisper",
    "text": "“Các cậu tính toán kích thước của nó dựa trên cường độ âm thanh chưa? Để tạo ra một làn sóng âm xuyên thủng 5.000 km nước biển đặc quánh... sinh vật đó phải dài ít nhất 250 mét. Đó không phải cá voi... Đó là một vị thần biển cổ đại!”",
    "text_en": "“Have you calculated the creature''s volume from the acoustic displacement? To forge an acoustic pulse traveling 5,000 km through dense ocean water... that organism must measure at least 250 meters. That is no whale... that is an ancient sea god!”"
  },
  {
    "type": "image",
    "url": "assets/images/creatures/bg_the_bloop.jpg",
    "caption": "Thiết bị thủy âm quét đáy đại dương phát hiện phần thân gai nhọn khổng lồ của thực thể The Bloop",
    "caption_en": "Deep-sea sonar scanning illuminates the titanic ridged flank of The Bloop leviathan"
  },
  {
    "type": "paragraph",
    "text": "Kỳ lạ hơn cả, tọa độ phát ra âm thanh Bloop — 50° vĩ Nam, 100° kinh Tây — chỉ cách tọa độ hư cấu của thành phố chìm R''lyeh trong thần thoại H.P. Lovecraft chưa đầy 1.700 hải lý. Nơi đây là vùng biển xa xôi và cô lập nhất hành tinh, được mệnh danh là Điểm Nemo, nơi nghĩa địa vệ tinh không gian rơi xuống và ánh sáng mặt trời vĩnh viễn không chạm tới đáy vực.",
    "text_en": "Most uncanny of all, the epicentral coordinates of The Bloop — 50°S, 100°W — lay less than 1,700 nautical miles from the mythological sunken city of R''lyeh penned decades prior by H.P. Lovecraft. This is Point Nemo, the Oceanic Pole of Inaccessibility, where defunct space stations are buried and sunlight never pierces the abyss."
  },
  {
    "type": "quote",
    "text": "Con người mới chỉ vẽ được bản đồ bề mặt Sao Hỏa chi tiết hơn 80% đáy biển của chính hành tinh mình. Dưới tầng nước đen vĩnh cửu, những kẻ khổng lồ tiền sử chưa từng tuyệt chủng.",
    "text_en": "Humanity has mapped the surface of Mars with greater fidelity than 80% of our own seabed. Beneath the eternal dark waters, prehistoric titans never went extinct."
  },
  {
    "type": "video",
    "url": "https://codego.io.vn/api/uploads/videos/the_bloop_leviathan.mp4",
    "caption": "Tái hiện quét hình ảnh thủy âm 3D về bóng dáng thực thể The Bloop trườn qua rãnh vực",
    "caption_en": "3D sonar acoustic reconstruction showing The Bloop gliding across the abyssal trench"
  },
  {
    "type": "paragraph",
    "text": "Năm 2008, một đoàn thám hiểm hải dương học sử dụng tàu lặn tự hành không người lái trang bị cảm biến sonar mảng quét sâu đã bắt gặp một rãnh nứt địa chất mới xuất hiện. Khi chiếu đèn halogen xuống kẽ nứt, camera đã ghi lại được khoảnh khắc một lớp da sừng xám xịt phủ đầy những ký sinh trùng phát sáng kích thước bằng người trưởng thành, đang chậm rãi uốn lượn lặn sâu xuống đáy manti Trái Đất.",
    "text_en": "In 2008, an autonomous oceanic exploration drone equipped with deep-scanning sonar encountered a newly opened abyssal fissure. Lowering halogen arrays into the trench, the camera captured a massive grey armored hide encrusted with human-sized bioluminescent parasites, slowly coiling down into the Earth''s mantle."
  },
  {
    "type": "climax_quote",
    "header": "ĐOẠN GHI ÂM BUỒNG ĐIỀU HÀNH TRẠM THỦY ÂM NOAA",
    "header_en": "TRANSMISSION FROM NOAA ACOUSTICS HEADQUARTERS",
    "text": "“Bộ lọc hạ âm vừa bắt được tiếng gầm thứ hai... Lần này âm lượng tăng thêm 14 decibel và đang di chuyển ngược dòng hải lưu về phía bờ biển Nam Mỹ! Nó đã thức giấc rồi!”",
    "text_en": "“The infrasound filter just caught a second roar... This pulse is 14 decibels louder and swimming against the Humboldt current toward South America! It has awakened!”"
  },
  {
    "type": "paragraph",
    "text": "Ngay sau khi thông tin bị rò rỉ, cơ quan khí quyển đã vội vã đưa ra lời đính chính rằng đó chỉ là ''tiếng nứt của một tảng băng trôi khổng lồ ở Nam Cực''. Nhưng các nhà khoa học tham gia dự án đều hiểu rằng: không một tảng băng nào có thể phát ra âm thanh dao động sinh học theo nhịp tim và tiếng thở.",
    "text_en": "Shortly after the leaks, officials hastily issued a press release claiming it was merely ''an Antarctic icequake''. Yet every acoustician on the watch knew the truth: no cracking glacier produces a harmonic cadence synchronized with heartbeat and respiration."
  },
  {
    "type": "epilogue_warning",
    "header": "QUY ƯỚC QUỐC TẾ VỀ QUẢN LÝ DẢI TẦN DƯỚI NƯỚC",
    "header_en": "INTERNATIONAL HYDRO-ACOUSTIC REGULATION PROTOCOL",
    "text": "Cấm tuyệt đối mọi hoạt động nổ mìn thăm dò dầu khí hoặc phát sóng sonar công suất vượt quá 220 decibel tại khu vực Nam Thái Bình Dương. Chúng ta không được phép gọi thứ đang nằm dưới đó trỗi dậy.",
    "text_en": "Strictly prohibits any seismic blasting or military active sonar exceeding 220 decibels in the South Pacific basin. We must never summon what lies slumbering below."
  }
]'
) ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `title_en` = VALUES(`title_en`),
  `subtitle` = VALUES(`subtitle`),
  `subtitle_en` = VALUES(`subtitle_en`),
  `author` = VALUES(`author`),
  `read_time_minutes` = VALUES(`read_time_minutes`),
  `cover_image` = VALUES(`cover_image`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `is_vip` = VALUES(`is_vip`),
  `content_json` = VALUES(`content_json`);

INSERT INTO `stories` (`story_id`, `title`, `title_en`, `subtitle`, `subtitle_en`, `author`, `read_time_minutes`, `cover_image`, `ambient_sound`, `is_vip`, `content_json`) VALUES
(
  'hms_terror',
  'Hải Trình Băng Giá HMS Terror: Quái Thú Vùng Cực Tuunbaq',
  'The Frozen Voyage of HMS Terror: The Arctic Beast Tuunbaq',
  'Bi kịch đoàn thám hiểm Franklin bị giam cầm trong băng vĩnh cửu và bóng ma săn người trắng toát',
  'The doomed Franklin expedition trapped in pack ice and hunted by a white apex nightmare',
  'Thuyền Trưởng Francis Crozier',
  9,
  'assets/images/creatures/bg_hms_terror.jpg',
  'assets/sounds/low_pressure.m4a',
  1,
  '[
  {
    "type": "log_entry",
    "header": "NHẬT KÝ HẢI QUÂN HOÀNG GIA ANH • THÁNG 4 NĂM 1848 • ĐẢO KING WILLIAM • BẮC BĂNG DƯƠNG",
    "header_en": "ROYAL NAVY ADMIRALTY LOG • APRIL 1848 • KING WILLIAM ISLAND • THE ARCTIC",
    "text": "Chiến thuyền HMS Terror và HMS Erebus đã bị đóng băng hoàn toàn suốt 19 tháng liên tiếp. Băng tuyết ép nghẹt thân tàu sồi bọc sắt, tiếng gỗ nứt toác từng đêm tựa tiếng xương người bị nghiền vụn. Đô đốc Sir John Franklin đã chết. 105 thủy thủ còn sống sót quyết định bỏ tàu, kéo lê những chiếc thuyền cứu sinh chất đầy đồ bạc trên sa mạc băng trắng xóa.",
    "text_en": "HMS Terror and HMS Erebus have been locked in pack ice for 19 grueling months. The creeping ice crushes our iron-sheathed oak hulls, echoing through the night like splintering human bones. Sir John Franklin is dead. 105 starving survivors abandoned ship, hauling heavy mahogany cutters across the desolate white desert."
  },
  {
    "type": "paragraph",
    "text": "Nhưng cái lạnh âm 50 độ C và bệnh còi xương không phải là bản án tử hình tồi tệ nhất. Trong màn đêm địa cực kéo dài suốt ba tháng không thấy mặt trời, một thực thể săn mồi khổng lồ bắt đầu theo dấu đoàn thám hiểm. Nó to lớn gấp ba lần một con gấu bắc cực hung dữ nhất, sở hữu khuôn mặt mang những nét u hồn tựa con người, và bộ lông trắng hòa tan tuyệt đối vào bão tuyết mù mịt.",
    "text_en": "Yet sub-zero temperatures of minus 50°C and scurvy were not our deadliest executioner. In the perpetual polar night where the sun vanishes for months, a predatory behemoth stalked our tracks. Thrice the bulk of the fiercest polar bear, with a visage unnervingly human, its alabaster fur blended seamlessly into blinding blizzards."
  },
  {
    "type": "whisper",
    "text": "“Các anh có ngửi thấy mùi lưu huỳnh và mỡ cá voi cháy khét trong gió không? Nó đang đứng trên gờ băng ngay phía sau lều của chúng ta... Đừng thò đầu ra ngoài, bất cứ ai rời hàng ngũ đều bị nó cắp đi mà không để lại một tiếng kêu!”",
    "text_en": "“Do you smell the burning blubber and sulfur on the gale? It looms upon the ice ridge directly behind our tents... Keep your head down, for anyone who steps outside is snatched without a whimper!”"
  },
  {
    "type": "image",
    "url": "assets/images/creatures/bg_hms_terror.jpg",
    "caption": "HMS Terror bị chôn vùi trong lớp băng vĩnh cửu dưới ánh sáng cực quang huyền bí",
    "caption_en": "HMS Terror entombed in pack ice beneath shimmering ethereal aurora borealis"
  },
  {
    "type": "paragraph",
    "text": "Người Eskimo bản địa gọi nó là Tuunbaq — hiện thân của linh hồn băng giá cổ xưa được nuôi dưỡng bởi sự phẫn nộ của vùng cực. Mỗi đêm trôi qua, một người lính gác lại biến mất bí ẩn. Sáng hôm sau, đồng đội chỉ tìm thấy những khẩu súng trường bị bẻ cong như cọng rơm và những vết cào sâu hoắm xé toạc các khối băng dày hơn hai thước.",
    "text_en": "The native Inuit call it the Tuunbaq — a spirit titan born of ancient ice, nourished by the wrath of the frozen north. With each passing night, a sentry disappeared. Morning patrols recovered only muskets bent like dry twigs and gouges carved two feet deep into solid glacial ice."
  },
  {
    "type": "quote",
    "text": "Bắc Cực không dung thứ cho sự ngạo mạn của văn minh con người. Khi la bàn mất phương hướng và thức ăn cạn kiệt, con người sẽ nhận ra họ không phải kẻ thống trị chuỗi thức ăn.",
    "text_en": "The Arctic forgives no imperial vanity. When compasses whirl aimlessly and rations turn to poison, man learns he is never at the apex of the food chain."
  },
  {
    "type": "video",
    "url": "https://codego.io.vn/api/uploads/videos/hms_terror_arctic.mp4",
    "caption": "Thước phim tái hiện bóng ma quái thú tuyết trắng rình rập toán thám hiểm giữa bão tuyết cực địa",
    "caption_en": "Cinematic visual of the polar demon stalking the stranded explorers through arctic storm"
  },
  {
    "type": "paragraph",
    "text": "Tuyệt vọng và điên loạn, toán thám hiểm bắt đầu phân rã. Nhiễm độc chì từ những hộp đồ hộp bảo quản kém chất lượng khiến các sĩ quan mất trí nhớ và xuất hiện ảo giác. Dưới ánh sáng cực quang xanh rợn ngập tràn bầu trời, những người lính còn lại nghe thấy tiếng bước chân ầm ầm như sấm sét chạy vòng quanh khu trại trước khi chiếc lều bạt bị xé toạc làm đôi.",
    "text_en": "Madness and despair fractured the remaining men. Chronic lead poisoning from faulty tinned provisions corroded cognitive sanity. Beneath emerald auroral veils, the shivering sailors heard thunderous footfalls circling the perimeter before the heavy canvas tents were ripped in half."
  },
  {
    "type": "climax_quote",
    "header": "BÚT TÍCH CUỐI CÙNG TRONG CHIẾC HỘP TRÒN TẠI VỊNH EREBUS",
    "header_en": "FINAL RECORD FOUND IN THE COPPER CYLINDER AT EREBUS BAY",
    "text": "“Đạn đại bác bọc bạc không thể làm trầy xước da thịt nó... Nó đang đứng nhìn ta bằng đôi mắt buồn bã của một linh hồn bị nguyền rủa. Đây là lời vĩnh biệt gửi đến Vương quốc Anh... Đừng bao giờ cử tàu tìm kiếm chúng tôi!”",
    "text_en": "“Silver cannon shot failed to pierce its hide... It stares into my soul with the sorrowful eyes of a damned god. This is our farewell to Great Britain... Send no rescue expeditions!”"
  },
  {
    "type": "paragraph",
    "text": "Gần một thế kỷ sau, các đoàn thám hiểm hiện đại mới tìm thấy những bộ hài cốt đông cứng của các thủy thủ đoàn Franklin rải rác trên bờ đá đảo King William. Các dấu vết trên xương cho thấy một bi kịch ăn thịt đồng loại tàn khốc đã diễn ra trong những ngày tháng cuối cùng của cơn ác mộng Bắc Cực.",
    "text_en": "Nearly a century elapsed before modern forensic teams uncovered the mummified remains of Franklin''s men scattered along King William Island. Cut marks on forensic skeletal remains bore silent testament to cannibalism during the dying days of the Arctic nightmare."
  },
  {
    "type": "epilogue_warning",
    "header": "BÁO CÁO GIẢI MÃ PHÁP Y HẢI QUÂN ANH 2014",
    "header_en": "BRITISH NAVAL ARCHEOLOGICAL DECLASSIFIED REPORT 2014",
    "text": "Xác con tàu HMS Terror được tìm thấy nguyên vẹn ở độ sâu 24m dưới đáy biển băng vào năm 2016. Cánh cửa phòng thuyền trưởng bị khóa chặt từ bên trong bằng những thanh xà sắt cắm sâu vào gỗ như để ngăn một thứ gì đó thoát ra.",
    "text_en": "The wreck of HMS Terror was discovered intact in 2016 in 24 meters of arctic water. The captain''s cabin door remained bolted from within by heavy iron bars, as if sealing something inside from escaping."
  }
]'
) ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `title_en` = VALUES(`title_en`),
  `subtitle` = VALUES(`subtitle`),
  `subtitle_en` = VALUES(`subtitle_en`),
  `author` = VALUES(`author`),
  `read_time_minutes` = VALUES(`read_time_minutes`),
  `cover_image` = VALUES(`cover_image`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `is_vip` = VALUES(`is_vip`),
  `content_json` = VALUES(`content_json`);

INSERT INTO `stories` (`story_id`, `title`, `title_en`, `subtitle`, `subtitle_en`, `author`, `read_time_minutes`, `cover_image`, `ambient_sound`, `is_vip`, `content_json`) VALUES
(
  'megalodon',
  'Siêu Cá Mập Megalodon: Tử Thần Tầng Nước Đen Rãnh Nhật Bản',
  'The Megalodon Protocol: Black Water Apex Predator',
  'Cuộc chạm trán ngoài dự kiến ở độ sâu 1.500m của tàu ngầm nghiên cứu và kẻ săn mồi thống trị kỷ nguyên',
  'Unexpected deep-sea encounter at 1,500m depth with the prehistoric apex predator',
  'Thuyền Trưởng Jonas Taylor',
  8,
  'assets/images/creatures/bg_megalodon.jpg',
  'assets/sounds/deep_hum.mp3',
  1,
  '[
  {
    "type": "log_entry",
    "header": "NHẬT KÝ THÁM HIỂM TÀU NGẦM TỰ HÀNH HAI LONG 2 • TỌA ĐỘ 32°N - 142°Đ • ĐỘ SÂU 1.520M",
    "header_en": "HAI LONG 2 DEEP RESEARCH SUBMERSIBLE LOG • COORD 32°N - 142°E • DEPTH 1,520M",
    "text": "Chúng tôi đang thả chiếc lồng sắt chứa xác cá mập mồi nặng ba tấn xuống sườn dốc rãnh nứt Suruga Bay để ghi hình loài cá mập ngủ Greenland. Hệ thống camera hồng ngoại 4K ghi nhận nhiệt độ nước biển xung quanh giảm đột ngột 4 độ C. Luồng đối lưu thủy triều ngầm bỗng đổi hướng dữ dội.",
    "text_en": "We deployed a three-ton bait cage of whale carcass along the steep ridges of Suruga Bay to record Greenland sleeper sharks. 4K infrared telemetry recorded a sudden water temperature plummet of 4°C. The sub-surface counter-current sheared violently."
  },
  {
    "type": "paragraph",
    "text": "Chiếc lồng thép hợp kim chịu lực nặng hơn hai tấn bỗng nhiên rung chuyển dữ dội như bị một toa tàu hỏa đâm sầm vào. Cảm biến gia tốc kế báo động đỏ. Từ trong màn nước đen như mực của tầng nước trung sâu (mesopelagic zone), một cái bóng khổng lồ dài hơn hai mươi mét chậm rãi lướt ngang qua ống kính camera trinh sát.",
    "text_en": "The reinforced alloy steel cage violently shuddered as though struck by a locomotive. Accelerometer sensors flashed critical red. Out from the inky blackness of the mesopelagic zone, an immense shadow over twenty meters in length drifted languidly past the camera rig."
  },
  {
    "type": "whisper",
    "text": "“Chúa ơi... Nhìn vào khoảng cách giữa hai vây bơi của nó xem... Ít nhất là năm mét! Cá mập trắng lớn nhất lịch sử cũng chỉ dài sáu mét. Thứ này không thuộc về thế kỷ 21... Otodus Megalodon vẫn chưa hề tuyệt chủng!”",
    "text_en": "“Dear God... Look at the dorsal wingspan... It measures five meters across! The largest Great White on record was six meters total. This beast does not belong to the 21st century... Otodus Megalodon is still alive!”"
  },
  {
    "type": "image",
    "url": "assets/images/creatures/bg_megalodon.jpg",
    "caption": "Ảnh chụp thực tế từ camera tàu ngầm: Siêu cá mập Megalodon lượn quanh lồng khảo sát",
    "caption_en": "Submersible camera capture: Colossal Megalodon shark circling the observation array"
  },
  {
    "type": "paragraph",
    "text": "Khi chiếc tàu ngầm bật đèn pha hồ quang 10.000 watt, toàn bộ thủy thủ đoàn trong buồng lái nín thở kinh hoàng. Cái đầu hình nêm đồ sộ bọc lớp da xám sẹo xước đầy những vết thương cổ đại hiện ra. Bộ hàm khổng lồ hé mở lộ ra năm hàng răng cưa hình tam giác sắc bén như những lưỡi rìu đá, mỗi chiếc răng dài hơn 18 centimet — đủ sức cắn đứt đôi một con cá voi lưng gù chỉ trong một cú đớp duy nhất.",
    "text_en": "As the submersible ignited its 10,000-watt arc lamps, the crew held their breath in collective terror. A wedge-shaped head scarred by ancient battles filled the viewport. Its colossal jaws parted slightly, exposing five concentric tiers of serrated triangular teeth large as broadaxe blades, each measuring over 18 centimeters — capable of severing a humpback whale in a single bite."
  },
  {
    "type": "quote",
    "text": "Đại dương chiếm hơn 70% bề mặt Trái Đất và tầng nước sâu là thế giới của kẻ thống trị thực sự. Chúng chỉ lặn sâu xuống để thích nghi với sự thay đổi của khí hậu, chứ chưa từng từ bỏ ngai vàng săn mồi.",
    "text_en": "The ocean blankets 70% of our world, and the deep bathypelagic realm belongs to its true sovereigns. They merely descended into the cold abyss to outlast climatic cataclysms, never relinquishing their apex throne."
  },
  {
    "type": "video",
    "url": "https://codego.io.vn/api/uploads/videos/megalodon_hunt.mp4",
    "caption": "Thước phim tàu lặn ghi lại khoảnh khắc siêu cá mập Megalodon nghiền nát lồng thép ở độ sâu 1.500m",
    "caption_en": "Deep-sea footage showing the Megalodon crushing the steel cage at 1,500m depth"
  },
  {
    "type": "paragraph",
    "text": "Con quái thú không hề tỏ ra sợ hãi ánh sáng nhân tạo. Với một cú quẫy đuôi mạnh mẽ tạo ra làn sóng xung kích làm rung chuyển vỏ tàu ngầm, nó lao thẳng vào chiếc lồng mồi. Tiếng thép dày 50mm bị nghiền nát như vỏ lon nước ngọt vang vọng khắp các cảm biến âm thanh. Nó ngậm trọn chiếc lồng thép nặng hai tấn rồi lặn mất tăm vào rãnh Mariana sâu thẳm chỉ trong chớp mắt.",
    "text_en": "The predator demonstrated zero fear toward artificial lighting. With a single flick of its crescent caudal fin generating a displacement surge that rocked our hull, it struck the bait cage. The horrific sound of 50mm hardened steel crunching like an aluminum soda can reverberated through hydrophone sensors. Clamping the two-ton steel rig in its jaws, it vanished into the trench in seconds."
  },
  {
    "type": "climax_quote",
    "header": "BÁO CÁO KHẨN TỪ KHOANG TÀU NGẦM NGHIÊN CỨU",
    "header_en": "FLASH REPORT TRANSMITTED TO MARITIME RECONNAISSANCE",
    "text": "“Lực cắn của nó vượt quá 18 tấn trên mỗi inch vuông! Thân tàu lặn của chúng tôi bị móp một mảng lớn ở mạn trái do sóng nước va đập! Yêu cầu trục vớt khẩn cấp trước khi nó quay lại tấn công lần thứ hai!”",
    "text_en": "“Bite force exceeded 18 tons per square inch! Our port pressure hull has sustained structural deformation from water displacement! Requesting emergency winch recovery before it circles back for a second strike!”"
  },
  {
    "type": "paragraph",
    "text": "Sau vụ chạm trán rùng rợn, toàn bộ đoạn phim và dữ liệu thủy âm đo đạc lực cắn đã bị các cơ quan quân sự tịch thu theo quy chế kiểm duyệt an ninh hàng hải. Rãnh biển sâu phía đông Nhật Bản lập tức được đưa vào danh sách vùng hạn chế lặn dân sự bí mật.",
    "text_en": "Following the harrowing encounter, all 4K footage and bite-force telemetry logs were impounded under national naval classification directives. The abyssal trenches off eastern Japan were quietly designated restricted civilian diving zones."
  },
  {
    "type": "epilogue_warning",
    "header": "CẢNH BÁO TÀU NGẦM THƯƠNG MẠI & QUÂN SỰ KHU VỰC VÀNH ĐAI LỬA",
    "header_en": "PACIFIC RIM SUBMERSIBLE NAVIGATION RESTRICTION",
    "text": "Không bao giờ phát tín hiệu âm thanh tần số thấp mô phỏng tiếng kêu đau đớn của cá voi ở tầng nước sâu quá 1.000m. Kẻ săn mồi tối thượng của kỷ Miocen vẫn đang lắng nghe trong bóng tối.",
    "text_en": "Never broadcast low-frequency acoustic beacons simulating marine distress at depths exceeding 1,000 meters. The Miocene super-predator is still listening in the deep black."
  }
]'
) ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `title_en` = VALUES(`title_en`),
  `subtitle` = VALUES(`subtitle`),
  `subtitle_en` = VALUES(`subtitle_en`),
  `author` = VALUES(`author`),
  `read_time_minutes` = VALUES(`read_time_minutes`),
  `cover_image` = VALUES(`cover_image`),
  `ambient_sound` = VALUES(`ambient_sound`),
  `is_vip` = VALUES(`is_vip`),
  `content_json` = VALUES(`content_json`);
