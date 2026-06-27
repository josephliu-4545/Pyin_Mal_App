# Pyin Mal — AI Fashion & Grooming App 💈👗

> A Flutter mobile application built for a design competition showcasing AI-powered styling, virtual outfit & hairstyle try-on, smart clothing scanning, 3D product previews, AR fitting room, and a gamified loyalty rewards system — all backed by Firebase and Gemini AI.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏠 **Home Screen** | Animated hero banner, horizontal feature carousels, trending collections |
| 🛍️ **Shop** | Browse fashion products with category filter chips, search tracking, and a live cart badge |
| 🛒 **Cart & Checkout** | Add items by size, adjust quantities, and simulate checkout — points awarded automatically |
| 💇 **Hair Recommendations** | Face shape analysis guide + trending hairstyle carousel |
| 👗 **Model Preview** | Virtual mannequin outfit try-on (Female / Male toggle, AI Demo mode) |
| 👔 **Virtual Try-On** | Upload your photo + clothing items (shirt, pants, shoes) → AI generates a realistic outfit preview via NanoBanana API |
| 💇‍♀️ **Hair Try-On** | Upload your photo + a reference hairstyle → AI generates your new look |
| 📸 **Smart Scan** | Point your camera at any clothing item → Gemini AI identifies it and matches it to the closest product in the catalog |
| 🪞 **AR Hair Filter** | Real-time face detection with ML Kit + camera overlay for hair style previews (Android & iOS) |
| 👗 **AR Fitting Room** | Real-time body pose detection using Google ML Kit to overlay virtual clothing directly onto the user's camera feed |
| 📏 **AI Body Scan & Sizing** | AI-powered body scanning to measure dimensions and provide accurate size recommendations |
| ♻️ **Resell & Donate** | Circular fashion ecosystem! List old items for resale, chat with buyers, or donate clothes |
| 🪟 **Floating Scanner** | A persistent floating window scanner that runs over other apps, using Android Overlay permissions |
| 🎙️ **Voice Search** | Integrated Speech-to-Text for hands-free product searching |
| 🌍 **Localization** | Multi-language support out of the box using Easy Localization |
| 📦 **Sale & Delivery** | Dedicated screens for tracking ongoing sales, orders, and delivery statuses |
| 🧊 **3D Product Viewer** | Procedurally generated GLB models displayed in an interactive `model_viewer_plus` widget with rotation & zoom |
| ❤️ **Favorites** | Searchable saved looks grid with remove functionality |
| 🤖 **AI Stylist Chat** | Context-aware Gemini AI that knows the user's style preferences, search history, viewed items, and purchases — returns structured JSON with inline product recommendations |
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
├── firebase_options.dart         # Firebase configuration (auto-generated)
├── core/
│   └── constants/
│       └── api_constants.dart    # CDN base URL, Gemini API key accessor
├── data/
│   └── product_repository.dart   # Static product catalog with lookup by ID
├── models/
│   ├── user_profile.dart         # UserProfile model (points, preferences, rank)
│   ├── product.dart              # Product model (id, name, price, image, brand, etc.)
│   └── ai_message.dart           # AiMessage model (text, isUser, recommendedProducts)
├── services/
│   ├── auth_service.dart         # Firebase Auth (sign in, register, sign out)
│   ├── database_service.dart     # Firestore (profile, tracking, points, context)
│   ├── cart_service.dart         # In-memory cart state (ChangeNotifier singleton)
│   ├── gemini_service.dart       # Gemini AI chat with dynamic user context injection
│   ├── nanobanana_api_service.dart # NanoBanana API: virtual try-on & hairstyle generation
│   ├── model_3d_service.dart     # Procedural GLB 3D model generation (hoodie mesh)
│   ├── pose_detection_service.dart # ML Kit skeletal tracking for AR Fitting Room
│   ├── bodygram_service.dart     # Integration for body scanning & measurements
│   ├── floating_scanner_service.dart # Overlay window background task management
│   └── opencart_service.dart     # OpenCart e-commerce catalog integration
├── screens/
│   ├── shop_screen.dart          # Fashion products grid + Barber booking + cart icon
│   ├── product_detail_screen.dart # Product details, size selector, Add to Cart, 3D viewer
│   ├── cart_screen.dart          # Cart items, quantity controls, checkout flow
│   ├── ar_fitting_room_screen.dart # Real-time camera with 33-point pose detection
│   ├── body_scan_screen.dart     # Body measurement & size recommendation flow
│   ├── resell_screen.dart        # Circular fashion marketplace listings
│   ├── donate_screen.dart        # Clothing donation portal
│   ├── haircut_screen.dart       # Face shape analysis + trending hairstyles
│   ├── model_preview_screen.dart # Virtual mannequin try-on
│   ├── try_on_screen.dart        # AI virtual try-on (person + clothing upload → result)
│   ├── hair_try_on_screen.dart   # AI hair try-on (person + reference hair → result)
│   ├── scan_screen.dart          # Smart Scan: camera/gallery → Gemini product identification
│   ├── ar_hair_filter_screen.dart # AR camera with ML Kit face detection overlay
│   ├── favorites_screen.dart     # Saved looks with search
│   ├── login_screen.dart         # Animated sign in / sign up
│   ├── onboarding_screen.dart    # New-user style preference survey
│   ├── profile_screen.dart       # Points, rank, progress bar
│   └── ai_chat_screen.dart       # AI Stylist chat interface
├── utils/
│   └── ranking_utils.dart        # Rank tiers and progress calculations
└── widgets/
    ├── cdn_image.dart            # Cached image widget with CDN fallback
    └── product_3d_viewer.dart    # Interactive 3D model viewer (ModelViewerPlus + rotation handle)

