import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/models/pub_var.dart' as pub_var;
import 'package:intl/intl.dart'; // Import for better date formatting

// Assuming AppRoutes and pub_var exist and are correctly configured

class CustomerContactPage extends StatefulWidget {
  const CustomerContactPage({Key? key}) : super(key: key);

  @override
  State<CustomerContactPage> createState() => _CustomerContactPageState();
}

class _CustomerContactPageState extends State<CustomerContactPage> {
  late Future<List<Map<String, dynamic>>> _contactsFuture;
  final Color _primaryColor = const Color(0xFF1E88E5); // Blue 600
  final Color _successColor = Colors.green.shade600;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchUnresolvedContacts();
  }

  // --- Data Fetching Logic (Kept the same for functionality) ---

  Future<List<Map<String, dynamic>>> _fetchUnresolvedContacts() async {
    final String url = "${pub_var.apiBase}/get_unresolved_contacts.php";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load contacts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<bool> _markAsContacted(int orderId) async {
    final String url = "${pub_var.apiBase}/update_contact_status.php";

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'order_id': orderId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    }
  }

  void _refresh() {
    setState(() {
      _contactsFuture = _fetchUnresolvedContacts();
    });
  }

  // --- UI/Widget Build Logic (Improved) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unresolved Customer Contacts'),
        backgroundColor: _primaryColor, // Use custom primary color
        foregroundColor: Colors.white,
        elevation: 4, // Add a slight shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded), // Updated icon
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primaryColor, // Color for the refresh indicator
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _contactsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final contacts = snapshot.data ?? [];

            if (contacts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _ContactCard(
                  contact: contact,
                  onContacted: () => _showConfirmDialog(contact),
                  primaryColor: _primaryColor,
                  successColor: _successColor,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_outlined, // More expressive icon
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Oh snap! Failed to load contacts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.contains('Network error')
                  ? 'Check your network connection and try again.'
                  : error.split(':').last.trim(), // Show specific error part
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.replay),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand, // A friendly, welcoming icon
              size: 72,
              color: _successColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'You\'re all caught up!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'No unresolved customer contacts found. Great job!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(Map<String, dynamic> contact) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Softer corners
          ),
          elevation: 10,
          title: Text(
            'Confirm Contact Status',
            style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(
                  text: 'Confirm marking the order for\n',
                  style: TextStyle(height: 1.4),
                ),
                TextSpan(
                  text: contact['customer_name'] ?? 'This Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const TextSpan(
                  text: '\n(Order ID: ',
                  style: TextStyle(height: 1.4),
                ),
                TextSpan(
                  text: '#${contact['order_id']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _primaryColor,
                  ),
                ),
                const TextSpan(text: ') as contacted?'),
              ],
            ),
          ),
          actionsAlignment:
              MainAxisAlignment.spaceBetween, // Distribute buttons
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mark Contacted'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final orderId = contact['order_id'] as int;
    final success = await _markAsContacted(orderId);

    if (!mounted) return;

    // Show better toast messages
    if (success) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Order #${orderId} marked as contacted!'),
            ],
          ),
          backgroundColor: _successColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating, // Modern look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// --- Contact Card Widget (Improved) ---

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onContacted;
  final Color primaryColor;
  final Color successColor;

  const _ContactCard({
    required this.contact,
    required this.onContacted,
    required this.primaryColor,
    required this.successColor,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      // Use intl package for a more readable format
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr.split(' ')[0]; // Fallback, showing just the date part
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = contact['customer_name'] ?? 'Unknown Customer';
    final phone = contact['customer_phone'] ?? 'No phone available';
    final orderId = contact['order_id'];
    final dateStr = contact['order_date'];

    return Card(
      elevation: 6, // Increased elevation for a floating effect
      margin: const EdgeInsets.only(bottom: 18), // More vertical space
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // More pronounced curve
        side: BorderSide(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ), // Subtle border
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onContacted,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row: Avatar, Name, Phone, and Button ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.call, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Mark as Contacted Button (Outlined for less visual weight)
                  OutlinedButton(
                    onPressed: onContacted,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Contact'),
                  ),
                ],
              ),

              const Divider(height: 30, thickness: 1, color: Colors.black12),

              // --- Footer Row: Order ID and Date ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Order ID: ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        '#${orderId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  // Order Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Date: ${_formatDate(dateStr)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
