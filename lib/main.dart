import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:provider/provider.dart';
import 'package:juecho/common/constants/app_colors.dart';

// Providers
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/analytics/presentation/provider/analytics_provider.dart';
import 'package:juecho/features/feedback/presentation/providers/submissions_provider.dart';
import 'package:juecho/features/feedback/presentation/providers/single_submission_provider.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/notifications/presentation/provider/notifications_provider.dart';

// Pages
import 'package:juecho/features/splash/presentation/pages/splash_page.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/auth/presentation/pages/signup_page.dart';
import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juecho/features/home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/profile/presentation/pages/profile_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/submit_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/my_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/single_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_submissions_review_page.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_new_submissions_page.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_single_submission_page.dart';
import 'package:juecho/features/analytics/presentation/pages/analytics_reports_page.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';

/// Application entry point.
///
/// Bootstrapping order:
/// 1) Ensure Flutter engine is initialized.
/// 2) Configure Amplify plugins + load amplify_outputs.json.
/// 3) Create the root dependency graph (providers).
/// 4) Start the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        // Global auth/session state shared across the entire app.
        //
        // Source of truth for:
        // - Cognito session state
        // - user profile
        // - role (admin navigation decisions)
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // Feature providers that do not require AuthProvider at construction time.
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),

        // Provider that depends on AuthProvider (needs access to auth.profile/userId).
        //
        // Uses ChangeNotifierProxyProvider to keep the provider instance stable while
        // swapping its AuthProvider reference on auth changes (login/logout).
        ChangeNotifierProxyProvider<AuthProvider, MyFullSubmissionsProvider>(
          create: (context) =>
          MyFullSubmissionsProvider(context.read<AuthProvider>())..init(),
          update: (context, auth, prev) {
            if (prev != null) {
              prev.updateAuth(auth);
              return prev;
            }
            return MyFullSubmissionsProvider(auth)..init();
          },
        ),

        // Home stats provider for general users.
        //
        // Depends on AuthProvider to resolve the current user/profile identity.
        ChangeNotifierProxyProvider<AuthProvider, GeneralHomeStatsProvider>(
          create: (context) =>
          GeneralHomeStatsProvider(context.read<AuthProvider>())..init(),
          update: (context, auth, prev) {
            if (prev != null) {
              prev.updateAuth(auth);
              return prev;
            }
            return GeneralHomeStatsProvider(auth)..init();
          },
        ),

        // Home stats provider for admins.
        //
        // Does not require AuthProvider at construction in this implementation.
        ChangeNotifierProvider<AdminHomeStatsProvider>(
          create: (_) => AdminHomeStatsProvider()..init(),
        ),
      ],
      child: const JUEchoApp(),
    ),
  );
}

/// Configures Amplify for the application.
///
/// Plugins:
/// - Auth (Cognito): authentication, groups, and session handling.
/// - API (AppSync GraphQL): backend data operations.
/// - Storage (S3): feedback attachment uploads/downloads.
///
/// Configuration:
/// - Reads `assets/config/amplify_outputs.json` generated by Amplify Gen 2.
/// - Calls `Amplify.configure()` once.
///
/// Error handling:
/// - If Amplify was already configured (hot restart / multiple calls), it is ignored.
/// - Other exceptions are printed to logs via [safePrint].
Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(),
      AmplifyStorageS3(),
    ]);

    final configJson = await rootBundle.loadString(
      'assets/config/amplify_outputs.json',
    );

    await Amplify.configure(configJson);
    safePrint('Amplify configured');
  } on AmplifyAlreadyConfiguredException {
    // Expected during hot restart or when configure is invoked more than once.
    safePrint('Amplify already configured');
  } catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

/// Root application widget.
///
/// Owns:
/// - Theme configuration
/// - Route table
/// - Initial route decision (Splash)
///
/// Notes:
/// - Some routes wrap their pages with per-page providers because those
///   providers require route arguments (e.g., submission id).
class JUEchoApp extends StatelessWidget {
  const JUEchoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUEcho',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.gray,
        ),
      ),
      initialRoute: SplashPage.routeName,
      routes: {
        // App bootstrap
        SplashPage.routeName: (_) => const SplashPage(),

        // Authentication routes
        LoginPage.routeName: (_) => const LoginPage(),
        SignupPage.routeName: (_) => const SignupPage(),
        ConfirmCodePage.routeName: (_) => const ConfirmCodePage(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),

        // Home routes
        //
        // Navigation target should be decided by AuthProvider role logic
        // (e.g., SplashPage redirects accordingly).
        AdminHomePage.routeName: (_) => const AdminHomePage(),
        GeneralHomePage.routeName: (_) => const GeneralHomePage(),

        // General user pages
        SubmitFeedbackPage.routeName: (_) => const SubmitFeedbackPage(),
        MyFeedbackPage.routeName: (_) => const MyFeedbackPage(),
        ProfilePage.routeName: (_) => const ProfilePage(),

        // Notifications (shared by roles; page selects the correct scaffold internally)
        NotificationsPage.routeName: (_) => const NotificationsPage(),

        // Admin lists: each route owns its provider instance.
        //
        // These providers depend on AuthProvider because backend filtering and
        // ownership logic require the current profile/userId.
        AdminNewSubmissionsPage.routeName: (context) {
          final auth = context.read<AuthProvider>();
          return ChangeNotifierProvider(
            create: (_) => AdminNewSubmissionsProvider(auth),
            child: const AdminNewSubmissionsPage(),
          );
        },
        AdminSubmissionsReviewPage.routeName: (context) {
          final auth = context.read<AuthProvider>();
          return ChangeNotifierProvider(
            create: (_) => AdminReviewSubmissionsProvider(auth),
            child: const AdminSubmissionsReviewPage(),
          );
        },

        // Analytics (admin)
        AnalyticsReportsPage.routeName: (_) => const AnalyticsReportsPage(),

        // Submission details (admin): provider requires submission id + auth.
        AdminSingleSubmissionPage.routeName: (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          final auth = context.read<AuthProvider>();

          return ChangeNotifierProvider(
            create: (_) => SingleSubmissionProvider(id, auth)..init(),
            child: const AdminSingleSubmissionPage(),
          );
        },

        // Submission details (general): provider requires submission id + auth.
        //
        // Routing decision (admin vs general) is handled by callers when navigating.
        SingleFeedbackPage.routeName: (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          final auth = context.read<AuthProvider>();

          return ChangeNotifierProvider(
            create: (_) => SingleSubmissionProvider(id, auth)..init(),
            child: const SingleFeedbackPage(),
          );
        },
      },
    );
  }
}