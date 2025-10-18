# 📁 Supabase Storage Setup Guide

**Date**: October 13, 2025  
**Purpose**: Complete storage configuration for LearnED MVP

---

## 🎯 **Quick Setup Checklist**

### **Phase 1: Create Storage Buckets** (5 minutes)
- [ ] Create `learning-materials` bucket
- [ ] Create `assignment-attachments` bucket  
- [ ] Create `profile-images` bucket

### **Phase 2: Configure Policies** (10 minutes)
- [ ] Apply learning materials policies
- [ ] Apply assignment attachments policies
- [ ] Apply profile images policies

### **Phase 3: Test & Validate** (5 minutes)
- [ ] Test teacher file upload
- [ ] Test student file upload
- [ ] Verify access controls

---

## 🛠️ **Step-by-Step Implementation**

### **Step 1: Create Buckets via Supabase Dashboard**

1. **Navigate to Storage** in your Supabase project
2. **Click "New Bucket"** for each bucket:

#### **Bucket 1: Learning Materials**
```
Name: learning-materials
Public: false (unchecked)
File size limit: 25 MB
Allowed MIME types: 
- application/pdf
- video/mp4
- video/webm
- image/jpeg
- image/png
- application/vnd.ms-powerpoint
- application/vnd.openxmlformats-officedocument.presentationml.presentation
- application/msword
- application/vnd.openxmlformats-officedocument.wordprocessingml.document
```

#### **Bucket 2: Assignment Attachments**
```
Name: assignment-attachments
Public: false (unchecked)
File size limit: 10 MB
Allowed MIME types:
- application/pdf
- image/jpeg
- image/png
- image/gif
- text/plain
- application/msword
- application/vnd.openxmlformats-officedocument.wordprocessingml.document
```

#### **Bucket 3: Profile Images**
```
Name: profile-images
Public: false (unchecked)
File size limit: 2 MB
Allowed MIME types:
- image/jpeg
- image/png
- image/webp
```

### **Step 2: Apply RLS Policies via SQL Editor**

Copy and paste these into your Supabase SQL Editor:

#### **Learning Materials Policies:**
```sql
-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Teachers can upload learning materials
CREATE POLICY "Teachers can upload learning materials" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials' 
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);

-- Teachers can read their own materials
CREATE POLICY "Teachers can read own materials" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);

-- Students can read materials from enrolled classrooms
CREATE POLICY "Students can read classroom materials" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[2] IN (
    SELECT se.classroom_id FROM public.student_enrollments se
    JOIN public.students s ON se.student_id = s.id
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid() AND se.status = 'active'
  )
);

-- Teachers can delete their own materials
CREATE POLICY "Teachers can delete own materials" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);
```

#### **Assignment Attachments Policies:**
```sql
-- Students can upload assignment attachments
CREATE POLICY "Students can upload assignment attachments" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT s.id::text FROM public.students s
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  )
);

-- Students can read their own attachments
CREATE POLICY "Students can read own attachments" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT s.id::text FROM public.students s
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  )
);

-- Teachers can read attachments from their assignments
CREATE POLICY "Teachers can read assignment attachments" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[2] IN (
    SELECT a.id::text FROM public.assignments a
    JOIN public.teachers t ON a.teacher_id = t.id
    JOIN public.users u ON t.user_id = u.id
    WHERE u.id = auth.uid()
  )
);
```

#### **Profile Images Policies:**
```sql
-- Users can upload their own profile images
CREATE POLICY "Users can upload own profile images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'profile-images'
  AND (
    (storage.foldername(name))[2] IN (
      SELECT t.id::text FROM public.teachers t 
      JOIN public.users u ON t.user_id = u.id 
      WHERE u.id = auth.uid()
    )
    OR (storage.foldername(name))[2] IN (
      SELECT s.id::text FROM public.students s
      JOIN public.users u ON s.user_id = u.id
      WHERE u.id = auth.uid()
    )
  )
);

-- Public read for profile images (for UI display)
CREATE POLICY "Public read profile images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'profile-images');
```

### **Step 3: Flutter Integration Example**

#### **Teacher File Upload (Learning Materials):**
```dart
Future<String?> uploadLearningMaterial({
  required File file,
  required String teacherId,
  required String classroomId,
}) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final filePath = '$teacherId/$classroomId/$fileName';
    
    await Supabase.instance.client.storage
        .from('learning-materials')
        .upload(filePath, file);
    
    final url = Supabase.instance.client.storage
        .from('learning-materials')
        .getPublicUrl(filePath);
    
    return url;
  } catch (e) {
    print('Upload error: $e');
    return null;
  }
}
```

#### **Student File Upload (Assignment Attachments):**
```dart
Future<List<String>> uploadAssignmentAttachments({
  required List<File> files,
  required String studentId,
  required String assignmentId,
}) async {
  List<String> uploadedUrls = [];
  
  for (var file in files) {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$studentId/$assignmentId/$fileName';
      
      await Supabase.instance.client.storage
          .from('assignment-attachments')
          .upload(filePath, file);
      
      final url = Supabase.instance.client.storage
          .from('assignment-attachments')
          .getPublicUrl(filePath);
      
      uploadedUrls.add(url);
    } catch (e) {
      print('Upload error for ${file.path}: $e');
    }
  }
  
  return uploadedUrls;
}
```

---

## 🎯 **Integration with Database Functions**

### **Learning Materials Flow:**
1. **Flutter**: Upload file → Get URL
2. **Database**: Call `upload_learning_material(file_url: url)`
3. **Result**: Material saved and accessible to students

### **Assignment Submission Flow:**
1. **Flutter**: Upload files → Get URLs array
2. **Database**: Call `submit_assignment_attempt(attachment_urls: urls)`
3. **Result**: Submission saved with attachments for teacher review

---

## ✅ **Testing Your Setup**

### **Test 1: Teacher Upload**
```dart
// After bucket creation, test with a dummy file
final testUrl = await uploadLearningMaterial(
  file: testFile,
  teacherId: 'your-teacher-uuid',
  classroomId: 'your-classroom-uuid',
);
print('Upload successful: $testUrl');
```

### **Test 2: Student Upload**
```dart
// Test student attachment upload
final attachmentUrls = await uploadAssignmentAttachments(
  files: [testFile],
  studentId: 'your-student-uuid',
  assignmentId: 'your-assignment-uuid',
);
print('Attachments uploaded: $attachmentUrls');
```

### **Test 3: Access Control**
- Try accessing another user's files (should fail)
- Try uploading to wrong folder structure (should fail)
- Verify enrolled students can access materials (should succeed)

---

## 🚨 **Common Issues & Solutions**

### **Issue 1: RLS Policy Errors**
```
Error: "new row violates row-level security policy"
```
**Solution**: Check that the user is properly authenticated and has the right role

### **Issue 2: File Upload Fails**
```
Error: "Bucket not found" or "Permission denied"
```
**Solution**: Verify bucket names match exactly and RLS policies are applied

### **Issue 3: Can't Access Files**
```
Error: Files upload but can't be accessed
```
**Solution**: Check that `foldername()` structure matches your upload path

---

## 📋 **Production Checklist**

Before going live:
- [ ] All 3 buckets created with correct settings
- [ ] All RLS policies applied and tested
- [ ] File upload/download working in Flutter
- [ ] Access controls verified (students can't see other students' files)
- [ ] File size limits tested and working
- [ ] MIME type restrictions enforced
- [ ] Error handling implemented in Flutter code

---

**Result**: Complete file storage system ready for MVP deployment! 🚀