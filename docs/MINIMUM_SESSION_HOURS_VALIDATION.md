# Minimum Session Hours Validation Implementation

**Date:** November 4, 2025  
**Feature:** Enforce minimum monthly session hours for classrooms with recurring sessions

---

## Overview

This feature ensures that when teachers create recurring sessions for a classroom, they must meet a minimum monthly hours requirement. This guarantees consistent educational delivery and prevents under-scheduling.

## Key Requirements

### 1. **Minimum Monthly Hours**
- Each classroom has a `minimum_monthly_hours` field (default: 12 hours)
- Teachers/admins can configure this value per classroom
- Validation enforces this requirement during recurring session creation

### 2. **Minimum Duration**
- Recurring sessions must span **at least 30 days (1 month)**
- This ensures proper monthly hour calculation
- Prevents short-term recurring patterns that don't represent true monthly commitment

### 3. **Validation Points**
- **Before creation**: Preview validation shows calculated hours
- **During creation**: Database trigger enforces minimum requirements
- **User feedback**: Clear error messages with suggestions for improvement

---

## Database Changes

### New Column: `classrooms.minimum_monthly_hours`

```sql
ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS minimum_monthly_hours numeric DEFAULT 0 
CHECK (minimum_monthly_hours >= 0);
```

- **Type:** `numeric`
- **Default:** `12` hours (updated for existing classrooms)
- **Constraint:** Must be >= 0

### New Functions

#### 1. `calculate_recurring_session_monthly_hours()`
Calculates average monthly hours based on session pattern:

**Inputs:**
- `p_start_time`: Session start time
- `p_end_time`: Session end time
- `p_recurrence_days`: Array of days (0=Sun, 6=Sat)
- `p_start_date`: Pattern start date
- `p_end_date`: Pattern end date

**Logic:**
```
Hours per session = (end_time - start_time) in hours
Sessions per week = count(recurrence_days)
Total weeks = duration / 7
Total hours = hours_per_session × sessions_per_week × total_weeks
Monthly average = (total_hours × 30) / duration_days
```

**Returns:** Average monthly hours

#### 2. `validate_recurring_session_hours()` (Trigger Function)
Automatically validates recurring sessions on INSERT/UPDATE:

**Validation Steps:**
1. Get classroom's `minimum_monthly_hours`
2. Check duration >= 30 days
3. Calculate monthly hours
4. Compare against minimum requirement
5. Raise exception if validation fails

**Error Messages:**
- Duration < 30 days: "Recurring sessions must span at least 30 days (1 month)"
- Hours insufficient: "Insufficient session hours. This classroom requires at least X hours per month, but the current schedule provides only Y hours per month"

#### 3. `preview_recurring_session_hours()` (UI Helper)
Provides validation preview before creation:

**Inputs:** Same as calculate function + classroom_id

**Returns Table:**
- `minimum_required_hours`: Classroom requirement
- `calculated_monthly_hours`: Calculated hours for pattern
- `is_valid`: Boolean validation result
- `sessions_per_week`: Number of sessions per week
- `hours_per_session`: Duration of each session
- `total_duration_days`: Total pattern duration

---

## Flutter Implementation

### Service Layer

#### `RecurringSessionService.previewRecurringSessionHours()`

```dart
Future<Map<String, dynamic>> previewRecurringSessionHours({
  required String classroomId,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required List<int> recurrenceDays,
  required DateTime startDate,
  DateTime? endDate,
}) async {
  // Calls preview_recurring_session_hours() RPC
  // Returns validation data
}
```

#### `TeacherService.previewRecurringSessionHours()`
Wrapper that delegates to `RecurringSessionService`

### UI Layer

#### `CreateSessionScreen` Changes

**New Validation Flow:**

1. **Before Submitting:**
   - User fills out recurring session form
   - Clicks "Create Recurring Sessions"

2. **Validation Phase:**
   ```dart
   // Calculate effective end date
   final effectiveEndDate = _hasEndDate && _recurringEndDate != null
       ? _recurringEndDate!
       : _recurringStartDate!.add(Duration(days: 30 * _monthsAhead));

   // Preview validation
   final validation = await teacherService.previewRecurringSessionHours(
     classroomId: _recurringClassroomId!,
     startTime: validationStartTime,
     endTime: validationEndTime,
     recurrenceDays: _selectedDays.toList(),
     startDate: _recurringStartDate!,
     endDate: effectiveEndDate,
   );
   ```

3. **Duration Check:**
   - If `totalDurationDays < 30`: Show error snackbar
   - Prompt user to extend end date or select "No end date"

4. **Hours Check:**
   - If `!isValid`: Show detailed error dialog
   - Display:
     - Minimum required hours
     - Calculated monthly hours
     - Sessions per week
     - Hours per session
     - Total duration
     - Suggestions for improvement

**Error Dialog Example:**

