import 'package:flutter/material.dart';
import 'package:scenario_kit_flutter/scenario_kit_flutter.dart';

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
}

/// Example Product model.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    this.inStock = true,
  });

  final String id;
  final String name;
  final double price;
  final double rating;
  final String category;
  final bool inStock;
}

// ---------------------------------------------------------------------------
// Mock Datasets
// ---------------------------------------------------------------------------

const mockSuccessProducts = <Product>[
  Product(
    id: 'p1',
    name: 'Wireless Noise-Canceling Headphones',
    price: 299.99,
    rating: 4.8,
    category: 'Audio',
  ),
  Product(
    id: 'p2',
    name: 'Mechanical Gaming Keyboard',
    price: 149.50,
    rating: 4.6,
    category: 'Accessories',
  ),
  Product(
    id: 'p3',
    name: 'Ultra-Wide 4K Gaming Monitor',
    price: 689.00,
    rating: 4.9,
    category: 'Displays',
  ),
  Product(
    id: 'p4',
    name: 'Ergonomic Vertical Mouse',
    price: 79.99,
    rating: 4.4,
    category: 'Accessories',
  ),
  Product(
    id: 'p5',
    name: 'Thunderbolt 4 Docking Station',
    price: 219.00,
    rating: 4.7,
    category: 'Hubs & Power',
  ),
];

const mockOfflineProducts = <Product>[
  Product(
    id: 'p1',
    name: 'Wireless Noise-Canceling Headphones',
    price: 299.99,
    rating: 4.8,
    category: 'Audio (Cached)',
  ),
  Product(
    id: 'p2',
    name: 'Mechanical Gaming Keyboard',
    price: 149.50,
    rating: 4.6,
    category: 'Accessories (Cached)',
  ),
];

// ---------------------------------------------------------------------------
// Application Root & Scenarios Definition
// ---------------------------------------------------------------------------

class ScenarioKitExampleApp extends StatelessWidget {
  const ScenarioKitExampleApp({super.key});

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
        screenName: 'Product Catalog',
        scenarios: [
          // 1. Success State (Default)
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
            builder: (context) =>
                const ProductCatalogScreen(products: mockSuccessProducts),
          ),

          // 2. Loading State
          Scenario.loading(
            id: 'catalog_loading',
            name: 'Loading State',
            description: 'Skeleton placeholder shimmer during initial API call',
            group: 'Catalog States',
            metadata: const {'simulated_delay': Duration(milliseconds: 1500)},
            builder: (context) => const ProductLoadingView(),
          ),

          // 3. Empty State
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
            builder: (context) => const ProductEmptyView(),
          ),

          // 4. Server Error State
          Scenario.error(
            id: 'network_error_500',
            name: 'Server Error (500)',
            description: 'API returned Internal Server Error with retry action',
            group: 'Network Conditions',
            metadata: const {
              'status_code': 500,
              'error_code': 'ERR_INTERNAL_SERVER',
            },
            builder: (context) => const ProductErrorView(
              errorCode: 500,
              errorMessage:
                  'Unable to reach inventory servers. Please try again.',
            ),
          ),

          // 5. Offline State
          Scenario.offline(
            id: 'network_offline',
            name: 'Offline Cached Mode',
            description:
                'Device is offline; displaying locally cached items and warning banner',
            group: 'Network Conditions',
            metadata: const {'cached_at': '10 mins ago', 'cached_items': 2},
            builder: (context) => const ProductCatalogScreen(
              products: mockOfflineProducts,
              isOffline: true,
            ),
          ),

          // 6. Pagination Loading State
          Scenario.paginationLoading(
            id: 'catalog_pagination',
            name: 'Pagination Loading',
            description: 'User scrolls to bottom; page 2 is actively fetching',
            group: 'Catalog States',
            metadata: const {'current_page': 1, 'next_page': 2},
            builder: (context) => const ProductCatalogScreen(
              products: mockOfflineProducts,
              isLoadingMore: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen Views
// ---------------------------------------------------------------------------

class ProductCatalogScreen extends StatelessWidget {
  const ProductCatalogScreen({
    super.key,
    required this.products,
    this.isOffline = false,
    this.isLoadingMore = false,
  });

  final List<Product> products;
  final bool isOffline;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GearStore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              color: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'You are offline. Showing cached catalog.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                final product = products[index];
                return ProductCard(product: product);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.devices_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        product.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductLoadingView extends StatelessWidget {
  const ProductLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('GearStore')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductEmptyView extends StatelessWidget {
  const ProductEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('GearStore')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Products Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We could not find any products matching your filters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () {},
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductErrorView extends StatelessWidget {
  const ProductErrorView({
    super.key,
    required this.errorCode,
    required this.errorMessage,
  });

  final int errorCode;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('GearStore')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error $errorCode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
