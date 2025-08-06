import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCarScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AddCarScreen({super.key, required this.userData});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final TextEditingController carNameController = TextEditingController();
  final TextEditingController modelNumberController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController fuelTypeController = TextEditingController();

  final picker = ImagePicker();
  final String imgbbApiKey = 'fdd08c8a0e60ed3970be63f376e768ba';

  List<File?> carImages = [null, null, null, null];

  bool isLoading = false;

  Future<void> pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        carImages[index] = File(picked.path);
      });
    }
  }

  Future<String?> uploadImageToImgbb(File imageFile) async {
    try {
      var uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      var jsonData = json.decode(resBody);
      return jsonData['data']['url'];
    } catch (e) {
      print("❌ Image Upload Error: $e");
      return null;
    }
  }

  Future<void> handleSubmit() async {
    if (carImages.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload all 4 car images.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload all images
      List<String?> imageUrls = [];
      for (File? img in carImages) {
        final url = await uploadImageToImgbb(img!);
        imageUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('cars').add({
        'userId': user.uid,
        'ownerName': widget.userData['name'],
        'ownerSurname': widget.userData['surname'],
        'ownerEmail': widget.userData['email'],
        'ownerPhone': widget.userData['phone'],
        'ownerAddress': widget.userData['address'],
        'carName': carNameController.text.trim(),
        'modelNumber': modelNumberController.text.trim(),
        'price': priceController.text.trim(),
        'fuelType': fuelTypeController.text.trim(),
        'image1': imageUrls[0],
        'image2': imageUrls[1],
        'image3': imageUrls[2],
        'image4': imageUrls[3],
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Car added successfully 🚗")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("❌ Firestore Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add car.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: Colors.pink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );
  }

  Widget buildImageUploader(int index) {
    return GestureDetector(
      onTap: () => pickImage(index),
      child: Container(
        height: 100,
        width: 100,
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade100,
        ),
        child: carImages[index] == null
            ? Center(child: Icon(Icons.add_a_photo, size: 30, color: Colors.pink))
            : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(carImages[index]!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Car'),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Owner Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Name: ${widget.userData['name'] ?? ''}"),
            Text("Surname: ${widget.userData['surname'] ?? ''}"),
            Text("Email: ${widget.userData['email'] ?? ''}"),
            Text("Phone: ${widget.userData['phone'] ?? ''}"),
            Text("Address: ${widget.userData['address'] ?? ''}"),
            SizedBox(height: 14),

            Text("Upload Car Images", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Wrap(
              children: List.generate(4, (index) => buildImageUploader(index)),
            ),
            SizedBox(height: 14),

            Text("Car Information", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            buildTextField("Car Name", carNameController, Icons.directions_car),
            buildTextField("Model Number", modelNumberController, Icons.confirmation_number),
            buildTextField("Price ₹", priceController, Icons.currency_rupee),
            buildTextField("Fuel Type", fuelTypeController, Icons.local_gas_station),

            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: handleSubmit,
              icon: Icon(Icons.save),
              label: Text("Add Car"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
