# Product Detail Screen - Design Plan
*Pyin Mal Fashion Shopping App*

---

## 🎯 Design Vision

**Image-focused, interaction-rich, beautifully minimal.**

The product detail screen is where fashion enthusiasts decide to buy. The design should celebrate the clothing through large, clear imagery while providing essential information effortlessly. Advanced interactions (360° rotation) feel magical but serve the practical job: let customers see what they're buying.

**Core Principle**: Product is the hero. Everything else—details, buttons, colors—supports that hero without competing.

---

## 📐 Visual Hierarchy

Priority ranking (highest to lowest):
1. **Product Image** (45-50% of viewport height)
2. **Product Name & Price** (15-20%)
3. **Rating & Key Details** (10-15%)
4. **Call-to-Action Buttons** (10-12%)
5. **Color Variants** (8-10%)
6. **Supporting Info** (Description, Size, Shop, Characteristics) — below fold, minimal

---

## 🎨 Color System

### Strategy: Adaptive Restrained

**Light Theme (Primary)**
- **Background**: Off-white/cream (OKLCH L 0.97, minimal chroma toward brand hue)
- **Surface**: Pure white for cards/image containers
- **Text Primary**: Dark ink (OKLCH L 0.15, near-black)
- **Text Secondary**: Muted gray (OKLCH L 0.45, -0.01 chroma)
- **Accent**: Brand/Secondary accent (used for selected states, pricing, interactions)
- **Border**: Light gray (OKLCH L 0.90)

**Dark Theme (Adaptive)**
- **Background**: Dark charcoal (OKLCH L 0.20)
- **Surface**: Slightly lighter dark (OKLCH L 0.28)
- **Text Primary**: Near-white (OKLCH L 0.95)
- **Text Secondary**: Muted light gray (OKLCH L 0.65, -0.005 chroma)
- **Accent**: Same accent (elevated brightness on dark)
- **Border**: Dark gray (OKLCH L 0.35)

### Contrast Requirements
- Body text (14-16px): ≥4.5:1 against background
- Secondary text: ≥4.5:1 (no exemptions)
- Labels: ≥3:1 minimum
- Color swatches: Border + label, not color alone

---

## 🔤 Typography

### Font Family
**Single sans-serif throughout**: Use system-ui stack or a single family (e.g., Inter, Outfit).
- **Headings**: Weight 600–700
- **Body**: Weight 400–500
- **Labels**: Weight 500–600

### Scale (Fixed rem, not clamp)
- **Product Name (h2)**: 18–20px, weight 700, line-height 1.2
- **Price**: 16–18px, weight 700, accent color
- **Rating & Details**: 12–13px, weight 500, secondary text
- **Button Labels**: 13–14px, weight 600
- **Color Label ("Colors")**: 12px, weight 600
- **Body/Description**: 14px, weight 400, line-height 1.6
- **Helper Text**: 12px, weight 400, secondary text

### Rules
- No all-caps body copy (labels only)
- No gradient text
- No display fonts in UI
- Maximum line length for prose: 70ch
- Minimum line-height: 1.4 for body (1.6+ for longer text)

---

## 🏗️ Layout Structure

### Mobile-First (Primary Viewport: 375–480px)

```
┌─────────────────────┐
│  Status Bar + Icons │ (fixed top)
├─────────────────────┤
│ Product Info Banner │ (small, compact)
├─────────────────────┤
│                     │
│   Product Image     │ ← Hero (400px height)
│ (with rotation <→)  │
│                     │
├─────────────────────┤
│ Product Name  $Price│ ← Minimal, compact
│ ⭐⭐⭐⭐⭐ 4.8 (128) │
├─────────────────────┤
│ [Try On] [Shop Now] │ ← Side-by-side buttons
├─────────────────────┤
│ Colors: [●][●][●]   │ ← Inline with label
├─────────────────────┤
│ 📍 Pyin Mal Official│ ← Shop info (compact)
├─────────────────────┤
│ Description...      │ ← Scrollable below fold
│ Sizes...            │
│ Characteristics...  │
└─────────────────────┘
│ [⚙][⚙][👤][💬][🔍]│ ← Floating action bar
└─────────────────────┘
```

