<?php
header('Content-Type: application/json');
require_once 'config.php';

// Only allow POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['order_id']) || !is_numeric($input['order_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Invalid or missing order_id']);
    exit();
}

$orderId = (int)$input['order_id'];   // <-- matches Flutter

$sql = "UPDATE tblorders SET alr_contact = 1 WHERE id = ? AND alr_contact = 0";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $orderId);

if ($stmt->execute()) {
    $affected = $stmt->affected_rows;
    echo json_encode(['success' => $affected > 0]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Update failed: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>