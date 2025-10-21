import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learned_flutter/routes/app_routes.dart';

class StudentDrawer extends StatelessWidget {
  final String userName;
  final String currentRoute;

  const StudentDrawer({super.key, required this.userName, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Student', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            route: AppRoutes.student,
            isSelected: currentRoute == AppRoutes.student,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.schedule_outlined,
            title: 'Schedule',
            route: AppRoutes.studentSchedule,
            isSelected: currentRoute == AppRoutes.studentSchedule,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.menu_book_outlined,
            title: 'Learning Materials',
            route: '${AppRoutes.student}/materials',
            isSelected: currentRoute == '${AppRoutes.student}/materials',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.assessment_outlined,
            title: 'My Progress',
            route: AppRoutes.studentProgress,
            isSelected: currentRoute == AppRoutes.studentProgress,
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            route: AppRoutes.studentSettings,
            isSelected: currentRoute == AppRoutes.studentSettings,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            route: AppRoutes.studentHelp,
            isSelected: currentRoute == AppRoutes.studentHelp,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            route: AppRoutes.login,
            isSelected: false,
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    bool isLogout = false,
  }) {
    return Container(
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () async {
          Navigator.pop(context); // Close drawer

          if (isSelected) {
            // Already on this page, do nothing
            return;
          }

          if (isLogout) {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          } else {
            // Navigate to the route
            context.go(route);
          }
        },
      ),
    );
  }
}
