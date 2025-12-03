# Recurring Sessions Feature - Database Migration Plan

**Date:** October 27, 2025  
**Status:** Planning  
**Author:** System Design

## Overview
Adding support for recurring sessions (e.g., sessions that repeat on specific days of the week) to the LearnED platform.

---

## Migration Checkpoints

### ✅ Phase 1: Database Schema Design
- [x] Analyze current `class_sessions` table structure
- [x] Design `recurring_sessions` table
- [x] Plan relationship between recurring templates and session instances
- [x] Review and approve schema design

### ✅ Phase 2: Create Migration SQL
- [x] Create `recurring_sessions` table
- [x] Add columns to `class_sessions` table for recurring links
- [x] Create helper function to generate session instances from recurring pattern
- [x] Add RLS policies for `recurring_sessions` table
- [x] Migration file created: `supabase/migrations/20251027_add_recurring_sessions.sql`
- [ ] Test migration script on development database (NEXT STEP)

### ⬜ Phase 3: Backend Functions
- [ ] Create function: `generate_recurring_sessions(recurring_session_id)`
- [ ] Create function: `delete_recurring_series(recurring_session_id)`
- [ ] Create function: `update_recurring_series(recurring_session_id, update_future_only)`
- [ ] Add validation for recurrence patterns
- [ ] Test all functions

### ⬜ Phase 4: Flutter Models & Services
- [ ] Create `RecurringSessionModel` class
- [ ] Update `SessionModel` to include recurring fields
- [ ] Add methods in `TeacherService` for recurring sessions
- [ ] Create `RecurringSessionService` for CRUD operations
- [ ] Test service methods

### ⬜ Phase 5: UI Implementation
- [ ] Add tabs to `CreateSessionScreen` (One-Time / Recurring)
- [ ] Create recurring session form UI
- [ ] Add day-of-week multi-selector widget
- [ ] Add recurrence date range pickers
- [ ] Add session preview/summary
- [ ] Implement save logic
- [ ] Test UI flow

### ⬜ Phase 6: Edit & Delete Features
- [ ] Add "Edit Series" vs "Edit Instance" options
- [ ] Implement edit recurring series logic
- [ ] Add "Delete Series" vs "Delete Instance" options
- [ ] Update session management screen to show recurring indicators
- [ ] Test edit and delete operations

### ⬜ Phase 7: Testing & Validation
- [ ] Test recurring session creation
- [ ] Test session instance generation
- [ ] Verify student schedule displays all instances
- [ ] Test editing series vs instances
- [ ] Test deleting series vs instances
- [ ] Test edge cases (no end date, overlapping times, etc.)
- [ ] Performance testing with large recurring series

### ⬜ Phase 8: Documentation
- [ ] Update COMPLETE_SYSTEM_SPECIFICATION.md
- [ ] Document API endpoints
- [ ] Add user guide for teachers
- [ ] Update database schema documentation

---

## Database Schema Details

### New Table: `recurring_sessions`

```sql
CREATE TABLE public.recurring_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id varchar NOT NULL,
  title varchar NOT NULL,
  description text,
  session_type varchar DEFAULT 'live',
  meeting_url text,
  is_recorded boolean DEFAULT false,
  
  -- Recurrence Pattern
  recurrence_type varchar NOT NULL CHECK (recurrence_type IN ('weekly', 'daily')),
  recurrence_days integer[] NOT NULL, -- Array of day numbers: 0=Sunday, 1=Monday, ..., 6=Saturday
  start_time time NOT NULL,
  end_time time NOT NULL,
  
  -- Recurrence Bounds
  start_date date NOT NULL,
  end_date date, -- NULL means no end date (continues indefinitely)
  
  -- Metadata
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  -- Foreign Keys
  CONSTRAINT recurring_sessions_classroom_id_fkey 
    FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id) ON DELETE CASCADE
);
```

### Updates to `class_sessions` Table

```sql
-- Add new columns
ALTER TABLE public.class_sessions 
  ADD COLUMN recurring_session_id uuid,
  ADD COLUMN is_recurring_instance boolean DEFAULT false,
  ADD CONSTRAINT class_sessions_recurring_session_id_fkey 
    FOREIGN KEY (recurring_session_id) REFERENCES public.recurring_sessions(id) ON DELETE CASCADE;

-- Add index for performance
CREATE INDEX idx_class_sessions_recurring_session_id 
  ON public.class_sessions(recurring_session_id);
```

---

## Key Design Decisions

### 1. **Separate Table Approach**
- **Why:** Keeps recurring logic separate from individual session instances
- **Benefits:** 
  - No changes needed to student schedule queries
  - Individual sessions can still be edited independently
  - Easy to delete entire series or single instances

### 2. **Day-of-Week Array**
- **Format:** `integer[]` with values 0-6 (0=Sunday, 6=Saturday)
- **Example:** `{1,3,5}` = Monday, Wednesday, Friday
- **Why:** Simple to query and validate

### 3. **No End Date Option**
- **Use Case:** Ongoing weekly classes
- **Implementation:** `end_date = NULL` means continue indefinitely
- **Limit:** Backend function will generate sessions up to 1 year in advance

### 4. **Session Instance Generation**
- **Trigger:** Automatically generate instances when recurring session is created
- **Regeneration:** If recurring session is updated, delete future instances and regenerate
- **Performance:** Generate in batches, limit to reasonable timeframe

