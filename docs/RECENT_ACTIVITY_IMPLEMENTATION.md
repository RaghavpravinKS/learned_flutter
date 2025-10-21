# Recent Activity Feed Implementation Guide

## Current Status
✅ UI is now consistent with Quick Actions section (same padding and text styling)
✅ Placeholder data is displaying correctly

## Backend Data Strategy

Based on your current database schema, here's how to fetch real activity data:

### 1. **Assignment Graded Activities**
**Challenge:** There's no `assignment_submissions` or `grades` table in your schema yet.

**Solution Options:**
- **Option A:** Add these tables to track submissions and grades
- **Option B:** Use assignment `updated_at` field to show "New assignment available" instead

**Recommended SQL (once submission tables are added):**
```sql
-- Get recent graded assignments for a student
SELECT 
  a.title,
  a.updated_at as graded_at,
  s.grade,
  s.feedback
FROM assignment_submissions s
JOIN assignments a ON a.id = s.assignment_id
WHERE s.student_id = :student_id
  AND s.status = 'graded'
ORDER BY s.graded_at DESC
LIMIT 5;
```

### 2. **New Material Uploaded**
**Available Now!** ✅ You have the `learning_materials` table.

**SQL Query:**
```sql
-- Get recently uploaded materials for student's classrooms
SELECT 
  lm.id,
  lm.title,
  lm.material_type,
  lm.upload_date,
  lm.classroom_id,
  c.name as classroom_name
FROM learning_materials lm
JOIN classrooms c ON c.id = lm.classroom_id
JOIN student_enrollments se ON se.classroom_id = c.id
WHERE se.student_id = :student_id
  AND lm.upload_date >= NOW() - INTERVAL '7 days'
ORDER BY lm.upload_date DESC
LIMIT 10;
```

### 3. **New Assignment Added**
**Available Now!** ✅ You have the `assignments` table.

**SQL Query:**
```sql
-- Get recently published assignments for student's classrooms
SELECT 
  a.id,
  a.title,
  a.due_date,
  a.created_at,
  a.classroom_id,
  c.name as classroom_name,
  a.total_points
FROM assignments a
JOIN classrooms c ON c.id = a.classroom_id
JOIN student_enrollments se ON se.classroom_id = c.id
WHERE se.student_id = :student_id
  AND a.is_published = true
  AND a.created_at >= NOW() - INTERVAL '7 days'
ORDER BY a.created_at DESC
LIMIT 10;
```

### 4. **Classroom Posts/Announcements**
**Challenge:** No `classroom_posts` or `announcements` table exists.

**Temporary Solution:** Skip this for now, or add a simple announcements table:
```sql
CREATE TABLE public.classroom_announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id varchar NOT NULL REFERENCES classrooms(id),
  teacher_id uuid NOT NULL REFERENCES teachers(id),
  title varchar NOT NULL,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

## Implementation Steps

### Step 1: Create a Supabase Function
Create a new file: `supabase/get_student_recent_activity.sql`

```sql
CREATE OR REPLACE FUNCTION get_student_recent_activity(p_student_id uuid)
RETURNS TABLE (
  activity_id uuid,
  activity_type varchar,
  title varchar,
  description text,
  classroom_name varchar,
  created_at timestamptz,
  metadata jsonb
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  
  -- New materials
  SELECT 
    lm.id as activity_id,
    'new_material'::varchar as activity_type,
    lm.title,
    'New ' || lm.material_type || ' uploaded'::text as description,
    c.name as classroom_name,
    lm.upload_date as created_at,
    jsonb_build_object(
      'material_type', lm.material_type,
      'file_url', lm.file_url
    ) as metadata
  FROM learning_materials lm
  JOIN classrooms c ON c.id = lm.classroom_id
  JOIN student_enrollments se ON se.classroom_id = c.id
  WHERE se.student_id = p_student_id
    AND lm.upload_date >= NOW() - INTERVAL '30 days'
  
  UNION ALL
  
  -- New assignments
  SELECT 
    a.id as activity_id,
    'new_assignment'::varchar as activity_type,
    a.title,
    'Due ' || to_char(a.due_date, 'Mon DD')::text as description,
    c.name as classroom_name,
    a.created_at,
    jsonb_build_object(
      'due_date', a.due_date,
      'total_points', a.total_points,
      'assignment_type', a.assignment_type
    ) as metadata
  FROM assignments a
  JOIN classrooms c ON c.id = a.classroom_id
  JOIN student_enrollments se ON se.classroom_id = c.id
  WHERE se.student_id = p_student_id
    AND a.is_published = true
    AND a.created_at >= NOW() - INTERVAL '30 days'
  
  ORDER BY created_at DESC
  LIMIT 20;
END;
$$;
```

### Step 2: Create Flutter Service
Create: `lib/features/student/services/activity_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRecentActivity(String studentId) async {
    try {
      final response = await _supabase
          .rpc('get_student_recent_activity', params: {'p_student_id': studentId});
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching recent activity: $e');
      rethrow;
    }
  }
}
```

### Step 3: Create Provider
Create: `lib/features/student/providers/activity_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/activity_service.dart';

final activityServiceProvider = Provider((ref) => ActivityService());

final recentActivityProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(activityServiceProvider);
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user == null) {
    throw Exception('User not authenticated');
  }
  
  // Get student ID from user metadata or profile
  final studentId = user.id;
  return service.getRecentActivity(studentId);
});
```

### Step 4: Update course_progress_section.dart

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final activityAsync = ref.watch(recentActivityProvider);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Recent Activity',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 180,
        child: activityAsync.when(
          data: (activities) => activities.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(activities),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildPlaceholderActivityList(context),
        ),
      ),
    ],
  );
}

Widget _buildActivityList(List<Map<String, dynamic>> activities) {
  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: activities.length,
    itemBuilder: (context, index) {
      final activity = activities[index];
      return _buildActivityCard(
        icon: _getIconForActivityType(activity['activity_type']),
        iconColor: _getColorForActivityType(activity['activity_type']),
        title: activity['title'],
        description: '${activity['classroom_name']} • ${activity['description']}',
        time: _formatTime(DateTime.parse(activity['created_at'])),
      );
    },
  );
}

IconData _getIconForActivityType(String type) {
  switch (type) {
    case 'new_material':
      return Icons.file_present;
    case 'new_assignment':
      return Icons.assignment;
    case 'assignment_graded':
      return Icons.grade;
    case 'classroom_post':
      return Icons.announcement;
    default:
      return Icons.notifications;
  }
}

Color _getColorForActivityType(String type) {
  switch (type) {
    case 'new_material':
      return Colors.blue;
    case 'new_assignment':
      return Colors.red;
    case 'assignment_graded':
      return Colors.green;
    case 'classroom_post':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

String _formatTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
}
```

## Priority Implementation Order

1. ✅ **Phase 1 (Current):** Placeholder UI working
2. **Phase 2 (Immediate):** Fetch new materials and assignments (tables exist!)
3. **Phase 3 (Next):** Add submission/grading tables, implement graded assignments
4. **Phase 4 (Future):** Add announcements table, implement classroom posts

## Quick Win: Implement Phase 2 Now!

You can start fetching real data immediately for:
- New materials uploaded
- New assignments added

These tables already exist in your database!
