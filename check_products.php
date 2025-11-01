<?php
require 'lib/api/connection.php';

$result = $conn->query("SELECT * FROM products LIMIT 1");
if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    echo json_encode($row) . "\n";
} else {
    echo "No products found.\n";
}

$conn->close();
?>
