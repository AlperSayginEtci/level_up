# Luna's Progress Log - LevelUp

## Session: July 16, 2026

- [x] Assistant nickname established: **Luna**.
- [x] Project workspace confirmed: `LevelUp` (Flutter habit tracking app with Solo Leveling mechanics).
- [x] Setup initial packages (`provider`, `shared_preferences`, etc.) in `pubspec.yaml`.
- [x] Created PlayerStats model in `lib/models/player_stats.dart` with custom direct-stat-increase logic based on completed quest types.
- [x] Clean up default template and errors in `lib/main.dart` (Next step!).
- [x] Create Quest model in `lib/models/quest.dart`.

## Session: July 21, 2026

- [x] Created an animated, glowing **"Level Up!"** popup (`LevelUpDialog`) that triggers in `MainLayout` when the user gains enough EXP.
- [x] Completely refactored `CreateQuestScreen` to feature a Solo Leveling "System Window" aesthetic (dark background, neon blue borders, custom inputs).
- [x] Introduced **End-of-Day Limit Quests** (e.g. Calorie targets). Modified `Quest` model to support `isEndOfDayEvaluation` and `maxLimit`.
- [x] Updated `PlayerProgressAndStatsController`'s `_checkDailyReset` to properly evaluate limit-based quests (like staying under 2300 calories) at midnight and distribute rewards.
- [x] Updated `HomeScreen` to visually represent Limit Quests (progress bar turns RED if exceeded, displays "LIMIT EXCEEDED").

## Session: July 25, 2026

- [x] Added `Achievement` model to support a Milestone (Rank) system from E-Rank to SSS-Rank.
- [x] Integrated `fl_chart` to display a Solo Leveling themed Pentagon Radar Chart (Combat Power Analysis).
- [x] Placed the Radar Chart side-by-side with base attributes on the `HomeScreen` in a responsive flex layout.
- [x] Created `ProfileScreen` to display a list of all earned and locked Hunter Ranks & Titles.
- [x] **Future Plan:** Enhance the `ProfileScreen` to act as an account page (adding user avatar, name editing, and account details).
- [x] **Future Plan:** Slightly shrink the size of the Radar Chart on the `HomeScreen` further and remove numeric values from its labels, keeping only stat abbreviations (e.g., 'STR', 'SEN') for a cleaner System UI look.

## Session: July 28, 2026

- [x] Replaced `SharedPreferences` with `Hive` for blazing fast local database storage.
- [x] Integrated `flutter_wear_os_connectivity` and created `SyncService` for phone-to-watch communication.
- [x] Designed `WearHomeScreen` and dynamic routing logic in `MainLayout` to detect watch screen size.
- [x] Added `launch.json` to fix Web Port (8080) ensuring IndexedDB persistence across restarts.
- [x] **Bug/Todo:** User requested new tabs/features for the Wear OS UI, currently noting that some bugs exist in the initial UI draft that need to be resolved later.

## Session: July 30, 2026

- [x] Fixed string interpolation bugs in `WearHomeScreen` and updated `AndroidManifest.xml` to fully support Wear OS native Tiles.
- [x] Created `OnboardingScreen` (Local System Awakening) to allow the player to register their Hunter Name.
- [x] Enhanced `ProfileScreen` into an account page that displays the avatar, completed quests, and allows Hunter Name editing.
- [x] Cleaned up the Radar Chart (`stat_radar_chart.dart`) by removing numeric values and shrinking its layout in `HomeScreen`.
- [x] Cleaned up the Radar Chart (`stat_radar_chart.dart`) by removing numeric values and shrinking its layout in `HomeScreen`.

## Session: July 31, 2026

- [x] Designed and integrated a dynamic, animated circuit/star-map background (`SystemBackground`) across all screens in the app to establish the Solo Leveling aesthetic.
- [x] Refactored `AppTheme` to create a robust, global design system.
- [x] Implemented a **Hidden Easter Egg** in the Profile Screen: tapping the highest rank unlocks the "Shadow Monarch" (Mor/Purple) system theme. The user can toggle this theme seamlessly across the entire app.
- [x] Fixed all active IDE warnings, deprecations, and compiler errors across the codebase to ensure optimal stability.
- [x] Fixed all active IDE warnings, deprecations, and compiler errors across the codebase to ensure optimal stability.

## Session: August 1, 2026

- [x] Configured Firebase CLI and FlutterFire to connect the app to Firebase.
- [x] Implemented `CloudSyncService` leveraging Firestore for free and seamless data backup/restore.
- [x] Created `UpdateService` to fetch OTA (Over-The-Air) update metadata (`version.json`) from a remote source.
- [x] Built a Solo Leveling themed `SystemUpdateDialog` that downloads and installs APK updates natively without Google Play (using `dio` and `open_file`).
- [x] Intercepted `MainLayout` initialization to automatically check for System Upgrades.
- [x] Created `AuthService` using Firebase Auth and Google Sign-In for a complete account system.
- [x] Designed `LoginScreen` with E-mail/Password and Google Sign-In options matching the neon aesthetic.
- [x] Refactored `CloudSyncService` to automate Cloud Synchronization in the background upon data changes and login.
- [x] Fixed `google_sign_in` Web compatibility issues by overriding web auth with `FirebaseAuth.signInWithPopup`.
- [x] Removed manual backup buttons to deliver a seamless real-time syncing experience.
## Session: August 2, 2026

