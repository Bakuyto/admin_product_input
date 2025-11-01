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
$required = ['id', 'name','price','stock_quantity','category_ids','description'];
foreach ($required as $f) {
    if (!isset($json[$f])) jsonResponse(false, "Missing field: $f");
}

$id = (int)$json['id'];
if ($id <= 0) jsonResponse(false, "Invalid product ID");

// Sanitize inputs
$name           = $conn->real_escape_string(trim($json['name']));
$sku            = $conn->real_escape_string(trim($json['sku'] ?? ''));
$price          = (float)$json['price'];
$stock_quantity = (int)$json['stock_quantity'];
$description    = $conn->real_escape_string($json['description']);

// Handle category IDs properly
$categoryArray = is_array($json['category_ids']) ? $json['category_ids'] : [];
sort($categoryArray, SORT_NUMERIC);
$category_ids  = $conn->real_escape_string(implode(',', $categoryArray));

// Folder setup
$uploadDir = __DIR__ . "/picture/images/";
if (!is_dir($uploadDir) && !mkdir($uploadDir, 0755, true)) jsonResponse(false, "Failed to create image folder");

$allowedTypes = ['jpg','jpeg','png','gif'];
$maxSize = 5 * 1024 * 1024; // 5MB

// Fetch existing product to get current images
$existing = $conn->query("SELECT image_path, images_json FROM products WHERE wc_id = $id");
if (!$existing || $existing->num_rows === 0) jsonResponse(false, "Product not found");
$existingRow = $existing->fetch_assoc();
$currentMainImage = $existingRow['image_path'];
$currentSubImages = json_decode($existingRow['images_json'], true) ?? [];

// ── Main image (optional, if provided)
$mainFileName = $currentMainImage;
if (isset($_FILES['main_image'])) {
    $mainImage = $_FILES['main_image'];
    $ext = strtolower(pathinfo($mainImage['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $allowedTypes)) jsonResponse(false, "Main image type not allowed");
    if ($mainImage['size'] > $maxSize) jsonResponse(false, "Main image exceeds 5MB");

    $mainFileName = uniqid('main_') . '.' . $ext;
    $mainDest = $uploadDir . $mainFileName;
    if (!move_uploaded_file($mainImage['tmp_name'], $mainDest)) jsonResponse(false, "Failed to move main image");

    // Delete old main image if exists
    if (!empty($currentMainImage) && file_exists($uploadDir . $currentMainImage)) {
        unlink($uploadDir . $currentMainImage);
    }
}

// ── Sub-images (optional, if provided)
$subImagesFilenames = $currentSubImages;
if (!empty($_FILES['sub_images'])) {
    // Delete old sub images
    foreach ($currentSubImages as $oldSub) {
        $oldPath = $uploadDir . $oldSub;
        if (file_exists($oldPath)) unlink($oldPath);
    }

    $subImagesFilenames = [];
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

$sql = "UPDATE products SET
        name = '$name',
        sku = '$sku',
        price = $price,
        stock_quantity = $stock_quantity,
        category_ids = '$category_ids',
        description = '$description',
        image_path = '$mainFileName',
        images_json = '$imagesJson'
        WHERE wc_id = $id";

if ($conn->query($sql) === TRUE) {
    jsonResponse(true, "Product updated successfully.", [
        "product_id" => $id,
        "main_image" => $mainFileName,
        "sub_images" => $subImagesFilenames,
        "category_ids" => $categoryArray
    ]);
} else {
    jsonResponse(false, "Database error: " . $conn->error);
}

$conn->close();
?>
