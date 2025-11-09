import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/account_products_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/consistent_list_tile.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class AccountProductsScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? biometricSettings;
  
  const AccountProductsScreen({
    super.key,
    this.userProfile,
    this.biometricSettings,
  });

  @override
  State<AccountProductsScreen> createState() => _AccountProductsScreenState();
}

class _AccountProductsScreenState extends State<AccountProductsScreen> 
    with TickerProviderStateMixin {
  final AccountProductsService _productsService = AccountProductsService();
  
  late TabController _tabController;
  List<AccountProduct> _allProducts = [];
  List<AccountProduct> _recommendedProducts = [];
  List<AccountProduct> _bankingProducts = [];
  List<AccountProduct> _creditProducts = [];
  List<AccountProduct> _investmentProducts = [];
  
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Load all available products
      _allProducts = await _productsService.getAvailableProducts();
      
      // Get recommendations if user profile is provided
      if (widget.userProfile != null) {
        _recommendedProducts = await _productsService.getRecommendedProducts(
          userProfile: widget.userProfile!,
        );
      } else {
        _recommendedProducts = _allProducts
            .where((p) => p.isRecommended)
            .toList();
      }
      
      // Categorize products
      _bankingProducts = _allProducts
          .where((p) => p.category == ProductCategory.banking)
          .toList();
      _creditProducts = _allProducts
          .where((p) => p.category == ProductCategory.credit)
          .toList();
      _investmentProducts = _allProducts
          .where((p) => p.category == ProductCategory.investment)
          .toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Products',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recommended'),
            Tab(text: 'Banking'),
            Tab(text: 'Credit'),
            Tab(text: 'Investments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsList(_recommendedProducts, isRecommended: true),
                    _buildProductsList(_bankingProducts),
                    _buildProductsList(_creditProducts),
                    _buildProductsList(_investmentProducts),
                  ],
                ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductsList(
    List<AccountProduct> products, {
    bool isRecommended = false,
  }) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new product offerings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, isRecommended: isRecommended);
      },
    );
  }
  
  Widget _buildProductCard(AccountProduct product, {bool isRecommended = false}) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ConsistentListTile(
        leading: ConsistentListTileLeading(
          icon: _getProductIcon(product.type),
          backgroundColor: _getProductColor(product.type).withOpacity(0.1),
          iconColor: _getProductColor(product.type),
        ),
        title: Row(
          children: [
            Expanded(
              child: ConsistentListTileTitle(
                text: product.name,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (product.isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConsistentListTileSubtitle(
              text: '${product.institution} • ${_getAccountTypeName(product.type)}',
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                height: 1.3,
                fontFamily: 'Geist',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Key details row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (product.interestRate > 0)
                  _buildDetailChip(
                    '${product.interestRate.toStringAsFixed(2)}% APY',
                    Icons.trending_up,
                    Colors.green,
                  ),
                if (product.monthlyFee == 0)
                  _buildDetailChip(
                    'No Fee',
                    Icons.money_off,
                    Colors.blue,
                  ),
                if (product.minimumDeposit <= 25)
                  _buildDetailChip(
                    'Low Min',
                    Icons.account_balance_wallet,
                    Colors.orange,
                  ),
                if (product.isPlaidSupported)
                  _buildDetailChip(
                    'Instant',
                    Icons.link,
                    Colors.purple,
                  ),
              ],
            ),
          ],
        ),
        trailing: ConsistentListTileTrailing(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => _createAccount(product),
                style: FilledButton.styleFrom(
                  backgroundColor: product.isRecommended
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.8),
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  product.isPlaidSupported ? 'Connect' : 'Open',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () => _showProductDetails(product),
        backgroundColor: product.isRecommended
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildDetailChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
  
  void _showProductDetails(AccountProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsSheet(product),
    );
  }
  
  Widget _buildProductDetailsSheet(AccountProduct product) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getProductColor(product.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getProductIcon(product.type),
                          color: _getProductColor(product.type),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.institution,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    product.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      fontFamily: 'Geist',
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Key details
                  Text(
                    'Account Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    'Account Type',
                    _getAccountTypeName(product.type),
                  ),
                  _buildDetailRow(
                    'Minimum Opening Deposit',
                    '\$${product.minimumDeposit.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Monthly Maintenance Fee',
                    product.monthlyFee == 0 
                        ? 'None' 
                        : '\$${product.monthlyFee.toStringAsFixed(2)}',
                  ),
                  if (product.interestRate > 0)
                    _buildDetailRow(
                      'Interest Rate (APY)',
                      '${product.interestRate.toStringAsFixed(2)}%',
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Features
                  Text(
                    'Features & Benefits',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Geist',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ...product.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getProductColor(product.type),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _createAccount(product);
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text(
                            product.isPlaidSupported ? 'Connect Account' : 'Open Account',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Geist',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Geist',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _createAccount(AccountProduct product) async {
    SoundService().playButtonTap();
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating account...'),
            ],
          ),
        ),
      );
      
      // Create the account
      final result = await _productsService.createAccountProduct(
        productId: product.id,
        userInfo: widget.userProfile ?? {},
        biometricSettings: widget.biometricSettings ?? {},
        initialDeposit: product.minimumDeposit,
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Created Successfully!'),
            content: Text(
              'Your ${product.name} account has been created and added to your profile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('View Dashboard'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create account: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  Color _getProductColor(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Colors.blue;
      case AccountType.savings:
        return Colors.green;
      case AccountType.credit:
        return Colors.orange;
      case AccountType.investment:
        return Colors.purple;
      case AccountType.retirement:
        return Colors.indigo;
      case AccountType.moneyMarket:
        return Colors.teal;
      case AccountType.cd:
        return Colors.amber;
      case AccountType.loan:
        return Colors.red;
    }
  }
  
  IconData _getProductIcon(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return Icons.account_balance_wallet;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.credit:
        return Icons.credit_card;
      case AccountType.investment:
        return Icons.trending_up;
      case AccountType.retirement:
        return Icons.elderly;
      case AccountType.moneyMarket:
        return Icons.account_balance;
      case AccountType.cd:
        return Icons.lock_clock;
      case AccountType.loan:
        return Icons.request_quote;
    }
  }
  
  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return 'Checking Account';
      case AccountType.savings:
        return 'Savings Account';
      case AccountType.credit:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment Account';
      case AccountType.retirement:
        return 'Retirement Account (IRA)';
      case AccountType.moneyMarket:
        return 'Money Market Account';
      case AccountType.cd:
        return 'Certificate of Deposit';
      case AccountType.loan:
        return 'Loan Account';
    }
  }
}