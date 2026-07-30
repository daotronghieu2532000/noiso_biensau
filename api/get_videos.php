<?php
/**
 * CODE GO API - GET ALL VIDEOS
 * API endpoint: /api/get_videos.php
 * Method: GET
 * 
 * Mô tả: Lấy danh sách các video trận chiến đại dương từ database
 */

// Cho phép truy cập từ mọi origin (CORS) và định dạng JSON
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Content-Type: application/json; charset=utf-8');

// Require cấu hình database
require_once __DIR__ . '/includes/config.php';

try {
    // Truy vấn lấy toàn bộ danh sách video
    $query = "SELECT * FROM `videos` ORDER BY `id` ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Lỗi truy vấn database: " . $conn->error);
    }

    $videos = [];
    while ($row = $result->fetch_assoc()) {
        $videos[] = [
            'title' => $row['title'],
            'title_en' => $row['title_en'],
            'description' => $row['description'],
            'description_en' => $row['description_en'],
            'video_url' => $row['video_url'],
            'thumbnail_url' => $row['thumbnail_url']
        ];
    }

    // Trả về JSON kết quả
    echo json_encode($videos, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
