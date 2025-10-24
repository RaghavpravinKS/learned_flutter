# Materials Tab Setup - Quick Start Guide

## ✅ Already Completed
Based on your STORAGE_SETUP_GUIDE.md, you already have:
- ✅ Storage bucket `learning-materials` created
- ✅ Storage RLS policies configured
- ✅ Materials management screens and models

## 🎯 Materials Tab in Classroom Detail

### What's New
A simplified Materials tab has been added to the classroom detail screen that allows teachers to:
- Upload files directly within classroom context
- View all materials for that classroom
- Delete materials with confirmation
- See file type icons and metadata
- Pull-to-refresh to reload materials

### Required Setup Steps

#### Step 1: Apply Database RLS Policies
Run this SQL in your Supabase Dashboard → SQL Editor:

```sql
-- File: supabase/learning_materials_rls_policies.sql
-- Copy and paste the entire contents of this file
```

This ensures:
- Teachers can view/add/edit/delete materials for their classrooms
- Students can view materials for enrolled classrooms
- Proper security isolation

#### Step 2: Verify Storage Bucket Exists
In Supabase Dashboard → Storage, verify you have:
- Bucket name: `learning-materials`
- Public: false (or true if you want direct URLs)

If not created, run the storage policies from your STORAGE_SETUP_GUIDE.md

#### Step 3: Test the Feature

1. **Navigate to Classroom Detail**:
   - Go to any classroom from "My Classrooms"
   - Click on the classroom to open details

2. **Go to Materials Tab**:
   - Click the 4th tab "Materials"

3. **Upload a Test File**:
   - Click "Upload Material" button
   - Select any file (PDF, image, video, doc, etc.)
   - Wait for upload confirmation
   - File should appear in the list

4. **Verify File Display**:
   - File should show with appropriate icon
   - Metadata (size, date) should be visible
   - "Public" badge if applicable

5. **Test Delete**:
   - Click three-dot menu on a material
   - Select "Delete"
   - Confirm deletion
   - Material should be removed from list and storage

### File Path Structure
Files are uploaded to storage with this path:
```
classrooms/{classroom_id}/{timestamp}_{filename}
```

This ensures:
- Files are organized by classroom
- No filename conflicts (timestamp prefix)
- Easy to track ownership

### Common Issues

**Issue: "Permission denied" on upload**
- ✅ Solution: Run the RLS policies SQL (Step 1)

**Issue: "Bucket not found"**
- ✅ Solution: Verify bucket name is exactly `learning-materials` (with hyphen)

**Issue: Files upload but don't appear**
- ✅ Solution: Check that `_loadMaterials()` is being called
- Pull down to refresh the list

**Issue: Can't delete files**
- ✅ Solution: Verify RLS policies allow teachers to delete their own materials

### Database Columns Used
The Materials tab queries these columns from `learning_materials`:
- `id` - Primary key
- `classroom_id` - Foreign key to classrooms
- `teacher_id` - Foreign key to teachers
- `title` - Material title (uses file_name)
- `file_name` - Original filename
- `file_url` - Supabase Storage URL
- `file_path` - Storage path (for deletion)
- `file_size` - Size in bytes
- `is_public` - Visibility flag
- `created_at` - Upload timestamp

### Differences from Full Materials Management Screen

| Feature | Materials Tab | Full Materials Screen |
|---------|--------------|----------------------|
| Context | Single classroom | All classrooms |
| Upload fields | File only (title auto-set) | Full form with type, tags, description |
| Filtering | N/A (classroom-scoped) | Type & classroom filters |
| Material types | Auto-detected from MIME | Explicit selection |
| Tags | Not supported | Supported |
| Description | Not supported | Supported |
| Use case | Quick upload | Comprehensive management |

### Next Steps After Testing

Once the Materials tab is working:
- ✅ Materials are accessible to students (RLS policy in place)
- ✅ Files are stored securely in Supabase Storage
- ✅ Teachers can manage materials per classroom
- Consider adding download/view functionality for students in student UI

### Security Notes
- ✅ RLS enabled on learning_materials table
- ✅ Storage policies restrict uploads to teachers
- ✅ Students can only view materials for enrolled classrooms
- ✅ File paths contain classroom_id for organization
- ✅ Teachers can only manage their own classroom materials

---

**Status**: ✅ Implementation complete, ready for testing
**Focus**: Simplified in-classroom material management
**Coexists with**: Full materials management screen (materials_management_screen.dart)
