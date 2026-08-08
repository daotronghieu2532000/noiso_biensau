<?php
/**
 * CODE GO API - GET ALL CREATURES
 * API endpoint: /api/get_creatures.php
 * Method: GET
 * 
 * Mô tả: Lấy danh sách tất cả các quái thú đại dương từ database
 */

// Cho phép truy cập từ mọi origin (CORS) và định dạng JSON
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Content-Type: application/json; charset=utf-8');

// Require cấu hình database
require_once __DIR__ . '/includes/config.php';

try {
    // Truy vấn lấy toàn bộ danh sách quái thú
    $query = "SELECT * FROM `creatures` ORDER BY `min_depth` ASC";
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Lỗi truy vấn database: " . $conn->error);
    }

    $creatures = [];
    while ($row = $result->fetch_assoc()) {
        $creatures[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'name_en' => $row['name_en'],
            'scientific_name' => $row['scientific_name'],
            'type' => $row['type'],
            'min_depth' => intval($row['min_depth']),
            'max_depth' => intval($row['max_depth']),
            'danger_level' => intval($row['danger_level']),
            'size_human_ratio' => $row['size_human_ratio'],
            'size_human_ratio_en' => $row['size_human_ratio_en'],
            'human_size_meters' => floatval($row['human_size_meters']),
            'creature_size_meters' => floatval($row['creature_size_meters']),
            'image_url' => $row['image_url'],
            'video_url' => isset($row['video_url']) ? $row['video_url'] : '',
            'ambient_sound' => $row['ambient_sound'],
            'description' => $row['description'],
            'description_en' => $row['description_en'],
            'is_locked' => intval($row['is_locked']) === 1 ? true : false
        ];
    }

    // Trả về JSON kết quả
    echo json_encode($creatures, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
