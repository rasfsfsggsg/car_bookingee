import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String userEmail = '';
  bool isLoading = true;
  List<DocumentSnapshot> bookingList = [];

  @override
  void initState() {
    super.initState();
    fetchBookingsForOwner();
  }

  /// 🔄 Fetch bookings where ownerEmail == current user's email
  Future<void> fetchBookingsForOwner() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        userEmail = currentUser.email ?? '';

        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerEmail', isEqualTo: userEmail)
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          bookingList = bookingsSnapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => isLoading = false);
    }
  }

  /// ✅ Update booking status in Firestore
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Booking $newStatus')),
      );

      fetchBookingsForOwner(); // Refresh list
    } catch (e) {
      print('❌ Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error updating booking status')),
      );
    }
  }

  /// 🎨 UI for each booking card with Accept/Reject
  Widget buildBookingCard(DocumentSnapshot doc) {
    final booking = doc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🚗 ${booking['carName'] ?? 'Unknown Car'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("👤 User: ${booking['userName'] ?? 'N/A'}"),
            Text("📧 Email: ${booking['userEmail'] ?? 'N/A'}"),
            Text("📝 Description: ${booking['description'] ?? 'None'}"),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    "Status: ${booking['status'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: booking['status'] == 'accepted'
                      ? Colors.green
                      : booking['status'] == 'rejected'
                      ? Colors.red
                      : Colors.orange,
                ),
                const Spacer(),
                if (booking['status'] == 'requested') ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        updateBookingStatus(doc.id, 'accepted'),
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () =>
                        updateBookingStatus(doc.id, 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Booking Requests'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingList.isEmpty
          ? const Center(child: Text("No booking requests found."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "📥 Received Booking Requests",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookingList.length,
              itemBuilder: (context, index) {
                return buildBookingCard(bookingList[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
