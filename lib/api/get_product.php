<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require_once "connection.php";

$baseImageUrl = "https://app.pacific.com.kh/lyheng/picture/";

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

if ($id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid product ID']);
    exit;
}

// ✅ Fetch product
$sql = "SELECT * FROM products WHERE wc_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Product not found']);
    exit;
}

$product = $result->fetch_assoc();

// ✅ Process images
$images_json = json_decode($product['images_json'], true) ?? [];
$main_image = null;
$sub_images = [];

foreach ($images_json as $img) {
    if (!empty($img['src'])) {
        $src = $img['src'];
        if (strpos($src, 'http') !== 0) {
            $src = $baseImageUrl . $src;
        }
        if (!empty($img['is_main'])) {
            $main_image = $src;
        } else {
            $sub_images[] = $src;
        }
    }
}

// ✅ Fallback if main image is missing
if (!$main_image && !empty($product['image_path'])) {
    $main_image = $baseImageUrl . $product['image_path'];
}

// ✅ Process categories
$category_ids = $product['category_ids'] === '' ? [] : explode(',', $product['category_ids']);
$categories = [];

if (!empty($category_ids)) {
    $placeholders = implode(',', array_fill(0, count($category_ids), '?'));
    $cat_sql = "SELECT id, name FROM categories WHERE id IN ($placeholders)";
    $cat_stmt = $conn->prepare($cat_sql);
    $cat_stmt->bind_param(str_repeat('i', count($category_ids)), ...$category_ids);
    $cat_stmt->execute();
    $cat_result = $cat_stmt->get_result();
    while ($cat_row = $cat_result->fetch_assoc()) {
        $categories[] = $cat_row;
    }
    $cat_stmt->close();
}

$product_data = [
    'id' => (int)$product['wc_id'],
    'name' => $product['name'],
    'sku' => $product['sku'],
    'price' => (float)$product['price'],
    'stock_quantity' => (int)$product['stock_quantity'],
    'description' => $product['description'],
    'main_image' => $main_image,
    'sub_images' => $sub_images,
    'categories' => $categories,
    'created_at' => $product['created_at'],
    'updated_at' => $product['updated_at']
];

$stmt->close();

echo json_encode([
    'success' => true,
    'product' => $product_data
], JSON_UNESCAPED_UNICODE);
?>
