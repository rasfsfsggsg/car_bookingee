import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  final faqs = [
    {'q': 'Can I cancel a booking?', 'a': 'Yes, before 24 hours of pickup.'},
    {'q': 'Is license verification needed?', 'a': 'Yes, mandatory before pickup.'},
  ];

  final TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support & Help')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('FAQs', style: TextStyle(fontWeight: FontWeight.bold)),
            ...faqs.map((faq) => ExpansionTile(
              title: Text(faq['q']!),
              children: [Padding(padding: EdgeInsets.all(8), child: Text(faq['a']!))],
            )),
            Divider(height: 30),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Send a message',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Support message sent'))),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
