# ضاد - DAAD Marketing Agency App

<p align="center">
  <img src="assets/images/logo.png" width="120" alt="DAAD Logo">
</p>

<p align="center">
  <strong>شريكك الرقمي في التعلم، التطوير، والأمان التجاري</strong><br>
  Your Digital Partner in Learning, Development & Business Security,
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-blue" alt="Platforms">
</p>

---

## 📖 Description

DAAD App is the official mobile application for **DAAD Digital Marketing Agency**, providing an interactive experience that combines learning, communication, and practical benefits for clients interested in digital marketing and e-commerce.

The app serves as a comprehensive platform offering:

- 🎧 Educational podcasts on marketing, e-commerce & entrepreneurship
- 📚 Professional articles on latest strategies and trends
- ⭐ Loyalty points system with rewards up to 100% discount
- 🤖 AI-powered chatbot trained for marketing consultation
- 📄 Client contracts & agreements management
- 💼 Full portfolio of agency services and projects

---

## ✨ Key Features

| Feature                         | Description                                              |
| ------------------------------- | -------------------------------------------------------- |
| **تعلم ضاد (Learn DAAD)**       | Curated podcasts & articles on digital marketing         |
| **نظام النقاط (Points System)** | Earn points with every interaction, redeem for discounts |
| **عجلة الحظ (Fortune Wheel)**   | Gamified rewards and promotions                          |
| **شات ذكي (AI Chat)**           | Context-aware AI assistant for marketing questions       |
| **العقود (Contracts)**          | Secure access to your service agreements                 |
| **الخدمات (Services)**          | Browse full catalog of agency offerings                  |
| **الأعمال (Portfolio)**         | View completed projects and case studies                 |
| **لوحة التحكم (Dashboard)**     | Admin panel for user/content management                  |

---

## 🛠 Tech Stack

### Core Framework

- **Flutter SDK** `^3.9.2` - Cross-platform UI framework
- **Dart** - Programming language

### Backend & Services

| Package                  | Version | Purpose                     |
| ------------------------ | ------- | --------------------------- |
| `firebase_core`          | ^3.6.0  | Firebase initialization     |
| `firebase_auth`          | ^5.3.1  | Authentication              |
| `cloud_firestore`        | ^5.4.4  | NoSQL database              |
| `firebase_storage`       | ^12.3.4 | File storage                |
| `firebase_messaging`     | ^15.0.4 | Push notifications          |
| `firebase_remote_config` | ^5.1.3  | Remote configuration        |
| `onesignal_flutter`      | ^5.3.4  | Advanced push notifications |

### State Management

| Package            | Version | Purpose                          |
| ------------------ | ------- | -------------------------------- |
| `flutter_riverpod` | ^2.5.1  | Primary state management         |
| `flutter_bloc`     | ^9.1.1  | BLoC pattern (specific features) |

### AI & Integrations

| Package                | Version | Purpose                   |
| ---------------------- | ------- | ------------------------- |
| `google_generative_ai` | ^0.4.7  | Gemini AI integration     |
| `dio`                  | ^5.9.0  | HTTP client               |
| `gsheets`              | ^0.5.0  | Google Sheets integration |

### UI & Media

| Package                        | Version | Purpose           |
| ------------------------------ | ------- | ----------------- |
| `flutter_screenutil`           | ^5.9.3  | Responsive sizing |
| `cached_network_image`         | ^3.4.1  | Image caching     |
| `carousel_slider`              | ^5.0.0  | Image carousels   |
| `lottie`                       | ^3.3.0  | Animations        |
| `video_player`                 | ^2.9.2  | Video playback    |
| `syncfusion_flutter_pdfviewer` | ^31.2.5 | PDF viewing       |

### Security

| Package                  | Version | Purpose                 |
| ------------------------ | ------- | ----------------------- |
| `flutter_secure_storage` | ^9.2.4  | Encrypted local storage |

---

## 📁 Architecture

```
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp configuration
├── router.dart            # Navigation routes
├── firebase_options.dart  # Firebase config
│
├── core/                  # Shared utilities
│   ├── constants.dart
│   ├── utils/
│   │   ├── app_colors/    # Theme colors
│   │   ├── caching_utils/ # Local caching
│   │   ├── services/      # Core services (logger, storage, deep links)
│   │   └── ...
│   └── widgets/           # Reusable UI components
│
└── features/              # Feature modules
    ├── auth/              # Authentication
    │   ├── data/          # Services & repositories
    │   └── presentation/  # Screens & widgets
    ├── home/              # Home screen
    ├── dashboard/         # Admin dashboard
    │   ├── forms/         # CRUD forms
    │   ├── services/      # Firebase operations
    │   ├── tabs/          # Dashboard tabs
    │   └── widgets/       # Dashboard UI
    ├── loyalty/           # Points & rewards
    ├── chatbot/           # AI chat
    ├── articles/          # Blog content
    ├── portfolio/         # Agency work
    ├── services/          # Service catalog
    ├── contact/           # Contact forms
    └── ...
```

**Pattern:** Feature-first modular architecture with separation between:

- `data/` - Business logic, services, repositories
- `presentation/` - UI screens and widgets
- `models/` - Data classes

---

## 🚀 Installation

### Prerequisites

- Flutter SDK `^3.9.2`
- Dart SDK `^3.3.0`
- Firebase project configured
- Android Studio or VS Code

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/daad_app.git
   cd daad_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Replace `lib/firebase_options.dart` with your project config
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**

   ```bash
   # Development
   flutter run

   # Release build
   flutter build apk --release
   flutter build ios --release
   ```

---

## 📱 Deployment

The app uses **Shorebird** for code push updates:

```bash
# Patch an existing release
shorebird patch android
shorebird patch ios
```

---

## 🔐 Security

- PII stored in encrypted storage via `flutter_secure_storage`
- Debug logs disabled in production builds
- Firebase Security Rules enforced
- Strict privacy policy compliance

---

## 👥 Team

Developed by **Zbooma(eng/Omar Shemais)**

---

## 📄 License

Proprietary - All rights reserved © DAAD Agency 2025

in the conact screen i want to make sure that notification in working for both users and admins or sales roles and make sure that the notification deepLink goes to the Chat od normal user goes to the user UserChatScreen Screen and if admin or sales goes to the Chat of the user in the dashboard
