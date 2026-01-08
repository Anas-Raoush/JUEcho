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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();

  runApp(
    MultiProvider(
      providers: [
        // ONE global auth state
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // Providers that DON'T need profile
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),

        // Providers that DEPEND on AuthProvider (profile comes from auth.profile)
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

        // Stats providers
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

        ChangeNotifierProvider<AdminHomeStatsProvider>(
          create: (_) => AdminHomeStatsProvider()..init(),
        ),
      ],
      child: const JUEchoApp(),
    ),
  );
}

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
    safePrint('Amplify already configured');
  } catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

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
        SplashPage.routeName: (_) => const SplashPage(),

        // Auth
        LoginPage.routeName: (_) => const LoginPage(),
        SignupPage.routeName: (_) => const SignupPage(),
        ConfirmCodePage.routeName: (_) => const ConfirmCodePage(),
        ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),

        // Home
        AdminHomePage.routeName: (_) => const AdminHomePage(),
        GeneralHomePage.routeName: (_) => const GeneralHomePage(),

        // Feedback
        SubmitFeedbackPage.routeName: (_) => const SubmitFeedbackPage(),
        MyFeedbackPage.routeName: (_) => const MyFeedbackPage(),
        ProfilePage.routeName: (_) => const ProfilePage(),

        // Notifications
        NotificationsPage.routeName: (_) => const NotificationsPage(),

        // Admin lists
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
        AnalyticsReportsPage.routeName: (_) => const AnalyticsReportsPage(),

        // Per-page provider (needs id + auth)
        AdminSingleSubmissionPage.routeName: (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          final auth = context.read<AuthProvider>();

          return ChangeNotifierProvider(
            create: (_) => SingleSubmissionProvider(id, auth)..init(),
            child: const AdminSingleSubmissionPage(),
          );
        },

        // Per-page provider (needs id + auth)
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