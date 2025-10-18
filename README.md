# 🎓 LearnED - Comprehensive E-Learning Platform

A modern Flutter-based e-learning platform that connects students, teachers, and parents in an integrated educational ecosystem.

## 📱 **Current Status: Student App COMPLETE**

The student-facing features are fully functional and ready for production use. See [PROJECT_STATUS.md](PROJECT_STATUS.md) for detailed progress tracking.

### ✅ **Completed Features**
- **Student Registration & Authentication** - Secure signup with grade/board selection
- **Interactive Dashboard** - Real enrollment statistics and progress tracking  
- **Classroom Discovery** - Browse, search, and filter available classes
- **Enrollment System** - Complete flow with mock payment integration
- **My Classes** - Enrolled classes with teacher info and progress
- **Assignment Management** - View assignments with due dates and status
- **Learning Materials** - PDF and video content viewer
- **Profile Management** - Real student data with edit capabilities
- **Class Schedule** - Weekly timetable for enrolled sessions

## 🚀 **Quick Start**

### Prerequisites
- Flutter SDK (managed via FVM)
- Supabase account and project
- VS Code with Flutter extensions

### Environment Setup
1. **Clone the repository**
   ```bash
   git clone https://github.com/RaghavpravinKS/learned_flutter.git
   cd learned_flutter
   ```

2. **Install dependencies**
   ```bash
   fvm flutter pub get
   ```

3. **Configure environment variables**
   - Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in VS Code settings
   - Or use the provided build scripts with dart-define

4. **Run the app**
   ```bash
   fvm flutter run
   ```

### Production Build
Use the provided build scripts:
```bash
# Debug APK
./build-debug.bat

# Release APK  
./build-release.bat
```

## 📊 **Project Structure**
```
lib/
├── core/           # Shared utilities, constants, and services
├── features/       # Feature-based modules (auth, student, teacher, etc.)
├── routes/         # Navigation and routing configuration
├── services/       # Global services and API clients
└── shared/         # Shared widgets and utilities

supabase/          # Database schema, migrations, and functions
docs/              # Technical documentation and specifications
```

## 🔧 **Tech Stack**
- **Frontend**: Flutter with Material Design 3
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Navigation**: GoRouter
- **Build System**: FVM + Custom build scripts

## 📋 **Database Schema**
The platform uses a comprehensive PostgreSQL schema with 25+ tables including:
- User management (students, teachers, parents, admins)
- Classroom and enrollment system
- Assignment and progress tracking
- Payment and subscription management
- Communication and notifications

See `docs/complete_system_architecture.md` for detailed database design.

## 🎯 **Roadmap**
- ✅ **Student App** - Complete and ready for production
- 🔄 **Admin Panel** - User creation and management (95% ready)
- 📋 **Teacher Portal** - Class management and content creation
- 📋 **Parent App** - Child progress monitoring and communication
- 📋 **Video Integration** - Live classes with WebRTC
- 📋 **Payment Gateway** - Real payment processing integration

## 📞 **Support & Documentation**
- **Project Status**: [PROJECT_STATUS.md](PROJECT_STATUS.md) - Current progress and feature completion
- **System Architecture**: [docs/COMPLETE_SYSTEM_SPECIFICATION.md](docs/COMPLETE_SYSTEM_SPECIFICATION.md) - Complete technical specification
- **Database Setup**: Database reset and initialization instructions in system specification

## 👨‍💻 **Developer**
**Ragha** - Full-stack Flutter Developer  
📧 raghavpravinks@gmail.com  
🔗 [GitHub](https://github.com/RaghavpravinKS)

---
*Built with ❤️ in Flutter • Powered by Supabase*
