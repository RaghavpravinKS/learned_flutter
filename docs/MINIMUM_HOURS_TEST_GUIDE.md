# Quick Test Guide: Minimum Session Hours Validation

## Prerequisites

1. **Apply Migration First:**
   ```bash
   # Connect to your Supabase database and run:
   psql -h YOUR_SUPABASE_HOST -U postgres -d YOUR_DATABASE \
     -f supabase/migrations/20251104_add_minimum_session_hours.sql
   ```

2. **Verify Migration:**
   ```sql
   -- Check column exists
   SELECT minimum_monthly_hours FROM classrooms LIMIT 5;
   
   -- Check trigger exists
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name = 'check_recurring_session_hours';
   ```

---

## Test Scenarios

### ✅ Test 1: Valid Session (Should Pass)

**Setup:**
1. Open app as teacher
2. Navigate to Session Management → Create Session
3. Select "Recurring Session" tab

**Steps:**
1. Select a classroom (with minimum_monthly_hours = 12)
2. Enter title: "Math Class"
3. Select days: Monday, Wednesday, Friday
4. Set time: 10:00 AM - 11:30 AM (1.5 hours)
5. Set start date: Today
6. Enable "Set end date" and set 30+ days from now
7. Click "Create Recurring Sessions"

**Expected Result:**
- ✅ Sessions created successfully
- Success message: "Recurring session created successfully! X sessions generated."

**Why it passes:**
- Duration: 30+ days ✓
- Hours: 1.5 hrs × 3 days/week × ~4 weeks = ~18 hrs/month ✓

---

### ❌ Test 2: Insufficient Hours (Should Fail)

**Setup:** Same as Test 1

**Steps:**
1. Select a classroom
2. Enter title: "Quick Review"
3. Select days: **Tuesday only** (1 day)
4. Set time: 2:00 PM - 3:00 PM (1 hour)
5. Set start date: Today
6. Set end date: 30 days from now
7. Click "Create Recurring Sessions"

**Expected Result:**
- ❌ Error dialog appears
- Title: "⚠️ Insufficient Session Hours"
- Shows:
  - "This classroom requires at least 12 hours per month"
  - "Current schedule provides: ~4.3 hours per month"
  - Sessions per week: 1
  - Hours per session: 1.0
  - Suggestions box with tips
- No sessions created

**Why it fails:**
- Hours: 1 hr × 1 day/week × ~4 weeks = ~4 hrs/month < 12 ✗

---

### ❌ Test 3: Duration Too Short (Should Fail)

**Setup:** Same as Test 1

**Steps:**
1. Select a classroom
2. Enter title: "Test Session"
3. Select days: Monday, Wednesday, Friday
4. Set time: 10:00 AM - 12:00 PM (2 hours)
5. Set start date: Today
6. Set end date: **Only 20 days from now**
7. Click "Create Recurring Sessions"

**Expected Result:**
- ❌ Red snackbar appears
- Message: "Recurring sessions must span at least 30 days (1 month). Current duration: 20 days. Please extend the end date or select 'No end date'."
- No sessions created

**Why it fails:**
- Duration: 20 days < 30 ✗

---

### ✅ Test 4: No End Date (Should Pass)

**Setup:** Same as Test 1

**Steps:**
1. Select a classroom
2. Enter title: "Ongoing Class"
3. Select days: Monday, Wednesday
4. Set time: 3:00 PM - 5:00 PM (2 hours)
5. Set start date: Today
6. **Uncheck** "Set end date" (ongoing session)
7. Click "Create Recurring Sessions"

**Expected Result:**
- ✅ Sessions created successfully
- System treats as 3+ months for validation
- Hours: 2 hrs × 2 days/week × ~4 weeks = ~16 hrs/month ✓

---

### ✅ Test 5: Just Enough Hours (Boundary Test)

**Setup:** Same as Test 1

**Steps:**
1. Select a classroom (minimum = 12 hours)
2. Select days: Monday, Wednesday, Thursday (3 days)
3. Set time: 1:00 PM - 2:00 PM (1 hour)
4. Duration: 30 days
5. Click "Create Recurring Sessions"

**Expected Result:**
- ✅ Should pass (barely)
- Hours: 1 hr × 3 days × ~4 weeks = ~12 hrs/month ✓

---

### ❌ Test 6: Just Under Minimum (Boundary Test)

**Setup:** Same as Test 1

