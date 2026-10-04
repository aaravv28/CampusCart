# CampusCart — Presentation & Demo Guide

## 1. Project Overview
- **Product**: CampusCart 🛒
- **Problem**: College students struggle with unverified secondary marketplaces where fraud, logistical inconvenience, and spam are common.
- **Solution**: A hyper-local, college-domain verified peer-to-peer marketplace connecting students within the exact same campus for textbooks, lab equipment, electronics, and dorm essentials.

## 2. Target Users
- Undergraduate & Graduate university students.
- Campus clubs and student researchers buying/selling course-specific gear.
- Incoming freshmen looking for affordable textbooks and dorm furniture.

## 3. Core Features
1. **Official Campus Email Verification**: Restricts community access to verified university domains (`.ac.in`, `.edu`).
2. **Campus Isolation**: Listings and chats are automatically partitioned by university domain.
3. **Course Code Tagging**: Instant searching by specific course codes (e.g. `CHEM210`, `MATH150`, `CS101`).
4. **Multi-criteria Filtering**: Category chips, condition dropdowns, max price slider, and sorting.
5. **Real-Time Campus Chat**: Dedicated chat room per listing between buyers and sellers.
6. **Seller Listing Management**: Multi-step posting flow with photo support and validation.
7. **Offline Demo Mode**: Complete functional demo mode operating with zero internet dependency.

## 4. Technology Stack
- **Framework**: Flutter (Channel stable, Material 3 design system)
- **Language**: Dart (Full null safety, strict analysis)
- **Backend / Database**: Supabase (PostgreSQL, Gotrue Auth, Realtime Streams, Storage)
- **State & Architecture**: Service-Repository pattern with In-Memory Demo Store Fallback

---

## 5. Live Presentation Demo Script (Step-by-Step)

### Step 1: Opening & Motivation (30 seconds)
> *"Good morning everyone. Today we are presenting CampusCart, a verified campus marketplace designed specifically for college students. Most peer-to-peer marketplaces lack trust and community verification. CampusCart solves this by tying student identity directly to verified university email domains and scoping listings strictly within each college campus."*

### Step 2: Launch & Offline Demo Mode (30 seconds)
> *"Notice here on the login screen, we can connect live to our Supabase cloud backend, or for today's presentation, tap **'Quick Demo Login'**. This activates our offline-first architecture, ensuring the app is 100% functional even if the venue Wi-Fi fails."*

### Step 3: Explore the Marketplace Feed (45 seconds)
> *"Upon entering, we land on the Home Feed. All items are scoped to Dharmsinh Desai University. Notice the clean Material 3 card layout, course codes like CHEM210, prices, condition tags, and safe offline image fallbacks. If we search for 'Organic', the feed filters instantly."*

### Step 4: Explore & Multi-Criteria Filtering (45 seconds)
> *"Switching to the Search tab, we have multi-parameter filtering: we can filter by Category chips like 'Electronics', tap the tune icon to adjust the Max Price slider down to $50, and filter by condition. The results update reactively."*

### Step 5: Item Details & Real-Time Messaging (45 seconds)
> *"Selecting an item opens the Item Detail Screen with condition details and seller verification. Tapping **'Message Seller'** opens a direct chat room. Notice our real-time messaging stream: we can type a message like 'Can we meet at the campus library?', hit send, and see it appear instantly in the chat timeline."*

### Step 6: Selling Flow & Validation (45 seconds)
> *"In the Sell tab, students can post items. Notice the robust form validation: invalid prices (like negative numbers or non-numeric input) are rejected with clear error feedback. We can attach photos, select categories and conditions, and post the listing, which immediately appears in the feed."*

### Step 7: Profile Management & Demo State Reset (30 seconds)
> *"In the Profile tab, students manage their verified campus credentials, active listings count, and contact preferences. If we ever want to reset our presentation after demonstrating mutations, we simply tap **'Reset Demo Presentation Data'**, restoring the initial clean catalog."*

### Step 8: Closing & Technical Summary (30 seconds)
> *"To summarize: CampusCart combines campus isolation, real-time messaging, centralized exception handling, zero-crash safety, and full offline resilience. Thank you!"*
