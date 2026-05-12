
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';

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
  // Track favorite items locally
  final Set<String> _favorites = {};
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
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Shop', style: GoogleFonts.rufina(
            fontWeight: FontWeight.bold,
            color: accent,
          )),
          bottom: TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: isDark ? AppColors.paleText : AppColors.inkGrey,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Fashion'),
              Tab(text: 'Barber Shop'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: accent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Search functionality available soon')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: accent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Your shopping bag is currently empty')),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Fashion Tab
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [AppColors.burgundy, Color(0xFF1C1A1A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/Hero/index.jpg'),
                          fit: BoxFit.cover,
                          opacity: 0.4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Curated pieces\nfor your style',
                              style: GoogleFonts.rufina(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explore outfits that match your personality.',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Male', 'Female', 'Hoodie', 'T-Shirt', 'Set'].map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat, style: GoogleFonts.outfit(
                                color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? AppColors.paleText : AppColors.inkGrey),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              )),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              selectedColor: accent,
                              checkmarkColor: isDark ? AppColors.charcoal : Colors.white,
                              backgroundColor: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                              shape: const StadiumBorder(),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fashion Products',
                          style: GoogleFonts.rufina(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                        Text(
                          '${_filtered.length} Items',
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final product = _filtered[index];
                        return _buildProductCard(context, product, isDark);
                      },
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
                    margin: const EdgeInsets.all(16),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/Hero/baber.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('BOOK YOUR STYLE', style: GoogleFonts.outfit(color: AppColors.gold, letterSpacing: 3, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Select a Barber Shop', style: GoogleFonts.rufina(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Professional grooming, curated for you', style: GoogleFonts.outfit(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildBarberCard(context, 'Yangon Classic Barber', '4.8', '95', 'Bogyoke Market, Yangon', ['Classic Haircut — 8,000 MMK', 'Fade Cut — 12,000 MMK', 'Beard Trim — 5,000 MMK'], isDark),
                        const SizedBox(height: 16),
                        _buildBarberCard(context, 'Mandalay Heritage Salon', '4.9', '112', '84th Street, Mandalay', ['Pompadour — 15,000 MMK', 'Textured Crop — 12,000 MMK', 'Full Groom — 20,000 MMK'], isDark),
                        const SizedBox(height: 16),
                        _buildBarberCard(context, 'Golden Scissors Studio', '4.7', '78', 'Sanchaung, Yangon', ['Undercut — 10,000 MMK', 'Buzz Cut — 7,000 MMK', 'Skin Fade — 13,000 MMK'], isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
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
    final isFav = _favorites.contains(product.name);
    return GestureDetector(
      onTap: () => _showProductDetails(context, product, isDark, accent),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.asset(
                      product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (c, e, s) => Container(
                        color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                        child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFav) {
                            _favorites.remove(product.name);
                          } else {
                            _favorites.add(product.name);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_outline,
                          size: 18,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.gender} • ${product.category}',
                        style: GoogleFonts.outfit(
                          color: isDark ? AppColors.charcoal : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: GoogleFonts.outfit(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.shopping_bag_outlined, size: 18, color: accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _showProductDetails(context, product, isDark, accent),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    child: Text('View Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, _Product product, bool isDark, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : AppColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(product.image, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 100, height: 100, color: Colors.grey)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
                      const SizedBox(height: 8),
                      Text(product.price, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Available Colors', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildColorCircle(Colors.black),
                _buildColorCircle(Colors.white),
                _buildColorCircle(AppColors.burgundy),
                _buildColorCircle(AppColors.gold),
                _buildColorCircle(Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            Text('Related Items', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _fashionProducts.take(4).map((p) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(p.image, width: 80, height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 100, color: Colors.grey)),
                  ),
                )).toList(),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // In a real app we would set the selected item globally and go to ModelPreviewScreen
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen()));
                    },
                    icon: Icon(Icons.person_add_alt_1, color: accent),
                    label: Text('Try on Model', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: accent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.shopping_bag, color: isDark ? AppColors.charcoal : Colors.white),
                    label: Text('Add to Bag', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
    );
  }

  Widget _buildBarberCard(BuildContext context, String name, String rating, String reviewCount, String location, List<String> services, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64, height: 64,
                    color: accent.withOpacity(0.15),
                    child: Icon(Icons.content_cut, color: accent, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.rufina(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star, color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('$rating ($reviewCount reviews)', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Text(location, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
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
                Text('Services', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.inkBlack)),
                const SizedBox(height: 12),
                ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.split('—')[0].trim(), style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                      Text(s.split('—').length > 1 ? s.split('—')[1].trim() : '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: accent)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Book Appointment', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
