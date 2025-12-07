import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LaptopListScreen(),
    );
  }
}

class Laptop {
  final String name;
  final String image;
  final double price;

  Laptop({
    required this.name,
    required this.image,
    required this.price,
  });
}

class LaptopListScreen extends StatefulWidget {
  const LaptopListScreen({super.key});

  @override
  State<LaptopListScreen> createState() => _LaptopListScreenState();
}

class _LaptopListScreenState extends State<LaptopListScreen> {
  String searchQuery = "";
  late Future<List<Laptop>> laptopsFuture;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    laptopsFuture = fetchLaptopsFromApi("");
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Laptop>> fetchLaptopsFromApi(String query) async {
    await Future.delayed(const Duration(seconds: 1));

    List<Laptop> allLaptops = [
      Laptop(
        name: "Alienware m15",
        image: "https://images.unsplash.com/photo-1517336714731-489689fd1ca8",
        price: 3340,
      ),
      Laptop(
        name: "Razer Blade 15",
        image: "https://images.unsplash.com/photo-1518770660439-4636190af475",
        price: 2400,
      ),
      Laptop(
        name: "ASUS ROG G14",
        image: "https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2",
        price: 1990,
      ),
      Laptop(
        name: "MSI Katana 15",
        image: "https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2",
        price: 1800,
      ),
    ];

    if (query.isEmpty) return allLaptops;

    return allLaptops
        .where(
            (laptop) => laptop.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
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
              laptopsFuture = fetchLaptopsFromApi(searchQuery);
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
                laptopsFuture = fetchLaptopsFromApi(searchQuery);
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Category Name
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              "Gaming Laptops",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // ✅ Laptop Grid
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
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No results found"));
                }

                final laptops = snapshot.data!;

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
