# Pyin Mal — Fashion & Grooming App 💈👗

> A Flutter mobile application built for a design competition showcasing AI-powered styling, virtual outfit preview, hairstyle recommendations, and a gamified loyalty rewards system — all backed by Firebase.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏠 **Home Screen** | Animated hero banner, horizontal feature carousels, trending collections |
| 🛍️ **Shop** | Browse fashion products with category filter chips, search tracking, and a live cart badge |
| 🛒 **Cart & Checkout** | Add items by size, adjust quantities, and simulate checkout — points awarded automatically |
| 💇 **Hair Recommendations** | Face shape analysis guide + trending hairstyle carousel |
| 👗 **Model Preview** | Virtual mannequin outfit try-on (Female / Male toggle, AI Demo mode) |
| ❤️ **Favorites** | Searchable saved looks grid with remove functionality |
| 🤖 **AI Stylist Chat** | Context-aware Gemini AI that knows the user's style preferences, search history, viewed items, and purchases |
| 🔐 **Authentication** | Animated login/sign-up screen with Firebase Auth (email & password) |
| 🧭 **Onboarding Survey** | New users select their Style, Size, and Clothing preferences — saved to Firebase |
| 🏆 **Points & Ranking** | Earn 1 point per 100 MMK spent; rank up through Bronze → Silver → Gold → Platinum tiers |
| 👤 **Profile Screen** | View rank, points progress bar, and user details — streamed live from Firestore |
| 🌙 **Dark / Light Mode** | Live theme toggle (sun/moon icon) — persists across all screens |
| 📱 **Responsive Layout** | Adapts between mobile, tablet, and desktop widths |

---

## 🏗️ Project Structure

```
lib/
├── main.dart                     # App entry point, ThemeData & AppColors config
├── theme_notifier.dart           # Global ValueNotifier for light/dark toggle
├── app_shell.dart                # MainShell: glassmorphic bottom nav + Home tab
├── models/
│   ├── user_profile.dart         # UserProfile model (points, preferences, rank)
│   └── product.dart              # Product model
├── services/
│   ├── auth_service.dart         # Firebase Auth (sign in, register, sign out)
│   ├── database_service.dart     # Firestore (profile, tracking, points, context)
│   ├── cart_service.dart         # In-memory cart state (ChangeNotifier singleton)
│   └── gemini_service.dart       # Gemini AI chat with dynamic user context injection
├── screens/
│   ├── shop_screen.dart          # Fashion products grid + Barber booking + cart icon
│   ├── product_detail_screen.dart # Product details, size selector, Add to Cart
│   ├── cart_screen.dart          # Cart items, quantity controls, checkout flow
│   ├── haircut_screen.dart       # Face shape analysis + trending hairstyles
│   ├── model_preview_screen.dart # Virtual mannequin try-on
│   ├── favorites_screen.dart     # Saved looks with search
│   ├── login_screen.dart         # Animated sign in / sign up
│   ├── onboarding_screen.dart    # New-user style preference survey
│   ├── profile_screen.dart       # Points, rank, progress bar
│   └── ai_chat_screen.dart       # AI Stylist chat interface
├── utils/
│   └── ranking_utils.dart        # Rank tiers and progress calculations
└── widgets/
    └── cdn_image.dart            # Cached image widget

assets/
├── images/
│   ├── Hero/                     # Hero backgrounds, AI recommendation images
│   ├── Photo/                    # Trending collection photos
│   ├── HairStyle/
│   │   ├── Male/                 # Male hairstyles by face shape
│   │   └── Female/               # Female hairstyles by face shape
│   ├── Male/                     # Men's fashion products (Nrf, Malory, etc.)
│   ├── Female/                   # Women's fashion products (Luna sets, etc.)
│   └── outfits/                  # Outfit layer assets for model preview
```

---

## 🔥 Firebase Architecture

The app uses **Firebase Auth** and **Cloud Firestore** for user management and activity tracking.

### Firestore Data Model