```
┌─────────────────────────────────────┐
│ ⚠️  Insufficient Session Hours      │
├─────────────────────────────────────┤
│ This classroom requires at least    │
│ 12 hours per month.                 │
│                                     │
│ Current schedule provides:          │
│ Monthly Hours:      8.5 hrs  ⚠️     │
│ Sessions per Week:  2               │
│ Hours per Session:  1.0 hrs         │
│ Duration:           30 days         │
│                                     │
│ 💡 Suggestions:                     │
│ • Add more days per week            │
│ • Extend session duration           │
│ • Extend the end date               │
└─────────────────────────────────────┘
```

---

## User Flow

### Teacher Creates Recurring Session

1. **Navigate:** Session Management → Create Session → Recurring tab

2. **Fill Form:**
   - Select classroom
   - Enter title and description
   - Select days of week (e.g., Mon, Wed, Fri)
   - Set start and end times
   - Choose start date
   - Optionally set end date (or "No end date")

3. **Submit:**
   - Click "Create Recurring Sessions"

4. **Validation:**
   - **Pass:** Sessions created, success message shown
   - **Fail (Duration):** Error snackbar, prompt to extend
   - **Fail (Hours):** Detailed dialog with suggestions

5. **Adjust & Retry:**
   - Teacher modifies schedule based on feedback
   - Resubmits until validation passes

---

## Calculation Examples

### Example 1: Valid Schedule

**Input:**
- Days: Monday, Wednesday, Friday (3 days)
- Time: 10:00 AM - 11:30 AM (1.5 hours)
- Duration: 30 days
- Minimum required: 12 hours/month

**Calculation:**
```
Hours per session = 1.5
Sessions per week = 3
Total weeks = 30 / 7 = 4.29
Total hours = 1.5 × 3 × 4.29 = 19.3
Monthly average = (19.3 × 30) / 30 = 19.3 hours
```

**Result:** ✅ Valid (19.3 >= 12)

### Example 2: Invalid Schedule

**Input:**
- Days: Tuesday (1 day)
- Time: 2:00 PM - 3:00 PM (1 hour)
- Duration: 30 days
- Minimum required: 12 hours/month

**Calculation:**
```
Hours per session = 1.0
Sessions per week = 1
Total weeks = 30 / 7 = 4.29
Total hours = 1.0 × 1 × 4.29 = 4.29
Monthly average = (4.29 × 30) / 30 = 4.29 hours
```

**Result:** ❌ Invalid (4.29 < 12)

**Suggestions:**
- Add 2 more days (3 × 4.29 = 12.87 hours ✅)
- OR extend to 2 hours per session (2 × 4.29 = 8.58, still need more days)
- OR add more days AND extend session

### Example 3: Too Short Duration

**Input:**
- Days: Monday, Wednesday, Friday
- Time: 10:00 AM - 12:00 PM (2 hours)
- Duration: **20 days**
- Minimum required: 12 hours/month

**Result:** ❌ Invalid - "Recurring sessions must span at least 30 days"

---

## Configuration

### Setting Classroom Minimum Hours

#### Option 1: SQL Update
```sql
UPDATE public.classrooms 
SET minimum_monthly_hours = 15 
WHERE id = 'MATH_12_CBSE';
```

#### Option 2: Admin Panel (Future)
- Navigate to classroom settings
- Edit "Minimum Monthly Hours" field
- Save changes

### Default Values
- New classrooms: `12 hours/month`
- Can be set to `0` to disable validation
- Recommended range: `8-20 hours/month`

---

## Benefits

### For Administrators
- ✅ Ensures consistent course delivery
- ✅ Prevents under-committed classrooms
- ✅ Maintains educational quality standards
- ✅ Provides clear metrics for scheduling

### For Teachers
- ✅ Clear guidance on scheduling requirements
- ✅ Immediate feedback during creation
- ✅ Helpful suggestions for improvement
- ✅ Prevents rejected schedules

### For Students
- ✅ Guaranteed minimum instruction time
- ✅ Consistent learning experience
- ✅ Better value for enrollment
- ✅ Predictable schedules

---

## Testing

### Test Cases

#### 1. Valid Recurring Session
- Create session meeting minimum hours
- Verify success message
- Confirm sessions generated

#### 2. Insufficient Hours
- Create session below minimum
- Verify error dialog shown
- Confirm no sessions created

#### 3. Short Duration
- Create session < 30 days
- Verify duration error
- Confirm helpful message

#### 4. No End Date
- Create ongoing session
- Verify treated as 3+ months for validation
- Confirm validation passes

#### 5. Zero Minimum
- Set classroom minimum to 0
- Create any valid session
- Verify no validation errors

### SQL Testing

```sql
-- Test preview function
SELECT * FROM preview_recurring_session_hours(
  'MATH_12_CBSE',
  '10:00:00'::time,
  '11:30:00'::time,
  ARRAY[1,3,5],  -- Mon, Wed, Fri
  '2025-01-01'::date,
  '2025-01-31'::date
);

-- Test validation directly
INSERT INTO recurring_sessions (
  classroom_id, title, recurrence_type, recurrence_days,
  start_time, end_time, start_date, end_date
) VALUES (
  'MATH_12_CBSE', 'Test Session', 'weekly', ARRAY[1,3,5],
  '10:00:00', '11:30:00', '2025-01-01', '2025-01-31'
);
-- Should succeed if >= minimum hours
```

