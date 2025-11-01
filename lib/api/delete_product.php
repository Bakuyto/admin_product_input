<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php-error.log');

function jsonResponse(bool $success, string $message, array $extra = []) {
    echo json_encode(array_merge(["success" => $success, "message" => $message], $extra));
    exit;
}

set_exception_handler(fn($e) => jsonResponse(false, "Server error: " . $e->getMessage()));
set_error_handler(fn($errno, $errstr, $errfile, $errline) => jsonResponse(false, "PHP error: $errstr in $errfile on line $errline"));

require_once "connection.php";

// Only POST or DELETE
if (!in_array($_SERVER['REQUEST_METHOD'], ['POST', 'DELETE'])) jsonResponse(false, "Only POST or DELETE allowed");

// Get product ID
$id = null;
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
} else {
    $json = json_decode(file_get_contents('php://input'), true);
    $id = (int)($json['id'] ?? 0);
}

if ($id <= 0) jsonResponse(false, "Invalid product ID");

// Fetch existing product to get images for deletion
$existing = $conn->query("SELECT image_path, images_json FROM products WHERE wc_id = $id");
if (!$existing || $existing->num_rows === 0) jsonResponse(false, "Product not found");
$existingRow = $existing->fetch_assoc();
$currentMainImage = $existingRow['image_path'];
$currentSubImages = json_decode($existingRow['images_json'], true) ?? [];

// Delete images from filesystem
$uploadDir = __DIR__ . "/picture/images/";
if (!empty($currentMainImage) && file_exists($uploadDir . $currentMainImage)) {
    unlink($uploadDir . $currentMainImage);
}
foreach ($currentSubImages as $oldSub) {
    $oldPath = $uploadDir . $oldSub;
    if (file_exists($oldPath)) unlink($oldPath);
}

// Delete from database
$sql = "DELETE FROM products WHERE wc_id = $id";
if ($conn->query($sql) === TRUE) {
    jsonResponse(true, "Product deleted successfully.", ["product_id" => $id]);
} else {
    jsonResponse(false, "Database error: " . $conn->error);
}

$conn->close();
?>
