import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../services/teacher_service.dart';

class AssignmentGradingScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const AssignmentGradingScreen({super.key, required this.assignment});

  @override
  State<AssignmentGradingScreen> createState() => _AssignmentGradingScreenState();
}

class _AssignmentGradingScreenState extends State<AssignmentGradingScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  List<SubmissionModel> _submissions = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load submissions and enrolled students in parallel
      await Future.wait([_loadSubmissions(), _loadEnrolledStudents()]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubmissions() async {
    try {
      final response = await Supabase.instance.client
          .from('student_assignment_attempts')
          .select('''
            *,
            student:student_id (
              id,
              user_id,
              users!inner (
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('assignment_id', widget.assignment.id!)
          .order('submitted_at', ascending: false);

      final submissions = (response as List).map((item) {
        // Flatten the nested structure
        final student = item['student'] as Map<String, dynamic>?;
        final user = student?['users'] as Map<String, dynamic>?;

        final firstName = user?['first_name'] ?? '';
        final lastName = user?['last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).trim();

        return SubmissionModel.fromMap({
          ...item,
          'student_name': fullName.isNotEmpty ? fullName : 'Unknown',
          'student_email': user?['email'],
        });
      }).toList();

      setState(() {
        _submissions = submissions;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadEnrolledStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('student_enrollments')
          .select('''
            student_id,
            student:student_id (
              id,
              user_id,
              users!inner (
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('classroom_id', widget.assignment.classroomId)
          .eq('status', 'active');

      setState(() {
        _enrolledStudents = List<Map<String, dynamic>>.from(response as List);
      });
    } catch (e) {
      rethrow;
    }
  }

  List<SubmissionModel> get _pendingSubmissions {
    // Group by student_id and get the latest submission for each student
    final Map<String, SubmissionModel> latestByStudent = {};

    for (var submission in _submissions.where((s) => s.isSubmitted && !s.isGraded)) {
      final studentId = submission.studentId;
      if (!latestByStudent.containsKey(studentId) ||
          submission.submittedAt!.isAfter(latestByStudent[studentId]!.submittedAt!)) {
        latestByStudent[studentId] = submission;
      }
    }

    return latestByStudent.values.toList();
  }

  List<SubmissionModel> get _gradedSubmissions {
    // Group by student_id and get the latest submission for each student
    final Map<String, SubmissionModel> latestByStudent = {};

    for (var submission in _submissions.where((s) => s.isGraded)) {
      final studentId = submission.studentId;
      if (!latestByStudent.containsKey(studentId) ||
          submission.submittedAt!.isAfter(latestByStudent[studentId]!.submittedAt!)) {
        latestByStudent[studentId] = submission;
      }
    }

    return latestByStudent.values.toList();
  }

  List<Map<String, dynamic>> get _notSubmittedStudents {
    final submittedStudentIds = _submissions.where((s) => s.isSubmitted).map((s) => s.studentId).toSet();

    return _enrolledStudents.where((student) => !submittedStudentIds.contains(student['student_id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade Assignment', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(widget.assignment.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
                Tab(text: 'Pending (${_pendingSubmissions.length})'),
                Tab(text: 'Graded (${_gradedSubmissions.length})'),
                Tab(text: 'Not Submitted (${_notSubmittedStudents.length})'),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading submissions',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSubmissionsList(_pendingSubmissions, 'No pending submissions'),
        _buildSubmissionsList(_gradedSubmissions, 'No graded submissions yet'),
        _buildNotSubmittedList(),
      ],
    );
  }

  Widget _buildSubmissionsList(List<SubmissionModel> submissions, String emptyMessage) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: submissions.length,
        itemBuilder: (context, index) => _buildSubmissionCard(submissions[index]),
      ),
    );
  }

  Widget _buildSubmissionCard(SubmissionModel submission) {
    final isGraded = submission.isGraded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showGradingDialog(submission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student name and status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      submission.studentName[0].toUpperCase(),
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.studentName,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (submission.studentEmail != null)
                          Text(submission.studentEmail!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGraded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isGraded ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      submission.submissionStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isGraded ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Submission details
              Row(
                children: [
                  _buildInfoChip(Icons.schedule, 'Submitted', submission.formattedSubmittedDate),
                  const SizedBox(width: 12),
                  if (submission.timeTaken != null)
                    _buildInfoChip(Icons.timer, 'Time Taken', submission.formattedTimeTaken),
                  const SizedBox(width: 12),
                  if (isGraded) _buildInfoChip(Icons.star, 'Score', submission.scoreDisplay, color: Colors.green),
                ],
              ),
              if (isGraded && submission.percentage != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: submission.percentage! / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_getGradeColor(submission.percentage!)),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  '${submission.percentage!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getGradeColor(submission.percentage!),
                  ),
                ),
              ],
              if (!isGraded) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showGradingDialog(submission),
                    icon: const Icon(Icons.grading),
                    label: const Text('Grade Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color ?? Colors.grey[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSubmittedList() {
    if (_notSubmittedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
            const SizedBox(height: 24),
            Text(
              'All students have submitted!',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green[700]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notSubmittedStudents.length,
      itemBuilder: (context, index) {
        final studentData = _notSubmittedStudents[index];
        final student = studentData['student'] as Map<String, dynamic>;
        final user = student['users'] as Map<String, dynamic>;

        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        final name = (firstName + ' ' + lastName).trim();
        final email = user['email'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name),
            subtitle: Text(email),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(
                'Not Submitted',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red[700]),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showGradingDialog(SubmissionModel submission) async {
    // Get all submissions for this student
    final allStudentSubmissions = _submissions.where((s) => s.studentId == submission.studentId).toList()
      ..sort((a, b) => (b.submittedAt ?? DateTime(2000)).compareTo(a.submittedAt ?? DateTime(2000)));

    // Navigate to full screen grading page
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _GradingScreen(allSubmissions: allStudentSubmissions, assignment: widget.assignment),
      ),
    );

    // Reload data after grading
    _loadData();
  }
}

class _GradingScreen extends StatefulWidget {
  final List<SubmissionModel> allSubmissions;
  final AssignmentModel assignment;

  const _GradingScreen({required this.allSubmissions, required this.assignment});

  @override
  State<_GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<_GradingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController();
    _feedbackController = TextEditingController();

    // Pre-fill with existing grade if any attempt is already graded
    final gradedAttempt = widget.allSubmissions.firstWhere(
      (s) => s.isGraded,
      orElse: () => widget.allSubmissions.first,
    );
    _scoreController.text = gradedAttempt.score?.toStringAsFixed(1) ?? '';
    _feedbackController.text = gradedAttempt.feedback ?? '';
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String? _getFileUrl(SubmissionModel submission) {
    final answers = submission.answers;
    if (answers != null) {
      return answers['file_url'] as String?;
    }
    return null;
  }

  String? _getFilePath(SubmissionModel submission) {
    final answers = submission.answers;
    if (answers != null) {
      return answers['file_path'] as String?;
    }
    return null;
  }

  String? _getFileName(SubmissionModel submission) {
    final answers = submission.answers;
    if (answers != null) {
      final fileName = answers['file_name'] as String?;
      if (fileName != null) return fileName;
    }
    final fileUrl = _getFileUrl(submission);
    if (fileUrl != null) {
      return fileUrl.split('/').last;
    }
    final filePath = _getFilePath(submission);
    if (filePath != null) {
      return filePath.split('/').last;
    }
    return null;
  }

  Future<void> _openFile(SubmissionModel submission) async {
    try {
      setState(() => _isLoading = true);

      // Get the storage path directly from answers
      final storagePath = _getFilePath(submission);

      if (storagePath == null || storagePath.isEmpty) {
        // Fallback: try to extract from file_url if it exists (for old submissions)
        final fileUrl = _getFileUrl(submission);
        if (fileUrl != null && fileUrl.contains('assignment-attachments/')) {
          final extractedPath = fileUrl.split('assignment-attachments/').last;
          final decodedPath = Uri.decodeComponent(extractedPath);

          await _openFileWithPath(decodedPath);
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file path found'), backgroundColor: Colors.orange));
        }
        return;
      }

      await _openFileWithPath(storagePath);
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error opening file: $e';

        // Provide helpful message for missing files
        if (e.toString().contains('Object not found') || e.toString().contains('404')) {
          errorMessage =
              'File not found in storage. This may be an old submission before the storage system was properly configured. Please ask the student to resubmit.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openFileWithPath(String storagePath) async {
    try {
      final supabase = Supabase.instance.client;


      // Generate signed URL from Supabase storage
      final signedUrl = await supabase.storage
          .from('assignment-attachments')
          .createSignedUrl(storagePath, 3600); // Valid for 1 hour


      // Launch the signed URL directly (canLaunchUrl returns false for storage URLs on Android)
      final uri = Uri.parse(signedUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final score = double.parse(_scoreController.text);
      final maxScore = widget.assignment.totalPoints.toDouble();
      final percentage = (score / maxScore) * 100;
      final feedback = _feedbackController.text.trim();

      final teacherService = TeacherService();
      final teacherId = await teacherService.getCurrentTeacherId();

      final supabase = Supabase.instance.client;

      final studentId = widget.allSubmissions.first.studentId;
      final studentName = widget.allSubmissions.first.studentName;

      // Update ALL attempts for this student/assignment with the same grade
      // This ensures the student has ONE consistent grade across all attempts
      await supabase
          .from('student_assignment_attempts')
          .update({
            'score': score,
            'max_score': maxScore,
            'percentage': percentage,
            'feedback': feedback,
            'is_graded': true,
            'graded_by': teacherId,
            'graded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentId)
          .eq('assignment_id', widget.assignment.id!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grade saved for $studentName (${widget.allSubmissions.length} attempt(s) updated)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving grade: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.allSubmissions.first.studentName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grade Assignment', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(studentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Assignment info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.assignment.title,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Points: ${widget.assignment.totalPoints}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // All Attempts Section
                    Text(
                      'Submission Attempts (${widget.allSubmissions.length})',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...widget.allSubmissions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final submission = entry.value;
                      final attemptNum = widget.allSubmissions.length - index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: submission.isGraded ? Colors.green.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: submission.isGraded ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  submission.isGraded ? Icons.check_circle : Icons.pending,
                                  size: 16,
                                  color: submission.isGraded ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Attempt #$attemptNum',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                if (submission.submittedAt != null)
                                  Text(
                                    submission.formattedSubmittedDate,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            if (_getFilePath(submission) != null || _getFileUrl(submission) != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _getFileName(submission) ?? 'View File',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
                                    onPressed: () => _openFile(submission),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Score input
                    Text(
                      'Final Grade (applies to all attempts)',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _scoreController,
                      decoration: InputDecoration(
                        labelText: 'Score *',
                        hintText: '0 - ${widget.assignment.totalPoints}',
                        prefixIcon: const Icon(Icons.star),
                        suffixText: '/ ${widget.assignment.totalPoints}',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a score';
                        }
                        final score = double.tryParse(value);
                        if (score == null) {
                          return 'Please enter a valid number';
                        }
                        if (score < 0 || score > widget.assignment.totalPoints) {
                          return 'Score must be between 0 and ${widget.assignment.totalPoints}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Feedback input
                    TextFormField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: 'Feedback *',
                        hintText: 'Write feedback for the student...',
                        prefixIcon: const Icon(Icons.comment_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide feedback for the student';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Actions at bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveGrade,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Saving...' : 'Save Grade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
