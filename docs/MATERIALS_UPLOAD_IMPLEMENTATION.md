# Learning Materials Feature Implementation Guide

## Overview
This guide covers the complete setup of the learning materials upload/download feature for the LearnED platform.

## Features Implemented
✅ Upload files from device (all file types supported)
✅ Store files in Supabase Storage
✅ Track materials in database with metadata
✅ Display materials list with file type icons
✅ Delete materials with confirmation
✅ Download/view materials
✅ File size formatting
✅ Pull-to-refresh
✅ Loading states and error handling

## Prerequisites Setup

### 1. Create Supabase Storage Bucket

Run this SQL in your Supabase Dashboard SQL Editor:

```sql
-- File: supabase/setup_learning_materials_storage.sql
```

This will:
- Create the 'learning-materials' storage bucket (public access for downloads)
- Set up storage policies for teachers to upload/delete files
- Allow authenticated users (students) to read files

### 2. Set Up RLS Policies for Database Table

Run this SQL in your Supabase Dashboard SQL Editor:

```sql
-- File: supabase/learning_materials_rls_policies.sql
```

This enables:
- Teachers to view/add/edit/delete materials for their classrooms
- Students to view materials for classrooms they're enrolled in
- Proper security isolation

### 3. Verify Database Schema

Ensure your `learning_materials` table has these columns:
```sql
- id (uuid, primary key)
- classroom_id (uuid, foreign key to classrooms)
- teacher_id (uuid, foreign key to teachers)
- title (text)
- description (text, nullable)
- file_name (text)
- file_url (text)
- file_path (text) -- Important: used for storage deletion
- file_size (bigint)
- is_public (boolean, default true)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)
```

## UI Implementation

### Files Modified
- `lib/features/teacher/screens/classroom_detail_screen.dart`

### Key Features Added

#### 1. Materials Tab
- Added as 4th tab in classroom details
- Shows empty state when no materials
- Lists all materials with file icons, sizes, and dates
- Upload button always accessible

#### 2. File Upload Flow
```
User clicks "Upload Material" 
  → File picker opens
  → User selects file
  → Upload to Supabase Storage (with progress indicator)
  → Save metadata to database
  → Refresh materials list
  → Show success message
```

#### 3. File Type Detection
Supports icons for:
- PDF (red)
- Word (blue)
- PowerPoint (orange)
- Excel (green)
- Images (purple)
- Videos (pink)
- Generic files (grey)

#### 4. Material Actions
- **Download**: Provides file URL (ready for browser/download integration)
- **Delete**: Confirms, then removes from both storage and database

## Usage Instructions

### For Teachers:

1. **Upload Material**:
   - Navigate to classroom details
   - Go to "Materials" tab
   - Click "Upload Material" button
   - Select file from device
   - Wait for upload confirmation

2. **Delete Material**:
   - Click three-dot menu on material card
   - Select "Delete"
   - Confirm deletion

3. **Share with Students**:
   - Materials are automatically visible to enrolled students
   - Use `is_public` flag to control visibility (currently defaults to true)

### For Students (Future):
- View materials in enrolled classrooms
- Download materials for offline access
- Filter by file type or date

## File Size Limits

Supabase Storage default limits:
- Free tier: 1 GB storage
- Pro tier: 100 GB storage
- Max file size: 50 MB (can be configured)

To increase limits, configure in Supabase Dashboard → Storage settings.

## Error Handling

The implementation handles:
- ✅ File picker cancellation
- ✅ Upload failures (network, storage)
- ✅ Database insertion errors
- ✅ Permission denied errors
- ✅ Missing file data
- ✅ Authentication errors

All errors show user-friendly messages via SnackBar.

## Testing Checklist

- [ ] Run SQL setup scripts in Supabase Dashboard
- [ ] Verify storage bucket exists
- [ ] Test file upload (various file types)
- [ ] Test file deletion
- [ ] Test with multiple materials
- [ ] Test pull-to-refresh
- [ ] Test empty state
- [ ] Test error scenarios (no network, large file)
- [ ] Verify students can view materials

## Future Enhancements

Potential improvements:
1. **Categories/Tags**: Organize materials by topic
2. **Search/Filter**: Search by filename or filter by type
3. **Preview**: In-app preview for PDFs, images
4. **Batch Upload**: Upload multiple files at once
5. **Version Control**: Track material updates
6. **Analytics**: Track download/view counts
7. **Permissions**: Granular control per material
8. **Compression**: Auto-compress images/videos

## Troubleshooting

### Upload fails with "permission denied"
→ Run `setup_learning_materials_storage.sql` to fix storage policies

### Materials not showing for students
→ Run `learning_materials_rls_policies.sql` to fix RLS policies

### "Bucket not found" error
→ Verify bucket name is 'learning-materials' (with hyphen, not underscore)

### Delete fails but file shows as deleted
→ Orphaned storage files - manually clean via Supabase Dashboard → Storage

## Security Notes

- ✅ RLS enabled on learning_materials table
- ✅ Storage policies prevent unauthorized access
- ✅ Teachers can only manage their own classroom materials
- ✅ Students can only view materials for enrolled classrooms
- ✅ File paths contain classroom_id for isolation
- ⚠️ Public bucket allows authenticated users to construct URLs - consider making bucket private and using signed URLs for sensitive materials

## Dependencies

Already included in `pubspec.yaml`:
- `file_picker: ^8.0.7` - File selection
- `supabase_flutter` - Backend integration
- `intl` - Date formatting

No additional packages needed!

## Deployment Notes

Before deploying to production:
1. Run both SQL setup files in production Supabase
2. Configure storage size limits
3. Set up backup policy for storage bucket
4. Test file upload/download on iOS/Android devices
5. Consider CDN for file delivery (Supabase has built-in CDN)

---

**Status**: ✅ Fully implemented and ready for testing
**Last Updated**: January 2025
