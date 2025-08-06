import 'package:flutter/material.dart';

class CarDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Car Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/car_sample.jpg', height: 200),
            SizedBox(height: 10),
            Text('Tesla Model 3', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text('Automatic | 5 Seater | Electric'),
            SizedBox(height: 10),
            Text('₹2500/day', style: TextStyle(fontSize: 18, color: Colors.green)),
            SizedBox(height: 20),
            Row(children: [Icon(Icons.person), SizedBox(width: 8), Text('Owner: Rajeev Sharma')]),
          ],
        ),
      ),
    );
  }
}
