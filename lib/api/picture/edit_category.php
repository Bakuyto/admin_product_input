<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
require_once "connection.php";

$data = json_decode(file_get_contents("php://input"), true);
if (!$data || empty($data['id']) || empty($data['name'])) {
    echo json_encode(["success" => false, "message" => "Invalid input. ID and name are required."]);
    exit;
}

$id = (int)$data['id'];
$name = $conn->real_escape_string($data['name']);

$sql = "UPDATE categories SET name = '$name' WHERE id = $id";
if ($conn->query($sql)) {
    if ($conn->affected_rows > 0) {
        echo json_encode([
            "success" => true,
            "message" => "Category updated successfully."
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Category not found."]);
    }
} else {
    echo json_encode(["success" => false, "message" => $conn->error]);
}
?>