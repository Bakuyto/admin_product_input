<?php
$host = "192.168.99.252";
$user = "root";
$pass = "Admin_Pacific_219";
$dbname = "smarthome";
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection
$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Log debug information to a file
$logFile = '/var/www/html/ard/api/upload_log.txt';
file_put_contents($logFile, "Uploaded Files Info: " . print_r($_FILES, true) . "\n", FILE_APPEND);

// Check if a video file is uploaded
if (isset($_FILES['video']) && $_FILES['video']['error'] == 0) {
    // Log the file info for the video
    file_put_contents($logFile, "Video: " . print_r($_FILES['video'], true) . "\n", FILE_APPEND);

    // Get the uploaded video file
    $videoTmpName = $_FILES['video']['tmp_name'];
    $videoName = basename($_FILES['video']['name']);
    $videoExtension = pathinfo($videoName, PATHINFO_EXTENSION);

    // Generate a unique filename for the video, preserving the original extension
    $videoFilename = uniqid('video_') . '.' . $videoExtension;

    // Set the target directory where videos will be stored
    $targetDir = '/var/www/html/ard/api/videos/';
    $targetFile = $targetDir . $videoFilename;

    // Allowed video extensions
    $allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', 'webm'];

    // Check if the uploaded video has an allowed extension
    if (in_array(strtolower($videoExtension), $allowedExtensions)) {
        // Move the uploaded video file to the target directory
        if (move_uploaded_file($videoTmpName, $targetFile)) {
            // Log the success of video upload
            file_put_contents($logFile, "Video uploaded successfully to: $targetFile\n", FILE_APPEND);

            // Video uploaded successfully, prepare the URL
            $url = "https://app.pacific.com.kh/ard/api/videos/" . $videoFilename;

            // Handle thumbnail image
            $thumbnailFile = $_FILES['thumbnail'] ?? null;
            if ($thumbnailFile && $thumbnailFile['error'] == 0) {
                // Log the file info for the thumbnail
                file_put_contents($logFile, "Thumbnail: " . print_r($thumbnailFile, true) . "\n", FILE_APPEND);

                // Process thumbnail file
                $thumbnailTmpName = $thumbnailFile['tmp_name'];
                $thumbnailName = basename($thumbnailFile['name']);
                $thumbnailExtension = pathinfo($thumbnailName, PATHINFO_EXTENSION);
                
                // Generate a unique filename for the thumbnail
                $thumbnailFilename = uniqid('thumbnail_') . '.' . $thumbnailExtension;
                
                // Set the thumbnail target file path (same as video directory)
                $thumbnailTargetFile = $targetDir . $thumbnailFilename;
                
                // Allowed image extensions
                $allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif'];

                // Check if the uploaded thumbnail has an allowed extension
                if (in_array(strtolower($thumbnailExtension), $allowedImageExtensions)) {
                    // Move the uploaded thumbnail file to the target directory
                    if (move_uploaded_file($thumbnailTmpName, $thumbnailTargetFile)) {
                        // Log the success of thumbnail upload
                        file_put_contents($logFile, "Thumbnail uploaded successfully to: $thumbnailTargetFile\n", FILE_APPEND);

                        // Thumbnail uploaded successfully, prepare the URL
                        $thumbnailUrl = "https://app.pacific.com.kh/ard/api/videos/" . $thumbnailFilename;
                    } else {
                        // Log error if thumbnail fails to upload
                        file_put_contents($logFile, "Error uploading thumbnail.\n", FILE_APPEND);
                        echo "Error uploading thumbnail.";
                        exit;
                    }
                } else {
                    // Log error if thumbnail file type is invalid
                    file_put_contents($logFile, "Invalid thumbnail file type.\n", FILE_APPEND);
                    echo "Invalid thumbnail file type.";
                    exit;
                }
            } else {
                // Log default thumbnail usage
                file_put_contents($logFile, "No thumbnail uploaded, using default.\n", FILE_APPEND);
                // If no thumbnail is provided, use the default image
                $thumbnailUrl = "https://app.pacific.com.kh/ard/api/videos/pacific.jpg";
            }

            // Get title and description from POST request
            $title = htmlspecialchars($_POST['title'], ENT_QUOTES, 'UTF-8');
            $description = htmlspecialchars($_POST['description'], ENT_QUOTES, 'UTF-8');

            // Prepare and bind SQL statement to insert video and thumbnail info
            $stmt = $conn->prepare("INSERT INTO videos (title, description, url, thm) VALUES (?, ?, ?, ?)");
            $stmt->bind_param("ssss", $title, $description, $url, $thumbnailUrl);

            // Execute SQL statement
            if ($stmt->execute()) {
                file_put_contents($logFile, "Video and thumbnail added successfully to database.\n", FILE_APPEND);
                echo "New video and thumbnail added successfully!";
            } else {
                file_put_contents($logFile, "Error inserting video data into the database.\n", FILE_APPEND);
                echo "Error: " . $stmt->error;
            }

            $stmt->close();
        } else {
            // Log error if video upload fails
            file_put_contents($logFile, "Error uploading video.\n", FILE_APPEND);
            echo "Error uploading video.";
            exit;
        }
    } else {
        // Log error if video file type is invalid
        file_put_contents($logFile, "Invalid video file type.\n", FILE_APPEND);
        echo "Invalid video file type.";
        exit;
    }
} else {
    // Log error if no video is uploaded
    file_put_contents($logFile, "No video file uploaded.\n", FILE_APPEND);
    echo "No video file uploaded or there was an error with the upload.";
    exit;
}

$conn->close();
?>