---

## RLS Policies Required

```sql
-- Teachers can view their own recurring sessions
CREATE POLICY "Teachers can view recurring sessions for their classrooms"
  ON public.recurring_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can create recurring sessions
CREATE POLICY "Teachers can create recurring sessions"
  ON public.recurring_sessions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can update their recurring sessions
CREATE POLICY "Teachers can update recurring sessions"
  ON public.recurring_sessions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can delete their recurring sessions
CREATE POLICY "Teachers can delete recurring sessions"
  ON public.recurring_sessions FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );
```

---

## Backend Functions

### 1. Generate Session Instances

```sql
CREATE OR REPLACE FUNCTION generate_recurring_sessions(
  p_recurring_session_id uuid,
  p_months_ahead integer DEFAULT 3
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recurring_session recurring_sessions%ROWTYPE;
  v_current_date date;
  v_end_date date;
  v_day_of_week integer;
  v_sessions_created integer := 0;
BEGIN
  -- Get recurring session details
  SELECT * INTO v_recurring_session
  FROM recurring_sessions
  WHERE id = p_recurring_session_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Recurring session not found';
  END IF;
  
  -- Set end date (either specified or months_ahead)
  v_end_date := COALESCE(
    v_recurring_session.end_date, 
    v_recurring_session.start_date + (p_months_ahead || ' months')::interval
  );
  
  -- Loop through dates
  v_current_date := v_recurring_session.start_date;
  
  WHILE v_current_date <= v_end_date LOOP
    -- Get day of week (0=Sunday, 6=Saturday)
    v_day_of_week := EXTRACT(DOW FROM v_current_date);
    
    -- Check if this day is in the recurrence pattern
    IF v_day_of_week = ANY(v_recurring_session.recurrence_days) THEN
      -- Create session instance
      INSERT INTO class_sessions (
        classroom_id,
        title,
        description,
        session_date,
        start_time,
        end_time,
        session_type,
        meeting_url,
        is_recorded,
        recurring_session_id,
        is_recurring_instance,
        status
      ) VALUES (
        v_recurring_session.classroom_id,
        v_recurring_session.title,
        v_recurring_session.description,
        v_current_date,
        v_recurring_session.start_time,
        v_recurring_session.end_time,
        v_recurring_session.session_type,
        v_recurring_session.meeting_url,
        v_recurring_session.is_recorded,
        p_recurring_session_id,
        true,
        'scheduled'
      )
      ON CONFLICT DO NOTHING; -- Avoid duplicates
      
      v_sessions_created := v_sessions_created + 1;
    END IF;
    
    -- Move to next day
    v_current_date := v_current_date + interval '1 day';
  END LOOP;
  
  RETURN v_sessions_created;
END;
$$;
```

### 2. Delete Recurring Series

```sql
CREATE OR REPLACE FUNCTION delete_recurring_series(
  p_recurring_session_id uuid,
  p_delete_future_only boolean DEFAULT false,
  p_from_date date DEFAULT CURRENT_DATE
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sessions_deleted integer;
BEGIN
  IF p_delete_future_only THEN
    -- Delete only future instances
    DELETE FROM class_sessions
    WHERE recurring_session_id = p_recurring_session_id
    AND session_date >= p_from_date
    AND is_recurring_instance = true;
    
    GET DIAGNOSTICS v_sessions_deleted = ROW_COUNT;
  ELSE
    -- Delete all instances and the recurring session
    DELETE FROM class_sessions
    WHERE recurring_session_id = p_recurring_session_id;
    
    GET DIAGNOSTICS v_sessions_deleted = ROW_COUNT;
    
    DELETE FROM recurring_sessions
    WHERE id = p_recurring_session_id;
  END IF;
  
  RETURN v_sessions_deleted;
END;
$$;
```

---

## UI Components Needed

### 1. Recurring Session Form Fields
- Tab selector (One-Time / Recurring)
- Day selector (Multi-select checkboxes)
- Start date picker
- End date picker (optional)
- Time pickers
- Preview list of generated sessions

### 2. Session Management Updates
- Badge/indicator for recurring sessions
- "Edit Series" button
- "Delete Series" button
- Warning dialogs for bulk operations

---

## Testing Scenarios

1. **Create weekly recurring session** (Mon, Wed, Fri for 3 months)
2. **Create recurring session with no end date**
3. **Edit recurring series** - change time
4. **Edit single instance** - change title
5. **Delete recurring series**
6. **Delete single instance from series**
7. **Verify student sees all instances** in schedule
8. **Test overlapping recurring sessions** (same classroom, different times)
9. **Test recurrence across month/year boundaries**
10. **Test performance** with 100+ sessions generated

---

## Rollback Plan

If issues arise:
1. Drop new columns from `class_sessions`
2. Drop `recurring_sessions` table
3. Drop helper functions
4. Restore from backup if data corruption occurs

---

## Next Steps

1. ✅ Review this migration plan
2. ⬜ Create SQL migration file
3. ⬜ Test migration on development database
4. ⬜ Proceed with Flutter model updates
5. ⬜ Implement UI components

---

## Notes

- Recurring sessions will be limited to **weekly** recurrence initially
- Future enhancement: Monthly recurrence (e.g., "First Monday of every month")
- Consider adding notification when new session instances are generated
- May need cron job to auto-generate sessions for ongoing recurring patterns
