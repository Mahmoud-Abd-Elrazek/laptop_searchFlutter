import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

/* ================= APP ROOT ================= */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LaptopListScreen(),
    );
  }
}

/* ================= MODEL ================= */
class Laptop {
  final String id;
  final String name;
  final String image;
  final double price;

  Laptop({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  factory Laptop.fromJson(Map<String, dynamic> json) {
    return Laptop(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown",
      image: json['imageUrl'] ?? "",
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

/* ================= HOME SCREEN ================= */
class LaptopListScreen extends StatefulWidget {
  const LaptopListScreen({super.key});

  @override
  State<LaptopListScreen> createState() => _LaptopListScreenState();
}

class _LaptopListScreenState extends State<LaptopListScreen> {
  String searchQuery = "";
  late Future<List<Laptop>> laptopsFuture;
  final TextEditingController searchController = TextEditingController();
  final String categoryId = "3fa85f64-5717-4562-b3fc-2c963f66afa6";

  @override
  void initState() {
    super.initState();
    laptopsFuture = fetchLaptopsFromApi("", categoryId: categoryId);
  }

  List<Laptop> mockLaptops = [
    Laptop(
      id: "1",
      name: "ASUS ROG Strix G16",
      image: "https://m.media-amazon.com/images/I/71tHNTGasKL._AC_SL1500_.jpg",
      price: 1450,
    ),
    Laptop(
      id: "2",
      name: "Lenovo Legion 5",
      image: "https://m.media-amazon.com/images/I/71tHNTGasKL._AC_SL1500_.jpg",
      price: 1320,
    ),
    Laptop(
      id: "3",
      name: "HP Omen 16",
      image: "https://m.media-amazon.com/images/I/71tHNTGasKL._AC_SL1500_.jpg",
      price: 1500,
    ),
    Laptop(
      id: "4",
      name: "MSI Katana GF66",
      image: "https://m.media-amazon.com/images/I/71tHNTGasKL._AC_SL1500_.jpg",
      price: 1250,
    ),
    Laptop(
      id: "5",
      name: "Acer Predator Helios 300",
      image: "https://m.media-amazon.com/images/I/71tHNTGasKL._AC_SL1500_.jpg",
      price: 1600,
    ),
  ];

  Future<List<Laptop>> fetchLaptopsFromApi(String query,
      {required String categoryId}) async {
    await Future.delayed(const Duration(seconds: 1)); // Fake loading

    return mockLaptops.where((laptop) {
      return query.isEmpty ||
          laptop.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Future<List<Laptop>> fetchLaptopsFromApi(String query,
  //     {required String categoryId}) async {
  //   final uri = Uri.parse(
  //       'https://laptopapp.runasp.net/api/GetLaptopsByCategoryEndPoint?CategoryId=$categoryId');

  //   final response = await http.get(uri);

  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to fetch laptops');
  //   }

  //   final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

  //   final data = jsonBody['data'] as List<dynamic>;

  //   List<Laptop> laptops = data.map((item) {
  //     return Laptop.fromJson(item);
  //   }).where((laptop) {
  //     return query.isEmpty ||
  //         laptop.name.toLowerCase().contains(query.toLowerCase());
  //   }).toList();

  //   return laptops;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      /// ✅ ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLaptopScreen()),
          );
        },
      ),

      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: "Search laptops...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              laptopsFuture =
                  fetchLaptopsFromApi(searchQuery, categoryId: categoryId);
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              setState(() {
                laptopsFuture = fetchLaptopsFromApi("", categoryId: categoryId);
              });
            },
          )
        ],
      ),

      body: FutureBuilder<List<Laptop>>(
        future: laptopsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final laptops = snapshot.data;

          if (laptops == null || laptops.isEmpty) {
            return const Center(child: Text("No laptops found"));
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              itemCount: laptops.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (_, index) {
                return LaptopCard(laptop: laptops[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

/* ================= CARD ================= */
class LaptopCard extends StatelessWidget {
  final Laptop laptop;
  const LaptopCard({super.key, required this.laptop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LaptopDetailsScreen(laptopId: laptop.id),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    laptop.image,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(laptop.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        "\$${laptop.price}",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// EDIT BUTTON
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 18,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditLaptopScreen(laptop: laptop),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= DETAILS ================= */
class LaptopDetailsScreen extends StatelessWidget {
  final String laptopId;

  const LaptopDetailsScreen({super.key, required this.laptopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laptop Details")),
      body: Center(
        child: Text(
          "Laptop ID: $laptopId",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

/* ================= ADD LAPTOP ================= */
class AddLaptopScreen extends StatelessWidget {
  const AddLaptopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final imageController = TextEditingController();
    final priceController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Laptop")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name")),
            TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Image URL")),
            TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Add Laptop"),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= EDIT LAPTOP ================= */
class EditLaptopScreen extends StatelessWidget {
  final Laptop laptop;

  const EditLaptopScreen({super.key, required this.laptop});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: laptop.name);
    final imageController = TextEditingController(text: laptop.image);
    final priceController =
        TextEditingController(text: laptop.price.toString());

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Laptop")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name")),
            TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Image URL")),
            TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
