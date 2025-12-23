# WINOVA Flutter MVP (UI + Mock API)

This is a **Flutter MVP** that matches the saved WINOVA foundations:
- Auth (signup/login) — **mocked locally** (no real backend yet)
- Wallet (Nova/Aura) + Convert Nova→Aura (1 Nova = 2 Aura)
- Contests (Join 10 Nova, Paid Vote using Aura)
- Team screens: "شو مطلوب مني؟" + Board + Presidency Race (MVP placeholders)
- Weekly Active (KSA week) concept shown in UI
- 14-day Dormant concept noted (mock)

## Why Mock API?
So you can run the app immediately and test UX flow.
Later you swap `MockWinovaApi` with real backend calls.

## Run
1) Create a Flutter project OR use this folder as project root:
```bash
flutter pub get
flutter run
```

## Configure backend later
In `lib/config/app_config.dart`:
- `useMockApi = true` (set false when you have backend)
- `apiBaseUrl = "https://your-api.com"`

Date: 2025-12-23
