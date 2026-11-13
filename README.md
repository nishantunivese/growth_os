# GROWTH OS — Premium Android Business & Productivity System

> **Production-grade personal enterprise OS for online creators, digital marketers, affiliate clippers, and course entrepreneurs.**

---

## ⚡ Tech Stack & Architecture

- **Platform:** Native Android (Kotlin & Flutter 3.x / Dart 3.x)
- **Design System:** Linear / Stripe / Notion-inspired Obsidian Dark Theme (`#080B11`, `#121826`, `#6366F1`)
- **State Management:** Flutter Riverpod
- **Backend & Database:** Supabase (PostgreSQL with 23 tables, RLS Policies, automated triggers)
- **Local Persistence & Sync:** SQLite (`sqflite`) with offline queue
- **Charts:** FL Chart
- **Hardware Integrations:** Native Audio Recording (`record`, `audioplayers`), Camera/Gallery (`image_picker`), Biometrics (`local_auth`)
- **Notifications:** Android Local Notifications + WorkManager background scheduler
- **Reporting:** Executive CSV and PDF Statements (`pdf`, `printing`, `share_plus`)

---

## 🚀 Key Modules Built

### 1. Authentication & Onboarding
- **Quick Demo Mode:** Instant one-click credentials auto-fill.
- **Supabase Auth:** Email/password, session persistence, automatic profile creation trigger.
- **Profile Customization:** Social handles (YouTube, Instagram, Telegram), monthly & annual earning targets, business category, preferred currency.

### 2. Intelligent Home Dashboard
- **Executive Metrics:** Today's Completed Tasks, Active Projects, Monthly Goal Completion Ring.
- **Calculated Growth Velocity:** Derived from actual recorded entries—never fake or hardcoded.
- **Financial Pulse:** Gross Revenue, Expenses, Refunds, Realized Net Profit.
- **7-Day Trend Chart:** Interactive FL Chart line chart showing daily cash flow spikes.

### 3. My Work — Project & Process Tracker
- **Multi-Stage Pipelines:** Support for Tenbox clipping, Whop communities, YouTube Shorts, course launches.
- **Weighted Progress:** Progress updates strictly according to completed stage weights.
- **Chronological Journey Timeline:**
  - What you did today
  - What worked / Result achieved
  - Problem or loss encountered
  - What was learned
  - Realized earnings (+\$XX) and losses (-\$XX)
  - Screenshot gallery & Native Voice Note player

### 4. Earning & Financial Goals
- **Separation of Cash Flow:** Gross Revenue, Expenses, Customer Refunds, and Net Realized Profit.
- **Platform Breakdown:** Tenbox, Whop, Course Sales, AdSense, Brand Deals, Client Retainers.
- **Export Engine:** Instant downloadable monthly financial reports in both **CSV** and **PDF** formats.

### 5. Smart Cadence Reminders
- **Intervals:** 2 hours (default), 4 hours, 6 hours, 12 hours.
- **Quiet Hours:** Automatically mutes between 10:00 PM and 7:00 AM.
- **Intelligent Deduplication:** If the user already submitted a project update or recorded daily earnings within the interval, notification is suppressed to avoid spam.

### 6. Client & Brand Management (Mini CRM)
- **8-Stage Pipeline:** New Lead → Contacted → Negotiation → Deal Confirmed → In Progress → Completed → Payment Pending → Closed.
- **1-Tap Quick Actions:** WhatsApp chat direct shortcut (`wa.me`), Phone dialer (`tel:`), Email (`mailto:`).
- **Interaction Log:** Save call notes, follow-up dates, and proposal outcomes.

### 7. Creator Growth Center (5 Special Features)
1. **Content Calendar:** Plan YouTube videos, Shorts, Reels, Telegram posts (Idea → Scripted → Recorded → Edited → Scheduled → Published).
2. **Audience Tracker:** Track subscriber counts, total views, and watch hours with manual catalyst notes.
3. **Course Sales Funnel:** Visual conversion stages (Audience → Leads → Checkout → Paid Customers).
4. **Lead & DM Manager:** Organize inbound leads from YouTube comments, Instagram DMs, and Telegram.
5. **Campaign Analytics:** Track videos published, views generated, sales, and ROI leaderboards.

### 8. AI Growth Intelligence Copilot
- **Bottleneck Detection:** Identifies overdue projects and dropping consistency.
- **Profitability Diagnosis:** Real-time net margin calculations.
- **Viral Hook Generator:** Generates high-CTR hooks for Shorts and Reels.
- **Configurable AI Key:** Supports OpenAI GPT-4o, Google Gemini, Groq Llama, and Offline Local Heuristics.

### 9. Owner Super-Admin Control Room
- **Access Gate:** Protected by Master PIN (`8888`) or owner credentials.
- **System Telemetry:** Platform-wide registered users, active daily users, storage health, sync queue.
- **Broadcast System:** Transmit instant push announcements to all active Android devices.
- **RLS Privacy Shield:** Strict cryptographic and database separation ensures user media, private entries, and voice notes are never visible to admins.

---

## 🛠️ Build & Play Store Deployment Guide

### Prerequisites
1. Install [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install/windows).
2. Ensure Android Studio with Android SDK 34 (Android 14) is installed.

### Build Commands

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Build Debug APK for immediate device testing
flutter build apk --debug

# 3. Build Release APK (sideloadable)
flutter build apk --release

# 4. Build Google Play Store Production App Bundle (.aab)
flutter build appbundle --release
```

The resulting Play Store bundle will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔒 Supabase Backend Migration

To deploy the backend database to your Supabase project:
1. Open your Supabase Dashboard -> **SQL Editor**.
2. Copy and paste the contents of [`supabase/migrations/001_initial_schema.sql`](file:///E:/projects%20ai%20automation/growth_os/supabase/migrations/001_initial_schema.sql).
3. Click **Run**. All 23 tables, indexes, triggers, and Row Level Security (RLS) policies will be created immediately.

