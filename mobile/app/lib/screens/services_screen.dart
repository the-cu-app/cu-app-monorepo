import 'package:flutter/material.dart';
// import 'cards_screen.dart'; // Disabled - needs CU widgets
import 'check_deposit_screen.dart';
import 'connect_account_screen.dart';
import 'analytics/spending_analytics_screen.dart';
// import 'analytics/net_worth_screen.dart'; // Disabled - needs CU widgets
import 'transfer_screen.dart';
import 'bill_pay_screen.dart';
import 'zelle_send_screen.dart';
import 'no_cap_dashboard_screen.dart';
import 'create_commitment_screen.dart';
// import 'file_dropper_demo_screen.dart'; // Disabled - needs CU widgets
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Services',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServicesGrid(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {
        'title': 'Card Management',
        'description': 'Manage your debit and credit cards',
        'icon': Icons.credit_card,
        'color': Colors.deepPurple,
        'route': '/cards',
      },
      {
        'title': 'Connect Accounts',
        'description': 'Link external bank accounts',
        'icon': Icons.link,
        'color': Colors.cyan,
        'route': '/connect-accounts',
      },
      {
        'title': 'Spending Analytics',
        'description': 'Track and analyze your spending',
        'icon': Icons.pie_chart,
        'color': Colors.pink,
        'route': '/spending-analytics',
      },
      {
        'title': 'Net Worth',
        'description': 'Monitor your financial health',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'route': '/net-worth',
      },
      {
        'title': 'Transfer Money',
        'description': 'Send money between accounts or to others',
        'icon': Icons.swap_horiz,
        'color': Colors.blue,
        'route': '/transfer',
      },
      {
        'title': 'Pay Bills',
        'description': 'Schedule and manage bill payments',
        'icon': Icons.payment,
        'color': Colors.amber,
        'route': '/bill-pay',
      },
      {
        'title': 'Deposit Check',
        'description': 'Mobile check deposit',
        'icon': Icons.upload,
        'color': Colors.orange,
        'route': '/check-deposit',
      },
      {
        'title': 'Apply for Loan',
        'description': 'Personal, auto, and home loans',
        'icon': Icons.account_balance,
        'color': Colors.purple,
        'route': '/loan-application',
      },
      {
        'title': 'Open Account',
        'description': 'Savings, checking, and investment accounts',
        'icon': Icons.add_circle_outline,
        'color': Colors.teal,
        'route': '/open-account',
      },
      {
        'title': 'Customer Support',
        'description': 'Get help and support',
        'icon': Icons.support_agent,
        'color': Colors.indigo,
        'route': '/support',
      },
      {
        'title': 'No Cap System',
        'description': 'AI budget commitments you can\'t break',
        'icon': Icons.lock_outline,
        'color': Colors.deepPurple,
        'route': '/no-cap-dashboard',
      },
      {
        'title': 'File Upload',
        'description': 'Upload and manage documents',
        'icon': Icons.cloud_upload,
        'color': Colors.lightBlue,
        'route': '/file-dropper',
      },
      {
        'title': 'CU Widget Showcase',
        'description': 'View all Credit Union design components',
        'icon': Icons.widgets,
        'color': Colors.black,
        'route': '/cu-showcase',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(context, service);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Card(
      child: InkWell(
        onTap: () {
          if (service.containsKey('route')) {
            switch (service['route']) {
              case '/cards':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card Management coming soon!'),
                    backgroundColor: Colors.deepPurple,
                  ),
                );
                break;
              case '/check-deposit':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CheckDepositScreen()),
                );
                break;
              case '/connect-accounts':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConnectAccountScreen()),
                );
                break;
              case '/spending-analytics':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpendingAnalyticsScreen()),
                );
                break;
              case '/net-worth':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Net Worth tracking coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
                break;
              case '/transfer':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransferScreen()),
                );
                break;
              case '/bill-pay':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BillPayScreen()),
                );
                break;
              case '/loan-application':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loan applications coming soon!'),
                    backgroundColor: Colors.purple,
                  ),
                );
                break;
              case '/open-account':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account opening coming soon!'),
                    backgroundColor: Colors.teal,
                  ),
                );
                break;
              case '/support':
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Customer Support'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.phone),
                          title: Text('Call Support'),
                          subtitle: Text('1-800-CUAPP-AI'),
                        ),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Email Support'),
                          subtitle: Text('support@cu.app'),
                        ),
                        ListTile(
                          leading: Icon(Icons.chat),
                          title: Text('Live Chat'),
                          subtitle: Text('Available 24/7'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
                break;
              case '/no-cap-dashboard':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoCapDashboardScreen()),
                );
                break;
              case '/file-dropper':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File Upload coming soon!'),
                    backgroundColor: Colors.lightBlue,
                  ),
                );
                break;
              case '/cu-showcase':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CU Widget Showcase - Coming Soon!'),
                    backgroundColor: Colors.black,
                  ),
                );
                break;
              default:
                break;
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: (service['color'] as Color).withValues(alpha: 0.1),
                child: Icon(
                  service['icon'] as IconData,
                  color: service['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  service['title'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  service['description'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Scanner launching...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Scan QR'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Nearby ATMs'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Icon(Icons.location_on, color: Colors.blue),
                                title: Text('Chase Bank'),
                                subtitle: Text('0.3 miles - 24/7 Access'),
                              ),
                              ListTile(
                                leading: Icon(Icons.location_on, color: Colors.blue),
                                title: Text('Bank of America'),
                                subtitle: Text('0.5 miles - No Fee'),
                              ),
                              ListTile(
                                leading: Icon(Icons.location_on, color: Colors.blue),
                                title: Text('Wells Fargo'),
                                subtitle: Text('0.8 miles - 24/7 Access'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Maps...'),
                                  ),
                                );
                              },
                              child: const Text('View in Maps'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Find ATM'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Schedule Appointment'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Select a service:'),
                              SizedBox(height: 16),
                              ListTile(
                                leading: Icon(Icons.account_balance),
                                title: Text('Loan Consultation'),
                                dense: true,
                              ),
                              ListTile(
                                leading: Icon(Icons.trending_up),
                                title: Text('Investment Advisor'),
                                dense: true,
                              ),
                              ListTile(
                                leading: Icon(Icons.credit_card),
                                title: Text('Account Services'),
                                dense: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening appointment scheduler...'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Appointments'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Help & Support'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.book),
                                title: Text('FAQ'),
                                subtitle: Text('Common questions'),
                              ),
                              ListTile(
                                leading: Icon(Icons.chat),
                                title: Text('Chat with CU.APPGPT'),
                                subtitle: Text('AI Assistant'),
                              ),
                              ListTile(
                                leading: Icon(Icons.phone),
                                title: Text('Call Support'),
                                subtitle: Text('1-800-CUAPP-AI'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Help'),
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
    );
  }
}
