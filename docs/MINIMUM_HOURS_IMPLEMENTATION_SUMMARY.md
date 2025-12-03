# Implementation Summary: Minimum Session Hours Validation

**Date:** November 4, 2025  
**Feature:** Enforce minimum monthly session hours for recurring classroom sessions

---

## What Was Implemented

### 1. Database Changes ✅

**New Migration File:** `20251104_add_minimum_session_hours.sql`

- **Added Column:** `classrooms.minimum_monthly_hours`
  - Type: `numeric`
  - Default: `12 hours`
  - Constraint: Must be >= 0

- **Created Functions:**
  1. `calculate_recurring_session_monthly_hours()` - Calculates average monthly hours
  2. `validate_recurring_session_hours()` - Trigger function for validation
  3. `preview_recurring_session_hours()` - UI helper for pre-validation

- **Created Trigger:** `check_recurring_session_hours`
  - Fires on INSERT/UPDATE to `recurring_sessions` table
  - Validates minimum duration (30 days) and hours requirements

### 2. Service Layer Changes ✅

**File:** `recurring_session_service.dart`

- Added `previewRecurringSessionHours()` method
- Calls database RPC function
- Returns validation data including:
  - Minimum required hours
  - Calculated monthly hours
  - Validation status
  - Session statistics

**File:** `teacher_service.dart`

- Added wrapper method `previewRecurringSessionHours()`
- Delegates to `RecurringSessionService`

### 3. UI Changes ✅

**File:** `create_session_screen.dart`

- **Enhanced `_saveRecurringSession()` method:**
  - Added pre-submission validation
  - Calls preview function before creating session
  - Validates minimum duration (30 days)
  - Validates minimum hours requirement
  
- **Added validation feedback:**
  - Duration error: Snackbar with clear message
  - Hours error: Detailed dialog with:
    - Current vs. required hours
    - Session statistics
    - Helpful suggestions
    
- **Added helper widget:**
  - `_buildValidationInfo()` - Displays validation metrics

---

## Key Features

### ✅ Minimum Duration Enforcement
- Recurring sessions must span **at least 30 days (1 month)**
- Ensures proper monthly calculation
- Clear error message with suggestions

### ✅ Minimum Hours Enforcement
- Each classroom has configurable minimum monthly hours (default: 12)
- Calculated based on:
  - Hours per session
  - Sessions per week
  - Total duration
- Average monthly hours must meet requirement

### ✅ User-Friendly Validation
- **Before creation:** Preview shows if schedule is valid
- **Clear errors:** Detailed explanations when validation fails
- **Helpful suggestions:** 
  - Add more days per week
  - Extend session duration
  - Extend end date

### ✅ Database-Level Protection
- Trigger enforces rules even if UI bypassed
- Consistent validation across all clients
- Prevents invalid data entry

---

## User Experience Flow

```
Teacher fills form
      ↓
Clicks "Create Recurring Sessions"
      ↓
System validates duration (>= 30 days)
      ↓ (if fails)
      Shows error snackbar
      ↓ (if passes)
System validates hours requirement
      ↓ (if fails)
      Shows detailed dialog with suggestions
      ↓ (if passes)
Creates recurring session
      ↓
Generates session instances
      ↓
Shows success message
```

---

## Validation Logic

### Monthly Hours Calculation

```
Hours per session = end_time - start_time
Sessions per week = count(selected days)
Total weeks = duration / 7
Total hours = hours_per_session × sessions_per_week × total_weeks
Monthly average = (total_hours × 30) / duration_days
```

### Example

**Input:**
- Days: Mon, Wed, Fri (3 days)
- Time: 10:00 AM - 11:30 AM (1.5 hours)
- Duration: 30 days
- Required: 12 hours/month

**Calculation:**
```
1.5 hours × 3 days × (30/7 weeks) = 19.3 hours/month
19.3 >= 12 ✅ Valid
```

---

## Configuration

### Setting Minimum Hours for a Classroom

```sql
UPDATE public.classrooms 
SET minimum_monthly_hours = 15 
WHERE id = 'MATH_12_CBSE';
```

### Disabling Validation

```sql
UPDATE public.classrooms 
SET minimum_monthly_hours = 0 
WHERE id = 'OPTIONAL_WORKSHOP';
```

---

## Files Modified

