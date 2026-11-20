import 'package:flutter/material.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

import 'app_shell.dart';
import 'catalog_screen.dart';
import 'models/user_profile.dart';
import 'profile_screen.dart';

final GlobalKey<NavigatorState> exampleNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  registerExampleFunctionalTests();
  runApp(const ScenarioKitExampleApp());
}

/// Registers automated functional tests showcasing ScenarioKit Test Mode.
void registerExampleFunctionalTests([ScenarioTestRegistry? registry]) {
  final target = registry ?? ScenarioTestRegistry.instance;
  target.clear();

  target.registerSuite(
    ScenarioTestSuite(
      screenName: 'Product Catalog',
      tests: [
        ScenarioTest(
          name: 'Verify Header & Catalog Branding',
          group: 'Branding',
          description:
              'Verifies store brand title and action icons are present',
          steps: [
            AssertExistsStep(finder: StepFinder.byText('GearStore')),
            AssertExistsStep(
              finder: StepFinder.byIcon(Icons.shopping_bag_outlined),
            ),
            TapStep(finder: StepFinder.byIcon(Icons.shopping_bag_outlined)),
          ],
        ),
        ScenarioTest(
          name: 'Verify First Product Details & Price',
          group: 'Catalog Content',
          description:
              'Checks product title, rating badge, and formatted currency price',
          steps: [
            AssertTextStep(
              finder: StepFinder.byText('Wireless Noise-Canceling Headphones'),
              expectedText: 'Wireless Noise-Canceling Headphones',
            ),
            AssertExistsStep(finder: StepFinder.byText(r'$299.99')),
            AssertExistsStep(finder: StepFinder.byIcon(Icons.star_rounded)),
          ],
        ),
        ScenarioTest(
          name: 'Scroll Down to Verify Docking Station',
          group: 'Catalog Content',
          description:
              'Scrolls through the catalog list and verifies the 5th item',
          steps: [
            ScrollStep(
              finder: StepFinder.byWidgetType(ListView),
              offset: const Offset(0, -300),
            ),
            AssertExistsStep(
              finder: StepFinder.byText('Thunderbolt 4 Docking Station'),
            ),
            AssertExistsStep(finder: StepFinder.byText(r'$219.00')),
          ],
        ),
      ],
    ),
  );

  target.registerSuite(
    ScenarioTestSuite(
      screenName: 'Network & Errors',
      tests: [
        ScenarioTest(
          name: 'Offline Warning Indicator',
          group: 'Offline Mode',
          tags: const ['network', 'smoke'],
          description: 'Checks offline cached mode warning banner',
          requiredScenarioId: 'network_offline',
          steps: [
            AssertExistsStep(finder: StepFinder.byIcon(Icons.wifi_off_rounded)),
          ],
        ),
        ScenarioTest(
          name: 'Server Error Retry Button',
          group: 'Error Recovery',
          tags: const ['network', 'regression'],
          description: 'Verifies error state retry action button',
          requiredScenarioId: 'network_error_500',
          steps: [
            AssertExistsStep(finder: StepFinder.byIcon(Icons.refresh_rounded)),
          ],
        ),
      ],
    ),
  );

  target.registerSuite(
    ScenarioTestSuite(
      screenName: 'User Profile',
      tests: [
        ScenarioTest(
          name: 'Profile header and loyalty stats',
          group: 'Profile Content',
          description: 'Verifies signed-in user header and stat cards',
          requiredScenarioId: 'profile_complete',
          steps: [
            AssertExistsStep(finder: StepFinder.byText('My Profile')),
            AssertExistsStep(finder: StepFinder.byText('Jordan Lee')),
            AssertExistsStep(finder: StepFinder.byText('Gold Member')),
            AssertExistsStep(finder: StepFinder.byText('1840')),
          ],
        ),
        ScenarioTest(
          name: 'Email verification banner',
          group: 'Verification',
          description: 'Shows resend action when email is not verified',
          requiredScenarioId: 'profile_unverified',
          steps: [
            AssertExistsStep(finder: StepFinder.byText('Verify your email')),
            AssertExistsStep(finder: StepFinder.byText('Resend email')),
          ],
        ),
        ScenarioTest(
          name: 'Guest sign-in prompt',
          group: 'Guest Mode',
          description: 'Guest scenario shows sign-in call to action',
          requiredScenarioId: 'profile_guest',
          steps: [
            AssertExistsStep(finder: StepFinder.byText('Sign in to GearStore')),
            AssertExistsStep(finder: StepFinder.byText('Sign in')),
          ],
        ),
      ],
    ),
  );
}

class ScenarioKitExampleApp extends StatefulWidget {
  const ScenarioKitExampleApp({super.key});

  @override
  State<ScenarioKitExampleApp> createState() => _ScenarioKitExampleAppState();
}

class _ScenarioKitExampleAppState extends State<ScenarioKitExampleApp> {
  String _screenName = 'Product Catalog';
  int _tabIndex = 0;

  void _onNavigateToScreen(String screenName) {
    setState(() {
      _screenName = screenName;
      _tabIndex = screenName == 'User Profile' ? 1 : 0;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _tabIndex = index;
      _screenName = index == 0 ? 'Product Catalog' : 'User Profile';
    });
  }

