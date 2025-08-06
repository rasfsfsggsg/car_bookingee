import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;
  File? _selectedImage;
  final picker = ImagePicker();
  final String imgbbApiKey = "fdd08c8a0e60ed3970be63f376e768ba";

  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final licenseController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  String userId = '';
  String userType = '';

  // Aadhaar & License Images for Customers
  File? aadhaarFront;
  File? aadhaarBack;
  File? licenseFront;
  File? licenseBack;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userId = user.uid;

    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      setState(() {
        userData = data;
        userType = data['userType'] ?? '';
        nameController.text = data['name'] ?? '';
        surnameController.text = data['surname'] ?? '';
        phoneController.text = data['phone'] ?? '';
        dobController.text = data['dob'] ?? '';
        licenseController.text = data['license'] ?? '';
        addressController.text = data['address'] ?? '';
        emailController.text = data['email'] ?? '';
        isLoading = false;
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
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> pickImageFor(String type) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        File image = File(picked.path);
        switch (type) {
          case 'aadhaarFront':
            aadhaarFront = image;
            break;
          case 'aadhaarBack':
            aadhaarBack = image;
            break;
          case 'licenseFront':
            licenseFront = image;
            break;
          case 'licenseBack':
            licenseBack = image;
            break;
        }
      });
    }
  }

  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl = userData?['profileImage'];
    if (_selectedImage != null) {
      imageUrl = await uploadImageToImgbb(_selectedImage!);
    }

    Map<String, dynamic> updateData = {
      "name": nameController.text.trim(),
      "surname": surnameController.text.trim(),
      "phone": phoneController.text.trim(),
      "dob": dobController.text.trim(),
      "license": licenseController.text.trim(),
      "address": addressController.text.trim(),
      "profileImage": imageUrl ?? '',
      "timestamp": Timestamp.now(),
    };

    // Only for Customer: Upload Aadhaar and License images
    if (userType == "Customer") {
      if (aadhaarFront != null) {
        updateData['aadhaarFront'] = await uploadImageToImgbb(aadhaarFront!);
      }
      if (aadhaarBack != null) {
        updateData['aadhaarBack'] = await uploadImageToImgbb(aadhaarBack!);
      }
      if (licenseFront != null) {
        updateData['licenseFront'] = await uploadImageToImgbb(licenseFront!);
      }
      if (licenseBack != null) {
        updateData['licenseBack'] = await uploadImageToImgbb(licenseBack!);
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));

    setState(() {
      isEditing = false;
      _selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Profile updated successfully.')));
    fetchUserDetails();
  }

  Widget buildTextField(String label, TextEditingController controller,
      IconData icon, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, color: Colors.pink),
          labelText: label,
          labelStyle: TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.pink.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildProfileImage() {
    ImageProvider image;

    if (_selectedImage != null) {
      image = FileImage(_selectedImage!);
    } else if (userData?['profileImage'] != null &&
        userData!['profileImage'] != '') {
      image = NetworkImage(userData!['profileImage']);
    } else {
      image = AssetImage('assets/default_user.png');
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.pink, Colors.pink.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: image,
            backgroundColor: Colors.white,
          ),
        ),
        if (isEditing)
          Positioned(
            bottom: 0,
            right: MediaQuery.of(context).size.width / 2 - 90,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: Icon(Icons.camera_alt),
                          title: Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            pickImageFor('profile');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_library),
                          title: Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            pickImageFor('profile');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Colors.pink),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildImageUploader(String label, File? image, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GestureDetector(
            onTap: () => pickImageFor(type),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: image == null
                  ? Center(
                  child: Icon(Icons.add_a_photo,
                      size: 30, color: Colors.pink))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("My Profile"),
        backgroundColor: Colors.pink,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 12),
          Text("User ID: $userId", style: TextStyle(color: Colors.grey[700])),
          SizedBox(height: 6),
          Center(child: buildProfileImage()),
          SizedBox(height: 6),
          Text(
            userType.isNotEmpty ? "User Type: $userType" : "",
            style: TextStyle(
                color: Colors.pink.shade700,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                buildTextField(
                    "First Name", nameController, Icons.person, isEditing),
                buildTextField("Surname", surnameController,
                    Icons.person_outline, isEditing),
                buildTextField("Phone", phoneController, Icons.phone,
                    isEditing),
                buildTextField("Date of Birth", dobController,
                    Icons.calendar_today, isEditing),
                buildTextField("License", licenseController,
                    Icons.credit_card, isEditing),
                buildTextField("Address", addressController,
                    Icons.location_city, isEditing),
                buildTextField(
                    "Email", emailController, Icons.email, false),
                if (userType == "Customer" && isEditing) ...[
                  buildImageUploader(
                      "Aadhaar Front", aadhaarFront, "aadhaarFront"),
                  buildImageUploader(
                      "Aadhaar Back", aadhaarBack, "aadhaarBack"),
                  buildImageUploader(
                      "License Front", licenseFront, "licenseFront"),
                  buildImageUploader(
                      "License Back", licenseBack, "licenseBack"),
                ],
                SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!isEditing) {
                    setState(() => isEditing = true);
                  }
                },
                icon: Icon(Icons.edit),
                label: Text("Edit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isEditing ? updateProfile : null,
                icon: Icon(Icons.check_circle),
                label: Text("Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isEditing ? Colors.pink : Colors.grey.shade300,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
