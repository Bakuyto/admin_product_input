<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once "connection.php";

function buildCategoryTree($parent_id = 0) {
    global $conn;
    $categories = [];
    $sql = "SELECT id, name FROM categories WHERE parent_id = $parent_id";
    $result = $conn->query($sql);
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $row['subcategories'] = buildCategoryTree($row['id']);
            $categories[] = $row;
        }
    }
    return $categories;
}

$tree = buildCategoryTree(0);
echo json_encode($tree);
?>