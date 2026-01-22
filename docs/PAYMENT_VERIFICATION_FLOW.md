# Payment Verification and Enrollment Flow

## Overview
This document explains the complete flow from payment submission to student enrollment after admin verification.

## 📋 Current Implementation

### 1. Payment Submission Flow
```
Student → Selects Classroom → Makes Payment → Uploads Proof → Status: PENDING
```

**UI Components:**
- `payment_screen.dart` - Payment submission with UPI/Bank transfer
- `payment_history_screen.dart` - View all payment history
- `classroom_detail_screen.dart` - Shows pending payment status

### 2. Admin Verification (Backend Required)
```
Admin Panel → Views Pending Payment → Verifies Proof → Updates Status: COMPLETED
```

**Database Changes Needed:**
When payment status changes from `pending` to `completed`, the following should happen automatically via **Supabase Database Trigger** or **Edge Function**:

```sql
-- Example trigger logic (to be implemented in Supabase)
CREATE OR REPLACE FUNCTION handle_payment_verification()
RETURNS TRIGGER AS $$
BEGIN
  -- When payment is marked as completed
  IF NEW.status = 'completed' AND OLD.status = 'pending' THEN
    
    -- 1. Create enrollment record
    INSERT INTO student_enrollments (
      student_id,
      classroom_id,
      payment_plan_id,
      enrollment_date,
      status,
      subscription_start_date,
      subscription_end_date
    )
    VALUES (
      NEW.student_id,
      NEW.classroom_id,
      NEW.payment_plan_id,
      NOW(),
      'active',
      NOW(),
      NEW.expire_at  -- Set by admin during verification
    )
    ON CONFLICT (student_id, classroom_id) 
    DO UPDATE SET
      status = 'active',
      subscription_end_date = NEW.expire_at;
    
    -- 2. Optionally send notification to student
    -- (implement notification logic here)
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to payments table
CREATE TRIGGER payment_verification_trigger
  AFTER UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION handle_payment_verification();
```

### 3. Student Enrollment Flow (Automatic)
```
Payment Status: COMPLETED → Trigger Creates Enrollment → Student Can Access Classroom
```

## 🎨 UI Changes Implemented

### New Provider: `enrollmentDetailsProvider`
**File:** `classroom_provider.dart`

Fetches enrollment details including:
- Subscription expiry date (`expire_at`)
- Payment plan information
- Enrollment status

```dart
final enrollmentDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((
  ref,
  classroomId,
) async {
  // Fetches from student_enrollments or payments table
  // Returns enrollment data with expire_at field
});
```

### Subscription Status Card
**File:** `classroom_home_screen.dart`

**Features:**
- ✅ Displays subscription expiry date
- ✅ Color-coded status (Active, Expiring Soon, Expired)
- ✅ Days remaining countdown
- ✅ Renewal button (when expiring soon)
- ✅ Payment plan information

**Status Colors:**
| Status | Days Remaining | Color | Icon |
|--------|---------------|-------|------|
| Active | > 30 days | Green | ✓ Check Circle |
| Active | 8-30 days | Yellow | ⏰ Schedule |
| Expiring Soon | 1-7 days | Orange | ⚠️ Warning |
| Expired | < 0 days | Red | ❌ Error |

## 🔄 Complete User Journey

### Scenario 1: New Enrollment
1. **Student** browses classrooms in `classroom_list_screen.dart`
2. **Student** views details in `classroom_detail_screen.dart`
3. **Student** clicks "Enroll Now" → redirected to `payment_screen.dart`
4. **Student** submits payment with proof → status set to `pending`
5. **UI shows**: Orange "Pending Payment" card in `classroom_detail_screen.dart`
6. **Admin** verifies payment → changes status to `completed` + sets `expire_at`
7. **Backend Trigger**: Creates enrollment in `student_enrollments` table
8. **UI updates automatically**: 
   - `enrolledClassroomsProvider` refreshes
   - `studentEnrollmentStatusProvider` returns `true`
   - Student can now access `classroom_home_screen.dart`
9. **Subscription card** displays expiry date and status

### Scenario 2: Checking Enrolled Classrooms
**File:** `classroom_list_screen.dart` (or enrolled view)
- Provider: `enrolledClassroomsProvider`
- Automatically filters classrooms where student has active enrollment
- Shows only classrooms with `student_enrollments.status = 'active'`

### Scenario 3: Accessing Classroom
**File:** `classroom_home_screen.dart`
- Shows subscription status card at top
- Displays expiry date prominently
- Access granted only if enrolled

## 🎯 UI Checks Already in Place

### 1. Enrollment Status Check
```dart
// classroom_provider.dart
final studentEnrollmentStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, classroomId) async {
  final enrolledClassrooms = await service.getEnrolledClassrooms(null);
  return enrolledClassrooms.any((classroom) => classroom['id'] == classroomId);
});
```

**Used in:**
- `classroom_detail_screen.dart` - Shows 3 states:
  1. ✅ Enrolled (green card with "Go to Classroom" button)
  2. ⏳ Pending Payment (orange card with proof preview)
  3. ➕ Not Enrolled (white card with "Enroll Now" button)

