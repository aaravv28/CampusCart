# CampusCart 🛒
> **Modern, Trusted Peer-to-Peer Campus Marketplace for University Students**

CampusCart is a cross-platform Flutter application built to make campus commerce simple, secure, and isolated strictly to verified university domains. Students can buy and sell textbooks, electronics, dorm essentials, lab equipment, and more without dealing with external strangers or spam.

---

## 🌟 Key Features & Modern Innovations

### 1. 🤖 CartAI Conversational Shopping Copilot (New!)
- **Conversational Buying Assistant**: Students can query by courses (*"Need materials for CHEM210"*), budget (*"Items under \$30"*), or categories (*"Calculators for Math150"*).
- **Embedded Interactive Product Cards**: AI recommends matching items and renders rich product cards right inside the chat with one-tap inspection.
- **Dual-Engine Intelligence**: Connects to live **Google Gemini 2.0 / 1.5 Flash API** when an API key is provided, and automatically uses an **offline-first Campus Heuristic Engine** for instant, zero-latency replies with zero external network required!

### 2. 💡 In-Listing Deal & Safety Evaluator (New!)
- **Price Benchmark Check**: Evaluates listing price against bookstore retail to compute savings percentage and assign deal ratings (e.g. *Steal Deal 🔥*, *Great Value ⚡*).
- **Polite Bargaining Coach**: Generates 3 contextual, respectful discount negotiation templates that students can send directly to the seller with 1 tap.
- **In-Person Inspection Checklist**: Gives category-specific inspection tips so students know what to verify before paying.

### 3. 🛡️ Campus Verified Safe Trade Hubs (New!)
- **Designated Exchange Locations**: Pre-configured campus meetup spots (University Library Entrance, Student Center Cafeteria, Campus Security Post) with safety ratings and CCTV coverage.
- **One-Tap Meetup Proposal**: Buyers can suggest meeting at a safe campus trade zone directly in chat.

### 4. 🏛️ Campus Isolation & College Directory
- **Verified Domains**: Listings and conversations are restricted strictly to students within the same university domain (e.g., `@ddu.ac.in`, `@nirmauni.ac.in`, `@stanford.edu`).
- **Instant College Registration**: Students can register their university domain on the fly if not already pre-configured.

### 5. 🎨 "Aurora Iris & Cyber Slate" Aesthetic Design System
- **Next-Gen Palette**: Upgraded to Electric Iris (`#4F46E5`), Radiant Indigo (`#6366F1`), Cyber Violet (`#8B5CF6`), and Emerald Mint (`#10B981`) with soft glassmorphic shadows and rounded cards.
- **Adaptive Layouts**: Fluid thumb-friendly navigation on Android/iOS, and multi-column responsive desktop grids on Web.
- **Quick Category & Course Code Filter Pills**: Filter instantly by course code (`CS101`, `MATH150`, `CHEM210`, `EE204`, `ME201`) or category.

### 6. 🔍 Search & Multi-criteria Filtering
- **Keyword & Course Code Search**: Debounced search by item title, course code (e.g., `CHEM210`, `CS101`), or category.
- **Interactive Filter Bottom Sheet**: Price slider ($10 – $300), item condition chips, and multiple sorting modes (Newest First, Price: Low to High, Price: High to Low).
- **Active Filter Indicators**: Easily see and dismiss active filters with one tap.

### 7. 🏷️ Selling & Item Management
- **Universal Photo Upload**: Built to work seamlessly across Android (Camera & Gallery) and Web browsers (File Picker / Drag & Drop) without file system crashes.
- **Course Code Quick Selector**: Fast suggestions (`CS101`, `MATH150`, `CHEM210`, `EE204`, etc.).
- **Item Detail Screen**: Includes seller identity, campus verification badge, safety tips, and condition indicators.
- **Seller Actions**: Sellers can manage their own listings with "Mark as Sold" and "Delete Listing" options.

### 8. 💬 In-App Campus Messaging
- **Real-Time Direct Chat**: Buyers and sellers communicate directly about specific listings.
- **Product Context Header**: Displays product thumbnail, title, and price directly inside the chat window.
- **Quick Suggestion Chips**: Fast replies ("Is this still available?", "📍 Can we meet at the University Library?").

### 9. 👤 Student Profile & My Listings
- **Academic Info**: Department, graduation year, contact preferences, and campus verification status.
- **My Listings Manager**: View, inspect, mark as sold, or delete active listings.
- **Demo Data Control**: One-tap demo reset button to restore presentation data instantly.

### 10. ⚡ Offline Demo Mode
- **Zero Internet Requirement**: Complete presentation/demo capabilities without requiring a live backend.
- **Deterministic Mock Store**: Pre-seeded with realistic textbooks, calculators, dorm gear, and sample chat rooms.
- **One-Tap Quick Demo Login**: Instantly log in as Alex Johnson from Dharmsinh Desai University with zero typing.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.x (Compatible with Flutter 3.47+ / Dart 3.13+)
- **State Management**: Stateful widgets with centralized `ValueNotifier` & stream controllers
- **Backend (Optional Live Mode)**: Supabase (Auth, Postgres Database, Row Level Security, Realtime, Storage)
- **Local / Demo State**: `AppConfig` in-memory reactive data layer
- **Image Handling**: `image_picker` with cross-platform base64 memory streams and web-safe fallbacks