- [x] Redesigned `SystemBackground` to feature a geometric, neon-bordered UI frame with a centralized subtle glow, perfectly mimicking the system window aesthetic.
- [x] Fixed the bottom overflow issue in the Home Screen by utilizing `SingleChildScrollView`.
- [x] Updated `PlannerScreen` to filter quests strictly by the selected date, show daily quests, and indicate daily completion status with color-coded dots on the calendar.
- [x] Fixed a bug where recurring quests appeared as "completed" on future dates.
- [x] Applied the Shadow Monarch (Purple) theme to the `StatRadarChart` during the Easter Egg mode.
- [x] Developed an **AI Food Scanner** (`AiNutritionService`) utilizing the Google Gemini API to analyze food images and extract macro/calorie values.
- [x] Remodeled the `sys_calories` quest into `sys_nutrition` with dynamic sub-quests (Protein, Carbs, Fat) calculated automatically from the user's Age, Weight, and Height.
- [x] Expanded the `ProfileScreen` to allow users to input Physical Metrics and their personal Gemini API Key.
- [x] Updated `CloudSyncService` to back up all User Profile settings (including the API Key and Metrics) to Firebase to ensure true cross-device syncing.
- [x] Fixed `minSdkVersion` and namespace issues for Wear OS Connectivity plugin in Gradle.
- [x] Created `WearSyncScreen` for Watch OS to bypass Firebase Auth and wait for Phone synchronization.
- [x] Updated `SyncService` to handle `/sync_quests` logic on Wear OS, allowing local Hive updates.
- [x] Configured Google Sign-In with updated SHA-1 hashes inside `google-services.json`.
- [x] Generated a new perfectly balanced neon blue 'LEVEL UP' app icon with a thick vertical arrow and integrated it using `flutter_launcher_icons`.
- [x] Updated application name to "Level Up" across the Android manifest.

## Session: August 2, 2026 (Part 2) — v1.0.5

- [x] **Critical Fix:** Resolved fresh-install account reset bug. `_loadStatsFromStorage()` now calls `CloudSyncService.restoreDataFromCloud()` BEFORE initializing local quests if the local DB is empty and the user is logged in. Previously, the app would create a Level 1 account before Firebase data arrived.
- [x] **Fix:** Profile updates (API Key, body metrics, name, profile image) now immediately trigger `_saveStatsToStorage()` so all changes are backed up to Firebase in real-time — not just to SharedPreferences.
- [x] **Fix:** Replaced the `pedometer`-only step tracking with a dual approach: `health` package (v13.3.1) fetches the full day's step count from Android Health Connect on startup, and pedometer tracks live deltas. Samsung Health data is now included.
- [x] **Fix:** Added `android.permission.health.READ_STEPS` to `AndroidManifest.xml` for Health Connect access.
- [x] **Fix:** Added bidirectional Wear OS ↔ Phone sync for Player Stats. New method `SyncService.sendPlayerStatsToWatch(level, exp)` sends level/EXP to the watch every time data is saved. Watch level now updates in real-time when phone levels up.
- [x] **Fix:** Added `SyncService.sendProgressToPhone(questId, amount)` so tapping a quest on the watch sends the delta progress back to the phone. Watch quest progress is now reflected on the phone.
- [x] **Fix:** `sendQuestsToWatch()` now includes `currentProgress` and `targetProgress` fields so the watch can display accurate progress bars.
- [x] **Fix:** Added `/quest_progress` and `/sync_stats` message path handlers in `SyncService._handleIncomingMessage()`.
- [x] **Feature:** Added `restoreFromJsonMap()` to `CloudSyncService` and a **"Restore from JSON Backup"** tile in `ProfileScreen` — allows importing a `.json` backup file (e.g., from PC) to restore account data and push it to Firebase.
- [x] **Fix:** `PlayerStats` model now has a `copyWith()` method (required by the new sync logic in `SyncService`).
- [x] **Fix:** Bumped version to `1.0.5+5` in `pubspec.yaml` and updated `version.json` download URL to `v1.0.5`.
- [x] Pushed all changes to GitHub `main` branch. New APK `LevelUp_v1.0.5.apk` built and placed on Desktop.

## Remaining System Quests (Goals)

- [x] **Bug (Fixed):** AI Food Scanner (Gemini API) is not working. 
  *Root Cause:* The official `google_generative_ai` SDK was failing with 404 because older `gemini-1.5` models were deprecated and removed from the 2026 API.
  *Fix:* Completely replaced the official SDK with a raw HTTP REST client using `dio`. Implemented a robust fallback system and updated the endpoints to use the latest `gemini-2.5-flash` and `gemini-flash-latest` models. Added detailed error logging to the UI for future API key debugging.
- [ ] **Bug/Todo:** Resolve any lingering UI glitches in the Wear OS interface.
- [ ] **Bug (NEXT SESSION):** Watch/Phone Initial Sync Issue. The watch and phone sync increments (deltas) perfectly, but they do not sync their initial state upon first connection. If the phone is already at Level 4 (with 4 glasses of water) and the watch is freshly installed, the watch starts at Level 1 (0 water). Increments apply to both, but their absolute values remain mismatched. Need to implement a full state sync upon first connection or app startup.