### Tablet & Above (768px+)
- Image can grow to ~450px height
- Details can become more spacious
- Same visual hierarchy maintained

### Key Spacing
- **Section gutters**: 16–20px (mobile), 24px (tablet+)
- **Internal spacing**: 8–12px between related elements
- **Between major sections**: 20–24px
- **Padding inside containers**: 12–16px

---

## 🎛️ Component Specifications

### Product Image Container
- **Height**: 400px (mobile), 450px (tablet+)
- **Border Radius**: 24px
- **Background**: Surface color (white/light dark)
- **Aspect Ratio**: 1:1 (square)
- **Responsive**: Full width - 32px margins (mobile)

### Rotation Indicator
- **Position**: Absolute, bottom of image (12px from bottom)
- **Style**: Floating badge (< ○ >, white bg light shadow)
- **Interactions**:
  - Tap `<` or `>`: Discrete rotation increment (0.3 radians)
  - Drag horizontally on image: Smooth continuous rotation
  - Touch target: 40px+ tap areas for arrows
- **Fallback**: Crossfade on reduced motion (no rotation animation)

### Product Details (Name, Price, Rating)
- **Layout**: Flex, space-between (name left, price right)
- **Name**: 18px, 700 weight, primary text, max 2 lines (text-wrap: balance)
- **Price**: 16px, 700 weight, accent color, right-aligned
- **Rating**: Row of 5 stars (14px) + "4.8 (128 reviews)" text (12px), secondary text
- **Spacing**: 4px below brand/category, 8px below name, 8px before rating

### Buttons (Try On / Shop Now)
- **Layout**: Row, equal widths, 10px gap
- **Try On**: 
  - Outlined style, border weight 1.5px
  - Border color: Accent or dark ink
  - Background: Transparent
  - Text: 13px, 600 weight, primary text
  - Padding: 12px vertical, auto horizontal
  - Border radius: 10px
  - Hover: Light background tint
  - Active: Darker border
- **Shop Now**:
  - Elevated/filled style, accent background
  - Text: White (light) / dark (dark theme)
  - Padding: 12px vertical, auto horizontal
  - Border radius: 10px
  - Hover: Darker accent
  - Active: Even darker

### Color Variants
- **Layout**: Inline row (label "Colors" + swatch row, scrollable)
- **Swatch Size**: 60x60px (mobile), 70x70px (tablet+)
- **Border Radius**: 14px
- **Unselected**:
  - Border: 1px, light gray
  - Shadow: Subtle (0 2px 6px rgba(..., 0.08))
- **Selected**:
  - Border: 2.5px, accent color
  - Shadow: Glow effect (0 4px 12px rgba(accent, 0.25))
  - Transform: Scale 1.08 (smooth 200ms animation)
- **Interaction**: Tap to select, visual feedback immediate
- **Accessibility**: Color is not the only indicator; add a checkmark or border emphasis for selected state

### Floating Action Bar
- **Position**: Fixed bottom, 20px from bottom, full width - 40px
- **Layout**: 5 icon buttons, evenly spaced
- **Style (Light Theme)**:
  - Background: Dark charcoal with slight transparency (rgba(0, 0, 0, 0.92))
  - Border radius: 20px
  - Padding: 12px horizontal, 10px vertical
  - Icons: 20–24px, white
  - Touch targets: 40x40px each
- **Style (Dark Theme)**:
  - Background: Slightly lighter (rgba(255, 255, 255, 0.1)) or darker charcoal
  - Icons: Light gray or white
- **Icons**: Wrench, Settings, Avatar (profile), Chat, Search
- **Interactions**: Each tap triggers navigation or action (with SnackBar feedback)
- **Reduced Motion**: Icons still interactive, no animations

---

## ✨ Interactions & Motion

### 360° Product Rotation
- **Interaction**: Tap arrows OR drag horizontally on image
- **Behavior**:
  - Arrow tap: 0.3 radian increment
  - Drag: Sensitive to delta.dx (0.01 multiplier)
