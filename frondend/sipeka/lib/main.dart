// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

import 'providers/auth_provider.dart';
import 'providers/kegiatan_provider.dart';
import 'providers/undangan_provider.dart';
import 'providers/realisasi_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bidang_provider.dart';
import 'providers/data_management_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

import 'screens/kegiatan/kegiatan_screen.dart';
import 'screens/kegiatan/detail_kegiatan_screen.dart';
import 'screens/kegiatan/input_realisasi_screen.dart';

import 'screens/undangan/undangan_screen.dart';
import 'screens/tentang/tentang_screen.dart';

import 'screens/admin/admin_kegiatan_screen.dart';
import 'screens/admin/admin_undangan_screen.dart';
import 'screens/admin/admin_bidang_screen.dart';
import 'screens/admin/data_management_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SipekaApp());
}

class SipekaApp extends StatelessWidget {
  const SipekaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KegiatanProvider()),
        ChangeNotifierProvider(create: (_) => UndanganProvider()),
        ChangeNotifierProvider(create: (_) => RealisasiProvider()),

        // ✅ Admin Provider
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ✅ Bidang Provider — master data bidang untuk seluruh fitur
        ChangeNotifierProvider(create: (_) => BidangProvider()),
        ChangeNotifierProvider(create: (_) => DataManagementProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDarkMode;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor:
                  isDark ? const Color(0xFF0F172A) : AppColors.background,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
            child: MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              themeAnimationDuration: const Duration(milliseconds: 220),

              // Start at splash
              home: const _SplashGate(),

              routes: {
                AppRoutes.login: (_) => const LoginScreen(),

                AppRoutes.dashboard: (_) => const DashboardScreen(),

                AppRoutes.kegiatan: (_) => const KegiatanScreen(),

                AppRoutes.detailKegiatan: (_) => const DetailKegiatanScreen(),

                AppRoutes.inputRealisasi: (_) => const InputRealisasiScreen(),

                AppRoutes.undangan: (_) => const UndanganScreen(),

                AppRoutes.tentang: (_) => const TentangScreen(),

                // ✅ ADMIN ROUTES
                AppRoutes.adminKegiatan: (_) =>
                    const _AdminGuard(child: AdminKegiatanScreen()),

                AppRoutes.adminUndangan: (_) =>
                    const _AdminGuard(child: AdminUndanganScreen()),

                AppRoutes.adminBidang: (_) =>
                    const _AdminGuard(child: AdminBidangScreen()),

                AppRoutes.adminData: (_) =>
                    const _AdminGuard(child: DataManagementScreen()),
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── ADMIN GUARD ─────────────────────────────────────────────────────────────
//
// Memastikan hanya Admin yang bisa akses halaman admin

class _AdminGuard extends StatelessWidget {
  final Widget child;

  const _AdminGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // Belum login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Bukan admin
    if (user.role != 'Admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Akses ditolak. Hanya Admin yang bisa mengakses halaman ini.',
            ),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}

// ─── Splash Gate ─────────────────────────────────────────────────────────────
//
// Shows splash screen then routes based on auth status

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    _ctrl.forward();

    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // ignore: use_build_context_synchronously
    final auth = context.read<AuthProvider>();

    await auth.checkLogin();

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Image(
                        image: AssetImage('assets/images/logo_sipeka.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Name
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Kinerja & Anggaran Kegiatan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
