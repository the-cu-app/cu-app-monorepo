import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServicesScroll extends StatefulWidget {
  const ServicesScroll({super.key});

  @override
  State<ServicesScroll> createState() => _ServicesScrollState();
}

class _ServicesScrollState extends State<ServicesScroll> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.account_balance,
      'title': 'Accounts',
      'subtitle': 'View balances',
      'color': Colors.black,
    },
    {
      'icon': Icons.swap_horiz,
      'title': 'Transfer',
      'subtitle': 'Send money',
      'color': Colors.black,
    },
    {
      'icon': Icons.receipt_long,
      'title': 'Bill Pay',
      'subtitle': 'Pay bills',
      'color': Colors.black,
    },
    {
      'icon': Icons.analytics,
      'title': 'Insights',
      'subtitle': 'Spending analysis',
      'color': Colors.black,
    },
    {
      'icon': Icons.chat,
      'title': 'Support',
      'subtitle': 'Get help',
      'color': Colors.black,
    },
    {
      'icon': Icons.location_on,
      'title': 'Locations',
      'subtitle': 'Find branches',
      'color': Colors.black,
    },
    {
      'icon': Icons.credit_card,
      'title': 'Cards',
      'subtitle': 'Manage cards',
      'color': Colors.black,
    },
    {
      'icon': Icons.savings,
      'title': 'Savings',
      'subtitle': 'Goals & plans',
      'color': Colors.black,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double itemWidth = 120.0; // Width of each service item
    final double currentOffset = _scrollController.offset;
    final int newIndex = (currentOffset / itemWidth).round();

    if (newIndex != _currentIndex &&
        newIndex >= 0 &&
        newIndex < _services.length) {
      setState(() {
        _currentIndex = newIndex;
      });

      // Haptic feedback for snap-to
      SystemChannels.platform.invokeMethod('HapticFeedback.selectionChanged');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final isSelected = index == _currentIndex;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    // Haptic feedback on tap
                    SystemChannels.platform
                        .invokeMethod('HapticFeedback.lightImpact');

                    // Scroll to item
                    _scrollController.animateTo(
                      index * 112.0, // 100 + 12 margin
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? service['color'].withOpacity(0.1)
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: service['color'],
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? service['color']
                                : service['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            service['icon'],
                            color: isSelected ? Colors.white : service['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service['title'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? service['color']
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service['subtitle'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