### 2. Enrolled Classrooms Filter
```dart
// classroom_provider.dart
final enrolledClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return service.getEnrolledClassrooms(null);
});
```

**Used in:**
- Dashboard "My Classes" section
- Any enrolled classrooms list view

### 3. Pending Payment Check
```dart
// classroom_provider.dart
final pendingPaymentForClassroomProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, classroomId) async {
  // Returns pending payment if exists
});
```

**Used in:**
- `classroom_detail_screen.dart` - Shows pending payment details with proof

## 📊 Database Schema Requirements

### Tables Involved

#### 1. `payments`
```sql
- id (UUID)
- student_id (FK)
- classroom_id (FK)
- payment_plan_id (FK)
- amount (DECIMAL)
- currency (VARCHAR) -- 'INR'
- payment_method (VARCHAR) -- 'upi' or 'bank_transfer'
- status (VARCHAR) -- 'pending', 'completed', 'failed'
- payment_proof_path (TEXT) -- Storage path
- expire_at (TIMESTAMPTZ) -- Set by admin
- remarks (TEXT) -- Admin remarks
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)
```

#### 2. `student_enrollments`
```sql
- id (UUID)
- student_id (FK)
- classroom_id (FK)
- payment_plan_id (FK)
- enrollment_date (TIMESTAMPTZ)
- status (VARCHAR) -- 'active', 'inactive', 'expired'
- subscription_start_date (TIMESTAMPTZ)
- subscription_end_date (TIMESTAMPTZ) -- From payments.expire_at
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)
```

## 🛠️ Backend TODO

### Required Implementation
1. **Database Trigger** (RECOMMENDED)
   - Trigger on `payments` table
   - Watches for status changes from `pending` to `completed`
   - Automatically creates/updates `student_enrollments` record
   - Copies `expire_at` to `subscription_end_date`

2. **Alternative: Edge Function**
   - Create Supabase Edge Function
   - Call from admin panel when verifying payment
   - Handles enrollment creation
   - Sends notification to student

### Example Edge Function (TypeScript)
```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { paymentId, status, expireAt } = await req.json()
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  // Update payment
  const { data: payment } = await supabase
    .from('payments')
    .update({ status, expire_at: expireAt })
    .eq('id', paymentId)
    .select()
    .single()
  
  if (status === 'completed') {
    // Create enrollment
    await supabase
      .from('student_enrollments')
      .upsert({
        student_id: payment.student_id,
        classroom_id: payment.classroom_id,
        payment_plan_id: payment.payment_plan_id,
        enrollment_date: new Date().toISOString(),
        status: 'active',
        subscription_start_date: new Date().toISOString(),
        subscription_end_date: expireAt
      })
  }
  
  return new Response(JSON.stringify({ success: true }))
})
```

## 🔍 UI Behavior Summary

| User Action | UI Component | Provider Used | Backend Required |
|-------------|-------------|---------------|------------------|
| Browse classrooms | `classroom_list_screen` | `allClassroomsProvider` | ✅ Query classrooms |
| View enrolled classes | My Classes section | `enrolledClassroomsProvider` | ✅ Query enrollments |
| Check enrollment status | `classroom_detail_screen` | `studentEnrollmentStatusProvider` | ✅ Check enrollment |
| View pending payment | `classroom_detail_screen` | `pendingPaymentForClassroomProvider` | ✅ Query payments |
| Access classroom | `classroom_home_screen` | `enrollmentDetailsProvider` | ✅ Query enrollment + expiry |
| View subscription expiry | Subscription card | `enrollmentDetailsProvider` | ✅ Query expire_at |
| Pay for classroom | `payment_screen` | `PaymentService` | ✅ Create payment |
| View payment history | `payment_history_screen` | `paymentHistoryProvider` | ✅ Query payments |

## ✅ What's Already Handled in UI

1. **Enrollment Detection**: `studentEnrollmentStatusProvider` checks if student is enrolled
2. **State-based UI**: `classroom_detail_screen` shows 3 different states
3. **Enrolled List**: `enrolledClassroomsProvider` fetches only enrolled classrooms
4. **Pending Payments**: `pendingPaymentForClassroomProvider` shows pending status
5. **Subscription Display**: `enrollmentDetailsProvider` + subscription card show expiry
6. **Access Control**: `classroom_home_screen` accessible only to enrolled students
7. **Payment History**: Full payment tracking with status and proofs

## 🚀 Next Steps

1. **Implement Backend Trigger/Function** (CRITICAL)
   - Creates enrollment when payment is verified
   - Copies expiry date from payment to enrollment
   
2. **Test Flow End-to-End**
   - Submit payment
   - Verify as admin
   - Check enrollment is created
   - Verify student can access classroom
   - Confirm expiry date displays correctly

3. **Add Renewal Flow** (Future)
   - Renew button functionality
   - Navigate to payment screen with renewal action
   - Handle subscription extensions

## 📝 Notes

- The UI is fully reactive and will update automatically when data changes
- All providers use `.autoDispose` for proper cleanup
- Subscription card only shows when enrollment data with `expire_at` exists
- The backend trigger is the recommended approach for production
- Consider adding email notifications when enrollment is activated
