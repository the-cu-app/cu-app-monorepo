import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/plaid_service.dart';
import '../../services/banking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class ConnectAccountsScreen extends StatefulWidget {
  const ConnectAccountsScreen({super.key});

  @override
  State<ConnectAccountsScreen> createState() => _ConnectAccountsScreenState();
}

class _ConnectAccountsScreenState extends State<ConnectAccountsScreen> {
  final PlaidService _plaidService = PlaidService();
  final BankingService _bankingService = BankingService();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<ConnectedAccount> _connectedAccounts = [];
  List<Institution> _popularInstitutions = [];
  List<Institution> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
    _loadPopularInstitutions();
  }

  Future<void> _loadConnectedAccounts() async {
    setState(() => _isLoading = true);
    try {
      // Load connected accounts from Plaid
      final accounts = await _bankingService.getUserAccounts();
      setState(() {
        _connectedAccounts = accounts.map((acc) => ConnectedAccount(
          id: acc['id'] ?? '',
          institutionName: acc['institution'] ?? 'Unknown Bank',
          accountName: acc['name'] ?? 'Account',
          accountType: acc['subtype'] ?? 'checking',
          mask: acc['mask'] ?? '****',
          balance: (acc['balance'] ?? 0.0).toDouble(),
          lastSync: DateTime.now(),
          status: ConnectionStatus.healthy,
        )).toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadPopularInstitutions() {
    _popularInstitutions = [
      Institution(id: 'ins_3', name: 'Chase', logo: '', plaidId: 'ins_3'),
      Institution(id: 'ins_1', name: 'Bank of America', logo: '', plaidId: 'ins_1'),
      Institution(id: 'ins_4', name: 'Wells Fargo', logo: '', plaidId: 'ins_4'),
      Institution(id: 'ins_5', name: 'Citi', logo: '🌆', plaidId: 'ins_5'),
      Institution(id: 'ins_6', name: 'US Bank', logo: '🇺🇸', plaidId: 'ins_6'),
      Institution(id: 'ins_7', name: 'PNC', logo: '', plaidId: 'ins_7'),
      Institution(id: 'ins_8', name: 'Capital One', logo: '💳', plaidId: 'ins_8'),
      Institution(id: 'ins_9', name: 'TD Bank', logo: '🍁', plaidId: 'ins_9'),
    ];
  }

  Future<void> _connectInstitution(Institution institution) async {
    setState(() => _isLoading = true);
    try {
      // Create Plaid Link token
      final linkToken = await _plaidService.createLinkToken();
      
      // In production, this would launch Plaid Link
      // For now, create a sandbox connection
      final publicToken = await _plaidService.createSandboxPublicToken(
        institutionId: institution.plaidId,
        initialProducts: ['auth', 'transactions', 'identity', 'accounts_details_transactions'],
      );
      
      // Exchange for access token
      await _plaidService.exchangePublicToken(publicToken);
      
      // Show success
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to ${institution.name}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload accounts
        await _loadConnectedAccounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchInstitutions(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() {
      _searchResults = _popularInstitutions
          .where((inst) => inst.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Accounts'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Connected Accounts Section
            if (_connectedAccounts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Connected Accounts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final account = _connectedAccounts[index];
                    return _buildConnectedAccountCard(account);
                  },
                  childCount: _connectedAccounts.length,
                ),
              ),
            ],
            
            // Add New Account Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Account',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: _searchInstitutions,
                      decoration: InputDecoration(
                        hintText: 'Search for your bank or credit union',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Search Results or Popular Banks
            if (_searchResults.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final institution = _searchResults[index];
                      return _buildInstitutionCard(institution);
                    },
                    childCount: _searchResults.length,
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Popular Banks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final institution = _popularInstitutions[index];
                      return _buildInstitutionCard(institution);
                    },
                    childCount: _popularInstitutions.length,
                  ),
                ),
              ),
            ],
            
            // Loading Overlay
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedAccountCard(ConnectedAccount account) {
    final theme = Theme.of(context);
    final statusColor = account.status == ConnectionStatus.healthy
        ? Colors.green
        : account.status == ConnectionStatus.needsReauth
            ? Colors.orange
            : Colors.red;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance, size: 24),
        ),
        title: Text(account.institutionName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account.accountName} ••${account.mask}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  account.status.name,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${account.balance.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              _loadConnectedAccounts();
            } else if (value == 'remove') {
              // Handle account removal
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to account details
        },
      ),
    );
  }

  Widget _buildInstitutionCard(Institution institution) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () => _connectInstitution(institution),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                institution.logo,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  institution.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data Models
class ConnectedAccount {
  final String id;
  final String institutionName;
  final String accountName;
  final String accountType;
  final String mask;
  final double balance;
  final DateTime lastSync;
  final ConnectionStatus status;

  ConnectedAccount({
    required this.id,
    required this.institutionName,
    required this.accountName,
    required this.accountType,
    required this.mask,
    required this.balance,
    required this.lastSync,
    required this.status,
  });
}

enum ConnectionStatus { healthy, needsReauth, error }

class Institution {
  final String id;
  final String name;
  final String logo;
  final String plaidId;

  Institution({
    required this.id,
    required this.name,
    required this.logo,
    required this.plaidId,
  });
}