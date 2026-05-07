import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModelPreviewScreen extends StatefulWidget {
  const ModelPreviewScreen({super.key});

  @override
  State<ModelPreviewScreen> createState() => _ModelPreviewScreenState();
}

class _ModelPreviewScreenState extends State<ModelPreviewScreen> {
  String _gender = 'Female';
  String _mode = 'Mannequin';
  String? _selectedTop;
  String? _selectedBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text('Model Preview', style: GoogleFonts.rufina(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Model Preview', style: GoogleFonts.rufina(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Try on different outfits and hairstyles on our virtual model. Mix and match to create your perfect look!',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbit(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Left Selection Panel (Tops / Bottoms)
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: _buildSelectionPanel(isDark),
                ),
                if (isDesktop) const SizedBox(width: 32),
                if (!isDesktop) const SizedBox(height: 32),

                // 2. Center Model Canvas
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: _buildModelCanvas(isDark),
                ),
                if (isDesktop) const SizedBox(width: 32),
                if (!isDesktop) const SizedBox(height: 32),

                // 3. Right AI Panel
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: _buildAIPanel(isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select pieces', style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Text('Tops', style: GoogleFonts.rufina(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              _buildItemCard('White Shirt', 'assets/images/outfits/top-1.png', 'top', isDark),
              _buildItemCard('Knit Tank', 'assets/images/outfits/top-2.png', 'top', isDark),
            ],
          ),
          const SizedBox(height: 24),
          Text('Bottoms', style: GoogleFonts.rufina(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              _buildItemCard('Wide Trousers', 'assets/images/outfits/bottom-1.png', 'bottom', isDark),
              _buildItemCard('Relaxed Denim', 'assets/images/outfits/bottom-2.png', 'bottom', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(String name, String imagePath, String category, bool isDark) {
    final isSelected = (category == 'top' && _selectedTop == imagePath) || 
                       (category == 'bottom' && _selectedBottom == imagePath);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (category == 'top') _selectedTop = imagePath;
          if (category == 'bottom') _selectedBottom = imagePath;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : (isDark ? const Color(0xFF1a1a1a) : Colors.grey[50]),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.image, color: Colors.grey)), // Placeholder for actual outfit img
              ),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCanvas(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleButton('Mannequin', _mode == 'Mannequin', () => setState(() => _mode = 'Mannequin')),
              _buildToggleButton('AI Real View', _mode == 'AI Real View', () => setState(() => _mode = 'AI Real View')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildToggleButton('Female', _gender == 'Female', () => setState(() => _gender = 'Female')),
              _buildToggleButton('Male', _gender == 'Male', () => setState(() => _gender = 'Male')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Preview', style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Canvas
          Container(
            height: 500,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base Model Placeholder
                Icon(Icons.person, size: 200, color: Colors.grey[400]),
                
                // Top Overlay
                if (_selectedTop != null)
                  Positioned(
                    top: 100,
                    child: Container(
                      width: 150, height: 150,
                      color: Colors.blue.withOpacity(0.5),
                      child: const Center(child: Text('Top Layer', style: TextStyle(color: Colors.white))),
                    ),
                  ),
                  
                // Bottom Overlay
                if (_selectedBottom != null)
                  Positioned(
                    top: 250,
                    child: Container(
                      width: 150, height: 200,
                      color: Colors.red.withOpacity(0.5),
                      child: const Center(child: Text('Bottom Layer', style: TextStyle(color: Colors.white))),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {
                setState(() {
                  _selectedTop = null;
                  _selectedBottom = null;
                });
              }, child: const Text('Reset'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Save Screenshot'))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAIPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Real View (Demo)', style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('1. Upload your photo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload),
            label: const Text('Choose File'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 24),
          const Text('2. Choose an item', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: 'Select from your wardrobe',
                items: const [
                  DropdownMenuItem(value: 'Select from your wardrobe', child: Text('Select from your wardrobe'))
                ],
                onChanged: (v) {},
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Generate Demo Result'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
