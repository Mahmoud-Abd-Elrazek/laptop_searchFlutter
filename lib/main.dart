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
  final String categoryId;

  Laptop({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.categoryId,
  });

  factory Laptop.fromJson(Map<String, dynamic> json) {
    return Laptop(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown",
      image: json['imageUrl'] ?? "",
      price: (json['price'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? "",
    );
  }
}

class Category {
  final String id;
  final String name;
  final String imageUrl;

  Category({required this.id, required this.name, required this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown",
      imageUrl: json['imageUrl'] ?? "",
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
  late Future<List<Category>> categoriesFuture;
  final TextEditingController searchController = TextEditingController();
  String selectedCategoryId = "";
  String selectedCategoryName = "All";

  @override
  void initState() {
    super.initState();
    categoriesFuture = fetchCategories();
    laptopsFuture = fetchLaptops();
  }

  /// ✅ Fetch all categories
  Future<List<Category>> fetchCategories() async {
    final uri =
        Uri.parse('https://laptopapp.runasp.net/api/GetAllCategoriesEndPoint');
    final response = await http.get(uri);

    if (response.statusCode != 200)
      throw Exception('Failed to fetch categories');

    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    final List data = jsonBody['data'] as List<dynamic>;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  /// ✅ Fetch laptops by search and/or category
  Future<List<Laptop>> fetchLaptops() async {
    Uri uri;

    if (selectedCategoryId.isEmpty) {
      uri = Uri.parse('https://laptopapp.runasp.net/api/GetAllLaptopsEndPoint');
    } else {
      uri = Uri.parse(
          'https://laptopapp.runasp.net/api/GetLaptopsEndPoint?CategoryId=$selectedCategoryId');
    }

    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Failed to fetch laptops');

    final Map<String, dynamic> jsonBody = jsonDecode(response.body);
    final List data = jsonBody['data'] as List<dynamic>;

    List<Laptop> laptops = data.map((e) => Laptop.fromJson(e)).toList();

    if (searchQuery.isNotEmpty) {
      laptops = laptops
          .where(
              (l) => l.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return laptops;
  }

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
              laptopsFuture = fetchLaptops();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              setState(() {
                searchQuery = "";
                laptopsFuture = fetchLaptops();
              });
            },
          )
        ],
      ),

      body: Column(
        children: [
          /// ✅ Categories Bar
          FutureBuilder<List<Category>>(
            future: categoriesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()));
              }
              final categories = snapshot.data!;
              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                color: Colors.white.withOpacity(0.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final categoryName =
                        isAll ? "All" : categories[index - 1].name;
                    final categoryId = isAll ? "" : categories[index - 1].id;
                    final isSelected =
                        categoryId == selectedCategoryId && !isAll ||
                            (isAll && selectedCategoryId.isEmpty);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryId = categoryId;
                          selectedCategoryName = categoryName;
                          laptopsFuture = fetchLaptops();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /// ✅ Laptops Grid
          Expanded(
            child: FutureBuilder<List<Laptop>>(
              future: laptopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final laptops = snapshot.data;
                if (laptops == null || laptops.isEmpty) {
                  return const Center(child: Text("No laptops found"));
                }

                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: GridView.builder(
                    itemCount: laptops.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
