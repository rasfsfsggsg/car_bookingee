import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.pink.shade400,
        elevation: 4,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Edit Profile'),
            onTap: () {
              // TODO: Navigate to edit profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit Profile Clicked')),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification Settings'),
            onTap: () {
              // TODO: Navigate or show settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notification Settings Clicked')),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy & Security'),
            onTap: () {
              // TODO: Implement privacy settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Privacy & Security Clicked')),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              // TODO: Navigate to support screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Help & Support Clicked')),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.info),
            title: Text('About App'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Car Booking App',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.car_rental),
                children: [
                  Text('This is a demo app for car bookings.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