assets/
├── images/                       # All static image assets
│   ├── Male/                     # Men's fashion products (NRF, AJOHN, ABCD, etc.)
│   ├── Female/                   # Women's fashion products (Luna sets, etc.)
│   └── ...                       # Mannequin images, textures, misc
```

---

## 🤖 AI Architecture

The app integrates **several distinct AI systems**:

### 1. Gemini AI Stylist (Chat)

`GeminiService` powers the AI Stylist chat. On every query it:

1. Fetches live user context via `DatabaseService.getRecentHistoryContext()` — survey preferences, last 5 purchases, last 5 views, last 5 searches.
2. Injects the full product catalog from `ProductRepository` into the system prompt.
3. Forces **structured JSON output** (`responseMimeType: 'application/json'`) so the response always contains a `message` string and a `recommended_product_ids` array.
4. Maps returned IDs to real `Product` objects for inline product cards in the chat UI.

### 2. Gemini Vision — Smart Scan

`ScanScreen` uses Gemini's multimodal capabilities to:

1. Accept a photo from the camera or gallery.
2. Send the image + the full product catalog to `gemini-2.5-flash` with a product-matching prompt.
3. Parse the JSON response to find the `matched_product_id`.
4. Navigate directly to the matched `ProductDetailScreen`.

### 3. NanoBanana API — Virtual Try-On & Hair Try-On

`NanoBananaApiService` handles image-to-image AI generation:

1. **Compress** uploaded images (JPEG, ≤500px, quality 50).
2. **Upload** to a temporary public host (`tmpfiles.org`) to obtain public URLs.
3. **POST** to the NanoBanana `/generate` endpoint with the image URLs.
4. **Poll** the `/record-info` endpoint every 3 seconds (up to 30 attempts) for the result image.

### 4. Google ML Kit — AR Fitting Room & Pose Detection

`PoseDetectionService` processes real-time camera frames:

1. Tracks 33 skeletal landmarks.
2. Maps virtual clothing assets dynamically onto the user's shoulders, torso, and hips.
3. Adapts the bounding box scaling based on the detected body proportions.

### 5. Floating Scanner Overlay

Powered by `flutter_overlay_window` and foreground services, the app provides a floating camera button that persists outside the application. This allows users to instantly snap and scan fashion items they spot anywhere on their device (e.g., social media or browsing).

---

## 🧊 3D Product Viewer

The `Product3DViewer` widget renders interactive 3D models:

- `Model3DService` procedurally generates GLB (Binary glTF) meshes with body, hood, and arm geometry.
- On native platforms, the GLB is saved to the app's documents directory; on web, a base64 data URL is used.
- `model_viewer_plus` provides touch-to-rotate, pinch-to-zoom, and a custom `_RotationHandle` overlay with curved arc arrows.

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
| `AppColors.darkWarm` | Card/surface background (dark mode) |
| `AppColors.paleText` | Secondary text (dark mode) |
| `AppColors.inkGrey` | Secondary text (light mode) |

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
- **`CustomPaint`** — 3D viewer rotation handle with arc arrows

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.5.0`
- Dart SDK compatible version
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- A `.env` file in `Pyin_Mal_App/` with your API keys:

