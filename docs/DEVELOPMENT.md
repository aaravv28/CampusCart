# CampusCart — Developer Architecture & Engineering Documentation

## 1. System Architecture

CampusCart employs a robust, modular, layer-separated architecture tailored for high reliability, fault tolerance, and offline capability:

```
┌────────────────────────────────────────────────────────┐
│                        UI Layer                        │
│   (Screens, Form Fields, Item Cards, Dialogs, Badges)  │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│                    Service Layer                       │
│    (AuthService, ListingsService, ChatService, etc.)   │
└─────────────▲────────────────────────────▲─────────────┘
              │                            │
   [AppConfig.isDemoMode == false]   [AppConfig.isDemoMode == true]
              │                            │
┌─────────────▼──────────────┐   ┌─────────▼─────────────┐
│    Remote Supabase API     │   │   Local Demo Store    │
│  (Auth, DB, Realtime, S3)  │   │  (In-Memory AppConfig)│
└────────────────────────────┘   └───────────────────────┘
```

### Flow of Operations:
1. **UI Layer**:
   - Renders state via standard widgets (`FutureBuilder`, `StreamBuilder`, `StatefulWidget`).
   - Handles empty states gracefully via `EmptyView` and error states via `ErrorView`.
   - Never exposes technical exceptions or raw socket failures to end users.
2. **Service Layer**:
   - Encapsulates domain logic (`createListing`, `filterListings`, `sendMessage`, `getColleges`).
   - Directly checks `AppConfig.instance.isDemoMode` and Supabase availability.
   - Converts low-level exceptions into typed `AppError` models.
3. **Data Source Layer**:
   - **Remote**: Live Supabase instance (PostgreSQL database, Gotrue Auth, Realtime WebSocket streams, S3 Storage).
   - **Local Demo Store**: Thread-safe in-memory database within `AppConfig` supporting full CRUD, query filtering, price calculation, real-time message streams, and state resets.

---

## 2. Centralized Error Handling Architecture

Low-level technical errors (such as `SocketException`, `TimeoutException`, `FormatException`, `AuthException`, or RLS violations) are intercepted before reaching the UI.

### The Conversion Pipeline:
```
Low-Level Exception (e.g. SocketException / HTTP 500)
                 ↓
      Service / Repository Catch Block
                 ↓
AppError.fromException(e) [Maps error type & generates safe message]
                 ↓
        UI Presentation (ErrorView or SnackBar)
                 ↓
   User-Friendly Message + Actionable Retry Button
```

### Error Taxonomy (`AppErrorType`):
- `network`: Internet down, server unreachable, DNS lookup failed.
- `timeout`: Server request exceeded operational timeout limit.
- `authentication`: Invalid credentials, unverified email, session expired.
- `validation`: Missing required form fields, invalid price, malformed domain.
- `database`: PostgreSQL query failure or constraint violation.
- `storage`: Image upload or file decoding error.
- `notFound`: Requested listing, conversation, or user profile missing.
- `unknown`: Safe generic fallback.

### Global Error Hooks (`main.dart`):
- `FlutterError.onError`: Traps framework layout and rendering anomalies.
- `PlatformDispatcher.instance.onError`: Traps uncaught asynchronous microtask errors without abruptly killing the process.
- `ErrorWidget.builder`: Renders an elegant fallback widget instead of the red crash screen.

---

## 3. Offline-First Demo Mode Architecture

CampusCart is engineered to be presentation-ready with **zero internet requirements**.

### How Demo Mode Works:
- Automatically activated if `.env` is missing, Supabase initialization fails, or user taps **"Quick Demo Login (Offline Ready)"**.
- Replaces all external network dependencies with local implementations:
  - **Auth**: Pre-seeded demo user (`alex.johnson@ddu.ac.in`).
  - **Colleges**: Pre-seeded university directory (`ddu.ac.in`, `nirmauni.ac.in`, `iitb.ac.in`, etc.).
  - **Listings**: Pre-seeded campus items across textbooks, calculators, monitors, dorm gear, and lab equipment.
  - **Images**: Rendered safely via `SafeItemImage`, supporting local file paths, placeholders, and error-safe network caches.
  - **Realtime Chat**: Powered by local broadcast `StreamController` instances simulating real-time buyer-seller conversations.
  - **Local Persistence & Reset**: Live additions (new items, new messages, profile edits) persist during the session. Tapping **"Reset Demo Presentation Data"** in Profile resets the store to factory state.

---

---

## 4. 🤖 AI Shopping Assistant & Deal Inspector Architecture

CampusCart integrates a dual-engine AI architecture designed for 100% availability:

```
                  ┌─────────────────────────────────────────┐
                  │          Student Natural Query          │
                  │   ("CHEM210 book", "Budget < $40")      │
                  └───────────────────▲─────────────────────┘
                                      │
                         ┌────────────┴────────────┐
                         │ AiShoppingAssistantSvc  │
                         └──────┬────────────┬─────┘
                                │            │
               [Online & GEMINI_API_KEY]   [Offline / No Key]
                                │            │
            ┌───────────────────▼──┐      ┌──▼────────────────────┐
            │  Google Gemini 2.0/  │      │  Campus Heuristic     │
            │  1.5 Flash REST API  │      │  Semantic NLP Engine  │
            └──────────────────────┘      └───────────────────────┘
```

### Highlights:
1. **Zero-Failure Offline AI**: When offline or if an API key is not supplied, the app never crashes. The deterministic campus NLP engine processes course codes (`CS101`, `CHEM210`, `MATH150`, `ME201`), budget bounds, and category keywords to recommend items.
2. **In-Listing Deal Inspector**: Computes savings against bookstore retail benchmarks and categorizes deals (*Steal Deal 🔥*, *Great Value ⚡*, *Fair Price 👍*).
3. **Polite Bargaining Coach**: Generates 3 contextual negotiation scripts ready for 1-tap dispatch to the seller.
4. **Safe Trade Zones**: Direct integration with campus meetup checkpoints (Library Ground Floor, Student Union, Campus Police Post).

---

## 5. Verification & Validation Commands

Run these standard commands in the project directory:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analyzer (must yield 0 issues)
flutter analyze

# 3. Format code
dart format .

# 4. Run automated test suite (all 23 tests passing)
flutter test

# 5. Build Debug APK
flutter build apk --debug

# 6. Build Release APK
flutter build apk --release
```
