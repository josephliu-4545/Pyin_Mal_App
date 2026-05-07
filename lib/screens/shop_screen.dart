import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
          title: Text(
            'Shop',
            style: GoogleFonts.rufina(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fashion'),
              Tab(text: 'Barber Shop'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(icon: const Icon(Icons.shopping_bag_outlined), onPressed: () {}),
          ],
        ),
        body: TabBarView(
          children: [
            // Fashion Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilters(context),
                  const SizedBox(height: 24),
                  Text(
                    'Fashion Products',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Mock Grid of products
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, index);
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Load More'),
                    ),
                  ),
                ],
              ),
            ),

            // Barber Shop Tab
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.blueGrey,
                    ),
                    child: Column(
                      children: [
                        Text('Book your style', style: TextStyle(color: Colors.white70, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text('Select a Barber Shop', style: GoogleFonts.rufina(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildBarberCard(context, 'Yangon Classic Barber', '4.8 (95)', 'Bogyoke Market, Yangon'),
                        const SizedBox(height: 16),
                        _buildBarberCard(context, 'Mandalay Heritage Salon', '4.9 (112)', '84th Street, Mandalay'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildDropdown('Category', ['All', 'Tops', 'Bottoms', 'Shoes']),
          _buildDropdown('Price', ['All', '0-30k', '30k-60k']),
          _buildDropdown('Sort by', ['Newest', 'Popular', 'Price Low']),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items[0],
              isDense: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('25,000 MMK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberCard(BuildContext context, String name, String rating, String location) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.store, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.rufina(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('★ $rating', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Classic Haircut'),
                Row(
                  children: [
                    const Text('8,000 MMK', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Checkbox(value: false, onChanged: (v) {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
