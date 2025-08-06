import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'booking_form.dart'; // 👈 Import the separate booking form

class MainHomeFeed extends StatefulWidget {
  const MainHomeFeed({super.key});

  @override
  State<MainHomeFeed> createState() => _MainHomeFeedState();
}

class _MainHomeFeedState extends State<MainHomeFeed> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCE4EC), Color(0xFFFFFFFF)], // light pink to white
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text("🚘 Available Cars"),
                backgroundColor: Colors.pinkAccent,
                centerTitle: true,
                elevation: 0,
              ),

              // 🔍 Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '🔍 Search by Area...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // 🔄 Car List Stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cars')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("🚘 कोई कार उपलब्ध नहीं है"));
                    }

                    final allCars = snapshot.data!.docs;

                    // 🧠 Filter based on address
                    final filteredCars = allCars.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final address = data['ownerAddress']?.toString().toLowerCase() ?? '';
                      return address.contains(_searchQuery);
                    }).toList();

                    return Scrollbar(
                      thickness: 6.0,
                      radius: const Radius.circular(10),
                      thumbVisibility: true,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredCars.length,
                        itemBuilder: (context, index) {
                          final car = filteredCars[index].data() as Map<String, dynamic>;
                          final images = [
                            car['image1'],
                            car['image2'],
                          ].where((img) => img != null && img != '').toList();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (images.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: SizedBox(
                                      height: 200,
                                      child: PageView.builder(
                                        itemCount: images.length,
                                        itemBuilder: (context, i) {
                                          return Image.network(
                                            images[i],
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) =>
                                            const Center(child: Icon(Icons.broken_image)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        car['carName'] ?? 'Unknown Car',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text("📅 मॉडल: ${car['modelNumber'] ?? 'N/A'}"),
                                      Text("⛽ ईंधन: ${car['fuelType'] ?? 'N/A'} • ₹${car['price'] ?? '0'}"),
                                      Text("📍 किमी चली है: ${car['kmDriven'] ?? '0'} KM"),
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const Text(
                                        "🧑‍💼 मालिक की जानकारी",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.person, color: Colors.pinkAccent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("नाम: ${car['ownerName'] ?? 'N/A'}"),
                                                Text("ईमेल: ${car['ownerEmail'] ?? 'N/A'}"),
                                                Text("पता: ${car['ownerAddress'] ?? 'N/A'}"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // 🚗 Book Now Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            BookingForm.show(context, car);
                                          },
                                          child: const Text("🚗 Book Now"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
