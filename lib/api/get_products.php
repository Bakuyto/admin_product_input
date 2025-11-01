<?php
error_reporting(0);
ini_set('display_errors', 0);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
require_once "connection.php";

$baseImageUrl = "https://app.pacific.com.kh/lyheng/picture/";

// Pagination params
$page = isset($_GET['page']) ? (int)$_GET['page'] : null;
$per_page = isset($_GET['per_page']) ? (int)$_GET['per_page'] : null;
$searchQuery = isset($_GET['search']) ? $_GET['search'] : '';

if (($page === null || $per_page === null) && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);
    if (is_array($body)) {
        if (isset($body['page'])) $page = (int)$body['page'];
        if (isset($body['per_page'])) $per_page = (int)$body['per_page'];
        if (isset($body['search'])) $searchQuery = $body['search'];
    }
}

if ($page === null || $page < 1) $page = 1;
if ($per_page === null || $per_page < 1) $per_page = 20;

// Build search SQL
$searchSQL = '';
$params = [];
$types = '';

if (!empty($searchQuery)) {
    $searchSQL = " WHERE p.name LIKE ?";
    $params[] = "%$searchQuery%";
    $types .= 's';
}

// Count total
$countStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM products p $searchSQL");
if (!empty($params)) $countStmt->bind_param($types, ...$params);
$countStmt->execute();
$countResult = $countStmt->get_result();
$total = 0;
if ($row = $countResult->fetch_assoc()) $total = (int)$row['cnt'];
$total_pages = max(1, (int)ceil($total / $per_page));
$offset = ($page - 1) * $per_page;

// Fetch products with category name
$sql = "SELECT p.*, c.name AS category_name
        FROM products p
        LEFT JOIN categories c ON FIND_IN_SET(c.id, p.category_ids)
        $searchSQL
        ORDER BY c.name ASC, p.name ASC
        LIMIT ?, ?";

$stmt = $conn->prepare($sql);

// Bind params dynamically
if (!empty($params)) {
    $types .= 'ii';
    $params[] = $offset;
    $params[] = $per_page;
    $stmt->bind_param($types, ...$params);
} else {
    $stmt->bind_param('ii', $offset, $per_page);
}

$stmt->execute();
$result = $stmt->get_result();

$products = [];
while ($row = $result->fetch_assoc()) {
    $row['id'] = $row['wc_id'];
    $row['image_url'] = !empty($row['image_path'])
        ? $baseImageUrl . $row['image_path']
        : (json_decode($row['images_json'], true)[0]['src'] ?? null);

    $row['category_ids'] = $row['category_ids'] === '' ? [] : explode(',', $row['category_ids']);
    $products[] = $row;
}

$stmt->close();

echo json_encode([
    'data' => $products,
    'total' => $total,
    'page' => $page,
    'per_page' => $per_page,
    'total_pages' => $total_pages,
], JSON_UNESCAPED_UNICODE);
?>
