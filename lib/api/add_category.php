<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
require_once "connection.php";

$data = json_decode(file_get_contents("php://input"), true);
if (!$data || empty($data['name'])) {
    echo json_encode(["success" => false, "message" => "Category name is required."]);
    exit;
}

$name = $conn->real_escape_string(trim($data['name']));
$parent_id = isset($data['parent_id']) ? (int)$data['parent_id'] : 0;

// Validate name length
if (strlen($name) > 100) {
    echo json_encode(["success" => false, "message" => "Category name is too long (max 100 characters)."]);
    exit;
}

// Check for duplicate category name under the same parent
$check_sql = "SELECT id FROM categories WHERE name = '$name' AND parent_id = $parent_id";
$check_result = $conn->query($check_sql);
if ($check_result->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Category '$name' already exists under this parent."]);
    exit;
}

// Validate parent_id exists if provided
if ($parent_id > 0) {
    $parent_check_sql = "SELECT id FROM categories WHERE id = $parent_id";
    $parent_check_result = $conn->query($parent_check_sql);
    if ($parent_check_result->num_rows == 0) {
        echo json_encode(["success" => false, "message" => "Invalid parent category ID."]);
        exit;
    }
}

// Insert new category
$sql = "INSERT INTO categories (name, parent_id) VALUES ('$name', $parent_id)";
if ($conn->query($sql)) {
    echo json_encode([
        "success" => true,
        "message" => "Category '$name' added successfully.",
        "id" => $conn->insert_id
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Database error: " . $conn->error]);
}
$conn->close();
?>