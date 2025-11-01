<?php
require 'lib/api/connection.php';

$result = $conn->query("DESCRIBE products");
while ($row = $result->fetch_assoc()) {
    echo json_encode($row) . "\n";
}

$conn->close();
?>
