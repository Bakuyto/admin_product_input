<?php
// connection.php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();               // <-- nothing else should run
}

$servername = "192.168.99.252";
$username   = "root";
$password   = "Admin_Pacific_219";
$dbname     = "smarthome";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['error' => 'DB connection failed: ' . $conn->connect_error]));
}
?>