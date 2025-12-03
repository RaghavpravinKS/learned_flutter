# UI Enhancement: Minimum Hours Display and Early Validation

**Date:** November 4, 2025  
**Feature:** Display minimum hours requirement and provide early feedback in the UI

---

## Changes Made

### 1. Teacher Service Update ✅

**File:** `teacher_service.dart`

Added `minimum_monthly_hours` to the classroom query:
```dart
.select('''
  id,
  name,
  // ... other fields
  minimum_monthly_hours,  // ← ADDED
  created_at,
  updated_at
''')
```

Now classrooms include their minimum hours requirement in the data returned to the UI.

---

### 2. UI Information Display ✅

**File:** `create_session_screen.dart`

**Added after classroom dropdown:**
- Blue info box showing the minimum hours requirement
- Only displays if classroom is selected and has minimum > 0
- Example: "This classroom requires at least 12 hours per month"

**Visual Design:**
- Light blue background (`Colors.blue[50]`)
- Blue border
- Info icon
- Clear, concise message

---

### 3. Client-Side Early Warning ✅

**Added quick calculation before API call:**

```dart
// Calculates:
- Hours per session
- Sessions per week  
- Total duration
- Approximate monthly hours

// Shows warning if:
- Calculated hours < 80% of minimum
```

**Warning Snackbar:**
- Orange color (not an error, just a warning)
- Shows approximate hours: "~15.2 hrs/month"
- Shows requirement: "12 hours requirement"
- Message: "Validating..." (indicates further check coming)
- Duration: 3 seconds

---

### 4. Helper Methods Added ✅

**`_getSelectedClassroomMinimumHours()`**
- Retrieves minimum hours for currently selected classroom
- Returns 0 if no classroom selected or no minimum set
- Type-safe extraction from classroom data

**`_buildMinimumHoursInfo()`**
- Builds the blue info box widget
- Returns empty widget if minimum is 0
- Responsive layout with icon and text

---

## User Experience Flow

### Scenario 1: Sufficient Hours ✅

```
1. Teacher selects classroom
   → Blue info box appears: "Requires 12 hours per month"

2. Teacher configures:
   - Days: Mon, Wed, Fri (3 days)
   - Time: 10:00 AM - 11:30 AM (1.5 hours)
   - Duration: 30 days

3. Teacher clicks "Create"
   → No warning (18 hrs/month > 12)
   → Proceeds to validation
   → Success!
```

### Scenario 2: Borderline Hours ⚠️

```
1. Teacher selects classroom
   → Blue info box: "Requires 12 hours per month"

2. Teacher configures:
   - Days: Mon, Wed (2 days)
   - Time: 2:00 PM - 4:00 PM (2 hours)
   - Duration: 30 days

3. Teacher clicks "Create"
   → No early warning (16 hrs > 80% threshold)
   → Database validation checks exact calculation
   → Result depends on precise calculation
```

### Scenario 3: Insufficient Hours ❌

```
1. Teacher selects classroom
   → Blue info box: "Requires 12 hours per month"

2. Teacher configures:
   - Days: Tuesday only (1 day)
   - Time: 2:00 PM - 3:00 PM (1 hour)
   - Duration: 30 days

3. Teacher clicks "Create"
   → Orange warning: "~4.3 hrs/month may not meet 12 hours. Validating..."
   → Database validation runs
   → Red error dialog with detailed breakdown
   → Provides suggestions
```

---

## Visual Elements

### Blue Info Box (After Classroom Selection)
```
┌─────────────────────────────────────────┐
│ ℹ️  This classroom requires at least   │
│     12 hours per month                  │
└─────────────────────────────────────────┘
```

### Orange Warning (When Insufficient)
```
┌─────────────────────────────────────────┐
│ ⚠️  Warning: Current schedule          │
│     (~4.3 hrs/month) may not meet      │
│     the 12 hours requirement.          │
│     Validating...                       │
└─────────────────────────────────────────┘
```

