import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
import 'package:pyin_mal_app/core/favorites_notifier.dart';
import 'package:pyin_mal_app/data/product_repository.dart';

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
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _remove(String id) {
    favoritesNotifier.toggleFavorite(id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 640;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('favorites.title'.tr(), style: GoogleFonts.rufina(
          fontWeight: FontWeight.bold,
          color: accent,
        )),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: favoritesNotifier,
        builder: (context, favorites, _) {
          final query = _searchController.text.toLowerCase();
          
          final allFavoritedItems = ProductRepository.allProducts
              .where((p) => favorites.contains(p.id))
              .map((p) => SavedItem(
                    id: p.id,
                    title: p.name,
                    description: p.description ?? '',
                    image: p.image,
                    category: p.category,
                    shop: p.shopName ?? p.brand,
                  ))
              .toList();
              
          final filteredFavorites = query.isEmpty 
              ? allFavoritedItems
              : allFavoritedItems.where((item) {
                  return item.title.toLowerCase().contains(query) || 
                         item.description.toLowerCase().contains(query) || 
                         item.shop.toLowerCase().contains(query);
                }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Premium Header Section
                _buildHeader(isMobile, isDark, accent),

                // 2. Search & Grid Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    children: [
                      // Search Bar
                      _buildSearchBar(isDark, accent, filteredFavorites.length),
                      
                      const SizedBox(height: 32),

                      // Grid / Empty State
                      if (filteredFavorites.isEmpty)
                        _buildEmptyState(isDark, accent)
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 4 : (isMobile ? 2 : 3),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: filteredFavorites.length,
                          itemBuilder: (context, index) {
                            final item = filteredFavorites[index];
                            return _buildSavedCard(item, isDark, accent);
                          },
                        )
                    ],
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(bool isMobile, bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'favorites.header_subtitle'.tr(),
              style: GoogleFonts.outfit(
                color: AppColors.charcoal,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'favorites.header_title'.tr(),
            style: GoogleFonts.rufina(
              color: isDark ? Colors.white : AppColors.inkBlack,
              fontSize: isMobile ? 36 : 48,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'favorites.header_desc'.tr(),
            style: GoogleFonts.outfit(
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color accent, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'favorites.collection_items'.tr(),
                style: GoogleFonts.rufina(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              Text(
                'favorites.saved_count'.tr(args: [count.toString()]),
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'favorites.search_hint'.tr(),
                    prefixIcon: Icon(Icons.search, color: accent, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.charcoal : AppColors.creamAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.tune, color: isDark ? AppColors.charcoal : Colors.white, size: 20),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSavedCard(SavedItem item, bool isDark, Color accent) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CdnImage(
                    item.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                      child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _remove(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, size: 18, color: AppColors.burgundy),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.charcoal : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.rufina(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 12, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            item.shop,
                            style: GoogleFonts.outfit(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        'favorites.saved_recently'.tr(),
                        style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_outline, size: 64, color: accent),
          ),
          const SizedBox(height: 24),
          Text(
            'favorites.empty_title'.tr(),
            style: GoogleFonts.rufina(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'favorites.empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Usually navigate to shop, but we stay within current logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: isDark ? AppColors.charcoal : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('favorites.explore'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
