import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class SimpleDashboardScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final Function(Map<String, dynamic>)? onAccountSelected;

  const SimpleDashboardScreen({
    super.key,
    this.scrollController,
    this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : double.infinity,
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black,
                          Colors.grey.shade900,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '\$1,356,987.03',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Accounts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
              ),
              
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final accounts = [
                      {
                        'name': 'Personal Checking',
                        'type': 'checking',
                        'balance': 145234.67,
                        'lastFour': '4829',
                      },
                      {
                        'name': 'Business Premier',
                        'type': 'checking',
                        'balance': 892451.23,
                        'lastFour': '7156',
                      },
                      {
                        'name': 'Personal Savings',
                        'type': 'savings',
                        'balance': 68301.13,
                        'lastFour': '9234',
                      },
                    ];
                    
                    if (index >= accounts.length) return null;
                    final account = accounts[index];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet),
                          title: Text(account['name'] as String),
                          subtitle: Text('${account['type']} •••• ${account['lastFour']}'),
                          trailing: Text(
                            '\$${_formatAmount(account['balance'] as double)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            if (onAccountSelected != null) {
                              onAccountSelected!(account);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  childCount: 3,
                ),
              ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}