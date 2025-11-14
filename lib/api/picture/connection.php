<?php
$host = "192.168.99.252";
$user = "root";
$pass = "Admin_Pacific_219";
$dbname = "smarthome";

// $host = "192.168.99.197";
// $user = "root";
// $pass = "sb1281ch";
// $dbname = "testing";

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Database connection failed."]));
}

$conn->set_charset("utf8mb4");
?>
