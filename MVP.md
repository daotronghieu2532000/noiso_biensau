# 🌊 TÀI LIỆU PHÂN TÍCH BA & ĐỊNH HÌNH MVP: NỖI SỢ BIỂN SÂU (THALASSOPHOBIA APP)

Tài liệu này đóng vai trò là Product Requirement Document (PRD) và định hình chi tiết về chức năng, giao diện, và cấu trúc dữ liệu cho phiên bản MVP (V1) của ứng dụng di động **"Nỗi Sợ Biển Sâu"**. 

---

## 🎯 1. Tầm Nhìn Sản Phẩm & Trải Nghiệm Cảm Xúc (UX)

### 1.1. Tầm Nhìn
Biến sự tò mò và nỗi sợ nguyên thủy của con người trước đại dương bao la thành một trải nghiệm tương tác trực quan độc đáo. Ứng dụng không đơn thuần là bách khoa toàn thư, mà là một **"hành trình chìm dần vào cô độc và bóng tối"**, kết hợp hình ảnh huyền ảo và âm thanh ám ảnh.

### 1.2. Trải Nghiệm Cảm Xúc Chủ Đạo (Emotional UX)
*   **Sự ngột ngạt tăng dần:** Càng cuộn xuống sâu, màu sắc giao diện càng tối đi, âm thanh càng trở nên nặng nề, dồn dập.
*   **Bioluminescence (Phát quang sinh học):** Giữa bóng tối vô tận của các tầng vực sâu, các chi tiết UI (nút nhấn, viền thẻ sinh vật) sẽ phát sáng neon mờ ảo, tạo cảm giác kỳ dị nhưng cuốn hút.
*   **Trải nghiệm kể chuyện (Storytelling):** Nội dung mô tả sinh vật không viết theo kiểu khoa học khô khan mà viết dưới dạng nhật ký thám hiểm của một thủy thủ bị mắc kẹt dưới đáy biển.

---

## 🛠️ 2. Danh Sách Chức Năng Chi Tiết (MVP Scope)

Để tối ưu hóa thời gian phát triển của một Web Dev làm thêm ngoài giờ, phạm vi MVP sẽ tập trung tối đa vào **Giao diện tương tác dọc (Scroll)** và **Trải nghiệm Nghe - Nhìn**, loại bỏ hoàn toàn các chức năng cần Backend phức tạp (như đăng nhập, comment, chat). Dữ liệu sẽ được lưu trữ cục bộ dưới dạng file JSON nằm trong assets của Flutter.

### 📊 Bảng Tính Năng MVP (V1)

| STT | Tính Năng | Mô Tả Chi Tiết | Độ Ưu Tiên |
| :--- | :--- | :--- | :---: |
| **1** | **The Deep Scroll (Hành Trình Vực Sâu)** | Trục cuộn dọc vô hạn mô phỏng độ sâu từ 0m đến 11,000m. Màu nền chuyển từ xanh biển sáng $\rightarrow$ xanh thẫm $\rightarrow$ đen tuyền. Hiển thị mốc độ sâu (m) chạy liên tục khi cuộn. | **P0 (Critical)** |
| **2** | **Thư Viện Sinh Vật (Creature Encyclopedia)** | Phân chia thành 2 tab: **Sự Thật (Science)** và **Huyền Thoại (Abyss Myth)**. Mỗi sinh vật hiển thị dưới dạng Card tương tác. | **P0 (Critical)** |
| **3** | **Chi Tiết Sinh Vật & So Sánh Kích Thước** | Trang chi tiết hiển thị: Hình ảnh động/tư liệu, chỉ số nguy hiểm (1-5 đầu lâu), cốt truyện rùng rợn, và widget so sánh trực quan kích thước sinh vật với một thợ lặn (Human Silhouette). | **P0 (Critical)** |
| **4** | **Hệ Thống Âm Thanh Môi Trường (ASMR Engine)** | Phát nhạc nền âm u (ambient sound, tiếng tim đập chậm, tiếng nước chảy áp lực cao). Nút bật/tắt âm thanh nhanh dạng sóng nhạc chuyển động (Waveform). | **P1 (High)** |
| **5** | **Khóa Nội Dung Bằng Quảng Cáo (Monetization)** | Khóa các sinh vật ở độ sâu dưới 4,000m (hoặc tab Huyền thoại). Người dùng xem 1 Video Quảng cáo (Rewarded Ad) để mở khóa đọc trong 24 giờ. | **P1 (High)** |
| **6** | **Chế Độ "Nhật Ký Thủy Thủ" (Lore Collectibles)** | Thu thập các trang nhật ký cũ rải rác ở các độ sâu nhất định khi cuộn xuống. Giúp tăng tính tò mò và giữ chân người dùng. | **P2 (Medium)** |

