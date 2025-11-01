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

// Decode JSON metadata
$json = json_decode($_POST['data'] ?? '', true);
if (json_last_error() !== JSON_ERROR_NONE) jsonResponse(false, "Invalid JSON in 'data' field");

// Required fields
$required = ['name','price','stock_quantity','category_ids','description'];
foreach ($required as $f) {
    if (!isset($json[$f])) jsonResponse(false, "Missing field: $f");
}

// Sanitize inputs
$name           = $conn->real_escape_string(trim($json['name']));
$sku            = $conn->real_escape_string(trim($json['sku'] ?? ''));
$price          = (float)$json['price'];
$stock_quantity = (int)$json['stock_quantity'];
$description    = $conn->real_escape_string($json['description'] ?? '');

// Handle category IDs
$categoryArray = is_array($json['category_ids']) ? $json['category_ids'] : [];
sort($categoryArray, SORT_NUMERIC);
$category_ids  = $conn->real_escape_string(implode(',', $categoryArray));

// Folder setup
$uploadDir = __DIR__ . "/picture/images/";
if (!is_dir($uploadDir) && !mkdir($uploadDir, 0755, true)) jsonResponse(false, "Failed to create image folder");

$allowedTypes = ['jpg','jpeg','png','gif'];
$maxSize = 5 * 1024 * 1024; // 5 MB

// ── Main image (required)
if (!isset($_FILES['main_image'])) jsonResponse(false, "Main image is required");
$mainImage = $_FILES['main_image'];
$ext = strtolower(pathinfo($mainImage['name'], PATHINFO_EXTENSION));
if (!in_array($ext, $allowedTypes)) jsonResponse(false, "Main image type not allowed");
if ($mainImage['size'] > $maxSize) jsonResponse(false, "Main image exceeds 5 MB");

$mainFileName = uniqid('main_') . '.' . $ext;
$mainDest = $uploadDir . $mainFileName;
if (!move_uploaded_file($mainImage['tmp_name'], $mainDest)) jsonResponse(false, "Failed to move main image");

// ── Sub-images (optional)
$subImagesFilenames = [];
if (!empty($_FILES['sub_images'])) {
    if (is_array($_FILES['sub_images']['error'])) {
        foreach ($_FILES['sub_images']['error'] as $i => $err) {
            if ($err === UPLOAD_ERR_OK) {
                $ext = strtolower(pathinfo($_FILES['sub_images']['name'][$i], PATHINFO_EXTENSION));
                if (!in_array($ext, $allowedTypes)) continue;
                if ($_FILES['sub_images']['size'][$i] > $maxSize) continue;

                $fileName = uniqid('sub_') . '.' . $ext;
                $dest = $uploadDir . $fileName;
                if (move_uploaded_file($_FILES['sub_images']['tmp_name'][$i], $dest)) {
                    $subImagesFilenames[] = 'images/' . $fileName;
                }
            }
        }
    } elseif ($_FILES['sub_images']['error'] === UPLOAD_ERR_OK) {
        $ext = strtolower(pathinfo($_FILES['sub_images']['name'], PATHINFO_EXTENSION));
        if (in_array($ext, $allowedTypes) && $_FILES['sub_images']['size'] <= $maxSize) {
            $fileName = uniqid('sub_') . '.' . $ext;
            $dest = $uploadDir . $fileName;
            if (move_uploaded_file($_FILES['sub_images']['tmp_name'], $dest)) {
                $subImagesFilenames[] = 'images/' . $fileName;
            }
        }
    }
}

// Save filenames to DB
$imagesJson = $conn->real_escape_string(json_encode($subImagesFilenames));

$sql = "INSERT INTO products 
        (name, sku, price, stock_quantity, category_ids, description, image_path, images_json)
        VALUES 
        ('$name', '$sku', $price, $stock_quantity, '$category_ids', '$description', '$mainFileName', '$imagesJson')";

if ($conn->query($sql) === TRUE) {
    jsonResponse(true, "Product added successfully.", [
        "product_id" => $conn->insert_id,
        "main_image" => $mainFileName,
        "sub_images" => $subImagesFilenames,
        "category_ids" => $categoryArray
    ]);
} else {
    jsonResponse(false, "Database error: " . $conn->error);
}

$conn->close();
?>