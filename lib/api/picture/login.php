<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include 'connection.php';
$conn->set_charset("utf8");

// Handle POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['username']) || !isset($input['password'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Username and password are required"]);
        exit;
    }

    $username = trim($input['username']);
    $password = trim($input['password']);

    $username = $conn->real_escape_string($username);

    $sql = "SELECT user_id, user_name, user_password, user_role FROM tbluser WHERE user_name = ?";
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database query preparation failed"]);
        $conn->close();
        exit;
    }

    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Invalid username or password"]);
        $stmt->close();
        $conn->close();
        exit;
    }

    $user = $result->fetch_assoc();

    if ($password === $user['user_password']) {
        session_start();
        $_SESSION['user_id'] = $user['user_id'];
        $_SESSION['username'] = $user['user_name'];
        $_SESSION['user_role'] = $user['user_role'];

        echo json_encode([
            "success" => true,
            "message" => "Login successful",
            "user" => [
                "user_id" => $user['user_id'],
                "username" => $user['user_name'],
                "user_role" => $user['user_role']
            ]
        ]);
    } else {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Invalid username or password"]);
    }

    $stmt->close();
} else {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method not allowed"]);
}

$conn->close();
?>
