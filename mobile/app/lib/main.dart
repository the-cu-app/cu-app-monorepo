// Copyright 2021 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Colors, ScaffoldMessenger, SnackBar;
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:feedback/feedback.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_wrapper.dart';
import 'screens/connect_account_screen.dart';
import 'screens/chat_signup_screen.dart';
import 'screens/plaid_demo_screen.dart';
import 'screens/plaid_link_screen.dart';
import 'screens/transfer_screen.dart';
// import 'screens/chat_screen.dart'; // Disabled - needs CU widgets
import 'screens/auth/login_screen_riverpod.dart';
import 'screens/home_screen_riverpod.dart';
import 'config/supabase_config.dart';
import 'services/profile_service.dart';
import 'services/accessibility_service.dart';
import 'services/card_service.dart';
import 'services/sound_service.dart';
import 'screens/accessibility_settings_screen.dart';
// import 'screens/cards_screen.dart'; // Disabled - needs CU widgets
import 'screens/connect/connect_accounts_screen.dart';
import 'screens/analytics/spending_analytics_screen.dart';
// import 'screens/analytics/net_worth_screen.dart'; // Disabled - needs CU widgets
import 'screens/ai_signup_screen.dart';
import 'screens/account_products_screen.dart';
import 'screens/no_cap_dashboard_screen.dart';
import 'screens/create_commitment_screen.dart';
// import 'screens/cu_widget_showcase_screen.dart'; // Temporarily disabled
import 'screens/privacy/privacy_settings_screen.dart';
import 'screens/privacy/connected_apps_screen.dart';
import 'screens/privacy/data_export_screen.dart';
import 'screens/privacy/data_access_history_screen.dart';
import 'screens/account_details_screen.dart';
import 'screens/support_chat_screen.dart';
import 'services/plaid_service.dart';
import 'services/supabase_realtime_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Sound Service
  await SoundService().initialize();

  // Initialize Plaid with sandbox token
  try {
    final plaidService = PlaidService();
    debugPrint('Initializing Plaid sandbox connection...');
    final publicToken = await plaidService.createSimpleSandboxToken();
    await plaidService.exchangePublicToken(publicToken);
    debugPrint('Plaid initialized successfully with sandbox data');
  } catch (e) {
    debugPrint('Failed to initialize Plaid: $e');
    // Continue anyway - will use mock data
  }

  // Initialize Supabase real-time service
  try {
    final realtimeService = SupabaseRealtimeService();
    await realtimeService.initialize();
    debugPrint('Supabase real-time service initialized');
  } catch (e) {
    debugPrint('Failed to initialize Supabase real-time: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  final AccessibilityService _accessibilityService = AccessibilityService();
  ShakeDetector? _shakeDetector;
  bool _pilotModeEnabled = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
  
  @override
  void initState() {
    super.initState();
    _initializePilotMode();
  }
  
  Future<void> _initializePilotMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('pilot_mode') ?? false;
    
    if (mounted) {
      setState(() {
        _pilotModeEnabled = isEnabled;
      });
      
      if (isEnabled) {
        _setupShakeDetector();
      }
    }
  }
  
  void _setupShakeDetector() {
    _shakeDetector?.stopListening();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
        if (_pilotModeEnabled && navigatorKey.currentContext != null) {
          BetterFeedback.of(navigatorKey.currentContext!).show((UserFeedback feedback) {
            _handleFeedback(feedback);
          });
        }
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.5,
    );
  }
  
  void _handleFeedback(UserFeedback feedback) async {
    final text = feedback.text;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      // Store feedback in Supabase with real-time broadcast
      final feedbackData = {
        'message': text,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'platform': 'ios',
      };

      // Insert into database
      await Supabase.instance.client.from('feedback').insert(feedbackData);

      // Broadcast via real-time channel for instant support notification
      final channel = Supabase.instance.client.channel('feedback-notifications');
      await channel.sendBroadcastMessage(
        event: 'new_feedback',
        payload: feedbackData,
      );

      if (mounted && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Feedback sent to support team! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      if (mounted && navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Feedback saved locally'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (context) => ProfileService()),
        provider.ChangeNotifierProvider.value(value: _accessibilityService),
        provider.ChangeNotifierProvider(create: (context) => CardService()),
      ],
      child: BetterFeedback(
        theme: FeedbackThemeData(
          background: Colors.grey.shade900,
          feedbackSheetColor: Colors.white,
          activeFeedbackModeColor: const Color(0xFFFFD700),
          drawColors: [
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.yellow,
            const Color(0xFF9B59B6), // Purple
            const Color(0xFFFF69B4), // Pink
          ],
          bottomSheetDescriptionStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Geist',
            color: Colors.black87,
          ),
          sheetIsDraggable: true,
        ),
        localizationsDelegates: [
          GlobalFeedbackLocalizationsDelegate(),
        ],
        localeOverride: const Locale('en'),
        child: AnimatedBuilder(
          animation: _accessibilityService,
          builder: (context, child) {
            return CUApp(
              navigatorKey: navigatorKey,
              title: 'SUPAHYPER Credit Union',
              debugShowCheckedModeBanner: false,
              theme: _buildCULightTheme(),
              darkTheme: _buildCUDarkTheme(),
              isDarkMode: _isDarkMode,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''),
                Locale('es', ''),
              ],
              home: AuthWrapper(onThemeToggle: (isDark) => _toggleTheme()),
              routes: {
                '/auth': (context) =>
                    AuthWrapper(onThemeToggle: (isDark) => _toggleTheme()),
                '/connect': (context) => const ConnectAccountScreen(),
                '/chat-signup': (context) => const ChatSignupScreen(),
                '/plaid-demo': (context) => const PlaidDemoScreen(),
                '/plaid-link': (context) => const PlaidLinkScreen(),
                '/transfer': (context) => const TransferScreen(),
                // '/chat': (context) => const ChatScreen(), // Disabled - needs CU widgets
                '/home': (context) => HomeScreenRiverpod(onThemeToggle: (isDark) => _toggleTheme()),
                '/login': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return LoginScreenRiverpod(isAddAccount: args?['isAddAccount'] ?? false);
                },
                '/accessibility': (context) => const AccessibilitySettingsScreen(),
                // '/cards': (context) => const CardsScreen(), // Disabled - needs CU widgets
                '/connect-accounts': (context) => const ConnectAccountsScreen(),
                '/spending-analytics': (context) => const SpendingAnalyticsScreen(),
                // '/net-worth': (context) => const NetWorthScreen(), // Disabled - needs CU widgets
                '/ai-signup': (context) => const AISignupScreen(),
                // '/cu-showcase': (context) => const CUWidgetShowcaseScreen(), // Temporarily disabled
                '/account-products': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return AccountProductsScreen(
                    userProfile: args?['userProfile'],
                    biometricSettings: args?['biometricSettings'],
                  );
                },
                '/no-cap-dashboard': (context) => const NoCapDashboardScreen(),
                '/create-commitment': (context) => const CreateCommitmentScreen(),
                '/privacy': (context) => const PrivacySettingsScreen(),
                '/privacy/connected-apps': (context) => const ConnectedAppsScreen(),
                '/privacy/data-export': (context) => const DataExportScreen(),
                '/privacy/access-history': (context) => const DataAccessHistoryScreen(),
                '/account-details': (context) {
                  final account = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
                  return AccountDetailsScreen(account: account);
                },
                '/support-chat': (context) => const SupportChatScreen(),
              },
            );
          },
        ),
      ),
    );
  }

  CUThemeData _buildCULightTheme() {
    return CUThemeData(
      colorScheme: _applyCUAccessibility(CUColorScheme.light, isLight: true),
      isDark: false,
    );
  }

  CUThemeData _buildCUDarkTheme() {
    return CUThemeData(
      colorScheme: _applyCUAccessibility(CUColorScheme.dark, isLight: false),
      isDark: true,
    );
  }

  CUColorScheme _applyCUAccessibility(CUColorScheme scheme, {required bool isLight}) {
    final transform = _accessibilityService.transformColor;

    // Apply high contrast if enabled
    var primary = scheme.primary;
    var secondary = scheme.secondary;

    if (_accessibilityService.highContrastMode) {
      primary = isLight ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
      secondary = isLight ? const Color(0xFF616161) : const Color(0xFFE0E0E0);
    }

    // Apply color transformations for accessibility
    return CUColorScheme(
      primary: transform(primary),
      primaryVariant: transform(scheme.primaryVariant),
      secondary: transform(secondary),
      secondaryVariant: transform(scheme.secondaryVariant),
      background: scheme.background,
      surface: scheme.surface,
      error: transform(scheme.error),
      success: transform(scheme.success),
      warning: transform(scheme.warning),
      info: transform(scheme.info),
      onPrimary: scheme.onPrimary,
      onSecondary: scheme.onSecondary,
      onBackground: scheme.onBackground,
      onSurface: scheme.onSurface,
      onError: scheme.onError,
      positive: transform(scheme.positive),
      negative: transform(scheme.negative),
      neutral: transform(scheme.neutral),
      border: transform(scheme.border),
      divider: transform(scheme.divider),
      overlay: scheme.overlay,
      shadow: scheme.shadow,
    );
  }
}
