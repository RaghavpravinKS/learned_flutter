import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';

import '../services/classroom_service.dart';

class ClassroomListScreen extends ConsumerStatefulWidget {
  const ClassroomListScreen({super.key});

  @override
  ConsumerState<ClassroomListScreen> createState() => _ClassroomListScreenState();
}

class _ClassroomListScreenState extends ConsumerState<ClassroomListScreen> {
  final _searchController = TextEditingController();
  String _selectedSubject = 'All';
  String _selectedBoard = 'All';
  int? _selectedGrade;

  final List<String> _subjects = ['All', 'Mathematics', 'Physics', 'Chemistry', 'Biology'];
  final List<String> _boards = ['All', 'CBSE', 'ICSE', 'State Board'];
  final List<int> _grades = [8, 9, 10, 11, 12];

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
        title: const Text('Find a Classroom'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog)],
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
                  // Subject filter
                  if (_selectedSubject != 'All') {
                    final subject = (classroom['subject'] ?? '').toString().toLowerCase();
                    if (!subject.contains(_selectedSubject.toLowerCase())) {
                      return false;
                    }
                  }

                  // Board filter
                  if (_selectedBoard != 'All') {
                    final board = (classroom['board'] ?? '').toString();
                    if (board != _selectedBoard) {
                      return false;
                    }
                  }

                  // Grade filter
                  if (_selectedGrade != null) {
                    final gradeLevel = classroom['grade_level'] as int?;
                    if (gradeLevel != _selectedGrade) {
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
                print('Error loading classrooms: $error');
                print('Stack trace: $stack');
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
    final theme = Theme.of(context);
    final pricingList = classroom['classroom_pricing'] as List?;
    final pricingInfo = pricingList?.firstOrNull as Map<String, dynamic>?;
    final price = pricingInfo?['price'] ?? 0.0;
    final paymentPlan = pricingInfo?['payment_plans'] as Map<String, dynamic>?;
    final billingCycle = paymentPlan?['billing_cycle'] ?? 'month';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          context.push('/classrooms/${classroom['id']}');
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      classroom['name'] ?? 'No Name',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${classroom['student_count'] ?? 0}/${classroom['max_students']} students',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Subject: ${classroom['subject'] ?? 'N/A'}', style: theme.textTheme.bodyMedium),
              if (classroom['board'] != null) ...[
                const SizedBox(height: 4),
                Text('Board: ${classroom['board']}', style: theme.textTheme.bodyMedium),
              ],
              if (classroom['grade_level'] != null) ...[
                const SizedBox(height: 4),
                Text('Grade: ${classroom['grade_level']}', style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 8),
              Text(
                'Taught by: ${classroom['teacher_name'] ?? 'Unknown Teacher'}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (classroom['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  classroom['description'],
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${(price as num).toStringAsFixed(2)}/$billingCycle',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (paymentPlan?['name'] != null)
                        Text(
                          paymentPlan!['name'],
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () {
                      context.push('/classrooms/${classroom['id']}');
                    },
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

  Future<void> _showFilterDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Classrooms'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(value: subject, child: Text(subject));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBoard,
                  decoration: const InputDecoration(labelText: 'Board'),
                  items: _boards.map((board) {
                    return DropdownMenuItem(value: board, child: Text(board));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBoard = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedGrade,
                  decoration: const InputDecoration(labelText: 'Grade Level'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Grades')),
                    ..._grades.map((grade) {
                      return DropdownMenuItem(value: grade, child: Text('Grade $grade'));
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Trigger a rebuild with new filters
                setState(() {});
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