  ExampleAppShell _shell({
    required int initialTab,
    List<Product>? products,
    bool catalogIsOffline = false,
    bool catalogIsLoadingMore = false,
    Widget? catalogPage,
    UserProfile? profile,
    List<ProfileOrder>? profileOrders,
    bool profileShowVerification = false,
    bool profileIsLoading = false,
  }) {
    return ExampleAppShell(
      initialTabIndex: initialTab,
      selectedTabIndex: _tabIndex,
      onTabChanged: _onTabChanged,
      catalogProducts: products ?? mockSuccessProducts,
      catalogIsOffline: catalogIsOffline,
      catalogIsLoadingMore: catalogIsLoadingMore,
      catalogPage: catalogPage,
      profile: profile ?? mockProfileComplete,
      profileOrders: profileOrders ?? mockProfileOrders,
      profileShowVerification: profileShowVerification,
      profileIsLoading: profileIsLoading,
    );
  }

  List<Scenario> get _scenarios => [
        Scenario.success(
          id: 'catalog_success',
          name: 'Success (5 Products)',
          description: 'Standard product catalog populated with mock items',
          group: 'Catalog States',
          isDefault: true,
          metadata: const {
            'total_items': 5,
            'latency_ms': 240,
            'source': 'api.store.com/v1/products',
          },
          builder: (context) => _shell(initialTab: 0),
        ),
        Scenario.loading(
          id: 'catalog_loading',
          name: 'Loading State',
          description: 'Skeleton placeholder shimmer during initial API call',
          group: 'Catalog States',
          metadata: const {'simulated_delay': Duration(milliseconds: 1500)},
          builder: (context) => _shell(
            initialTab: 0,
            catalogPage: const ProductLoadingView(),
          ),
        ),
        Scenario.empty(
          id: 'catalog_empty',
          name: 'Empty State',
          description:
              'Zero items returned matching search or category filters',
          group: 'Catalog States',
          metadata: const {
            'search_query': 'Mechanical Keyboard',
            'results': 0,
          },
          builder: (context) => _shell(
            initialTab: 0,
            catalogPage: const ProductEmptyView(),
          ),
        ),
        Scenario.error(
          id: 'network_error_500',
          name: 'Server Error (500)',
          description: 'API returned Internal Server Error with retry action',
          group: 'Network Conditions',
          metadata: const {
            'status_code': 500,
            'error_code': 'ERR_INTERNAL_SERVER',
          },
          builder: (context) => _shell(
            initialTab: 0,
            catalogPage: const ProductErrorView(
              errorCode: 500,
              errorMessage:
                  'Unable to reach inventory servers. Please try again.',
            ),
          ),
        ),
        Scenario.offline(
          id: 'network_offline',
          name: 'Offline Cached Mode',
          description:
              'Device is offline; displaying locally cached items and warning banner',
          group: 'Network Conditions',
          metadata: const {'cached_at': '10 mins ago', 'cached_items': 2},
          builder: (context) => _shell(
            initialTab: 0,
            products: mockOfflineProducts,
            catalogIsOffline: true,
          ),
        ),
        Scenario.paginationLoading(
          id: 'catalog_pagination',
          name: 'Pagination Loading',
          description: 'User scrolls to bottom; page 2 is actively fetching',
          group: 'Catalog States',
          metadata: const {'current_page': 1, 'next_page': 2},
          builder: (context) => _shell(
            initialTab: 0,
            products: mockOfflineProducts,
            catalogIsLoadingMore: true,
          ),
        ),
        Scenario.success(
          id: 'profile_complete',
          name: 'Profile (Signed In)',
          description: 'Full account with orders, preferences, and stats',
          group: 'Profile States',
          isDefault: false,
          metadata: const {
            'user_id': 'user_42',
            'tier': 'gold',
            'orders': 24,
          },
          builder: (context) => _shell(
            initialTab: 1,
            profile: mockProfileComplete,
          ),
        ),
        Scenario.loading(
          id: 'profile_loading',
          name: 'Profile Loading',
          description: 'Skeleton state while account API loads',
          group: 'Profile States',
          builder: (context) => _shell(
            initialTab: 1,
            profileIsLoading: true,
          ),
        ),
        Scenario(
          id: 'profile_unverified',
          name: 'Email Not Verified',
          description: 'Signed-in user with verification banner',
          group: 'Profile States',
          metadata: const {'email_verified': false},
          builder: (context) => _shell(
            initialTab: 1,
            profile: mockProfileUnverified,
            profileShowVerification: true,
          ),
        ),
        Scenario.empty(
          id: 'profile_guest',
          name: 'Guest (Signed Out)',
          description: 'Browse-only profile with sign-in prompt',
          group: 'Profile States',
          builder: (context) => _shell(
            initialTab: 1,
            profile: mockProfileGuest,
            profileOrders: const [],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: exampleNavigatorKey,
      title: 'ScenarioKit Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: ScenarioKit(
        navigatorKey: exampleNavigatorKey,
        screenName: _screenName,
        onNavigateToScreen: _onNavigateToScreen,
        scenarios: _scenarios,
      ),
    );
  }
}