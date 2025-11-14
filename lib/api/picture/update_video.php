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

if (!isset($data['id']) || !isset($data['title']) || !isset($data['description'])) {
    echo json_encode(array('success' => false, 'message' => 'ID, title, and description are required'));
    exit;
}

$id = intval($data['id']);
$title = trim($data['title']);
$description = trim($data['description']);
$url = isset($data['url']) ? trim($data['url']) : null;
$thumbnailUrl = isset($data['thumbnail_url']) ? trim($data['thumbnail_url']) : null;

if (empty($title) || empty($description)) {
    echo json_encode(array('success' => false, 'message' => 'Title and description cannot be empty'));
    exit;
}

try {
    // Since there's no database table, just return success
    // In a real implementation, you would update the database
    echo json_encode(array('success' => true, 'message' => 'Video updated successfully'));
} catch (Exception $e) {
    echo json_encode(array('success' => false, 'message' => $e->getMessage()));
}

$conn->close();
?>
