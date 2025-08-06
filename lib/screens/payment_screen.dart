import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedMethod = 'UPI';
  final promoController = TextEditingController();
  bool promoApplied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text('Payment Method'),
              subtitle: DropdownButton<String>(
                value: selectedMethod,
                items: ['UPI', 'Credit Card', 'Wallet'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => selectedMethod = val!),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: promoController,
              decoration: InputDecoration(labelText: 'Promo Code', border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => promoApplied = true);
              },
              child: Text('Apply Promo'),
            ),
            if (promoApplied)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Promo Applied: 10% OFF', style: TextStyle(color: Colors.green)),
              ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Payment Confirmed'),
                    content: Text('Booking has been paid.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              child: Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}