```
users/{uid}
├── email           : String
├── displayName     : String
├── points          : int        ← awarded 1pt per 100 MMK spent at checkout
├── preferences     : String[]   ← from onboarding survey (style, size, clothing)
│
├── views/{auto}
│   ├── productId   : String
│   └── timestamp   : Timestamp  ← logged on every product tap
│
├── searches/{auto}
│   ├── query       : String
│   └── timestamp   : Timestamp  ← logged on search bar submit
│
└── purchases/{auto}
    ├── productId   : String
    ├── price       : double      ← total MMK for that item (price × qty)
    ├── pointsEarned: int
    └── timestamp   : Timestamp   ← logged on checkout
```

### AI Context Pipeline

Every time the AI Stylist is queried, `GeminiService` calls `DatabaseService.getRecentHistoryContext()` which fetches:

1. **Survey Preferences** — Style, Size, Clothing types from the onboarding profile
2. **Recent Purchases** — Last 5 bought product IDs
3. **Recent Views** — Last 5 tapped product IDs
4. **Recent Searches** — Last 5 search queries

This combined context string is injected directly into the Gemini system prompt so the AI responds with fully personalized recommendations.

---

## 🏆 Ranking System

| Rank | Points Required |
|---|---|
| 🥉 Bronze | 0 – 499 pts |
| 🥈 Silver | 500 – 1,499 pts |
| 🥇 Gold | 1,500 – 4,999 pts |
| 💎 Platinum | 5,000+ pts |

Points are earned at a rate of **1 point per 100 MMK spent** and are awarded atomically via a Firestore batch write at checkout.

---

## 🎨 Design System

### Color Palette
| Name | Usage |
|---|---|
| `AppColors.burgundy` | Primary accent (light mode) — buttons, active states |
| `AppColors.gold` | Primary accent (dark mode) — rank badges, highlights |
| `AppColors.charcoal` | Dark mode background |
| `AppColors.cream` | Light mode background |
| `AppColors.inkBlack` | Body text (light mode) |

### Typography
- **Rufina** — Headlines, section titles, product names
- **Outfit** — Body text, labels, buttons, navigation
- **Google Fonts** package used throughout

### UI Patterns
- **Glassmorphic bottom navigation** — `BackdropFilter` blur with translucent overlay
- **Staggered entrance animations** — `AnimationController` with `Interval`-based curves
- **`AnimatedSwitcher`** — Icon transitions (theme toggle, nav icons)
- **`IndexedStack`** — Bottom nav tabs preserve scroll state
- **`ListenableBuilder`** — Cart badge reacts to `CartService` changes in real time
- **`StreamBuilder`** — Profile screen streams live data from Firestore

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.5.0`
- Dart SDK compatible version
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- A `.env` file in `Pyin_Mal_App/` with your API keys:

```env
GEMINI_API_KEY=your_google_gemini_api_key
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** sign-in under Authentication
3. Create a **Firestore Database** (start in test mode)
4. Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in the correct directories
5. Run `flutterfire configure` to generate `firebase_options.dart`

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

## 📦 Key Dependencies

```yaml
dependencies:
  google_fonts: ^8.1.0            # Rufina, Outfit fonts
  google_generative_ai: ^0.4.7    # Gemini AI SDK
  flutter_dotenv: ^6.0.1          # .env file loading
  firebase_core: ^4.9.0           # Firebase initialization
  firebase_auth: ^6.5.1           # User authentication
  cloud_firestore: ^6.4.1         # User profiles & activity tracking
  cached_network_image: ^3.4.1    # Efficient image caching
  image_picker: ^1.2.2            # Photo upload in onboarding
  camera: ^0.10.5+5               # Camera access
```

---

## 📋 Future Work

- [ ] Real payment gateway integration (Stripe / local payment providers)
- [ ] Real-time AI face shape detection via camera
- [ ] Push notifications for checkout confirmations and rank-ups
- [ ] Order history screen with purchase timeline
- [ ] App Store / Play Store deployment

---

*© 2025 Pyin Mal — Designed for those who stand out.*
