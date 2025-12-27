# Quick Start Guide

## Prerequisites
- Flutter SDK installed (version 3.3.0 or higher)
- Chrome browser for web testing

## Installation Steps

```bash
# 1. Navigate to project directory
cd /home/runner/work/winova_flutter/winova_flutter

# 2. Get Flutter dependencies
flutter pub get

# 3. Verify setup
flutter doctor

# 4. Build for web
flutter build web

# 5. Run in Chrome
flutter run -d chrome
```

## Testing the Fixes

### Test 1: Preview Screen (Bug Fix #1)
1. App opens automatically (auto-login)
2. You'll see "المسابقات" (Contests) screen by default
3. Click **"عرض المتسابقين (Preview)"** button
4. ✅ **Expected**: Modal opens showing "لا يوجد متسابقون بعد" (no blank screen!)
5. Modal has button: **"إضافة متسابقين الآن"**

### Test 2: DEV Seed Contestants (Bug Fix #3)
1. On Contests screen, scroll to "أدوات DEV للاختبار" section
2. Click red button: **"إضافة 20 متسابق وهمي"**
3. Wait 2-3 seconds
4. ✅ **Expected**: Green snackbar shows "تم إضافة 20 متسابق وهمي"
5. Click **"عرض المتسابقين (Preview)"** again
6. ✅ **Expected**: Modal now shows 20 contestants with Arabic names and vote counts

### Test 3: Stage1 Screen (Bug Fix #2)
1. On Contests screen, click orange button: **"بدء المرحلة الأولى (Stage1)"**
2. Wait for success message
3. Click **"Stage1 — التصويت"** button (now visible)
4. ✅ **Expected**: Stage1 screen opens showing list of 20 contestants (no blank screen!)
5. Each contestant has a **"صوّت"** (Vote) button

### Test 4: Voting Flow
1. In Stage1 screen, check your Aura balance at top
2. If low, go back and click **"إضافة أموال تجريبية (100+100)"**
3. Return to Stage1 screen
4. Click **"صوّت"** on any contestant
5. ✅ **Expected**: 
   - Green snackbar: "تم التصويت بنجاح!"
   - Aura balance decreases by 1
   - Contestant vote count increases
   - List re-sorts by votes

## All DEV Tools Available

In the Contests screen, red section "أدوات DEV للاختبار":

1. **إضافة 20 متسابق وهمي** - Adds 20 mock contestants
2. **بدء المرحلة الأولى (Stage1)** - Changes contest to Stage1
3. **إضافة أموال تجريبية (100+100)** - Adds 100 Nova + 100 Aura

## Navigation Flow

```
App Start
  ↓ (auto-login)
Home Screen (Bottom Tabs)
  ├─ المسابقات (Contests) ← Default tab
  ├─ الفريق (Team) - Placeholder
  ├─ المحفظة (Wallet) - Placeholder
  └─ الملف (Profile) - Placeholder

Contests Screen
  ├─ انضم للمسابقة - Join contest button
  ├─ عرض المتسابقين (Preview) - Opens modal with contestants
  ├─ Stage1 — التصويت - Opens voting screen (if Stage1 active)
  └─ أدوات DEV - DEV tools section with 3 buttons

Stage1 Screen
  ├─ List of contestants (sorted by votes)
  ├─ Vote buttons for each contestant
  └─ Empty states with helpful messages if needed
```

## Troubleshooting

### Issue: "No contest active"
**Solution**: Click **"بدء المرحلة الأولى (Stage1)"** in DEV Tools

### Issue: "No contestants"
**Solution**: Click **"إضافة 20 متسابق وهمي"** in DEV Tools

### Issue: "Insufficient Aura"
**Solution**: Click **"إضافة أموال تجريبية (100+100)"** in DEV Tools

### Issue: "Not joined contest"
**Solution**: Click **"انضم للمسابقة"** button (costs 10 Nova)

## Key Features Implemented

✅ **No Blank Screens**: Every screen shows something helpful
✅ **Empty States**: Friendly messages with action buttons
✅ **DEV Tools**: One-click data generation for testing
✅ **Safe Guards**: Validation at every step
✅ **Reactive UI**: State updates immediately with notifyListeners()
✅ **Arabic Support**: Full RTL text support
✅ **Single Session Testing**: No backend needed

## Code Structure

```
lib/
├── api/
│   └── mock_winova_api.dart      # Mock backend
├── config/
│   └── app_config.dart            # Configuration
├── models/
│   ├── user.dart                  # User model
│   ├── contest.dart               # Contest model
│   └── contestant.dart            # Contestant model
├── screens/
│   ├── home_screen.dart           # Main navigation
│   ├── contests_screen.dart       # Contests + Preview + DEV tools
│   ├── stage1_screen.dart         # Voting screen
│   └── stage1_top50_screen.dart   # Leaderboard
├── state/
│   └── app_state.dart             # Main app state (Provider)
└── main.dart                      # App entry point
```

## Expected Output After Build

```bash
$ flutter build web
Compiling lib/main.dart for the Web...
Building without sound null safety
√ Built build/web
```

## What Changed

### Before (Buggy)
- ❌ Preview opened blank
- ❌ Stage1 opened blank or stuck
- ❌ Seed contestants didn't update UI

### After (Fixed)
- ✅ Preview always shows modal (list or empty state)
- ✅ Stage1 shows appropriate screen based on state
- ✅ Seed contestants creates data and updates UI immediately

## Next Steps

1. Run the tests above
2. Verify all screens render correctly
3. Test DEV tools functionality
4. Confirm no blank screens anywhere
5. Take screenshots if needed for documentation

## Support

If you encounter any issues:
1. Check the console for debug logs (look for "DEV:" prefix)
2. Verify Flutter SDK is properly installed
3. Clear browser cache if needed
4. Review VERIFICATION.md for detailed implementation details

---

**Ready to test!** Run `flutter run -d chrome` and follow the test scenarios above.
