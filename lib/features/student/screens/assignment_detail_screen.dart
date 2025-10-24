import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/assignment_model.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final Assignment? assignment;

  const AssignmentDetailScreen({super.key, required this.assignmentId, this.assignment});

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  final _supabase = Supabase.instance.client;
  Assignment? _assignment;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedFileName;
  String? _selectedFilePath;
  List<Map<String, dynamic>> _previousSubmissions = [];

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    if (_assignment == null) {
      _loadAssignment();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssignment() async {
    print('=== LOADING ASSIGNMENT DETAILS ===');
    print('Assignment ID: ${widget.assignmentId}');

    try {
      // Get current user and student ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final studentRecord = await _supabase.from('students').select('id').eq('user_id', userId).single();

      final studentDbId = studentRecord['id'] as String;
      print('Student DB ID: $studentDbId');

      final response = await _supabase
          .from('assignments')
          .select('''
            *,
            classrooms!inner(
              name,
              teachers!inner(
                users!inner(
                  first_name,
                  last_name
                )
              )
            )
          ''')
          .eq('id', widget.assignmentId)
          .single();

      print('Assignment loaded: ${response['title']}');

      // Extract classroom and teacher info
      final classroom = response['classrooms'] as Map<String, dynamic>?;
      final teacher = classroom?['teachers'] as Map<String, dynamic>?;
      final teacherUser = teacher?['users'] as Map<String, dynamic>?;

      final classroomName = classroom?['name'] as String?;
      final teacherFirstName = teacherUser?['first_name'] as String?;
      final teacherLastName = teacherUser?['last_name'] as String?;
      final teacherName = (teacherFirstName != null && teacherLastName != null)
          ? '$teacherFirstName $teacherLastName'
          : null;

      print('Classroom: $classroomName, Teacher: $teacherName');

      // Check if this assignment has submissions (with grading info)
      print('Checking for student submissions...');
      final submissions = await _supabase
          .from('student_assignment_attempts')
          .select('''
            id, submitted_at, is_graded, answers, created_at,
            score, max_score, percentage, feedback,
            graded_at, graded_by
          ''')
          .eq('assignment_id', widget.assignmentId)
          .eq('student_id', studentDbId)
          .order('submitted_at', ascending: false);

      String status = 'pending';
      String? submittedAt;
      String? submissionUrl;

      // Store all submissions for display
      final allSubmissions = <Map<String, dynamic>>[];
      bool isGraded = false;
      double? gradeScore;
      double? gradeMaxScore;
      double? gradePercentage;
      String? gradeFeedback;
      String? gradedByName;
      DateTime? gradedAtTime;

      if (submissions.isNotEmpty) {
        // Get the latest submission for status
        final latestSubmission = submissions.first;
        isGraded = latestSubmission['is_graded'] as bool? ?? false;
        status = isGraded ? 'graded' : 'submitted';
        submittedAt = latestSubmission['submitted_at'] as String?;

        // Get grading information (same for all attempts)
        if (isGraded) {
          gradeScore = latestSubmission['score'] as double?;
          gradeMaxScore = latestSubmission['max_score'] as double?;
          gradePercentage = latestSubmission['percentage'] as double?;
          gradeFeedback = latestSubmission['feedback'] as String?;
          gradedAtTime = latestSubmission['graded_at'] != null
              ? DateTime.parse(latestSubmission['graded_at'] as String)
              : null;

          // Fetch grader's name if graded_by is present
          final gradedById = latestSubmission['graded_by'] as String?;
          if (gradedById != null) {
            try {
              final graderResponse = await _supabase
                  .from('users')
                  .select('first_name, last_name')
                  .eq('id', gradedById)
                  .single();

              final firstName = graderResponse['first_name'] as String?;
              final lastName = graderResponse['last_name'] as String?;
              gradedByName = (firstName != null && lastName != null) ? '$firstName $lastName' : null;
            } catch (e) {
              print('Error fetching grader info: $e');
            }
          }
        }

        // Try to extract file URL from answers JSONB field
        final answers = latestSubmission['answers'];
        if (answers is Map && answers['file_url'] != null) {
          submissionUrl = answers['file_url'] as String;
        }

        // Store all submissions with their grading info
        for (var submission in submissions) {
          allSubmissions.add({
            'id': submission['id'],
            'submitted_at': submission['submitted_at'],
            'is_graded': submission['is_graded'] ?? false,
            'answers': submission['answers'],
            'created_at': submission['created_at'],
            'score': submission['score'],
            'max_score': submission['max_score'],
            'percentage': submission['percentage'],
            'feedback': submission['feedback'],
            'graded_at': submission['graded_at'],
          });
        }

        print('Found ${allSubmissions.length} submission(s), latest status=$status, submitted_at=$submittedAt');
        if (isGraded) {
          print('Graded: $gradePercentage% by $gradedByName at $gradedAtTime');
        }
      } else {
        print('No submissions found for this assignment');
      }

      setState(() {
        _assignment = Assignment.fromJson({
          ...response,
          'classroom_name': classroomName,
          'teacher_name': teacherName,
          'status': status,
          'submitted_at': submittedAt,
          'submission_url': submissionUrl,
          'score': gradeScore,
          'max_score': gradeMaxScore,
          'grade': gradePercentage,
          'feedback': gradeFeedback,
          'graded_by': gradedByName,
          'graded_at': gradedAtTime?.toIso8601String(),
        });
        _previousSubmissions = allSubmissions;
        _isLoading = false;
      });

      print('=== ASSIGNMENT DETAILS LOADED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      print('=== ERROR LOADING ASSIGNMENT DETAILS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('===========================================');

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load assignment: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _pickFile() async {
    print('=== FILE PICKER STARTED ===');
    try {
      print('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      print('File picker result: $result');
      print('Files selected: ${result?.files.length ?? 0}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('Selected file name: ${file.name}');
        print('File size: ${file.size} bytes');
        print('File path: ${file.path}');
        print('File extension: ${file.extension}');

        setState(() {
          _selectedFileName = file.name;
          _selectedFilePath = file.path;
        });

        print('File selected successfully: $_selectedFileName');
        print('File path stored: $_selectedFilePath');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File selected: ${file.name}')));
        }
      } else {
        print('No file selected or result is null');
      }
    } catch (e, stackTrace) {
      print('=== FILE PICKER ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('========================');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _submitAssignment() async {
    print('=== SUBMIT ASSIGNMENT STARTED ===');
    print('Selected file name: $_selectedFileName');
    print('Selected file path: $_selectedFilePath');
    print('Assignment ID: ${_assignment?.id}');

    if (_selectedFileName == null || _selectedFilePath == null) {
      print('ERROR: No file selected');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file first')));
      return;
    }

    setState(() => _isSubmitting = true);
    print('Submitting state set to true');

    try {
      print('Starting file upload process...');

      // Get student ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      print('User ID: $userId');

      // Get student record
      final studentResponse = await _supabase.from('students').select('id').eq('user_id', userId).single();
      final studentId = studentResponse['id'] as String;
      print('Student ID: $studentId');

      // Upload file to Supabase Storage
      final assignmentId = _assignment!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _selectedFileName!.split('.').last;

      // Calculate attempt number based on previous submissions
      final attemptNumber = _previousSubmissions.length + 1;
      print('This is attempt #$attemptNumber');

      // Path structure: {student_id}/{assignment_id}/attempt_{n}/{filename}
      final storagePath = '$studentId/$assignmentId/attempt_$attemptNumber/$timestamp-$_selectedFileName';

      print('Uploading file to storage...');
      print('Bucket: assignment-attachments');
      print('Storage path: $storagePath');

      final file = File(_selectedFilePath!);
      if (!await file.exists()) {
        throw Exception('File not found at path: $_selectedFilePath');
      }

      final bytes = await file.readAsBytes();
      print('File exists: true');
      print('File size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)');

      try {
        final uploadResponse = await _supabase.storage
            .from('assignment-attachments')
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(contentType: _getContentType(fileExtension), upsert: false),
            );

        print('Upload response: $uploadResponse');
        print('File uploaded successfully to storage');
      } catch (storageError) {
        print('=== STORAGE UPLOAD ERROR ===');
        print('Error: $storageError');
        print('Error type: ${storageError.runtimeType}');
        if (storageError is StorageException) {
          print('Storage error message: ${storageError.message}');
          print('Storage error status code: ${storageError.statusCode}');
        }
        print('===========================');

        // Check if it's a policy/permission error
        if (storageError.toString().contains('403') ||
            storageError.toString().contains('Unauthorized') ||
            storageError.toString().contains('policy')) {
          throw Exception(
            'Storage permission error: Students are not allowed to upload to this bucket. '
            'Please ask your administrator to set up storage policies for student assignment submissions.',
          );
        }

        rethrow;
      }

      // Store the storage path (not the URL) since bucket requires authentication
      // We'll generate signed URLs when needed
      print('File uploaded successfully. Storage path: $storagePath');

      // Create submission record in student_assignment_attempts table
      print('Creating submission record in database...');
      final submissionData = {
        'assignment_id': assignmentId,
        'student_id': studentId,
        'attempt_number': attemptNumber, // Use the calculated attempt number
        'submitted_at': DateTime.now().toIso8601String(),
        'answers': {
          'file_path': storagePath, // Store the actual storage path
          'file_name': _selectedFileName,
          'submitted_at': DateTime.now().toIso8601String(),
        },
        'is_graded': false,
      };

      print('Submission data: $submissionData');

      await _supabase.from('student_assignment_attempts').insert(submissionData);

      print('Submission record created successfully');

      // Reload assignment to get updated submissions list
      await _loadAssignment();

      setState(() {
        _isSubmitting = false;
        _selectedFileName = null;
        _selectedFilePath = null;
      });

      print('Assignment status updated to submitted');
      print('Submitted at: ${_assignment?.submittedAt}');
      print('=== SUBMIT ASSIGNMENT COMPLETED SUCCESSFULLY ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment submitted successfully! (Attempt #${_previousSubmissions.length})'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== SUBMIT ASSIGNMENT ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==============================');
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), duration: const Duration(seconds: 5)));
      }
    }
  }

  Future<void> _viewSubmittedFile(String fileUrl) async {
    print('=== VIEWING SUBMITTED FILE ===');
    print('File URL: $fileUrl');

    try {
      // Extract the file path from the stored URL
      String? filePath;

      if (fileUrl.contains('assignment-attachments/')) {
        filePath = fileUrl.split('assignment-attachments/').last;
        print('Extracted file path: $filePath');
      }

      Uri uri;

      // If we extracted a file path, create a signed URL
      if (filePath != null) {
        try {
          final signedUrl = await _supabase.storage
              .from('assignment-attachments')
              .createSignedUrl(filePath, 3600); // 1 hour expiry

          print('Generated signed URL: $signedUrl');
          uri = Uri.parse(signedUrl);
        } catch (e) {
          print('Error creating signed URL: $e, falling back to stored URL');
          uri = Uri.parse(fileUrl);
        }
      } else {
        uri = Uri.parse(fileUrl);
      }

      // Launch URL to view file
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

      if (!launched) {
        print('Failed to launch URL in browser view');
        // Try external application as fallback
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Successfully opened file in browser view');
      }
    } catch (e) {
      print('Error viewing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening file: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Assignment Details'), backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_assignment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Assignment Details'), backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: AppColors.gray400),
              const SizedBox(height: 16),
              Text('Assignment not found', style: TextStyle(fontSize: 16, color: AppColors.gray600)),
            ],
          ),
        ),
      );
    }

    final assignment = _assignment!;
    final isOverdue =
        assignment.dueDate != null && assignment.dueDate!.isBefore(DateTime.now()) && assignment.status == 'pending';
    // Prevent submissions after being graded
    final canSubmit = assignment.status != 'graded';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assignment Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (canSubmit)
            IconButton(
              icon: const Icon(Icons.help_outline),
              color: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Submission Help'),
                    content: const Text(
                      'Select a file (PDF, DOC, DOCX, TXT, or images) and tap Submit to turn in your assignment.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Status Card
            if (assignment.status != 'graded')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(assignment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(assignment.status),
                        color: _getStatusColor(assignment.status),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(assignment.status),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(assignment.status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isOverdue)
                            Text(
                              'Overdue by ${DateTime.now().difference(assignment.dueDate!).inDays} days',
                              style: TextStyle(color: AppColors.error, fontSize: 13),
                            )
                          else if (assignment.submittedAt != null)
                            Text(
                              'Submitted ${DateFormat('MMM d, y').format(assignment.submittedAt!)}',
                              style: TextStyle(color: AppColors.gray600, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    if (assignment.score != null && assignment.maxScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${assignment.score!.toInt()}/${assignment.maxScore!.toInt()}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Grading Information Card (if graded)
            if (assignment.status == 'graded' && assignment.score != null && assignment.maxScore != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.grade, color: AppColors.success, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Grading Details',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${assignment.score!.toInt()}/${assignment.maxScore!.toInt()}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Graded By
                    if (assignment.gradedBy != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 18, color: AppColors.gray600),
                          const SizedBox(width: 8),
                          Text(
                            'Graded by: ',
                            style: TextStyle(fontSize: 14, color: AppColors.gray600, fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              assignment.gradedBy!,
                              style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Graded At
                    if (assignment.gradedAt != null) ...[
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.gray600),
                          const SizedBox(width: 8),
                          Text(
                            'Graded on: ',
                            style: TextStyle(fontSize: 14, color: AppColors.gray600, fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, y • h:mm a').format(assignment.gradedAt!),
                              style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Feedback
                    if (assignment.feedback != null && assignment.feedback!.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Feedback',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Text(
                          assignment.feedback!,
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Assignment Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Classroom and Teacher
                  if (assignment.className != null || assignment.teacherName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 16, color: AppColors.gray600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${assignment.className ?? ""}${assignment.className != null && assignment.teacherName != null ? " • " : ""}${assignment.teacherName ?? ""}',
                            style: TextStyle(fontSize: 14, color: AppColors.gray600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Due Date
                  if (assignment.dueDate != null) ...[
                    Row(
                      children: [
                        Icon(Icons.schedule, color: isOverdue ? AppColors.error : AppColors.gray600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, MMMM d, y • h:mm a').format(assignment.dueDate!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isOverdue ? AppColors.error : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Description Section
                  if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Assignment Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assignment.description!,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Submission Section
            if (canSubmit) ...[
              // Submission Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Submission',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),

                    // File Picker
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedFileName != null ? AppColors.primary.withOpacity(0.5) : AppColors.gray300,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _selectedFileName != null ? AppColors.primary.withOpacity(0.05) : AppColors.gray50,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _selectedFileName != null
                                      ? Icons.insert_drive_file_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFileName ?? 'Tap to select a file',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedFileName != null ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: _selectedFileName != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedFileName == null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'PDF, DOC, DOCX, TXT, Images',
                                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.gray300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Submit Assignment',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (assignment.status == 'graded') ...[
              // Submission Locked Message
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_outline, color: AppColors.info, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submissions Closed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This assignment has been graded. No more submissions are allowed.',
                            style: TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Previous Submissions
            if (_previousSubmissions.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Submissions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_previousSubmissions.length} ${_previousSubmissions.length == 1 ? 'Attempt' : 'Attempts'}',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._previousSubmissions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final submission = entry.value;
                      final isLatest = index == 0;
                      final submittedAt = submission['submitted_at'] != null
                          ? DateTime.parse(submission['submitted_at'] as String)
                          : null;
                      final answers = submission['answers'];
                      String? fileUrl;
                      if (answers is Map && answers['file_url'] != null) {
                        fileUrl = answers['file_url'] as String;
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: index < _previousSubmissions.length - 1 ? 12 : 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLatest ? AppColors.primary.withOpacity(0.05) : AppColors.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLatest ? AppColors.primary.withOpacity(0.3) : AppColors.gray200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isLatest ? Icons.check_circle : Icons.history,
                                  color: isLatest ? AppColors.success : AppColors.gray600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isLatest ? 'Latest Submission' : 'Attempt ${_previousSubmissions.length - index}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isLatest ? FontWeight.w600 : FontWeight.w500,
                                      color: isLatest ? AppColors.success : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isLatest && assignment.score != null && assignment.maxScore != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.info,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${assignment.score!.toInt()}/${assignment.maxScore!.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (submittedAt != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: AppColors.gray600),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, y • h:mm a').format(submittedAt),
                                    style: TextStyle(fontSize: 12, color: AppColors.gray600),
                                  ),
                                ],
                              ),
                            ],
                            if (fileUrl != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _viewSubmittedFile(fileUrl!),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.gray300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.attach_file, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'View Attachment',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.gray600),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ], // Main Column children
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'late':
        return AppColors.error;
      case 'submitted':
        return AppColors.success;
      case 'graded':
        return AppColors.info;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_outlined;
      case 'late':
        return Icons.warning_amber_outlined;
      case 'submitted':
        return Icons.check_circle_outline;
      case 'graded':
        return Icons.star_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Not Submitted';
      case 'late':
        return 'Overdue';
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      default:
        return status.toUpperCase();
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
