# Kashi Nav

AI-powered travel companion for Varanasi (Kashi), India. Navigate pedestrian *galis*, get real-time context-aware recommendations, journal your experiences, and interact via voice with an agentic AI "Brain".

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.41.1 / Dart 3.11 |
| State | Riverpod 2.x |
| Routing | go_router 12.x |
| Maps | flutter_map + OpenStreetMap (Stadia tiles) |
| Local DB | SQLite via sqflite |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| AI | Gemini 2.0 Flash (primary), DeepSeek (fallback) |
| Voice | Groq Whisper (STT) + flutter_tts (TTS) |

## Prerequisites

- Flutter SDK >= 3.0
- Node.js >= 18 (for Firebase Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore, Auth, and Cloud Functions enabled

## Quick Start

```bash
# Clone the repo
git clone https://github.com/saketh1125/Saar.git
cd Saar

# Install mobile dependencies
cd mobile
flutter pub get

# Run in mock mode (no backend needed)
flutter run
```

## Mock vs Live Mode

The app runs in **mock mode by default** — all repositories return simulated data, no backend or API keys required.

To switch to **live mode**:

1. Create a Firebase project and enable Firestore, Authentication (anonymous), and Cloud Functions
2. Copy `.env.example` to `.env` and fill in your API keys
3. Deploy the Firebase Functions:
   ```bash
   cd firebase/functions
   npm install
   cd ..
   firebase deploy --only functions,firestore,storage
   ```
4. In the Flutter app, toggle `RepoMode` from `mock` to `live` in `lib/data/repositories/repositories.dart`

## Environment Variables

Copy `.env.example` to `.env` and fill in the values. All keys are optional for mock mode.

| Variable | Service | Free Tier |
|----------|---------|-----------|
| `GEMINI_API_KEY` | Google AI Studio | 15 RPM, 1M tokens/day |
| `DEEPSEEK_API_KEY` | DeepSeek | Generous free tier |
| `BRAVE_API_KEY` | Brave Search | 2000 queries/month |
| `TAVILY_API_KEY` | Tavily Search | 1000 queries/month |
| `EXA_API_KEY` | Exa Search | 1000 queries/month |
| `ORS_API_KEY` | OpenRouteService | 2000 routes/day |
| `STADIA_MAPS_KEY` | Stadia Maps | 100k tiles/month |
| `SUPABASE_URL` | Supabase | 500MB free |
| `SUPABASE_KEY` | Supabase | 500MB free |
| `GROQ_API_KEY` | Groq (Whisper) | Free tier varies |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      main.dart                          │
│  ProviderScope → AnimatedTheme → MaterialApp.router      │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
   ThemeController  SystemClock  WeatherNotifier
          │
   go_router (5 tabs): Map | Today | Brain | Journal | Tools
                       │
   ┌───────────────────┴──────────────────────┐
   │              Data Layer                   │
   │  Repositories (8 interfaces + mocks)     │
   │  Models (Poi, Itinerary, Panchang, etc.) │
   │  SQLite (journal, POIs, checklists)      │
   └───────────────────┬──────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │  Mock Mode                   │  Live Mode
        │  (simulated data)            │  (Firebase + APIs)
        └─────────────────────────────┘
```

## Directory Structure

```
kashi-nav/
├── .github/workflows/          # CI/CD (Flutter + Firebase)
├── firebase/
│   ├── firestore.rules         # Security rules
│   ├── storage.rules           # Storage rules
│   └── functions/              # Cloud Functions (TypeScript)
│       └── src/                # 8 callables + 3 scheduled crons
├── keynotes/                   # Design docs, roadmap, status
├── mobile/                     # Flutter app
│   └── lib/
│       ├── core/               # Theme, routing, DB, networking, widgets
│       ├── data/               # Models, repositories, seed POIs
│       └── features/           # Map, Today, Brain, Journal, Tools
├── .env.example                # Required API keys
├── LICENSE                     # MIT
└── README.md                   # This file
```

## Features

- **Dynamic Theming** — Colors morph based on Varanasi's solar position (sunrise/day/twilight/night/monsoon)
- **OSM Map** — 32 bundled POIs, category filters, escape-route FAB for pedestrian alleys
- **AI Brain** — Chat with confidence labels, source chips, voice input, execution feed
- **Journal** — Mood picker, local SQLite persistence, fire-and-forget AI reflection
- **Tools** — Scam Shield, temple checklist, media provider integration, theme preview

## Cost Estimate

| Service | Cost |
|---------|------|
| Firebase (Spark plan) | $0 |
| Gemini 2.0 Flash | $0 |
| Brave/Tavily/Exa Search | $0 |
| OpenRouteService | $0 |
| Stadia Maps | $0 |
| Supabase pgvector | $0 |
| **Total** | **~₹10/month** |

## License

MIT License - see [LICENSE](LICENSE)
