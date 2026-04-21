# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**KINETIC** — a gym management desktop app. Flutter frontend + Node.js/Express backend + MongoDB.

## Commands

### Client (Flutter)
```bash
cd client
flutter pub get          # Install dependencies
flutter run -d windows   # Run desktop app
flutter build windows    # Build release
flutter analyze          # Lint/type check
```

### Server (Node.js)
```bash
cd server
npm install              # Install dependencies
npm run dev              # Development with nodemon (auto-reload)
npm start                # Production
npm run seed             # Seed database with initial data
```

### Environment
Copy `server/.env.example` to `server/.env` and set:
- `MONGODB_URI` — MongoDB Atlas connection string
- `JWT_SECRET` — secret key for signing tokens
- `JWT_EXPIRES_IN` — e.g. `7d`
- `PORT` — default `5000`

## Architecture

### Client (`client/lib/`)

**Layer structure:**
- `core/` — constants, theme, global services
- `data/` — models (DTOs), repositories (API abstraction), services (HTTP + auth)
- `features/` — feature modules: `auth`, `dashboard`, `members`, `attendance`, `payments`, `settings`
- `shared/` — reusable widgets and layouts

**Key patterns:**
- **Repository pattern**: Each domain has a repository (e.g. `MemberRepository`) that wraps `ApiService` calls
- **`ApiService`**: Singleton HTTP client that auto-injects `Authorization: Bearer <token>` headers; throws `String` error messages
- **`AuthService`**: Manages JWT token in `SharedPreferences`; exposes `currentUser` and `isLoggedIn`
- **`DataSyncController`**: Singleton `ChangeNotifier` that broadcasts `DataRefreshEvent` enums — screens call `dataSync.notify(DataRefreshEvent.members)` after mutations; listeners rebuild their futures
- **Routing**: `go_router` with a `ShellRoute` that wraps authenticated screens in `AppShell` (sidebar nav layout)
- **Responsive layout**: `AppShell` switches between desktop sidebar and mobile bottom nav at 768px breakpoint

**API base URL** is in `core/constants/app_constants.dart`. Toggle `useVpsInDebug` to point at VPS (`http://82.25.180.20/gym/api`) vs local (`http://localhost:5000/api`).

### Server (`server/`)

**Structure:** `index.js` → routes → controllers → Mongoose models

**Multi-tenancy**: Every Mongoose model has an `owner` field (ref to User). All controllers filter queries by `req.user.id` — never return cross-owner data.

**Auth middleware** (`middleware/auth.js`): Validates JWT, attaches `req.user`.

**Payment status** is computed dynamically from the `Payment` collection, not stored statically on `Member`.

### API Endpoints

All routes prefixed `/api`:

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/auth/register` | Register gym owner |
| POST | `/auth/login` | Login |
| GET | `/auth/me` | Current user |
| PATCH | `/auth/profile` | Update profile |
| PATCH | `/auth/password` | Change password |
| GET/POST | `/members` | List (paginated) / create |
| GET/PATCH/DELETE | `/members/:id` | Read / update / delete |
| GET/POST | `/payments` | List / create |
| PATCH | `/payments/:id` | Update payment |
| GET/POST | `/attendance` | List / check-in |
| GET | `/dashboard` | Aggregated stats |
| GET/POST | `/tiers` | List / create membership tiers |
| PATCH/DELETE | `/tiers/:id` | Update / delete tier |
| GET | `/health` | Health check |

Pagination: `?page=1&limit=20` → response includes `total`, `pages`.

## Design System

- **Colors**: Cyan `#00D9FF` (primary), Orange `#FF6B35` (secondary), `#1A1A1A` (surface dark) — defined in `core/theme/app_colors.dart`
- **Fonts**: Roboto (body/headers), Syncopate (brand accent in sidebar)
- **Spacing tokens**: XS=4, S=8, M=16, L=24, XL=32, XXL=48 (px)
- **Breakpoints**: mobile < 768px, tablet 768–1024px, desktop > 1024px

All theme values come from `AppColors` and `AppTheme` — never hardcode hex values or spacing.
