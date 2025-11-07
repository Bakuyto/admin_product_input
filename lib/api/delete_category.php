<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
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

// Only POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(false, "Only POST allowed");

// Get category ID from JSON
$json = json_decode(file_get_contents('php://input'), true);
$id = (int)($json['id'] ?? 0);

if ($id <= 0) jsonResponse(false, "Invalid category ID");

// Check if category exists
$existing = $conn->query("SELECT id, name FROM categories WHERE id = $id");
if (!$existing || $existing->num_rows === 0) jsonResponse(false, "Category not found");

// Check for subcategories
$sub_check = $conn->query("SELECT COUNT(*) as count FROM categories WHERE parent_id = $id");
$sub_row = $sub_check->fetch_assoc();
if ($sub_row['count'] > 0) jsonResponse(false, "Cannot delete category with subcategories. Please delete subcategories first.");

// Check if referenced in products
$prod_check = $conn->query("SELECT COUNT(*) as count FROM products WHERE FIND_IN_SET($id, category_ids)");
$prod_row = $prod_check->fetch_assoc();
if ($prod_row['count'] > 0) jsonResponse(false, "Cannot delete category that is assigned to products. Please remove the category from products first.");

// Delete the category
$sql = "DELETE FROM categories WHERE id = $id";
if ($conn->query($sql) === TRUE) {
    jsonResponse(true, "Category deleted successfully.", ["category_id" => $id]);
} else {
    jsonResponse(false, "Database error: " . $conn->error);
}

$conn->close();
?>