1. ✅ `supabase/migrations/20251104_add_minimum_session_hours.sql` (NEW)
2. ✅ `lib/features/teacher/services/recurring_session_service.dart`
3. ✅ `lib/features/teacher/services/teacher_service.dart`
4. ✅ `lib/features/teacher/screens/create_session_screen.dart`
5. ✅ `docs/MINIMUM_SESSION_HOURS_VALIDATION.md` (NEW)
6. ✅ `docs/MINIMUM_HOURS_IMPLEMENTATION_SUMMARY.md` (NEW - this file)

---

## Next Steps

### To Deploy:

1. **Run Migration:**
   ```bash
   # Apply to your Supabase database
   psql -h YOUR_HOST -U postgres -d learned_db \
     -f supabase/migrations/20251104_add_minimum_session_hours.sql
   ```

2. **Update Existing Classrooms:**
   ```sql
   -- Set appropriate minimum hours for each classroom
   UPDATE classrooms 
   SET minimum_monthly_hours = 12 
   WHERE minimum_monthly_hours IS NULL OR minimum_monthly_hours = 0;
   ```

3. **Test the Feature:**
   - Try creating recurring session with insufficient hours
   - Verify error dialog appears
   - Follow suggestions and retry
   - Confirm successful creation when valid

### To Test:

**Test Case 1: Valid Session**
- Days: Mon, Wed, Fri
- Time: 2 hours each
- Duration: 30+ days
- Expected: Success ✅

**Test Case 2: Too Few Hours**
- Days: Tuesday only
- Time: 1 hour
- Duration: 30 days
- Expected: Error dialog with suggestions ❌

**Test Case 3: Too Short Duration**
- Days: Mon, Wed, Fri
- Time: 2 hours each
- Duration: 20 days
- Expected: Duration error ❌

**Test Case 4: No End Date**
- Days: Mon, Wed, Fri
- Time: 2 hours each
- No end date (ongoing)
- Expected: Treated as 3+ months, should pass ✅

---

## Benefits Delivered

### For Platform Quality
- ✅ Ensures consistent educational standards
- ✅ Prevents under-committed classrooms
- ✅ Maintains minimum instruction time
- ✅ Professional course delivery

### For Teachers
- ✅ Clear scheduling requirements
- ✅ Immediate validation feedback
- ✅ Helpful error messages
- ✅ Prevents wasted effort

### For Students
- ✅ Guaranteed minimum instruction hours
- ✅ Better learning outcomes
- ✅ Value for enrollment fees
- ✅ Predictable schedules

---

## Technical Highlights

### Backend (PostgreSQL)
- ✅ Pure SQL validation logic
- ✅ Database trigger protection
- ✅ Helper function for UI preview
- ✅ Efficient calculations

### Flutter (Dart)
- ✅ Clean service architecture
- ✅ Async validation flow
- ✅ User-friendly error handling
- ✅ Helpful UI feedback

### Integration
- ✅ Seamless end-to-end flow
- ✅ Consistent validation rules
- ✅ Type-safe Flutter implementation
- ✅ Database-enforced constraints

---

## Known Limitations

1. **Fixed Monthly Calculation:** Uses 30-day month approximation
2. **Weekly Only:** Currently only validates weekly recurrences (daily support planned)
3. **No Holiday Adjustment:** Doesn't account for breaks or holidays
4. **Single Minimum:** One minimum per classroom (can't vary by season)

### Future Enhancements
- [ ] Per-day time validation for custom times
- [ ] Holiday/break exclusions
- [ ] Seasonal minimums
- [ ] Subject-specific defaults
- [ ] Analytics dashboard
- [ ] Warning thresholds (90% of minimum)

---

## Support

### Common Issues

**Q: "Why is my 3-week session rejected?"**  
A: Minimum duration is 30 days (1 month) to ensure proper monthly calculation.

**Q: "Can I disable validation for optional workshops?"**  
A: Yes, set `minimum_monthly_hours = 0` for that classroom.

**Q: "How do I change the minimum for a classroom?"**  
A: Use SQL update or wait for admin panel feature.

**Q: "What if I need to schedule less than the minimum?"**  
A: Add more days, extend session duration, or contact admin to adjust classroom minimum.

---

## Conclusion

This feature successfully implements comprehensive validation for recurring session hours, ensuring educational quality while providing excellent user experience through clear feedback and helpful suggestions. The implementation spans database, service layer, and UI, with proper error handling and user guidance at each step.

**Status:** ✅ Ready for Production  
**Testing:** Required before deployment  
**Documentation:** Complete

---

**Implemented by:** GitHub Copilot  
**Date:** November 4, 2025  
**Version:** 1.0