- **Animation**: Transform.rotate(), applied to image
- **Performance**: Smooth 60fps, no jank
- **Reduced Motion**: Allow tap-based rotation only, no continuous drag animation

### Color Swatch Selection
- **Animation**: AnimatedScale (1.0 → 1.08)
- **Duration**: 200ms
- **Easing**: ease-out
- **Visual Feedback**: Border + glow appear simultaneously
- **Reduced Motion**: Instant scale, crossfade border + glow

### Button Interactions
- **Hover**: Slight background tint change (200ms ease-out)
- **Active**: Press feedback (scale 0.98 for tactile feel, then back)
- **Disabled**: Opacity 0.5, cursor not-allowed
- **Reduced Motion**: No scale animations, instant opacity changes

### State Feedback
- **Add to Cart**: SnackBar appears (2s duration) → "Added to cart"
- **Try On**: SnackBar → "Try-On feature coming soon"
- **Loading**: Button shows spinner (no full-page loader)

---

## 📱 Responsive Breakpoints

| Breakpoint | Viewport | Changes |
|---|---|---|
| Mobile | 375–599px | Base design (400px image, 60px colors) |
| Tablet | 600–999px | Image to 450px, spacing +4px |
| Desktop | 1000px+ | Image to 480px, details less dense |

**Rule**: Image never exceeds 60% of viewport height; details remain readable at all sizes.

---

## 🌓 Theme Switching

- **User Control**: Settings allow light/dark toggle (or system preference)
- **Persistence**: Store in SharedPreferences (Flutter)
- **CSS Variables**: Define all colors as theme-aware tokens in DESIGN.md
- **Transition**: 200ms ease-out on theme switch (no flash)
- **Images**: Adjust container background on theme change; image itself stays neutral

---

## 3D Model Integration Path (Future)

### When 3D Models Are Available

1. **Replace 2D Image**:
   - Current: `CdnImage` with `Transform.rotate()` (2D rotation)
   - Future: `ModelViewer` package or `three_dart` (3D model viewer)

2. **Preserve Interaction Pattern**:
   - Same rotation UX: tap arrows or drag
   - Model rotates instead of 2D image
   - Full 360° freedom (not just single axis)

3. **Fallback Strategy**:
   - If 3D model unavailable: Show highest-quality 2D image
   - Rotation disabled for 2D only
   - User expectations set clearly ("View in 3D" label when available)

4. **From Front/Back Photos**:
   - **Two images** (front + back) can be mapped onto a basic 3D model (cylinder/simple form)
   - Use texture mapping to simulate 360° view
   - Quality depends on model complexity (full 3D model beats texture-mapped 2D)
   - Can generate basic 3D models from 2D photos using photogrammetry or AI (e.g., OpenDream, Genfill)

---

## ✅ Design Checklist

Before implementation, verify:

- [ ] OKLCH color tokens defined (light + dark themes)
- [ ] Typography scale in rem, not px or clamp
- [ ] Image container height = 400px
- [ ] Rotation indicator styled as floating badge
- [ ] Product details text sizes match spec
- [ ] Buttons have proper touch targets (44x44px+)
- [ ] Color swatches scale on selection (1.08x, 200ms)
- [ ] Floating action bar styled correctly (dark, fixed)
- [ ] Reduced motion alternatives tested
- [ ] Light + dark themes visually verified
- [ ] Responsive layout tested on 375px, 768px, 1000px+
- [ ] Contrast verified (4.5:1 body, 3:1 labels minimum)

---

## 🚀 Next Steps

1. **Update `DESIGN.md`** with final token definitions (colors, typography, spacing)
2. **Implement changes** to `product_detail_screen.dart` following this plan
3. **Test themes** in simulator (light + dark)
4. **Verify responsive** behavior across device sizes
5. **Answer 3D question**: Can 2 photos (front/back) generate a usable 3D model?
6. **Plan 3D integration** once photos are ready

---

**This plan is the bridge from current code to production-ready design. Every color, spacing, and interaction decision is documented here.**
