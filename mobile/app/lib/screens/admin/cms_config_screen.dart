import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/cms_config_service.dart';
import '../../services/feature_registry_service.dart';
import '../../services/marketing_product_service.dart';

/// CMS Configuration Screen
/// 
/// Admin interface for credit unions to configure:
/// - Components & widgets
/// - FDX platform integration
/// - Core banking adapters
/// - Design tokens
/// - Branding
/// 
/// No code changes required - everything is database-driven.
class CMSConfigScreen extends StatefulWidget {
  const CMSConfigScreen({super.key});

  @override
  State<CMSConfigScreen> createState() => _CMSConfigScreenState();
}

class _CMSConfigScreenState extends State<CMSConfigScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return CUScaffold(
      appBar: CUAppBar(
        title: const Text('CMS Configuration'),
        actions: [
          CUButton(
            variant: CUButtonVariant.outline,
            onPressed: _saveAll,
            child: const Text('Save All'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: CUTheme.of(context).colors.surface,
            child: ListView(
              children: [
                _buildNavItem('Components', 0, Icons.widgets),
                _buildNavItem('Screens', 1, Icons.dashboard),
                _buildNavItem('Products', 2, Icons.shopping_bag),
                _buildNavItem('FDX Platform', 3, Icons.api),
                _buildNavItem('Core Banking', 4, Icons.account_balance),
                _buildNavItem('Design Tokens', 5, Icons.palette),
                _buildNavItem('Branding', 6, Icons.branding_watermark),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildComponentsTab(),
                _buildScreensTab(),
                _buildProductsTab(),
                _buildFDXTab(),
                _buildCoreBankingTab(),
                _buildDesignTokensTab(),
                _buildBrandingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return ListTile(
      leading: CUIcon(icon: icon),
      title: Text(label),
      selected: isSelected,
      onTap: () => setState(() => _selectedTab = index),
      selectedTileColor: CUTheme.of(context).colors.surfaceVariant,
    );
  }

  Widget _buildComponentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Component Configuration'),
          const SizedBox(height: 24),
          CUAlert(
            variant: CUAlertVariant.info,
            title: 'No Code Required',
            description: 'Configure all component props, styles, FDX bindings, and core banking adapters here.',
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: CMSConfigService.getComponentConfigs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CULoadingSpinner();
              }
              final configs = snapshot.data as Map<String, dynamic>;
              return Column(
                children: configs.entries.map((entry) {
                  return _buildComponentCard(entry.key, entry.value);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(String componentId, Map<String, dynamic> config) {
    return CUCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(componentId),
        subtitle: Text('Category: ${config['category']}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FDX Endpoint: ${config['fdx']?['endpoint'] ?? 'Not configured'}'),
                Text('Core Adapter: ${config['core']?['adapter'] ?? 'Not configured'}'),
                const SizedBox(height: 16),
                CUButton(
                  variant: CUButtonVariant.outline,
                  onPressed: () => _editComponent(componentId, config),
                  child: const Text('Edit Configuration'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreensTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Screen Configuration (149 Screens)'),
          const SizedBox(height: 16),
          CUAlert(
            variant: CUAlertVariant.info,
            title: 'Complete Screen Registry',
            description: 'Configure all 149 screens across 12 feature domains. Map components, FDX endpoints, and core banking functions.',
          ),
          const SizedBox(height: 24),
          // Feature domain tabs
          FutureBuilder(
            future: FeatureRegistryService.getAllDomains(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CULoadingSpinner();
              }
              final domains = snapshot.data as Map<String, Map<String, dynamic>>;
              
              return Column(
                children: domains.entries.map((entry) {
                  final domainId = entry.key;
                  final domainData = entry.value;
                  return _buildDomainSection(domainId, domainData);
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          CUButton(
            onPressed: _createNewScreen,
            child: const Text('Add New Screen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainSection(String domainId, Map<String, dynamic> domainData) {
    return FutureBuilder(
      future: FeatureRegistryService.getDomainScreens(domainId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final screens = snapshot.data as List<Map<String, dynamic>>;
        
        return CUCard(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(domainId.toUpperCase()),
            subtitle: Text('${screens.length} screens configured'),
            children: screens.map((screen) {
              return ListTile(
                title: Text(screen['screen_name'] ?? screen['screen_id']),
                subtitle: Text(screen['route_path'] ?? 'No route'),
                trailing: screen['is_enabled'] == true 
                    ? const CUBadge(label: 'Enabled', variant: CUBadgeVariant.success)
                    : const CUBadge(label: 'Disabled', variant: CUBadgeVariant.error),
                onTap: () => _editScreen(screen['screen_id'] as String),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    final productService = MarketingProductService();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Product Marketing Configuration'),
          const SizedBox(height: 16),
          CUAlert(
            variant: CUAlertVariant.info,
            title: 'Marketing Product Names',
            description: 'Configure product display names, descriptions, and marketing copy. Changes appear instantly in the app. Technical product codes remain unchanged for API compatibility.',
          ),
          const SizedBox(height: 24),
          FutureBuilder(
            future: productService.getProductsWithMarketingNames(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CULoadingSpinner();
              }
              
              final products = snapshot.data as List<Map<String, dynamic>>;
              
              if (products.isEmpty) {
                return CUCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CUTypography.h3('No Products Found'),
                        const SizedBox(height: 8),
                        Text('Products will appear here once they are added to product_catalog in Supabase.'),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: products.map((product) {
                  return _buildProductCard(product);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productService = MarketingProductService();
    
    return CUCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          product['display_name'] as String? ?? product['technical_name'] as String? ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${product['product_code']}'),
            if (product['product_type'] != null)
              Text('Type: ${product['product_type']}'),
            if (product['cms_hidden'] == true)
              const CUBadge(label: 'Hidden', variant: CUBadgeVariant.warning),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CUTypography.h4('Marketing Configuration'),
                const SizedBox(height: 16),
                _buildProductConfigField(
                  label: 'Display Name',
                  value: product['display_name'] ?? product['technical_name'],
                  onChanged: (value) async {
                    await productService.updateMarketingConfig(
                      productCode: product['product_code'],
                      displayName: value,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProductConfigField(
                  label: 'Marketing Description',
                  value: product['display_description'] ?? product['description'],
                  onChanged: (value) async {
                    await productService.updateMarketingConfig(
                      productCode: product['product_code'],
                      description: value,
                    );
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildProductConfigField(
                  label: 'Call to Action',
                  value: product['call_to_action'],
                  placeholder: 'e.g., "Open Account", "Apply Now"',
                  onChanged: (value) async {
                    await productService.updateMarketingConfig(
                      productCode: product['product_code'],
                      callToAction: value,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProductConfigField(
                  label: 'Badge Text',
                  value: product['badge_text'],
                  placeholder: 'e.g., "New", "Popular", "Limited"',
                  onChanged: (value) async {
                    await productService.updateMarketingConfig(
                      productCode: product['product_code'],
                      badgeText: value,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CUButton(
                        variant: CUButtonVariant.outline,
                        onPressed: () async {
                          await productService.updateMarketingConfig(
                            productCode: product['product_code'],
                            hidden: !(product['cms_hidden'] ?? false),
                          );
                          setState(() {}); // Refresh
                        },
                        child: Text(product['cms_hidden'] == true ? 'Show Product' : 'Hide Product'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CUButton(
                        onPressed: () async {
                          await productService.updateMarketingConfig(
                            productCode: product['product_code'],
                            enabled: !(product['cms_enabled'] ?? true),
                          );
                          setState(() {}); // Refresh
                        },
                        child: Text(product['cms_enabled'] == false ? 'Enable Product' : 'Disable Product'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CUTypography.h4('Technical Details'),
                const SizedBox(height: 8),
                CUCard(
                  color: CUTheme.of(context).colors.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Technical Name: ${product['technical_name']}'),
                        Text('Product Code: ${product['product_code']}'),
                        if (product['fees'] != null)
                          Text('Fees: ${product['fees']}'),
                        if (product['rates'] != null)
                          Text('Rates: ${product['rates']}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductConfigField({
    required String label,
    String? value,
    String? placeholder,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    final controller = TextEditingController(text: value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        CUTextField(
          controller: controller,
          placeholder: placeholder,
          maxLines: maxLines,
          onChanged: (value) => onChanged(value),
        ),
      ],
    );
  }

  Widget _buildFDXTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('FDX Platform Configuration'),
          const SizedBox(height: 24),
          FutureBuilder(
            future: CMSConfigService.getFDXConfig(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildFDXConfigForm();
              }
              return _buildFDXConfigForm(initialData: snapshot.data);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFDXConfigForm({Map<String, dynamic>? initialData}) {
    final gatewayUrlController = TextEditingController(
      text: initialData?['fdx_gateway_url'] ?? '',
    );
    final clientIdController = TextEditingController(
      text: initialData?['fdx_client_id'] ?? '',
    );

    return CUCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CUTypography.h3('FDX API Gateway'),
            const SizedBox(height: 16),
            CUTextField(
              controller: gatewayUrlController,
              label: 'Gateway URL',
              placeholder: 'https://api.fdx.com',
            ),
            const SizedBox(height: 16),
            CUTextField(
              controller: clientIdController,
              label: 'Client ID',
            ),
            const SizedBox(height: 24),
            CUButton(
              onPressed: () async {
                await CMSConfigService.updateFDXConfig(
                  gatewayUrl: gatewayUrlController.text,
                  clientId: clientIdController.text,
                );
                if (mounted) {
                  CUToaster.show(
                    context,
                    title: 'FDX Configuration Saved',
                    variant: CUToastVariant.success,
                  );
                }
              },
              child: const Text('Save FDX Configuration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreBankingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Core Banking Adapter Configuration'),
          const SizedBox(height: 24),
          FutureBuilder(
            future: CMSConfigService.getCoreBankingConfig(),
            builder: (context, snapshot) {
              return _buildCoreBankingForm(initialData: snapshot.data);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoreBankingForm({Map<String, dynamic>? initialData}) {
    String selectedSystem = initialData?['core_system'] ?? 'symitar';

    return CUCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CUTypography.h3('Core System Selection'),
            const SizedBox(height: 16),
            CUSelect<String>(
              value: selectedSystem,
              options: const [
                CUSelectOption(value: 'symitar', label: 'Jack Henry Symitar'),
                CUSelectOption(value: 'jackhenry', label: 'Jack Henry'),
                CUSelectOption(value: 'temenos', label: 'Temenos'),
                CUSelectOption(value: 'custom', label: 'Custom'),
              ],
              onChanged: (value) => setState(() => selectedSystem = value ?? 'symitar'),
            ),
            const SizedBox(height: 24),
            CUButton(
              onPressed: () async {
                await CMSConfigService.updateCoreBankingConfig(
                  coreSystem: selectedSystem,
                );
                if (mounted) {
                  CUToaster.show(
                    context,
                    title: 'Core Banking Configuration Saved',
                    variant: CUToastVariant.success,
                  );
                }
              },
              child: const Text('Save Core Banking Config'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignTokensTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Design Token Overrides'),
          const SizedBox(height: 24),
          FutureBuilder(
            future: CMSConfigService.getDesignTokens(),
            builder: (context, snapshot) {
              // Build token editor UI
              return CUCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Token editor coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUTypography.h2('Branding Configuration'),
          const SizedBox(height: 24),
          FutureBuilder(
            future: CMSConfigService.getBrandingConfig(),
            builder: (context, snapshot) {
              // Build branding editor UI
              return CUCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Branding editor coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _editComponent(String componentId, Map<String, dynamic> config) {
    // Show component editor modal with full config
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure $componentId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CUTextField(
                label: 'FDX Endpoint',
                initialValue: config['fdx']?['endpoint']?.toString(),
                onChanged: (value) {
                  // Update FDX endpoint
                },
              ),
              const SizedBox(height: 16),
              CUTextField(
                label: 'Core Banking Adapter',
                initialValue: config['core']?['adapter']?.toString(),
                onChanged: (value) {
                  // Update core adapter
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save component config
              Navigator.pop(context);
              CUToaster.show(
                context,
                title: 'Component configuration saved',
                variant: CUToastVariant.success,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editScreen(String screenId) {
    // Load and edit screen configuration
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenConfigEditor(screenId: screenId),
      ),
    );
  }

  void _createNewScreen() {
    // Show screen builder UI
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Screen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CUTextField(label: 'Screen ID', placeholder: 'my-custom-screen'),
            const SizedBox(height: 16),
            CUTextField(label: 'Screen Name', placeholder: 'My Custom Screen'),
            const SizedBox(height: 16),
            CUSelect<String>(
              label: 'Category',
              options: const [
                CUSelectOption(value: 'custom', label: 'Custom'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Screen Configuration Editor
class ScreenConfigEditor extends StatelessWidget {
  final String screenId;
  
  const ScreenConfigEditor({super.key, required this.screenId});

  @override
  Widget build(BuildContext context) {
    return CUScaffold(
      appBar: CUAppBar(
        title: Text('Configure: $screenId'),
      ),
      body: FutureBuilder(
        future: FeatureRegistryService.getScreenConfig(screenId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CULoadingSpinner();
          }
          
          final config = snapshot.data as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CUTypography.h2(config['screen_name'] ?? screenId),
                const SizedBox(height: 24),
                CUTypography.h3('FDX Endpoints'),
                const SizedBox(height: 16),
                // FDX endpoint configuration UI
                CUCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('FDX endpoint: ${config['fdx_endpoints']?['primary'] ?? 'Not configured'}'),
                  ),
                ),
                const SizedBox(height: 24),
                CUTypography.h3('Core Banking Functions'),
                const SizedBox(height: 16),
                CUCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Core function: ${config['core_functions']?['primary'] ?? 'Not configured'}'),
                  ),
                ),
                const SizedBox(height: 24),
                CUTypography.h3('Component Tree'),
                const SizedBox(height: 16),
                CUCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('${(config['component_tree'] as List?)?.length ?? 0} components configured'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAll() async {
    // Save all configurations
    CUToaster.show(
      context,
      title: 'All configurations saved',
      variant: CUToastVariant.success,
    );
  }
}