---

## 🎨 3. Thiết Kế Giao Diện & Trải Nghiệm Người Dùng (UI/UX)

### 3.1. Hệ Màu Sắc (Color Palette)
Hệ màu được thiết kế để tạo cảm giác huyền bí, lạnh lẽo và nguy hiểm:

*   🔴 **Primary Background (Abyss Black):** `#020813` (Đen vũ trụ, đại diện cho bóng tối tuyệt đối dưới đáy biển).
*   🔵 **Secondary Background (Twilight Blue):** `#0D1F3D` (Xanh đại dương thẫm).
*   🟢 **Bioluminescent Cyan (Accent):** `#00F0FF` (Xanh neon phát quang cho các chi tiết tương tác quan trọng, text độ sâu).
*   🔥 **Danger Red (Highlight):** `#FF3366` (Đỏ cảnh báo nguy hiểm cho các sinh vật thần thoại hoặc mức độ nguy hại cấp 5).
*   ⚪ **Text Light:** `#E2E8F0` (Màu chữ trắng xám dễ đọc trên nền tối, không gây mỏi mắt).

### 3.2. Cấu Trúc Các Màn Hình (Screen Wireframes)

#### Màn hình 1: Main Ocean Scroll (Màn hình chính)
```
+---------------------------------------------------+
|  [Waveform Icon] (Mute/Unmute)     [Info/Settings]|
|                                                   |
|                        ~                          |
|                       ~~~  (Mặt nước gợn sóng)     |
|                        0m                         |
|                                                   |
|                        |                          |
|    [Card: Cá mập trắng] |  <-- 150m                |
|                        |                          |
|                        |                          |
|                        v  (Độ sâu tăng dần,       |
|                            màu nền tối dần)       |
|                                                   |
|                      1,000m (Vùng Nửa Tối)        |
|    [Card: Cá Vây Chân (Anglerfish)]               |
|                                                   |
|                        |                          |
|                        v                          |
|                                                   |
|                      4,000m (Bóng tối vĩnh cửu)   |
|    [Card: Khóa 🔒 - Xem Quảng Cáo để mở]           |
|                                                   |
|                      11,000m (Đáy Mariana)        |
|    [Card: Âm thanh bí ẩn "The Bloop"]             |
+---------------------------------------------------+
```

#### Màn hình 2: Thư Viện Sinh Vật (Encyclopedia Screen)
Màn hình này chia làm 2 tab chính:
*   **Tab 1: Sinh Vật Có Thật (Real Beasts):** Xếp theo độ sâu tăng dần.
*   **Tab 2: Huyền Thoại Vực Thẳm (Cryptids & Myths):** Những quái thú khổng lồ trong truyền thuyết.
Giao diện hiển thị dạng Grid View với hiệu ứng kính mờ (Glassmorphism) trên nền đen.

#### Màn hình 3: Chi Tiết Sinh Vật (Creature Detail Screen)
*   **Header:** Ảnh lớn của sinh vật, phủ một lớp gradient đen mờ dần xuống dưới.
*   **Danger Level Widget:** Hệ thống chấm điểm nguy hiểm bằng biểu tượng đầu lâu phát sáng:
    *   💀 💀 💀 💀 💀 (Cực kỳ nguy hiểm)
*   **Size Comparison Box (Hộp so sánh kích thước):**
    Visual so sánh trực quan bằng hình vẽ silhouette màu neon:
    ```
    +-----------------------------------------------+
    | SO SÁNH KÍCH THƯỚC                            |
    |                                               |
    |   🚶 (Người - 1.8m)                           |
    |   [========================================]  |
    |   🦑 (Kraken - 50m)                           |
    |                                               |
    +-----------------------------------------------+
    ```
*   **Lore / Description:** Câu chuyện viết theo lối tự sự, bí ẩn, gợi sự tò mò.

---

## 💾 4. Cấu Trúc Dữ Liệu MVP (Data Model)

Toàn bộ dữ liệu của app sẽ nằm trong file JSON `assets/data/creatures.json`. Điều này giúp bạn dễ dàng cập nhật nội dung mới mà không cần sửa code Flutter, chỉ cần cập nhật file JSON này.

