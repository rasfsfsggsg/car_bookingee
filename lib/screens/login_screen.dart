import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String? verificationId;
  bool otpSent = false;

  Future<void> loginUser() async {
    final input = emailOrPhoneController.text.trim();
    final password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter all fields');
      return;
    }

    try {
      String email = input;

      if (RegExp(r'^[0-9]{10}$').hasMatch(input)) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: '+91$input')
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          final fetchedEmail = data['email']?.toString();
          if (fetchedEmail == null || fetchedEmail.isEmpty) {
            Fluttertoast.showToast(msg: 'Email not found for this phone number');
            return;
          }
          email = fetchedEmail;
        } else {
          Fluttertoast.showToast(msg: 'No user found with this phone number');
          return;
        }
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Fluttertoast.showToast(msg: 'Login Successful!');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } catch (e) {
      Fluttertoast.showToast(msg: 'Login Failed: ${e.toString()}');
    }
  }

  void showPhoneLoginDialog() {
    phoneController.clear();
    otpController.clear();
    otpSent = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Login with Phone & OTP',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+91', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit number',
                          hintStyle: TextStyle(color: Colors.black54),
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (otpSent)
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      hintStyle: TextStyle(color: Colors.black54),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
              ],
            ),
            actions: [
              if (!otpSent)
                TextButton(
                  onPressed: () async {
                    final phone = phoneController.text.trim();
                    if (phone.length != 10) {
                      Fluttertoast.showToast(msg: 'Enter valid 10-digit mobile number');
                      return;
                    }

                    final fullPhone = '+91$phone';

                    final snapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('phone', isEqualTo: fullPhone)
                        .limit(1)
                        .get();

                    if (snapshot.docs.isEmpty) {
                      Fluttertoast.showToast(msg: 'User not registered with this number');
                      return;
                    }

                    await _auth.verifyPhoneNumber(
                      phoneNumber: fullPhone,
                      timeout: Duration(seconds: 60),
                      verificationCompleted: (PhoneAuthCredential credential) async {
                        await _auth.signInWithCredential(credential);
                        Fluttertoast.showToast(msg: 'Login Successful via OTP!');
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                      },
                      verificationFailed: (FirebaseAuthException e) {
                        Fluttertoast.showToast(msg: 'OTP Failed: ${e.message}');
                      },
                      codeSent: (String vId, int? token) {
                        setState(() {
                          verificationId = vId;
                          otpSent = true;
                        });
                        Fluttertoast.showToast(msg: 'OTP Sent');
                      },
                      codeAutoRetrievalTimeout: (vId) {
                        verificationId = vId;
                      },
                    );
                  },
                  child: Text('Send OTP', style: TextStyle(color: Colors.blue)),
                ),
              if (otpSent)
                TextButton(
                  onPressed: () async {
                    final otp = otpController.text.trim();
                    if (otp.isEmpty || verificationId == null) {
                      Fluttertoast.showToast(msg: 'Please enter OTP');
                      return;
                    }

                    try {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId!,
                        smsCode: otp,
                      );
                      await _auth.signInWithCredential(credential);
                      Fluttertoast.showToast(msg: 'Login Successful!');
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                    } catch (e) {
                      Fluttertoast.showToast(msg: 'OTP Invalid: ${e.toString()}');
                    }
                  },
                  child: Text('Verify OTP', style: TextStyle(color: Colors.blue)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
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
        title: Text('Login', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),

            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 120,
              ),
            ),
            SizedBox(height: 20),

            Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 10),

            Text(
              "“Drive with confidence, park with purpose.”",
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black),
            ),
            SizedBox(height: 5),


            SizedBox(height: 30),

            TextField(
              controller: emailOrPhoneController,
              decoration: buildInputDecoration('Email or Phone Number', Icons.person),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: buildInputDecoration('Password', Icons.lock),
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: loginUser,
              icon: Icon(Icons.login),
              label: Text('Login', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            TextButton(
              onPressed: showPhoneLoginDialog,
              child: Text(
                'Or Login with Phone & OTP',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account?", style: TextStyle(color: Colors.black)),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                  },
                  child: Text('Register', style: TextStyle(color: Colors.blue.shade700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
