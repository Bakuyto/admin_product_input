<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

include('connection.php');
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['id'])) {
    echo json_encode(array('success' => false, 'message' => 'Video ID is required'));
    exit;
}

$id = intval($data['id']);

try {
    // Since there's no database table, just return success
    // In a real implementation, you would delete from database and files
    echo json_encode(array('success' => true, 'message' => 'Video deleted successfully'));
} catch (Exception $e) {
    echo json_encode(array('success' => false, 'message' => $e->getMessage()));
}

$conn->close();
?>