---

## Migration Instructions

1. **Backup Database:**
   ```bash
   pg_dump -h localhost -U postgres learned_db > backup.sql
   ```

2. **Run Migration:**
   ```bash
   psql -h localhost -U postgres -d learned_db \
     -f supabase/migrations/20251104_add_minimum_session_hours.sql
   ```

3. **Verify Migration:**
   ```sql
   -- Check column exists
   SELECT column_name, data_type, column_default 
   FROM information_schema.columns 
   WHERE table_name = 'classrooms' 
     AND column_name = 'minimum_monthly_hours';
   
   -- Check trigger exists
   SELECT trigger_name, event_manipulation, event_object_table 
   FROM information_schema.triggers 
   WHERE trigger_name = 'check_recurring_session_hours';
   
   -- Check functions exist
   SELECT routine_name, routine_type 
   FROM information_schema.routines 
   WHERE routine_schema = 'public' 
     AND routine_name LIKE '%recurring_session_hours%';
   ```

4. **Update Existing Classrooms:**
   ```sql
   -- Set appropriate values for your classrooms
   UPDATE classrooms 
   SET minimum_monthly_hours = 12 
   WHERE minimum_monthly_hours = 0 OR minimum_monthly_hours IS NULL;
   ```

---

## Future Enhancements

### Planned Features
- [ ] UI to edit classroom minimum hours
- [ ] Dashboard showing compliance status
- [ ] Historical hours tracking and analytics
- [ ] Flexible validation rules (per subject/grade)
- [ ] Warning threshold (e.g., warning at 90% of minimum)
- [ ] Academic year-based validation
- [ ] Integration with payment calculations

### Considerations
- Different standards for different subjects
- Seasonal variations (summer vs. regular term)
- Makeup session allowances
- Holiday adjustments

---

## Troubleshooting

### Common Issues

#### 1. "Recurring sessions must span at least 30 days"
**Cause:** Duration between start and end date < 30 days

**Solution:**
- Extend end date by at least 30 days
- Select "No end date" option
- Adjust start date earlier

#### 2. "Insufficient session hours"
**Cause:** Calculated monthly hours < classroom minimum

**Solutions:**
- Add more days per week
- Increase session duration (extend end time)
- Extend overall duration (longer end date)

#### 3. Validation passes but database rejects
**Cause:** Database trigger has stricter validation

**Debug:**
```sql
-- Check what database calculated
SELECT * FROM preview_recurring_session_hours(
  'YOUR_CLASSROOM_ID',
  'HH:MM:SS'::time,
  'HH:MM:SS'::time,
  ARRAY[1,3,5],
  'YYYY-MM-DD'::date,
  'YYYY-MM-DD'::date
);
```

#### 4. Error: "Function does not exist"
**Cause:** Migration not applied

**Solution:**
```bash
# Re-run migration
psql -h localhost -U postgres -d learned_db \
  -f supabase/migrations/20251104_add_minimum_session_hours.sql
```

---

## API Reference

### Database Functions

#### `calculate_recurring_session_monthly_hours`
```sql
calculate_recurring_session_monthly_hours(
  p_start_time time,
  p_end_time time,
  p_recurrence_days integer[],
  p_start_date date,
  p_end_date date
) RETURNS numeric
```

#### `preview_recurring_session_hours`
```sql
preview_recurring_session_hours(
  p_classroom_id varchar,
  p_start_time time,
  p_end_time time,
  p_recurrence_days integer[],
  p_start_date date,
  p_end_date date
) RETURNS TABLE(
  minimum_required_hours numeric,
  calculated_monthly_hours numeric,
  is_valid boolean,
  sessions_per_week integer,
  hours_per_session numeric,
  total_duration_days integer
)
```

### Flutter Services

#### `RecurringSessionService`
```dart
Future<Map<String, dynamic>> previewRecurringSessionHours({
  required String classroomId,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required List<int> recurrenceDays,
  required DateTime startDate,
  DateTime? endDate,
})
```

**Returns:**
```dart
{
  'minimumRequiredHours': 12.0,
  'calculatedMonthlyHours': 19.3,
  'isValid': true,
  'sessionsPerWeek': 3,
  'hoursPerSession': 1.5,
  'totalDurationDays': 30
}
```

---

## Change Log

### Version 1.0 (November 4, 2025)
- ✅ Added `minimum_monthly_hours` column to classrooms
- ✅ Created calculation and validation functions
- ✅ Implemented database trigger
- ✅ Added Flutter service methods
- ✅ Updated UI with validation flow
- ✅ Added comprehensive error messages
- ✅ Created documentation

---

## Related Documentation

- [Recurring Sessions Feature](RECURRING_SESSIONS_MIGRATION.md)
- [Database Schema](COMPLETE_SYSTEM_SPECIFICATION.md)
- [Session Management](SESSION_MANAGEMENT_IMPLEMENTATION.md)

---

**Status:** ✅ Implemented and Ready for Testing  
**Priority:** High (Quality Assurance Feature)  
**Category:** Backend Validation, Business Logic
