<?php
/*  get_unresolved_contacts.php  */
header('Content-Type: application/json');
require_once 'connection.php';   // your DB connection

/* ---------------------------------------------------------
   1. Get every order that has NOT been contacted yet
       - tblorders   → id, order_date, customer_name, customer_phone
       - tblorder_items → only used to guarantee the order has items
   --------------------------------------------------------- */
$sql = "
    SELECT 
        o.id,
        o.order_date,
        o.customer_name,
        o.customer_phone
    FROM tblorders o
    INNER JOIN tblorder_items oi ON o.id = oi.order_id
    WHERE o.alr_contact = 0
    GROUP BY o.id
    ORDER BY o.order_date DESC
";

$result = $conn->query($sql);

if ($result) {
    $contacts = [];
    while ($row = $result->fetch_assoc()) {
        $contacts[] = [
            /*  <-- FORCE int so JSON has 26, not "26"  --> */
            'order_id'       => (int)$row['id'],
            'order_date'     => $row['order_date'],
            'customer_name'  => $row['customer_name'] ?? 'Unknown',
            'customer_phone' => $row['customer_phone'] ?? 'N/A',
        ];
    }
    echo json_encode($contacts);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Query failed: ' . $conn->error]);
}

$conn->close();
?>