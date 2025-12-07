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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LaptopListScreen(),
    );
  }
}

/* ================= MODEL ================= */
class Laptop {
  final String name;
  final String image;
  final double price;

  Laptop({
    required this.name,
    required this.image,
    required this.price,
  });

  factory Laptop.fromJson(Map<String, dynamic> json) {
    return Laptop(
      name: json['name'] ?? "Unknown",
      image: json['imageUrl'] ?? "",
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

/* ================= SCREEN ================= */
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Laptop>> fetchLaptopsFromApi(String query,
      {required String categoryId}) async {
    final uri = Uri.parse(
        'https://laptopapp.runasp.net/api/GetLaptopsByCategoryEndPoint?CategoryId=$categoryId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch laptops');
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (jsonBody['isSuccess'] != true) {
      throw Exception('API returned an error: ${jsonBody['message']}');
    }

    final data = jsonBody['data'] as List<dynamic>;
    List<Laptop> laptops = data.map((item) {
      final m = item as Map<String, dynamic>;
      return Laptop.fromJson(m);
    }).where((laptop) {
      return query.isEmpty ||
          laptop.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return laptops;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: "Search laptops...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              laptopsFuture =
                  fetchLaptopsFromApi(searchQuery, categoryId: categoryId);
            });
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchQuery = "";
                searchController.clear();
                laptopsFuture = fetchLaptopsFromApi("", categoryId: categoryId);
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              "Gaming Laptops",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Laptop>>(
              future: laptopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Oops! Something went wrong.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                final laptops = snapshot.data;
                if (laptops == null || laptops.isEmpty) {
                  return const Center(child: Text("No results found"));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GridView.builder(
                    itemCount: laptops.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      return LaptopCard(laptop: laptops[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                laptop.image,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image_not_supported));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laptop.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "\$${laptop.price}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