### Red Error Dialog (After Validation)
```
┌─────────────────────────────────────────┐
│ ⚠️  Insufficient Session Hours         │
├─────────────────────────────────────────┤
│ This classroom requires at least        │
│ 12 hours per month.                     │
│                                          │
│ Current schedule provides:               │
│                                          │
│ Monthly Hours      4.3 hrs      ⚠️      │
│ Sessions per Week  1            ✓       │
│ Hours per Session  1.0 hrs      ✓       │
│ Duration           30 days      ✓       │
│                                          │
│ 💡 Suggestions:                         │
│ • Add more days per week                │
│ • Extend session duration               │
│ • Extend the end date                   │
├─────────────────────────────────────────┤
│              [OK, I'll Adjust]          │
└─────────────────────────────────────────┘
```

---

## Technical Details

### Calculation Method

**Client-Side (Approximate):**
```dart
hoursPerSession = (endTime - startTime) / 60
sessionsPerWeek = selectedDays.length
totalHours = hoursPerSession × sessionsPerWeek × (duration / 7)
monthlyHours = (totalHours × 30) / duration
```

**Server-Side (Precise):**
- Uses PostgreSQL date/time functions
- Accounts for exact weeks in period
- Provides exact monthly average
- Handles edge cases (leap years, etc.)

### Warning Threshold

**80% Rule:**
- Warning shows if calculated < 80% of minimum
- Prevents false positives for borderline cases
- Still validates precisely with server

**Why 80%?**
- Rounding differences between client/server
- Week calculations (28 vs 30 vs 31 days)
- Provides buffer for calculation variations

---

## Benefits

### For Teachers
✅ **Immediate Visibility** - See requirements upfront  
✅ **Early Feedback** - Warning before full validation  
✅ **Clear Guidance** - Know what's required from the start  
✅ **Better Planning** - Configure schedule with target in mind

### For Platform
✅ **Reduced Errors** - Fewer invalid submissions  
✅ **Better UX** - Progressive disclosure of requirements  
✅ **Faster Feedback** - Client-side check before API call  
✅ **Professional** - Shows platform cares about quality

---

## Testing Scenarios

### Test 1: Display Minimum Hours Info
1. Navigate to Create Session → Recurring tab
2. Select classroom dropdown
3. **Expected:** Blue info box appears below dropdown
4. **Message:** "This classroom requires at least X hours per month"

### Test 2: Early Warning (Low Hours)
1. Select classroom (12 hours minimum)
2. Configure: 1 day/week, 1 hour/session, 30 days
3. Click "Create Recurring Sessions"
4. **Expected:** Orange warning snackbar appears
5. **Message:** "~4.3 hrs/month may not meet 12 hours requirement. Validating..."
6. Then red error dialog appears with full details

### Test 3: No Warning (Sufficient Hours)
1. Select classroom (12 hours minimum)
2. Configure: 3 days/week, 1.5 hours/session, 30 days
3. Click "Create Recurring Sessions"
4. **Expected:** No orange warning
5. Proceeds directly to success or other validation

### Test 4: Classroom with No Minimum
1. Select classroom where `minimum_monthly_hours = 0`
2. **Expected:** No blue info box appears
3. No hours validation (only duration check)

---

## Files Modified

1. ✅ `lib/features/teacher/services/teacher_service.dart`
   - Added `minimum_monthly_hours` to classroom SELECT query

2. ✅ `lib/features/teacher/screens/create_session_screen.dart`
   - Added `_buildMinimumHoursInfo()` widget
   - Added `_getSelectedClassroomMinimumHours()` helper
   - Added client-side calculation and early warning
   - Integrated info box into recurring session form

3. ✅ `docs/MINIMUM_SESSION_HOURS_UI_ENHANCEMENT.md` (this file)

---

## Summary

The UI now provides:
1. **Visible Requirements** - Info box shows minimum hours after classroom selection
2. **Early Warning** - Client-side calculation alerts if clearly insufficient  
3. **Precise Validation** - Server-side check with detailed error dialog
4. **Progressive Disclosure** - Information appears when relevant

This creates a smooth, informative user experience that guides teachers to create valid recurring sessions while providing clear feedback at every step.

---

**Status:** ✅ Complete  
**No Breaking Changes:** All additions are backward compatible  
**Testing:** Required before production deployment
