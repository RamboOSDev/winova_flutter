# Testing Guide - Contest DEV Mode

## Prerequisites
- Flutter SDK installed
- Chrome browser installed

## Setup
```bash
cd /path/to/winova_flutter
flutter pub get
```

## Quick Test (5 minutes)

### 1. Launch App
```bash
flutter run -d chrome
```

### 2. Test "Open Full Flow" (One-Tap)
1. App should auto-login and show Contests screen
2. Scroll down to DEV section
3. Click "🚀 DEV: Open Full Flow (فتح المسابقة كاملة)"
4. Confirm the dialog
5. Wait for green success message
6. Verify all stages were set up

**Expected Result:**
- Contest created
- 20 contestants added
- Votes seeded
- Contest moved through all stages to "finished"

### 3. Verify Each Screen
After "Open Full Flow" completes:

#### A. Preview Contestants
1. Click "عرض المتسابقين (Preview)" button
2. **Expected:** Bottom sheet shows 20 contestants with names "متسابق 1" to "متسابق 20"
3. Close sheet

#### B. Top50 Leaderboard
1. Click "عرض أفضل 50 - Top50" button
2. **Expected:** Screen shows sorted list of contestants with vote counts
3. Press back

#### C. Final Results
1. Click "النتائج النهائية" button
2. **Expected:** Screen shows:
   - Trophy icon and title
   - Top 5 winners with ranks (gold #1, silver #2, bronze #3)
   - Prize amounts for each winner
   - Remaining contestants below
3. Press back

### 4. Test Manual Flow (Optional)

#### Reset and Start Fresh
1. Click "Reset Day" button
2. **Expected:** Orange snackbar "تم إعادة تعيين اليوم"
3. Contest info should show "لا توجد مسابقة نشطة اليوم"

#### Create Contest
1. Click "Create Contest" button
2. **Expected:** Green snackbar "تم إنشاء مسابقة اليوم"
3. Contest info should show today's date

#### Seed Contestants
1. Click "Seed 20" button
2. **Expected:** Green snackbar "تم إضافة 20 متسابق"
3. Count should show "عدد المتسابقين: 20"

#### Start Stage1
1. Click "Start Stage1" button
2. **Expected:** Green snackbar "تم بدء Stage1"
3. Stage should show "المرحلة الأولى"
4. "ابدأ التصويت - Stage1" button should appear

#### Test Voting
1. Click "ابدأ التصويت - Stage1" button
2. **Expected:** Screen shows list of 20 contestants
3. Click "صوّت" button on any contestant
4. **Expected:** Green snackbar "تم التصويت بنجاح!"
5. Vote count should increase
6. Press back

#### Seed Votes (Stage1)
1. Click "Seed Votes" button
2. **Expected:** Green snackbar "تم إضافة الأصوات"
3. Preview contestants - should see varied vote counts

#### Freeze Top50
1. Click "Freeze Top50" button
2. **Expected:** Green snackbar "تم تجميد أفضل 50"
3. Stage should show "أفضل 50 - المرحلة الأولى"
4. "عرض أفضل 50 - Top50" button should appear

#### Start Final
1. Click "Start Final" button
2. **Expected:** Green snackbar "تم بدء النهائي"
3. Stage should show "المرحلة النهائية"
4. "التصويت النهائي - Final" button should appear

#### Seed Votes (Final)
1. Click "Seed Votes" button again
2. **Expected:** Green snackbar "تم إضافة الأصوات"
3. Vote counts should update

#### Finish Contest
1. Click "Finish Now" button
2. **Expected:** Green snackbar "تم إنهاء المسابقة"
3. Stage should show "انتهت"
4. "النتائج النهائية" button should appear
5. Click it to see winners and prizes

### 5. Test Empty States

#### No Contestants
1. Reset Day
2. Create Contest
3. Click "عرض المتسابقين (Preview)"
4. **Expected:** Empty state with message "لا يوجد متسابقون بعد"
5. Has button "إضافة متسابقين الآن"

#### Wrong Stage
1. Reset Day
2. Create Contest (stage = preStage)
3. Try to navigate to Stage1 voting
4. **Expected:** Lock icon or disabled state

## Expected Output (Build)
When you run `flutter build web`, you should see:
```
✓ Built build/web
```

## No White Screens Test
Navigate through all screens rapidly:
1. Contests → Preview → Close
2. Contests → Stage1 (if available)
3. Contests → Top50 (if available)
4. Contests → Final Results (if available)

**Expected:** Every screen should render something (empty state, data, or error message). No blank white screens.

## Common Issues

### Issue: Contestants not showing after seeding
**Solution:** Check if contest was created first. Use "Open Full Flow" for guaranteed setup.

### Issue: Can't vote
**Possible causes:**
- Not joined contest (use DEV "Add Funds" then join)
- Contest not in stage1 (use DEV "Start Stage1")
- No contestants (use DEV "Seed 20")

### Issue: White screen
**Solution:** This should not happen with current implementation. If it does:
1. Check browser console for errors
2. Report the error with stack trace

## Build Verification

### Web Build
```bash
flutter build web
```
**Expected output line:**
```
✓ Built build/web
```

### Check Build Artifacts
```bash
ls -lh build/web/
```
**Expected:** Files like index.html, main.dart.js, flutter.js, etc.

### Run in Browser
```bash
flutter run -d chrome
```
**Expected:** Chrome opens with app running

## Success Criteria
✅ All DEV buttons work without errors
✅ "Open Full Flow" completes in under 10 seconds
✅ Preview shows 20 contestants after seeding
✅ Stage1 voting works and updates counts
✅ Top50 shows sorted list
✅ Final Results shows winners with prizes
✅ No white screens anywhere
✅ Empty states show helpful messages
✅ Build completes successfully

## Performance Notes
- "Open Full Flow" may take 5-10 seconds due to sequential async operations
- Each API call has artificial 100-300ms delay (mock simulation)
- Total flow: ~3-5 seconds for all stages

## Screenshot Checklist
Take screenshots of:
1. [ ] Contests screen with DEV buttons
2. [ ] Preview with 20 contestants
3. [ ] Stage1 voting screen
4. [ ] Top50 leaderboard
5. [ ] Final Results with winners
6. [ ] Empty state (any screen)
7. [ ] Build output showing "✓ Built build/web"

## Report Format
```
✅ Contests screen opens
✅ Open Full Flow completed in X seconds
✅ Preview shows 20 contestants
✅ Stage1 voting works
✅ Top50 shows entries
✅ Final Results shows Top5
✅ No white screens
✅ Build: ✓ Built build/web
```
