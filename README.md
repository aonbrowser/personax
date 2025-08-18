# Relate Coach – Global Multi-Language Platform (Expo + Web + PostgreSQL)

- **UI:** Expo (React Native) → iOS/Android/Web single codebase
- **Server:** Node/Express + PostgreSQL + OpenAI
- **Prompts:** `server/src/prompts/*` (self/other/dyad/coach)
- **Multi-Language:** 15+ languages supported globally
- **Language Safety:** GPT-5-mini validation with 2x retry, incident logging
- **Payment Testing:** "Super Payment" button (instant success assumption)

## Quick Start
1) Create `.env` file (see `.env.example`)
2) PostgreSQL migration → seed:
   ```bash
   cd server
   npm i
   npm run migrate
   npm run seed:items ../data/testbank.csv
   ```
3) Server:
   ```bash
   npm run dev
   # http://localhost:8080/health
   ```
4) Expo (web/mobile):
   ```bash
   cd ../apps/expo
   npm i
   npm run web
   # or npm run ios / npm run android
   ```

## Supported Languages
English, Spanish, French, German, Italian, Portuguese, Dutch, Russian, Chinese (Simplified), Chinese (Traditional), Japanese, Korean, Arabic, Turkish, Hindi, and more...