```json
[
  {
    "id": "anglerfish",
    "name": "Cá Vây Chân (Anglerfish)",
    "scientific_name": "Melanocetus johnsonii",
    "type": "real",
    "min_depth": 1000,
    "max_depth": 4000,
    "danger_level": 4,
    "size_human_ratio": "Lớn gấp 5 lần bàn tay người (Loài lớn nhất khoảng 1m)",
    "human_size_meters": 1.8,
    "creature_size_meters": 1.0,
    "image_url": "assets/images/creatures/anglerfish.png",
    "ambient_sound": "assets/sounds/angler_breath.mp3",
    "description": "Ở độ sâu 2,000 mét dưới mặt nước, nơi ánh sáng mặt trời chưa từng chiếu tới, Cá Vây Chân săn mồi bằng chiếc 'cần câu' phát sáng trên đầu. Kẻ thù bị thu hút bởi ánh sáng nhỏ nhoi đó sẽ chỉ tìm thấy một cái miệng khổng lồ chứa đầy răng sắc nhọn.",
    "is_locked": false
  },
  {
    "id": "kraken",
    "name": "Thủy Quái Kraken",
    "scientific_name": "Architeuthis Gigantus (Myth)",
    "type": "myth",
    "min_depth": 3000,
    "max_depth": 9000,
    "danger_level": 5,
    "size_human_ratio": "Khổng lồ (Dài hơn 50m, to hơn cả tàu chiến)",
    "human_size_meters": 1.8,
    "creature_size_meters": 50.0,
    "image_url": "assets/images/creatures/kraken.png",
    "ambient_sound": "assets/sounds/kraken_roar.mp3",
    "description": "Nỗi kinh hoàng của mọi thủy thủ Bắc Âu. Kraken không chỉ là một con mực khổng lồ, nó là hiện thân của sự giận dữ từ đại dương sâu thẳm. Nó có thể tạo ra những xoáy nước khổng lồ nuốt chửng cả những hạm đội lớn nhất.",
    "is_locked": true
  }
]
```

---

## 🛠️ 5. Kiến Trúc Kỹ Thuật Gợi Ý Cho Flutter

Vì bạn là Web Dev muốn triển khai nhanh và mượt mà:

1.  **State Management:** Dùng `Provider` hoặc `Riverpod` (đơn giản, dễ làm quen nhanh).
2.  **Packages quan trọng cần dùng:**
    *   `audioplayers`: Xử lý phát nhạc nền ASMR lặp đi lặp lại mượt mà không giật lag.
    *   `flutter_animate`: Tạo các chuyển động phát sáng, bọt nước nổi lên chậm rãi khi cuộn trang.
    *   `shared_preferences`: Lưu lại các sinh vật đã được người dùng mở khóa (qua Ad) hoặc lưu trạng thái tắt/bật âm thanh.
    *   `google_mobile_ads`: Để tích hợp quảng cáo Rewarded Video Ad khi người dùng muốn mở khóa sinh vật ở tầng sâu hơn.
3.  **Thuật toán đổi màu nền theo vị trí cuộn (Scroll Color Interpolation):**
    Sử dụng `ScrollController` lắng nghe vị trí cuộn (pixels) và tính toán tỷ lệ phần trăm độ sâu để ánh xạ (map) giá trị từ màu `Colors.blue` sang `Colors.black`.

---

## 📈 6. Kế Hoạch BA & Việc Cần Xác Nhận Tiếp Theo (Questions for User)

> [!IMPORTANT]
> Để chuẩn bị bước vào code giao diện và chức năng cho bản MVP này, bạn hãy xác nhận giúp tôi một số điểm sau:
> 1. **Dữ liệu nội dung:** Bạn muốn tôi chuẩn bị trước một danh sách khoảng 8-10 sinh vật (bao gồm cả Có thật & Huyền thoại) để đưa sẵn vào file JSON mẫu không?
> 2. **Kiểu hiển thị hình ảnh:** Bạn dự định dùng hình vẽ minh họa (Illustrations), ảnh chụp thực tế (Real photos), hay tôi nên generate trước một số ảnh nghệ thuật huyền bí bằng AI để bạn làm assets?
> 3. **Nhạc nền:** Bạn có cần tôi tìm và gợi ý các nguồn lấy nhạc nền ambient biển sâu/ASMR miễn phí bản quyền (Royalty-free) không?
