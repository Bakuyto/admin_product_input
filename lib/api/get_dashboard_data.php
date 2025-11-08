<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Database connection
$servername = "192.168.99.252";
$username = "root";
$password = "Admin_Pacific_219";
$dbname = "smarthome"; // Change this to your actual database name

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}

// Fetch total products
$product_query = "SELECT COUNT(*) AS total_products FROM products";
$product_result = $conn->query($product_query);
if ($product_result) {
    $product_row = $product_result->fetch_assoc();
} else {
    $response['error'] = 'Failed to fetch total products';
    echo json_encode($response);
    $conn->close();
    exit();
}

// Fetch new customers in the last 30 days
$customer_query = "SELECT COUNT(*) AS new_customers FROM tblorders WHERE order_date > NOW() - INTERVAL 30 DAY";
$customer_result = $conn->query($customer_query);
if ($customer_result) {
    $customer_row = $customer_result->fetch_assoc();
} else {
    $response['error'] = 'Failed to fetch new customers';
    echo json_encode($response);
    $conn->close();
    exit();
}

// Fetch unresolved tickets
$ticket_query = "SELECT COUNT(*) AS unresolved_tickets FROM tblorders WHERE alr_contact = 0";
$ticket_result = $conn->query($ticket_query);
if ($ticket_result) {
    $ticket_row = $ticket_result->fetch_assoc();
} else {
    $response['error'] = 'Failed to fetch unresolved tickets';
    echo json_encode($response);
    $conn->close();
    exit();
}

// Prepare and send response
$response = [
    'total_products' => $product_row['total_products'],
    'new_customers' => $customer_row['new_customers'],
    'unresolved_tickets' => $ticket_row['unresolved_tickets']
];

echo json_encode($response);

$conn->close();
?>
