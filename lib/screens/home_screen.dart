import 'package:car_booking/screens/profiles/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'MainHomeFeed.dart';
import 'my_bookings_screen.dart';

import 'add_car_screen.dart';
import 'settings_screen.dart'; // Add this if not already created
import 'login_screen.dart';    // For logout redirection

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String profileImageUrl = '';
  String userType = '';
  Map<String, dynamic> userData = {};

  List<Widget> _buildPages() {
    final basePages = <Widget>[
      MainHomeFeed(),
      MyBookingsScreen(),

    ];

    if (userType == 'Car Owner') {
      basePages.add(AddCarScreen(userData: userData));
    }

    return basePages;
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    final baseItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
      BottomNavigationBarItem(icon: Icon(Icons.support), label: 'Support'),
    ];

    if (userType == 'Car Owner') {
      baseItems.add(BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Car'));
    }

    return baseItems;
  }

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();

          setState(() {
            profileImageUrl = data['profileImage'] ?? '';
            userType = data['userType'] ?? 'Customer';
            userData = data;
          });

          print('✅ userType: $userType');
        }
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final navItems = _buildNavItems();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        elevation: 4,
        title: Text('Car Booking App'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  ).then((_) => fetchUserData());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 30, color: Colors.pink)
                          : null,
                    ),
                    SizedBox(height: 10),
                    Text(
                      userType,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            if (userType == 'Car Owner')
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Car'),
                onTap: () {
                  Navigator.pop(context); // Close Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCarScreen(userData: userData),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
