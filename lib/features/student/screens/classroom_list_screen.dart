import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassroomListScreen extends ConsumerStatefulWidget {
  const ClassroomListScreen({super.key});

  @override
  ConsumerState<ClassroomListScreen> createState() => _ClassroomListScreenState();
}

class _ClassroomListScreenState extends ConsumerState<ClassroomListScreen> {
  final _searchController = TextEditingController();

  // Student's grade and board - automatically detected from user profile
  String? _studentBoard;
  int? _studentGrade;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Fetch from students table (source of truth) instead of auth metadata
        final studentData = await Supabase.instance.client
            .from('students')
            .select('grade_level, board')
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _studentGrade = studentData['grade_level'] as int?;
            _studentBoard = studentData['board'] as String?;
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        // Fallback to auth metadata if DB fetch fails
        if (mounted) {
          setState(() {
            _studentGrade = user.userMetadata?['grade_level'] as int?;
            _studentBoard = user.userMetadata?['board'] as String?;
            _isLoadingProfile = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the simple provider that fetches all classrooms
    final classroomsAsync = ref.watch(allClassroomsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Find a Classroom'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search classrooms...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to filter results
              },
            ),
          ),
          Expanded(
            child: classroomsAsync.when(
              data: (allClassrooms) {
                // Apply filters
                var filteredClassrooms = allClassrooms.where((classroom) {
                  // AUTOMATIC FILTER: Student's Board (mandatory)
                  if (_studentBoard != null) {
                    final classroomBoard = (classroom['board'] ?? '').toString();
                    if (classroomBoard != _studentBoard) {
                      return false;
                    }
                  }

                  // AUTOMATIC FILTER: Student's Grade (mandatory)
                  if (_studentGrade != null) {
                    final gradeLevel = classroom['grade_level'] as int?;
                    if (gradeLevel != _studentGrade) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                // Apply search filter
                if (_searchController.text.isNotEmpty) {
                  final searchText = _searchController.text.toLowerCase();
                  filteredClassrooms = filteredClassrooms.where((classroom) {
                    final name = (classroom['name'] ?? '').toString().toLowerCase();
                    final subject = (classroom['subject'] ?? '').toString().toLowerCase();
                    final teacherName = (classroom['teacher_name'] ?? '').toString().toLowerCase();

                    return name.contains(searchText) ||
                        subject.contains(searchText) ||
                        teacherName.contains(searchText);
                  }).toList();
                }

                if (filteredClassrooms.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No classrooms found'),
                        Text('Try adjusting your filters'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredClassrooms.length,
                  itemBuilder: (context, index) {
                    final classroom = filteredClassrooms[index];
                    return _buildClassroomCard(context, classroom);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading classrooms'),
                      const SizedBox(height: 8),
                      Text(error.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(allClassroomsProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> classroom) {
    final pricingList = classroom['classroom_pricing'] as List?;
    final pricingInfo = pricingList?.firstOrNull as Map<String, dynamic>?;
    final price = pricingInfo?['price'] ?? 0.0;
    final paymentPlan = pricingInfo?['payment_plans'] as Map<String, dynamic>?;
    final billingCycle = paymentPlan?['billing_cycle'] ?? 'month';
    final studentCount = classroom['student_count'] ?? 0;
    final maxStudents = classroom['max_students'] ?? 0;
    final enrollmentPercentage = maxStudents > 0 ? studentCount / maxStudents : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/classrooms/${classroom['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom['name'] ?? 'Unknown Classroom',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${classroom['subject']} • Grade ${classroom['grade_level']} • ${classroom['board'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),

              // Description
              if (classroom['description'] != null && (classroom['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  classroom['description'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Teacher info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      classroom['teacher_name'] ?? 'Teacher Info Unavailable',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Enrollment progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enrollment',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      Text(
                        '$studentCount/$maxStudents students',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: enrollmentPercentage,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      enrollmentPercentage >= 0.9
                          ? Colors
                                .orange // Almost full
                          : AppColors.primary, // Red theme
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Price and action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${(price as num).toStringAsFixed(2)}/$billingCycle',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      if (paymentPlan?['name'] != null)
                        Text(paymentPlan!['name'], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/classrooms/${classroom['id']}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
