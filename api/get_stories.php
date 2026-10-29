<?php
/**
 * CODE GO API - GET ALL SAILOR STORIES (HẢI TRÌNH KÝ SỰ / CHUYỆN THỦY THỦ)
 * API endpoint: /api/get_stories.php
 * Method: GET
 * 
 * Mô tả: Lấy danh sách tất cả các câu chuyện huyền thoại thủy thủ từ database
 */

// Cho phép truy cập từ mọi origin (CORS) và định dạng JSON
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Content-Type: application/json; charset=utf-8');

// Require cấu hình database
require_once __DIR__ . '/includes/config.php';

try {
    // Truy vấn lấy toàn bộ danh sách chuyện thủy thủ
    $query = "SELECT * FROM `stories` ORDER BY `id` ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Lỗi truy vấn database: " . $conn->error);
    }

    $stories = [];
    while ($row = $result->fetch_assoc()) {
        // Parse content_json nếu có
        $content = [];
        if (!empty($row['content_json'])) {
            $decoded = json_decode($row['content_json'], true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                $content = $decoded;
            }
        }

        $stories[] = [
            'id' => intval($row['id']),
            'story_id' => $row['story_id'],
            'title' => $row['title'],
            'title_en' => $row['title_en'],
            'subtitle' => isset($row['subtitle']) ? $row['subtitle'] : '',
            'subtitle_en' => isset($row['subtitle_en']) ? $row['subtitle_en'] : '',
            'author' => isset($row['author']) ? $row['author'] : 'Thuyền Trưởng Hải Trình',
            'read_time_minutes' => isset($row['read_time_minutes']) ? intval($row['read_time_minutes']) : 4,
            'cover_image' => $row['cover_image'],
            'ambient_sound' => isset($row['ambient_sound']) ? $row['ambient_sound'] : '',
            'is_vip' => intval($row['is_vip']) === 1 ? true : false,
            'is_cover_video' => isset($row['is_cover_video']) ? intval($row['is_cover_video']) : 0,
            'cover_video' => isset($row['cover_video']) ? $row['cover_video'] : '',
            'content' => $content,
            'created_at' => isset($row['created_at']) ? $row['created_at'] : ''
        ];
    }

    // Trả về JSON kết quả
    echo json_encode($stories, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
