<?php
/**
 * CODE GO API - GỬI ĐÓNG GÓP Ý KIẾN, TRẢI NGHIỆM ĐÁNH GIÁ & GÓC NHÌN CÁ NHÂN
 * API endpoint: /api/submit_feedback.php
 * Method: POST
 */

// Cho phép truy cập từ mọi origin (CORS) và định dạng JSON
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// Xử lý preflight request của trình duyệt
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Chỉ chấp nhận method POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Phương thức yêu cầu không hợp lệ. Vui lòng sử dụng POST.'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Require cấu hình database và helpers
require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/helpers.php';

try {
    // 1. Đọc dữ liệu đầu vào (hỗ trợ cả JSON body lẫn form-data)
    $input = [];
    $rawInput = file_get_contents('php://input');
    if (!empty($rawInput)) {
        $decoded = json_decode($rawInput, true);
        if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
            $input = $decoded;
        }
    }
    if (empty($input) && !empty($_POST)) {
        $input = $_POST;
    }

    // 2. Validate nội dung bắt buộc
    $content = isset($input['content']) ? trim($input['content']) : '';
    if (empty($content) || mb_strlen($content, 'UTF-8') < 3) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Nội dung ý kiến đóng góp không được để trống (tối thiểu 3 ký tự).'
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Giới hạn độ dài nội dung tối đa 5000 ký tự
    if (mb_strlen($content, 'UTF-8') > 5000) {
        $content = mb_substr($content, 0, 5000, 'UTF-8');
    }

    // 3. Chuẩn hóa các trường dữ liệu
    $userName = isset($input['user_name']) ? trim($input['user_name']) : '';
    if (empty($userName)) {
        $userName = 'Ẩn danh Thủy Thủ';
    } else {
        $userName = mb_substr(strip_tags($userName), 0, 150, 'UTF-8');
    }

    $userEmail = isset($input['user_email']) ? trim($input['user_email']) : '';
    if (!empty($userEmail)) {
        $userEmail = filter_var($userEmail, FILTER_VALIDATE_EMAIL) ? $userEmail : null;
    } else {
        $userEmail = null;
    }

    // Số sao đánh giá (1 đến 5 sao)
    $rating = isset($input['rating']) ? intval($input['rating']) : 5;
    if ($rating < 1) $rating = 1;
    if ($rating > 5) $rating = 5;

    // Loại đóng góp
    $validTypes = ['experience', 'opinion', 'suggestion', 'bug_report'];
    $feedbackType = isset($input['feedback_type']) ? strtolower(trim($input['feedback_type'])) : 'experience';
    if (!in_array($feedbackType, $validTypes)) {
        $feedbackType = 'experience';
    }

    // Tiêu đề tóm tắt (nếu có)
    $title = isset($input['title']) ? trim(strip_tags($input['title'])) : null;
    if (!empty($title)) {
        $title = mb_substr($title, 0, 255, 'UTF-8');
    }

    // Thông tin thiết bị
    $deviceInfo = isset($input['device_info']) ? trim(strip_tags($input['device_info'])) : null;
    if (!empty($deviceInfo)) {
        $deviceInfo = mb_substr($deviceInfo, 0, 255, 'UTF-8');
    }

    // Lấy IP người dùng
    $ipAddress = getClientIP();

    // 4. Lưu vào cơ sở dữ liệu bằng Prepared Statement (Chống SQL Injection)
    $stmt = $conn->prepare("INSERT INTO `user_feedbacks` 
        (`user_name`, `user_email`, `rating`, `feedback_type`, `title`, `content`, `device_info`, `ip_address`, `status`) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'new')");

    if (!$stmt) {
        throw new Exception("Lỗi chuẩn bị truy vấn: " . $conn->error);
    }

    $stmt->bind_param("ssisssss", $userName, $userEmail, $rating, $feedbackType, $title, $content, $deviceInfo, $ipAddress);
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi thực thi truy vấn: " . $stmt->error);
    }

    $feedbackId = $stmt->insert_id;
    $stmt->close();

    // 5. Trả về phản hồi thành công
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Cảm ơn bạn! Ý kiến đóng góp và góc nhìn của bạn đã được ghi nhận thành công.',
        'data' => [
            'feedback_id' => $feedbackId,
            'rating' => $rating,
            'feedback_type' => $feedbackType,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Có lỗi xảy ra trong quá trình ghi nhận ý kiến. Vui lòng thử lại sau.',
        'error_detail' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
