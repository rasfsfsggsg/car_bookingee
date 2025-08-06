import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final licenseController = TextEditingController();

  String selectedUserType = 'Customer';
  final List<String> userTypes = ['Customer', 'Car Owner'];

  bool isVerificationSent = false;
  bool checkingVerification = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: 'Passwords do not match');
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      setState(() {
        isVerificationSent = true;
      });

      Fluttertoast.showToast(
        msg: 'Verification link sent. Please check your email.',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  Future<void> verifyAndSaveUser() async {
    setState(() => checkingVerification = true);
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;

    if (user != null && user.emailVerified) {
      try {
        String rawPhone = phoneController.text.trim();
        if (rawPhone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(rawPhone)) {
          Fluttertoast.showToast(msg: 'Enter valid 10-digit phone number');
          setState(() => checkingVerification = false);
          return;
        }

        String formattedPhone = '+91$rawPhone';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'dob': dobController.text.trim(),
          'address': addressController.text.trim(),
          'phone': formattedPhone,
          'license': licenseController.text.trim(),
          'email': emailController.text.trim(),
          'userType': selectedUserType,
          'timestamp': Timestamp.now(),
        }, SetOptions(merge: true));

        Fluttertoast.showToast(msg: 'Registration Successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error saving data: ${e.toString()}');
      }
    } else {
      Fluttertoast.showToast(msg: 'Email not verified yet.');
    }

    setState(() => checkingVerification = false);
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black),
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Register', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ✅ Logo
              Image.asset(
                'assets/logo.png',
                height: 120,
              ),
              SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedUserType,
                decoration: buildInputDecoration('Select User Type', Icons.person),
                items: userTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(color: Colors.black))))
                    .toList(),
                onChanged: (val) => setState(() => selectedUserType = val!),
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: nameController,
                      decoration: buildInputDecoration('First Name', Icons.person),
                      validator: (val) => val!.isEmpty ? 'Enter your first name' : null,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: surnameController,
                      decoration: buildInputDecoration('Surname', Icons.person_outline),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: buildInputDecoration('Date of Birth', Icons.cake),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: addressController,
                decoration: buildInputDecoration('Address', Icons.home),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: buildInputDecoration('Phone', Icons.phone),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: licenseController,
                decoration: buildInputDecoration('License No. (Optional)', Icons.badge),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: emailController,
                decoration: buildInputDecoration('Email', Icons.email),
                validator: (val) => val!.isEmpty ? 'Enter your email' : null,
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 20),

              if (!isVerificationSent)
                ElevatedButton.icon(
                  onPressed: registerUser,
                  icon: Icon(Icons.email),
                  label: Text('Submit & Send Verification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              if (isVerificationSent)
                TextButton(
                  onPressed: verifyAndSaveUser,
                  child: checkingVerification
                      ? CircularProgressIndicator()
                      : Text(
                    'Click Here After Verifying Email',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: TextStyle(color: Colors.black)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: Text('Login', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