### Project Structure
```text
lib/
├── core/
│   ├── config/          # AppConfig (Online vs Offline Demo mode, mock DB)
│   ├── errors/          # AppError (Centralized friendly error handling)
│   ├── theme/           # AppTheme (Refurbished Material 3 design tokens)
│   ├── utils/           # AppLogger (Safe debug logging)
│   └── widget/          # SafeItemImage, DemoBadge, CustomButton, EmptyView, ErrorView
├── features/
│   ├── auth/            # Login, Signup, Forgot Password, and AuthGate
│   ├── chat/            # Real-time messaging, Chat List, and Chat Detail
│   ├── colleges/        # University directory and domain validation
│   ├── listings/        # Marketplace feed, Add Item, Item Detail, ItemCard
│   ├── profile/         # Student Profile and Edit Profile
│   └── search/          # Explore and multi-criteria filter screen
├── navigation/          # MainNavigationShell (Indexed bottom navigation)
└── main.dart            # Application entry point with global error boundaries
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13+ or 3.47+)
- [Google Chrome](https://www.google.com/chrome/) (for Web execution)
- [Android Studio](https://developer.android.com/studio) or an Android device/emulator (for Android execution)

### 1. Clone & Install Dependencies
```bash
git clone <repository-url>
cd campus_cart
flutter pub get
```

---

## 🌐 Running on Browser (Web)

CampusCart is fully optimized and tested for browser execution:

```bash
# Run on Chrome
flutter run -d chrome

# Or run on Microsoft Edge
flutter run -d edge

# To build production Web assets:
flutter build web
```
The compiled web assets will be in `build/web/`.

---

## 📱 Running on Android

CampusCart is configured with standard Android permissions (Camera, Media Images, Internet):

```bash
# Check connected Android devices or emulators
flutter devices

# Run on connected Android device/emulator
flutter run -d android

# Build Debug APK
flutter build apk --debug

# Build Release APK
flutter build apk --release
```
The generated APK will be located at:
`build/app/outputs/flutter-apk/app-debug.apk` (or `app-release.apk`).

---

## 🎯 Offline Demo Mode (Instant Presentation)

You can run and test **100% of CampusCart features without any Supabase or backend setup**:

1. Launch the app (`flutter run -d chrome` or on Android).
2. On the login screen, click **"Quick Demo Login (Offline Ready)"**.
3. You will immediately enter the marketplace pre-populated with:
   - 8 realistic campus items (Textbooks, Graphing Calculator, Lab Coat, Monitor, Desk Lamp, Multimeter).
   - Sample buyer-seller chat conversations.
   - Profile management with active listings.
4. To reset data at any time, go to **Profile 👤** -> Tap **"Reset Demo Presentation Data"**.

---

## ☁️ Supabase Backend Setup (Live Production Mode)

To connect to a live Supabase backend:

### 1. Configure `.env`
Create or edit `.env` in the project root:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 2. Run Database SQL Schema
In your Supabase SQL Editor, run the following SQL script to set up tables and Row Level Security (RLS):

```sql
-- 1. Colleges Table
create table public.colleges (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  domain text not null unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Pre-seed Universities
insert into public.colleges (name, domain) values
  ('Dharmsinh Desai University', 'ddu.ac.in'),
  ('Nirma University', 'nirmauni.ac.in'),
  ('IIT Bombay', 'iitb.ac.in'),
  ('BITS Pilani', 'pilani.bits-pilani.ac.in'),
  ('Stanford University', 'stanford.edu');

-- 2. Profiles Table
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  email text not null,
  department text default 'General',
  graduation_year text default '2027',
  contact_preference text default 'In-App Messaging',
  college_id uuid references public.colleges(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Listings Table
create table public.listings (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  price numeric not null check (price > 0),
  course_code text not null,
  category text not null,
  condition text not null,
  description text default '',
  image_url text,
  status text default 'available',
  seller_id uuid references public.profiles(id) on delete cascade not null,
  college_id uuid references public.colleges(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Chat Rooms Table
create table public.chat_rooms (
  id uuid default gen_random_uuid() primary key,
  listing_id uuid references public.listings(id) on delete cascade not null,
  buyer_id uuid references public.profiles(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  college_id uuid references public.colleges(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Messages Table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  chat_room_id uuid references public.chat_rooms(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Storage Bucket for Listing Images
insert into storage.buckets (id, name, public) 
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;
```

---

## 🧪 Testing & Verification

Run tests and analysis to ensure everything is operating cleanly:

```bash
# Run unit and widget tests
flutter test

# Run static code analysis
flutter analyze

# Verify Web compilation
flutter build web

# Verify Android APK compilation
flutter build apk --debug
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
