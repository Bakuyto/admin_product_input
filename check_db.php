<?php
$host = "192.168.99.197";
$user = "root";
$pass = "sb1281ch";
$dbname = "testing";

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully\n";

$result = $conn->query("DESCRIBE categories");
while ($row = $result->fetch_assoc()) {
    echo json_encode($row) . "\n";
}

$conn->close();
?>
