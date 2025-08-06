import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class BookingForm {
  static void show(BuildContext context, Map<String, dynamic> carData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BookingFormWidget(carData: carData),
      ),
    );
  }
}

class BookingFormWidget extends StatefulWidget {
  final Map<String, dynamic> carData;

  const BookingFormWidget({Key? key, required this.carData}) : super(key: key);

  @override
  State<BookingFormWidget> createState() => _BookingFormWidgetState();
}

class _BookingFormWidgetState extends State<BookingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  File? _paymentScreenshot;

  bool _isLoading = false;
  bool _isFetchingUser = true;
  bool _paymentDone = false;

  String? _userName;
  String? _userEmail;
  String? _userAddress;

  int _selectedDayCount = 1;

  final picker = ImagePicker();
  final String imgbbApiKey = "fdd08c8a0e60ed3970be63f376e768ba";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _amountController.text = "1000"; // default for 1 day
  }

  Future<void> _fetchUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          _userName = data['name'] ?? '';
          _userEmail = data['email'] ?? user.email!;
          _userAddress = data['address'] ?? '';
        }
      }
    } catch (e) {
      print("❌ Error fetching user info: $e");
    } finally {
      setState(() => _isFetchingUser = false);
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDayCount = picked.end.difference(picked.start).inDays + 1;
        _amountController.text = (_selectedDayCount * 1000).toString();
      });
    }
  }

  Future<void> _pickScreenshot() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _paymentScreenshot = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImageToImgbb(File imageFile) async {
    try {
      var uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      var jsonData = json.decode(resBody);
      return jsonData['data']['url'];
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  Future<void> _launchUPIPayment() async {
    String amount = _amountController.text.trim();
    final uri = Uri.parse(
        "upi://pay?pa=7734815980@YBL&pn=CarRental&am=$amount&cu=INR");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // After return, confirm with dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Payment Confirmation"),
          content: const Text("Have you completed the UPI payment?"),
          actions: [
            TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _paymentDone = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Payment confirmed. Now upload screenshot.")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Could not open any UPI app.")),
      );
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please fill all fields and select date range.")),
      );
      return;
    }

    if (!_paymentDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("💸 Please confirm UPI payment first.")),
      );
      return;
    }

    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📷 Please upload payment screenshot.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? screenshotUrl = await _uploadImageToImgbb(_paymentScreenshot!);
      String amount = _amountController.text.trim();

      await FirebaseFirestore.instance.collection('bookings').add({
        'carName': widget.carData['carName'],
        'modelNumber': widget.carData['modelNumber'],
        'price': widget.carData['price'],
        'ownerName': widget.carData['ownerName'],
        'ownerEmail': widget.carData['ownerEmail'],
        'ownerAddress': widget.carData['ownerAddress'],
        'userName': _userName,
        'userEmail': _userEmail,
        'userAddress': _userAddress,
        'description': _descriptionController.text.trim(),
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'days': _selectedDayCount,
        'amount': amount,
        'paymentScreenshot': screenshotUrl ?? '',
        'status': 'requested',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Booking sent successfully!")),
      );
    } catch (e) {
      print("❌ Booking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isFetchingUser
        ? const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "🚗 Book This Car",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Booking Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (val) =>
                  val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text("📆 Duration: "),
                    DropdownButton<int>(
                      value: _selectedDayCount,
                      items: List.generate(7, (i) {
                        int d = i + 1;
                        return DropdownMenuItem(
                            value: d,
                            child: Text("$d Day${d > 1 ? 's' : ''}"));
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDayCount = val;
                            _startDate = DateTime.now();
                            _endDate = _startDate!.add(Duration(days: val - 1));
                            _amountController.text = (val * 1000).toString();
                          });
                        }
                      },
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _selectDateRange,
                      child: const Text("📅 Pick Dates"),
                    ),
                  ],
                ),

                if (_startDate != null && _endDate != null)
                  Text(
                    "From ${DateFormat.yMMMd().format(_startDate!)} to ${DateFormat.yMMMd().format(_endDate!)}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Edit Total Amount (₹)",
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? "Amount is required"
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _launchUPIPayment,
            icon: const Icon(Icons.open_in_new),
            label: const Text("Pay with UPI App"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _pickScreenshot,
            icon: const Icon(Icons.upload),
            label: const Text("Upload Payment Screenshot"),
          ),

          const SizedBox(height: 10),
          if (_paymentScreenshot != null)
            Image.file(_paymentScreenshot!, height: 150)
          else
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: const Center(
                child: Text("📷 No Screenshot Uploaded",
                    style: TextStyle(color: Colors.grey)),
              ),
            ),

          const SizedBox(height: 20),

          _isLoading
              ? const CircularProgressIndicator()
              : SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitBooking,
              icon: const Icon(Icons.check),
              label: const Text("📩 Confirm Booking"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
