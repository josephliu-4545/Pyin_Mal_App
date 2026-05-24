# Pyin Mal — Fashion & Grooming App 💈👗

> A Flutter mobile application migrated from a web-based fashion and grooming platform. Built for a design competition showcasing AI-powered styling, virtual outfit preview, and hairstyle recommendations.

read me

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏠 **Home Screen** | Animated hero banner, horizontal feature carousels, trending collections |
| 🛍️ **Shop** | Browse fashion products (Hoodies, T-Shirts, Sets) with filter chips + Barber booking |
| 💇 **Hair Recommendations** | Face shape analysis guide + trending hairstyle carousel |
| 👗 **Model Preview** | Virtual mannequin outfit try-on (Female / Male toggle, AI Demo mode) |
| ❤️ **Favorites** | Searchable saved looks grid with remove functionality |
| 🔐 **Login / Sign Up** | Animated sliding panel authentication screen |
| 🌙 **Dark / Light Mode** | Live theme toggle (sun/moon icon) — persists across all screens |
| 📱 **Responsive Layout** | Adapts between mobile, tablet, and desktop widths |

---

## 🏗️ Project Structure

```
lib/
├── main.dart                  # App entry point, ThemeData config
├── theme_notifier.dart        # Global ValueNotifier for light/dark toggle
├── app_shell.dart             # MainShell: glassmorphic bottom nav + Home tab
└── screens/
    ├── shop_screen.dart       # Fashion products grid + Barber booking
    ├── haircut_screen.dart    # Face shape analysis + trending hairstyles
    ├── model_preview_screen.dart  # Virtual mannequin try-on
    ├── favorites_screen.dart  # Saved looks with search
    └── login_screen.dart      # Animated sign in / sign up

assets/
├── images/
│   ├── Hero/                  # Hero backgrounds, AI recommendation images
│   ├── Photo/                 # Trending collection photos
│   ├── HairStyle/
│   │   ├── Male/              # Male hairstyles by face shape
│   │   └── Female/            # Female hairstyles by face shape
│   ├── Male/                  # Men's fashion products (Nrf, Malory, etc.)
│   ├── Female/                # Women's fashion products (Luna sets, etc.)
│   └── outfits/               # Outfit layer assets for model preview
```

---

## 🎨 Design System

### Color Palette
| Name | Hex | Usage |
|---|---|---|
| `primary500` | `#0ea5e9` | Buttons, active states, links |
| `primary400` | `#38bdf8` | Logo, highlights |
| `darkBg` | `#0f0f0f` | Dark mode background |
| `darkSurface` | `#1a1a1a` | Dark mode AppBar / bottom nav |
| `darkCard` | `#242424` | Dark mode card backgrounds |

### Typography
- **Rufina** — Headlines, section titles, brand name
- **Orbit** — Body text, labels, navigation
- **Itim** — Accent text

### UI Patterns
- **Glassmorphic bottom navigation** — `BackdropFilter` blur with translucent overlay
- **Staggered entrance animations** — `AnimationController` with `Interval`-based curves
- **`AnimatedSwitcher`** — Icon transitions (theme toggle, nav icons)
- **`IndexedStack`** — Bottom nav tabs preserve scroll state

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.11.4`
- Dart SDK compatible version
- Chrome (for web) or an Android/iOS emulator

### Install & Run

```bash
# Navigate to the app directory
cd Pyin_Mal_App

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on a connected device
flutter run
```

### Hot Reload vs Restart

| Scenario | Command |
|---|---|
| Code changes only | `r` — Hot Reload |
| New assets added to `pubspec.yaml` | `R` — Hot Restart |
| `pubspec.yaml` dependency changes | `q` then `flutter run` again |

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^8.1.0       # Rufina, Orbit, Itim fonts
  cupertino_icons: ^1.0.8
```

---

## 🖥️ Screens Overview

### Navigation
The app uses a **floating glassmorphic bottom navigation bar** with 4 tabs:
- **Home** → Animated landing page with hero + carousels
- **Shop** → Product grid with filter chips + barber booking
- **Hair** → Face shape guide + hairstyle recommendations  
- **Saved** → Favorites/wishlist screen

Pages like **Login**, **Model Preview**, and detailed product views are pushed via `Navigator.push`.

### Theme Toggle
The theme toggle button (☀️ / 🌙) in the home AppBar switches between light and dark mode **instantly across the entire app** using a global `ValueNotifier<ThemeMode>`.

---

## 🌐 Original Web Project

This Flutter app is a native migration of the **Pyin Mal** web application originally built with:
- **HTML / Tailwind CSS** — Layout and styling
- **Vanilla JavaScript** — Outfit generator logic, face analysis, wardrobe management
- **Swiper.js** — Carousel components
- **AOS** — Scroll animations

The web source is located at `../Pyin-Mal-main/` in the parent directory.

---

## 📋 Remaining / Future Work

- [ ] Backend / API integration (products, user accounts, favorites)
- [ ] Real AI face shape detection (camera upload)
- [ ] Real-time outfit generator logic (port from JS)
- [ ] Cart / Checkout flow
- [ ] Push notifications for booking confirmations
- [ ] App Store / Play Store deployment

---

*© 2025 Pyin Mal — Designed for those who stand out.*
