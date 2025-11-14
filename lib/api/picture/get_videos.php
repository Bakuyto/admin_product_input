<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

include('connection.php');
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // Query the database to get videos
    $sql = "SELECT id, title, description, url, thm FROM videos ORDER BY id DESC";
    $result = $conn->query($sql);

    $videos = array();
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $videos[] = $row;
        }
    }
    echo json_encode($videos);
} catch (Exception $e) {
    echo json_encode(array('error' => $e->getMessage()));
}

$conn->close();
?>
