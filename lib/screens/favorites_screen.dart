import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SavedItem {
  final String id;
  final String title;
  final String description;
  final String image;
  final String category;
  final String shop;

  SavedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.category,
    required this.shop,
  });
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<SavedItem> _allFavorites = [
    SavedItem(
      id: '1',
      title: 'Summer Collection Set',
      description: 'Light and breezy outfits perfect for warm weather',
      image: 'assets/images/Photo/summer collection.jpg',
      category: 'SET',
      shop: 'Pyin Mal Official',
    ),
    SavedItem(
      id: '2',
      title: 'Classic High Skin Fade',
      description: 'Modern fade haircut with longer top',
      image: 'assets/images/HairStyle/Male/Round Face/Round - High Skin Fade + Long Comb Over.jpg',
      category: 'HAIRSTYLE',
      shop: 'Barber Connect',
    ),
  ];

  List<SavedItem> _filteredFavorites = [];

  @override
  void initState() {
    super.initState();
    _filteredFavorites = List.from(_allFavorites);
  }

  void _filter(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFavorites = List.from(_allFavorites);
      });
      return;
    }
    
    final lower = query.toLowerCase();
    setState(() {
      _filteredFavorites = _allFavorites.where((item) {
        return item.title.toLowerCase().contains(lower) || 
               item.description.toLowerCase().contains(lower) || 
               item.shop.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _remove(String id) {
    setState(() {
      _allFavorites.removeWhere((item) => item.id == id);
      _filter(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 640;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites', style: GoogleFonts.rufina(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              color: const Color(0xFF171717),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SAVED FASHION', style: TextStyle(color: Colors.white60, letterSpacing: 4, fontSize: 12)),
                      const SizedBox(height: 12),
                      Text('Your saved outfits and\nfashion picks.', style: GoogleFonts.rufina(color: Colors.white, fontSize: isMobile ? 32 : 48, fontWeight: FontWeight.bold, height: 1.1)),
                      const SizedBox(height: 12),
                      const Text('Every fashion look you favorite across Pyin Mal appears here in one clean, easy-to-browse grid.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            // Search & Grid
            Container(
              color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[50],
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242424) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Saved looks', style: GoogleFonts.rufina(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('${_filteredFavorites.length} saved look${_filteredFavorites.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _filter,
                                    decoration: InputDecoration(
                                      hintText: 'Search by name, description, or shop',
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF1a1a1a) : Colors.grey[100],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _filter(_searchController.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Search'),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Grid
                      if (_filteredFavorites.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Text('No saved fashion yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Browse outfits and tap the heart icon to see them here.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : (isDesktop ? 3 : 2),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _filteredFavorites.length,
                          itemBuilder: (context, index) {
                            final item = _filteredFavorites[index];
                            return _buildSavedCard(item, isDark);
                          },
                        )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCard(SavedItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(item.image, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50))),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: GoogleFonts.rufina(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.category, style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                      Text(item.shop, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _remove(item.id),
                      child: const Text('Remove'),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