```env
GEMINI_API_KEY=your_google_gemini_api_key
NANOBANANA_API_KEY=your_nanobanana_api_key
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** sign-in under Authentication
3. Create a **Firestore Database** (start in test mode)
4. Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place them in the correct directories
5. Run `flutterfire configure` to generate `firebase_options.dart`

### Install & Run

```bash
# Clone the repository
git clone https://github.com/josephliu-4545/Pyin_Mal_App.git

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

### Platform Notes

| Feature | Web | Android | iOS | Windows |
|---|---|---|---|---|
| Core App (Shop, Cart, Auth) | ✅ | ✅ | ✅ | ✅ |
| AI Stylist Chat | ✅ | ✅ | ✅ | ✅ |
| Smart Scan | ✅ | ✅ | ✅ | ✅ |
| Virtual Try-On (NanoBanana) | ✅ | ✅ | ✅ | ⚠️ No image compression |
| Hair Try-On (NanoBanana) | ✅ | ✅ | ✅ | ⚠️ No image compression |
| AR Hair Filter (ML Kit) | ❌ | ✅ | ✅ | ❌ |
| AR Fitting Room (ML Kit) | ❌ | ✅ | ✅ | ❌ |
| 3D Product Viewer | ✅ (data URL) | ✅ (file) | ✅ (file) | ✅ (file) |
| Floating Scanner Overlay | ❌ | ✅ | ❌ | ❌ |

---

## 📦 Key Dependencies

```yaml
dependencies:
  google_fonts: ^8.1.0            # Rufina, Outfit fonts
  google_generative_ai: ^0.4.7    # Gemini AI SDK (chat + vision)
  flutter_dotenv: ^6.0.1          # .env file loading
  firebase_core: ^4.9.0           # Firebase initialization
  firebase_auth: ^6.5.1           # User authentication
  cloud_firestore: ^6.4.1         # User profiles & activity tracking
  cached_network_image: ^3.4.1    # Efficient image caching
  image_picker: ^1.2.2            # Photo upload (try-on, scan, onboarding)
  camera: ^0.10.5+5               # Live camera access (AR filter)
  google_mlkit_face_detection: ^0.13.0  # Real-time face detection for AR overlay
  google_mlkit_pose_detection: ^0.14.1  # Real-time body pose detection for AR fitting room
  easy_localization: ^3.0.8       # Multi-language translation support
  speech_to_text: ^7.4.0          # Voice search
  flutter_overlay_window: ^0.5.0  # Floating UI over other apps
  http: ^1.6.0                    # HTTP requests (NanoBanana API)
  flutter_image_compress: ^2.4.0  # Image compression before API upload
  model_viewer_plus: ^1.9.3       # Interactive 3D GLB model viewer
```

---

## 📋 Future Work

- [ ] Real payment gateway integration (Stripe / local payment providers)
- [ ] Push notifications for checkout confirmations and rank-ups
- [ ] Social sharing of try-on results
- [ ] App Store / Play Store deployment

---

## 🤝 Contributions

We welcome contributions to improve this project! To get started:

1. **Fork the repository** and create your feature branch:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
2. **Commit your changes**:
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
3. **Push to the branch**:
   ```bash
   git push origin feature/AmazingFeature
   ```
4. **Open a pull request** explaining your changes in detail.

For major changes, please open an issue first to discuss what you would like to change.

---

*© 2026 Pyin Mal — Designed for those who stand out.*
