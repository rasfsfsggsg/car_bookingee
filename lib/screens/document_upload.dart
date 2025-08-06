import 'package:flutter/material.dart';

class DocumentUploadScreen extends StatelessWidget {
  final List<String> docs = ['License Front', 'License Back', 'Aadhaar Card', 'Car Selfie'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Documents')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.upload_file),
              title: Text(docs[index]),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${docs[index]} uploaded')));
                },
                child: Text('Upload'),
              ),
            ),
          );
        },
      ),
    );
  }
}
