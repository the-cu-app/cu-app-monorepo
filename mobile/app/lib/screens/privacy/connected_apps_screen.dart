import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, showDialog, CircularProgressIndicator;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../../services/plaid_service.dart';

class ConnectedAppsScreen extends StatefulWidget {
  const ConnectedAppsScreen({super.key});

  @override
  State<ConnectedAppsScreen> createState() => _ConnectedAppsScreenState();
}

class _ConnectedAppsScreenState extends State<ConnectedAppsScreen> {
  final PlaidService _plaidService = PlaidService();
  List<ConnectedApp> _connectedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedApps();
  }

  Future<void> _loadConnectedApps() async {
    setState(() => _isLoading = true);

    // Simulate loading connected apps with Plaid data
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _connectedApps = [
        ConnectedApp(
          id: '1',
          name: 'Plaid',
          description: 'Financial data aggregation',
          logoUrl: 'https://www.google.com/s2/favicons?domain=plaid.com&sz=128',
          connectedDate: DateTime.now().subtract(const Duration(days: 30)),
          lastAccessed: DateTime.now().subtract(const Duration(hours: 2)),
          permissions: [
            AppPermission(type: PermissionType.accounts, granted: true),
            AppPermission(type: PermissionType.transactions, granted: true),
            AppPermission(type: PermissionType.identity, granted: true),
            AppPermission(type: PermissionType.balances, granted: true),
          ],
          status: ConnectionStatus.active,
        ),
        ConnectedApp(
          id: '2',
          name: 'Mint',
          description: 'Budget tracking and financial planning',
          logoUrl: 'https://www.google.com/s2/favicons?domain=mint.com&sz=128',
          connectedDate: DateTime.now().subtract(const Duration(days: 15)),
          lastAccessed: DateTime.now().subtract(const Duration(days: 1)),
          permissions: [
            AppPermission(type: PermissionType.accounts, granted: true),
            AppPermission(type: PermissionType.transactions, granted: true),
            AppPermission(type: PermissionType.balances, granted: true),
          ],
          status: ConnectionStatus.active,
        ),
        ConnectedApp(
          id: '3',
          name: 'Personal Capital',
          description: 'Investment and wealth management',
          logoUrl: 'https://www.google.com/s2/favicons?domain=personalcapital.com&sz=128',
          connectedDate: DateTime.now().subtract(const Duration(days: 60)),
          lastAccessed: DateTime.now().subtract(const Duration(days: 7)),
          permissions: [
            AppPermission(type: PermissionType.accounts, granted: true),
            AppPermission(type: PermissionType.balances, granted: true),
          ],
          status: ConnectionStatus.needsReauth,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _showAppDetails(ConnectedApp app) async {
    await showDialog(
      context: context,
      builder: (context) => Center(
        child: _AppDetailsDialog(app: app, onRevoke: () => _revokeAccess(app)),
      ),
    );
  }

  Future<void> _revokeAccess(ConnectedApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: _RevokeConfirmationDialog(appName: app.name),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _connectedApps.removeWhere((a) => a.id == app.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return CUScacuold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CUAppBar(
        title: const Text(
          'Connected Apps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Your Data Sharing',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Control which apps have access to your financial data. You can revoke access at any time.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              if (_connectedApps.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.apps,
                            label: 'Active Apps',
                            value: '${_connectedApps.where((a) => a.status == ConnectionStatus.active).length}',
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.warning_rounded,
                            label: 'Need Attention',
                            value: '${_connectedApps.where((a) => a.status == ConnectionStatus.needsReauth).length}',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Connected Apps List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_connectedApps.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Connected Apps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'Geist',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You haven\'t connected any third-party apps yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final app = _connectedApps[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ConnectedAppCard(
                            app: app,
                            onTap: () => _showAppDetails(app),
                          ),
                        );
                      },
                      childCount: _connectedApps.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CUOutlinedCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedAppCard extends StatelessWidget {
  final ConnectedApp app;
  final VoidCallback onTap;

  const _ConnectedAppCard({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final statusColor = app.status == ConnectionStatus.active
        ? Colors.green.shade600
        : const Color(0xFFF59E0B);

    final statusText = app.status == ConnectionStatus.active
        ? 'Active'
        : 'Needs Reauth';

    return CUOutlinedCard(
      onTap: onTap,
      child: Row(
        children: [
          CUAvatar(
            text: app.name,
            size: 48,
            imageUrl: app.logoUrl,
            icon: Icons.apps,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      _formatLastAccessed(app.lastAccessed),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  String _formatLastAccessed(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AppDetailsDialog extends StatelessWidget {
  final ConnectedApp app;
  final VoidCallback onRevoke;

  const _AppDetailsDialog({required this.app, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CUAvatar(
                text: app.name,
                size: 56,
                imageUrl: app.logoUrl,
                icon: Icons.apps,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Connection Info
          Text(
            'Connection Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Connected',
            value: _formatDate(app.connectedDate),
          ),
          _InfoRow(
            label: 'Last Access',
            value: _formatDate(app.lastAccessed),
          ),
          const SizedBox(height: 24),

          // Permissions
          Text(
            'Data Access Permissions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          ...app.permissions.map((perm) => _PermissionRow(permission: perm)),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: CUButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRevoke();
                  },
                  variant: CUButtonVariant.secondary,
                  child: const Text('Revoke Access'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Geist',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final AppPermission permission;

  const _PermissionRow({required this.permission});

  @override
  Widget build(BuildContext context) {
    final icon = _getPermissionIcon(permission.type);
    final label = _getPermissionLabel(permission.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.accounts:
        return Icons.account_balance_wallet;
      case PermissionType.transactions:
        return Icons.receipt_long;
      case PermissionType.identity:
        return Icons.person;
      case PermissionType.balances:
        return Icons.account_balance;
    }
  }

  String _getPermissionLabel(PermissionType type) {
    switch (type) {
      case PermissionType.accounts:
        return 'Account Information';
      case PermissionType.transactions:
        return 'Transaction History';
      case PermissionType.identity:
        return 'Identity Verification';
      case PermissionType.balances:
        return 'Account Balances';
    }
  }
}

class _RevokeConfirmationDialog extends StatelessWidget {
  final String appName;

  const _RevokeConfirmationDialog({required this.appName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 48, color: Colors.orange.shade600),
          const SizedBox(height: 16),
          Text(
            'Revoke Access?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This will immediately revoke $appName\'s access to your financial data. The app will no longer be able to view your accounts, transactions, or balances.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CUButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  variant: CUButtonVariant.secondary,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CUButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  variant: CUButtonVariant.secondary,
                  child: const Text('Revoke'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Models
class ConnectedApp {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final DateTime connectedDate;
  final DateTime lastAccessed;
  final List<AppPermission> permissions;
  final ConnectionStatus status;

  ConnectedApp({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.connectedDate,
    required this.lastAccessed,
    required this.permissions,
    required this.status,
  });
}

class AppPermission {
  final PermissionType type;
  final bool granted;

  AppPermission({required this.type, required this.granted});
}

enum PermissionType { accounts, transactions, identity, balances }
enum ConnectionStatus { active, needsReauth, revoked }
