import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, Colors, CircularProgressIndicator;
import 'package:cu_design_system_omni/cu_design_system_omni.dart';

class DataAccessHistoryScreen extends StatefulWidget {
  const DataAccessHistoryScreen({super.key});

  @override
  State<DataAccessHistoryScreen> createState() => _DataAccessHistoryScreenState();
}

class _DataAccessHistoryScreenState extends State<DataAccessHistoryScreen> {
  List<AccessEvent> _accessEvents = [];
  bool _isLoading = true;
  AccessFilter _selectedFilter = AccessFilter.all;

  @override
  void initState() {
    super.initState();
    _loadAccessHistory();
  }

  Future<void> _loadAccessHistory() async {
    setState(() => _isLoading = true);

    // Simulate loading access history
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _accessEvents = [
        AccessEvent(
          id: '1',
          appName: 'Plaid',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=plaid.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Transactions',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 45,
        ),
        AccessEvent(
          id: '2',
          appName: 'Mint',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=mint.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Balances',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 8,
        ),
        AccessEvent(
          id: '3',
          appName: 'Personal Capital',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=personalcapital.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Accounts',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 5,
        ),
        AccessEvent(
          id: '4',
          appName: 'Plaid',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=plaid.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Identity',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 1,
        ),
        AccessEvent(
          id: '5',
          appName: 'Mint',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=mint.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Transactions',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 120,
        ),
        AccessEvent(
          id: '6',
          appName: 'User Export',
          appLogoUrl: null,
          accessType: AccessType.export,
          dataCategory: 'All Data',
          timestamp: DateTime.now().subtract(const Duration(days: 7)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 500,
        ),
        AccessEvent(
          id: '7',
          appName: 'Plaid',
          appLogoUrl: 'https://www.google.com/s2/favicons?domain=plaid.com&sz=128',
          accessType: AccessType.read,
          dataCategory: 'Balances',
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          ipAddress: '192.168.1.100',
          location: 'San Francisco, CA',
          recordsAccessed: 8,
        ),
      ];
      _isLoading = false;
    });
  }

  List<AccessEvent> get _filteredEvents {
    switch (_selectedFilter) {
      case AccessFilter.all:
        return _accessEvents;
      case AccessFilter.today:
        final today = DateTime.now();
        return _accessEvents.where((event) {
          return event.timestamp.year == today.year &&
              event.timestamp.month == today.month &&
              event.timestamp.day == today.day;
        }).toList();
      case AccessFilter.last7Days:
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        return _accessEvents.where((event) => event.timestamp.isAfter(sevenDaysAgo)).toList();
      case AccessFilter.last30Days:
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        return _accessEvents.where((event) => event.timestamp.isAfter(thirtyDaysAgo)).toList();
    }
  }

  Map<String, List<AccessEvent>> get _groupedEvents {
    final Map<String, List<AccessEvent>> grouped = {};
    final events = _filteredEvents;

    for (var event in events) {
      final dateKey = _getDateKey(event.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(event);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today';
    } else if (eventDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final groupedEvents = _groupedEvents;

    return CUScacuold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CUAppBar(
        title: const Text(
          'Data Access History',
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
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Data Access Log',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View all instances when your financial data has been accessed by connected apps.',
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

              // Stats
              if (!_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.visibility,
                            label: 'Total Accesses',
                            value: '${_accessEvents.length}',
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.description,
                            label: 'Records',
                            value: '${_accessEvents.fold<int>(0, (sum, event) => sum + event.recordsAccessed)}',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedFilter == AccessFilter.all,
                          onTap: () => setState(() => _selectedFilter = AccessFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Today',
                          selected: _selectedFilter == AccessFilter.today,
                          onTap: () => setState(() => _selectedFilter = AccessFilter.today),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Last 7 Days',
                          selected: _selectedFilter == AccessFilter.last7Days,
                          onTap: () => setState(() => _selectedFilter = AccessFilter.last7Days),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Last 30 Days',
                          selected: _selectedFilter == AccessFilter.last30Days,
                          onTap: () => setState(() => _selectedFilter = AccessFilter.last30Days),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Access Events
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (groupedEvents.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Access Events',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'Geist',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No data access events in this time period',
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dateKeys = groupedEvents.keys.toList();
                        final dateKey = dateKeys[index];
                        final events = groupedEvents[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12, top: 16),
                              child: Text(
                                dateKey,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                            ...events.map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AccessEventCard(event: event),
                            )),
                          ],
                        );
                      },
                      childCount: groupedEvents.length,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.white,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }
}

class _AccessEventCard extends StatelessWidget {
  final AccessEvent event;

  const _AccessEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CUTheme.of(context);
    final accessTypeColor = event.accessType == AccessType.read
        ? theme.colorScheme.primary
        : event.accessType == AccessType.write
            ? const Color(0xFFF59E0B)
            : Colors.purple.shade600;

    final accessTypeIcon = event.accessType == AccessType.read
        ? Icons.visibility
        : event.accessType == AccessType.write
            ? Icons.edit
            : Icons.file_download;

    return CUOutlinedCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CUAvatar(
            text: event.appName,
            size: 40,
            imageUrl: event.appLogoUrl,
            icon: Icons.apps,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.appName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accessTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(accessTypeIcon, size: 12, color: accessTypeColor),
                          const SizedBox(width: 4),
                          Text(
                            event.accessType.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accessTypeColor,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.dataCategory,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(event.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Geist',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.description, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${event.recordsAccessed} records',
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
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

// Models
class AccessEvent {
  final String id;
  final String appName;
  final String? appLogoUrl;
  final AccessType accessType;
  final String dataCategory;
  final DateTime timestamp;
  final String ipAddress;
  final String location;
  final int recordsAccessed;

  AccessEvent({
    required this.id,
    required this.appName,
    this.appLogoUrl,
    required this.accessType,
    required this.dataCategory,
    required this.timestamp,
    required this.ipAddress,
    required this.location,
    required this.recordsAccessed,
  });
}

enum AccessType { read, write, export }
enum AccessFilter { all, today, last7Days, last30Days }