**Steps:**
1. Select a classroom (minimum = 12 hours)
2. Select days: Monday, Wednesday (2 days only)
3. Set time: 1:00 PM - 2:30 PM (1.5 hours)
4. Duration: 30 days
5. Click "Create Recurring Sessions"

**Expected Result:**
- ❌ Should fail
- Hours: 1.5 hrs × 2 days × ~4 weeks = ~12 hrs/month (might fail due to rounding)
- Follow suggestions to add 1 more day

---

## Testing Configuration Changes

### Test 7: Zero Minimum (Validation Disabled)

**Setup:**
```sql
UPDATE classrooms 
SET minimum_monthly_hours = 0 
WHERE id = 'YOUR_CLASSROOM_ID';
```

**Steps:**
1. Create any recurring session (even 1 day/week for 1 hour)
2. Duration still must be 30+ days

**Expected Result:**
- ✅ Passes with any hours (only duration checked)

### Test 8: High Minimum

**Setup:**
```sql
UPDATE classrooms 
SET minimum_monthly_hours = 20 
WHERE id = 'YOUR_CLASSROOM_ID';
```

**Steps:**
1. Create session with 3 days × 1.5 hrs (~18 hrs/month)

**Expected Result:**
- ❌ Should fail
- Message shows "requires at least 20 hours"

---

## Verification Queries

### Check Generated Sessions
```sql
SELECT 
  rs.title,
  rs.recurrence_days,
  rs.start_time,
  rs.end_time,
  COUNT(cs.id) as sessions_generated
FROM recurring_sessions rs
LEFT JOIN class_sessions cs ON cs.recurring_session_id = rs.id
GROUP BY rs.id, rs.title, rs.recurrence_days, rs.start_time, rs.end_time
ORDER BY rs.created_at DESC
LIMIT 5;
```

### Preview Before Creation
```sql
SELECT * FROM preview_recurring_session_hours(
  'YOUR_CLASSROOM_ID',
  '10:00:00'::time,
  '11:30:00'::time,
  ARRAY[1,3,5],  -- Mon, Wed, Fri
  CURRENT_DATE,
  CURRENT_DATE + interval '30 days'
);
```

---

## Expected Behavior Summary

| Test | Days/Week | Hours/Session | Duration | Minimum | Result |
|------|-----------|---------------|----------|---------|--------|
| 1    | 3         | 1.5           | 30+      | 12      | ✅ Pass |
| 2    | 1         | 1.0           | 30       | 12      | ❌ Fail (hours) |
| 3    | 3         | 2.0           | 20       | 12      | ❌ Fail (duration) |
| 4    | 2         | 2.0           | Ongoing  | 12      | ✅ Pass |
| 5    | 3         | 1.0           | 30       | 12      | ✅ Pass |
| 6    | 2         | 1.5           | 30       | 12      | ❌ Fail |
| 7    | 1         | 1.0           | 30       | 0       | ✅ Pass |
| 8    | 3         | 1.5           | 30       | 20      | ❌ Fail |

---

## UI Elements to Verify

### Error Dialog (Test 2)
- [ ] Warning icon visible
- [ ] Title: "Insufficient Session Hours"
- [ ] Shows minimum required hours
- [ ] Shows calculated hours (red with warning)
- [ ] Shows session statistics
- [ ] Orange suggestion box with 3 tips
- [ ] "OK, I'll Adjust" button

### Duration Error (Test 3)
- [ ] Red snackbar
- [ ] Clear message about 30-day minimum
- [ ] Duration in days shown
- [ ] Suggestion to extend or use "No end date"

### Success (Test 1)
- [ ] Green/default snackbar
- [ ] Shows number of sessions generated
- [ ] Navigator pops back to session list
- [ ] New sessions visible in list

---

## Troubleshooting

### "Function does not exist"
→ Run migration SQL file

### "Column does not exist"
→ Check migration applied: `\d classrooms`

### No validation happening
→ Check trigger: `SELECT * FROM information_schema.triggers WHERE trigger_name = 'check_recurring_session_hours';`

### Different results in UI vs database
→ Check preview function: Run SQL query above

---

## Success Criteria

✅ All validation tests pass/fail as expected  
✅ Error messages are clear and helpful  
✅ Suggestions are actionable  
✅ Valid sessions create successfully  
✅ Database trigger catches any bypass attempts  
✅ No crashes or unexpected behavior

---

**Testing Time:** ~15 minutes  
**Prerequisites:** Migration applied, teacher account with classrooms  
**Recommended:** Test in development environment first
