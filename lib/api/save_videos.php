<?php
header('Content-Type: text/plain'); // For debugging

include 'connection.php';

$logFile = '/var/www/html/ard/api/upload_log.txt';
file_put_contents($logFile, "\n=== NEW REQUEST ===\n", FILE_APPEND);
file_put_contents($logFile, "POST: " . print_r($_POST, true) . "\n", FILE_APPEND);
file_put_contents($logFile, "FILES: " . print_r($_FILES, true) . "\n", FILE_APPEND);

// --- Connect DB ---
$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    file_put_contents($logFile, "DB Error: " . $conn->connect_error . "\n", FILE_APPEND);
    echo "DB Connection failed.";
    exit;
}

// --- VIDEO ---
if (!isset($_FILES['video']) || $_FILES['video']['error'] !== UPLOAD_ERR_OK) {
    file_put_contents($logFile, "No video or upload error.\n", FILE_APPEND);
    echo "No video uploaded.";
    exit;
}

$video = $_FILES['video'];
$videoExt = strtolower(pathinfo($video['name'], PATHINFO_EXTENSION));
$allowedVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'];

if (!in_array($videoExt, $allowedVideo)) {
    echo "Invalid video type.";
    exit;
}

$videoName = uniqid('video_') . '.' . $videoExt;
$targetDir = '/var/www/html/ard/api/videos/';
$targetPath = $targetDir . $videoName;

if (!move_uploaded_file($video['tmp_name'], $targetPath)) {
    echo "Failed to save video.";
    exit;
}

$url = "https://app.pacific.com.kh/ard/api/videos/" . $videoName;

// --- THUMBNAIL (optional) ---
$thumbnailUrl = "https://app.pacific.com.kh/ard/api/videos/pacific.jpg"; // default

if (isset($_FILES['thumbnail']) && $_FILES['thumbnail']['error'] === UPLOAD_ERR_OK) {
    $thumb = $_FILES['thumbnail'];
    $thumbExt = strtolower(pathinfo($thumb['name'], PATHINFO_EXTENSION));
    $allowedImg = ['jpg', 'jpeg', 'png', 'gif'];

    if (in_array($thumbExt, $allowedImg)) {
        $thumbName = uniqid('thumb_') . '.' . $thumbExt;
        $thumbPath = $targetDir . $thumbName;
        if (move_uploaded_file($thumb['tmp_name'], $thumbPath)) {
            $thumbnailUrl = "https://app.pacific.com.kh/ard/api/videos/" . $thumbName;
        }
    }
}

// --- SAVE TO DB ---
$title = htmlspecialchars($_POST['title'] ?? '', ENT_QUOTES, 'UTF-8');
$desc  = htmlspecialchars($_POST['description'] ?? '', ENT_QUOTES, 'UTF-8');

$stmt = $conn->prepare("INSERT INTO videos (title, description, url, thm) VALUES (?, ?, ?, ?)");
$stmt->bind_param("ssss", $title, $desc, $url, $thumbnailUrl);

if ($stmt->execute()) {
    echo "Video saved successfully!";
} else {
    echo "DB Error: " . $stmt->error;
}

$stmt->close();
$conn->close();
?>