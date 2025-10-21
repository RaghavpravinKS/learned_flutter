# RLS Investigation Guide - Systematic Debugging

## Current State
- ✅ RLS is DISABLED on assignments and class_sessions
- ✅ GRANT permissions are in place (anon, authenticated roles)
- ✅ App is WORKING (showing assignments and sessions)

## Investigation Process

### 🔍 STEP 1: Enable RLS without policies
**File:** `rls_investigation_step1.sql`

**What it tests:** Whether RLS itself (without policies) causes issues

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: RLS is fine, the problem was our policy logic
- ❌ **FAILS**: RLS + Supabase Flutter has a fundamental compatibility issue

**Action if FAILS:** Report to Supabase support. May need to use application-layer security instead.

---

### 🔍 STEP 2: Add permissive "allow all" policy
**File:** `rls_investigation_step2.sql`

**Prerequisites:** Step 1 must WORK

**What it tests:** Whether basic policies work at all

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: Basic policies are fine, we can add restrictions
- ❌ **FAILS**: Supabase has issues evaluating ANY policy

**Action if FAILS:** This would be very unusual. Check Supabase project settings or contact support.

---

### 🔍 STEP 3: Add auth-based policy
**File:** `rls_investigation_step3.sql`

**Prerequisites:** Step 2 must WORK

**What it tests:** Whether `auth.uid()` function works in policies

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: `auth.uid()` is available and working
- ❌ **FAILS**: Auth context not available in RLS policies (very rare)

**Action if FAILS:** Contact Supabase support. This is a critical auth infrastructure issue.

---

### 🔍 STEP 4: Add teacher-specific policy with subqueries
**File:** `rls_investigation_step4.sql`

**Prerequisites:** Step 3 must WORK

**What it tests:** Whether subquery pattern works

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: Subquery pattern is the solution! Use this for all teacher policies.
- ❌ **FAILS**: Subquery pattern has issues, need to try alternatives

**Action if WORKS:** This is what we want! Document this pattern and apply to all tables.

---

### 🔍 STEP 5: Alternative EXISTS with JOIN pattern
**File:** `rls_investigation_step5.sql`

**Prerequisites:** Step 4 must FAIL

**What it tests:** Whether EXISTS + INNER JOIN works better than IN + subquery

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: EXISTS pattern is better for Supabase Flutter
- ❌ **FAILS**: The JOIN itself might be problematic

**Action if WORKS:** Use EXISTS pattern for all policies instead of IN.

---

### 🔍 STEP 6: Security definer functions
**File:** `rls_investigation_step6.sql`

**Prerequisites:** Step 5 must FAIL

**What it tests:** Whether wrapping logic in SECURITY DEFINER functions helps

**Run the script, then test your app**

**Expected Results:**
- ✅ **WORKS**: Function approach is the solution! Apply pattern to all tables.
- ❌ **FAILS**: Deep Supabase configuration issue. Check project settings.

**Action if WORKS:** Create helper functions for all permission checks.

---

## Testing Checklist

After running each script:

1. ✅ Check that script executed without errors in Supabase SQL Editor
2. ✅ **Hot restart your Flutter app** (not just hot reload)
3. ✅ Navigate to the classroom detail screen
4. ✅ Check if assignments appear in "Active Assignments" section
5. ✅ Check if sessions appear in "Upcoming Sessions" section
6. ✅ Check Android/Flutter logs for any PostgrestException errors

## Recording Results

For each step, record:
- ✅/❌ Did it WORK or FAIL?
- Any error messages from Flutter console
- Any unexpected behavior

## Next Steps After Investigation

Once we identify which step works:
1. Apply the same pattern to ALL tables that need RLS
2. Add INSERT, UPDATE, DELETE policies (not just SELECT)
3. Add student-specific policies for student tables
4. Document the working pattern for future reference

## Important Notes

- Each step builds on the previous one
- Don't skip steps - they isolate different issues
- Hot restart app between tests (hot reload might not refresh auth)
- Check both visual UI and Flutter console logs

---

## Quick Commands

```sql
-- To reset back to no RLS (if you need to start over)
ALTER TABLE public.assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions DISABLE ROW LEVEL SECURITY;

-- To drop all policies
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies 
              WHERE tablename IN ('assignments', 'class_sessions')) 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) 
                || ' ON public.' || quote_ident(r.tablename);
    END LOOP;
END $$;
```

---

**Start with Step 1 and report back the results!** 🚀
