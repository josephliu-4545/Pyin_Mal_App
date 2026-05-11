import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class _Product {
  final String name;
  final String price;
  final String image;
  final String category;
  final String gender;
  _Product(this.name, this.price, this.image, this.category, this.gender);
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';

  final List<_Product> _fashionProducts = [
    _Product('NRF Deathwish Hoodie', '45,000 MMK', 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg', 'Hoodie', 'Male'),
    _Product('AJOHN V2 Hoodie', '38,000 MMK', 'assets/images/Male/Nrf/Hoodie/AJOHN V2 HOODIE.jpg', 'Hoodie', 'Male'),
    _Product('ABCD 2XL Zip Up Hoodie', '35,000 MMK', 'assets/images/Male/Nrf/Hoodie/ABCD 2XL ZIP UP HOODIE0.jpg', 'Hoodie', 'Male'),
    _Product('V1 Introduction Hoodie', '32,000 MMK', 'assets/images/Male/Nrf/Hoodie/V1 INTRODUCTION Hoodie .jpg', 'Hoodie', 'Male'),
    _Product('ABCD Tee', '15,000 MMK', 'assets/images/Male/Nrf/Tee/ABCD TEE.jpg', 'T-Shirt', 'Male'),
    _Product('ACID T-Shirt', '18,000 MMK', 'assets/images/Male/Nrf/Tee/ACID TSHIRT 0.jpg', 'T-Shirt', 'Male'),
    _Product('NRFC Jersey', '22,000 MMK', 'assets/images/Male/Nrf/Tee/NRFC Jersey0.jpg', 'T-Shirt', 'Male'),
    _Product('LAPSES Tee Oatmeal', '19,000 MMK', 'assets/images/Male/Nrf/Tee/LAPSES TSHIRT OATMEAL0.jpg', 'T-Shirt', 'Male'),
    _Product('Luna Set 1', '55,000 MMK', 'assets/images/Female/dress.set/Luna/luna set1.jpg', 'Set', 'Female'),
    _Product('Luna Set 2', '55,000 MMK', 'assets/images/Female/dress.set/Luna/luna set2.jpg', 'Set', 'Female'),
    _Product('Luna Set 3', '55,000 MMK', 'assets/images/Female/dress.set/Luna/luna set3.jpg', 'Set', 'Female'),
    _Product('Luna Set 4', '55,000 MMK', 'assets/images/Female/dress.set/Luna/luna set4.jpg', 'Set', 'Female'),
  ];

  List<_Product> get _filtered {
    if (_selectedCategory == 'All') return _fashionProducts;
    return _fashionProducts.where((p) => p.category == _selectedCategory || p.gender == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
          title: Text('Shop', style: GoogleFonts.rufina(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.gold : AppColors.burgundy,
          )),
          bottom: TabBar(
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
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
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Male', 'Female', 'Hoodie', 'T-Shirt', 'Set'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat, style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : (isDark ? AppColors.paleText : AppColors.inkGrey),
                            )),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                            selectedColor: accent,
                            checkmarkColor: isDark ? AppColors.charcoal : Colors.white,
                            backgroundColor: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_filtered.length} Products',
                    style: GoogleFonts.orbit(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      return _buildProductCard(context, product, isDark);
                    },
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
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Hero/baber.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('BOOK YOUR STYLE', style: GoogleFonts.orbit(color: Colors.white70, letterSpacing: 3, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Select a Barber Shop', style: GoogleFonts.rufina(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Professional grooming, curated for you', style: GoogleFonts.orbit(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildBarberCard(context, 'Yangon Classic Barber', '4.8', '95', 'Bogyoke Market, Yangon', ['Classic Haircut — 8,000 MMK', 'Fade Cut — 12,000 MMK', 'Beard Trim — 5,000 MMK'], isDark),
                        const SizedBox(height: 20),
                        _buildBarberCard(context, 'Mandalay Heritage Salon', '4.9', '112', '84th Street, Mandalay', ['Pompadour — 15,000 MMK', 'Textured Crop — 12,000 MMK', 'Full Groom — 20,000 MMK'], isDark),
                        const SizedBox(height: 20),
                        _buildBarberCard(context, 'Golden Scissors Studio', '4.7', '78', 'Sanchaung, Yangon', ['Undercut — 10,000 MMK', 'Buzz Cut — 7,000 MMK', 'Skin Fade — 13,000 MMK'], isDark),
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

  Widget _buildProductCard(BuildContext context, _Product product, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.07),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                product.image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(product.price, style: GoogleFonts.outfit(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Add to Cart', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberCard(BuildContext context, String name, String rating, String reviewCount, String location, List<String> services, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFF0ea5e9).withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.content_cut, color: Color(0xFF0ea5e9), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.rufina(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('$rating ($reviewCount reviews)', style: GoogleFonts.orbit(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: GoogleFonts.orbit(fontSize: 12, color: Colors.grey)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Services', style: GoogleFonts.orbit(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.split('—')[0].trim(), style: GoogleFonts.orbit(fontSize: 13)),
                      Text(s.split('—').length > 1 ? s.split('—')[1].trim() : '', style: GoogleFonts.orbit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0ea5e9))),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0ea5e9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Book Appointment', style: GoogleFonts.orbit(fontWeight: FontWeight.bold)),
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
