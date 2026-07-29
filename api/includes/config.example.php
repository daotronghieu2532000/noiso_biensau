<?php
/**
 * CODE GO API - DATABASE CONFIGURATION EXAMPLE
 *
 * Cách dùng:
 * 1. Copy file này thành config.php
 * 2. Điền thông tin database từ hosting của bạn
 * 3. Giữ config.php trong .gitignore để không bị commit
 */

// ============================================
// DATABASE CONFIGURATION
// ============================================

$db_host = 'localhost';
$db_username = 'your_database_user';
$db_password = 'your_database_password';
$db_name = 'your_database_name';

// ============================================
// FALLBACK DATABASE CONFIGURATION
// ============================================

$db_fallback_username = 'your_fallback_user';
$db_fallback_password = 'your_fallback_password';
$db_fallback_name = 'your_fallback_database';

// ============================================
// KẾT NỐI DATABASE
// ============================================

$conn = null;
$connection_log = [];

$temp_conn = @new mysqli($db_host, $db_username, $db_password, $db_name);

if ($temp_conn->connect_error) {
    $connection_log[] = [
        'attempt' => 'Primary',
        'host' => $db_host,
        'username' => $db_username,
        'database' => $db_name,
        'error_code' => $temp_conn->connect_errno,
        'error_message' => $temp_conn->connect_error
    ];

    $temp_conn = @new mysqli($db_host, $db_fallback_username, $db_fallback_password, $db_fallback_name);

    if ($temp_conn->connect_error) {
        $connection_log[] = [
            'attempt' => 'Fallback',
            'host' => $db_host,
            'username' => $db_fallback_username,
            'database' => $db_fallback_name,
            'error_code' => $temp_conn->connect_errno,
            'error_message' => $temp_conn->connect_error
        ];

        if (ob_get_level() > 0) {
            ob_end_clean();
        }

        if (!headers_sent()) {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
        }

        echo json_encode([
            'success' => false,
            'message' => 'Database connection error'
        ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    } else {
        $conn = $temp_conn;
    }
} else {
    $conn = $temp_conn;
}

if ($conn === null) {
    if (ob_get_level() > 0) {
        ob_end_clean();
    }

    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
    }

    echo json_encode([
        'success' => false,
        'message' => 'Database connection not established'
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn->set_charset("utf8mb4");
date_default_timezone_set('Asia/Ho_Chi_Minh');
$codego_conn = $conn;

?>
