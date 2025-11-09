import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:provider/provider.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import '../models/card_model.dart';
import '../services/card_service.dart';
import '../services/profile_service.dart';
import '../services/feature_service.dart';
import '../widgets/card_widget.dart';
import '../widgets/particle_animation.dart';
import '../widgets/feature_gate.dart';
import '../widgets/consistent_list_tile.dart';
import 'card_details_screen.dart';
import 'card_controls_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> with TickerProviderStateMixin {
  final CardService _cardService = CardService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cardService.initialize();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileService = context.watch<ProfileService>();
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Cards',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: ParticleAnimation(
                  particleColor: theme.colorScheme.primary.withOpacity(0.1),
                  numberOfParticles: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Physical'),
                  Tab(text: 'Virtual'),
                  Tab(text: 'All Cards'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_card),
                  onPressed: _showAddCardOptions,
                  tooltip: 'Add Card',
                ),
              ],
            ),
          ];
        },
        body: AnimatedBuilder(
          animation: _cardService,
          builder: (context, child) {
            if (_cardService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return TabBarView(
              controller: _tabController,
              children: [
                _buildCardsList(_cardService.physicalCards, 'physical'),
                _buildCardsList(_cardService.virtualCards, 'virtual'),
                _buildCardsList(_cardService.currentProfileCards, 'all'),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCardsList(List<BankCard> cards, String type) {
    if (cards.isEmpty) {
      return _buildEmptyState(type);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CardWidget(
            card: card,
            isHero: true,
            onTap: () => _navigateToCardDetails(card),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(String type) {
    final theme = Theme.of(context);
    String message;
    IconData icon;
    
    switch (type) {
      case 'physical':
        message = 'No physical cards yet';
        icon = Icons.credit_card;
        break;
      case 'virtual':
        message = 'No virtual cards yet\nCreate one for secure online shopping';
        icon = Icons.credit_card_outlined;
        break;
      default:
        message = 'No cards available';
        icon = Icons.credit_card_off;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          if (type == 'virtual') ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createVirtualCard,
              icon: const Icon(Icons.add),
              label: const Text('Create Virtual Card'),
            ),
          ],
        ],
      ),
    );
  }
  
  void _navigateToCardDetails(BankCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(card: card),
      ),
    );
  }
  
  void _showAddCardOptions() {
    final theme = Theme.of(context);
    final featureService = FeatureService();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add New Card',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                ConsistentListTile(
                  leading: ConsistentListTileLeading(
                    icon: Icons.credit_card_outlined,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    iconColor: theme.colorScheme.primary,
                  ),
                  title: const ConsistentListTileTitle(text: 'Create Virtual Card'),
                  subtitle: const ConsistentListTileSubtitle(text: 'Instant card for online purchases'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _createVirtualCard();
                  },
                ),
                ConsistentListTile(
                  leading: ConsistentListTileLeading(
                    icon: Icons.credit_card,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    iconColor: theme.colorScheme.secondary,
                  ),
                  title: const ConsistentListTileTitle(text: 'Request Physical Card'),
                  subtitle: const ConsistentListTileSubtitle(text: 'Order a new physical card'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _requestPhysicalCard();
                  },
                ),
                // Business-specific features
                if (featureService.hasEnhancement('cards', 'employee_cards'))
                  ConsistentListTile(
                    leading: ConsistentListTileLeading(
                      icon: Icons.people,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      iconColor: Colors.blue,
                    ),
                    title: const ConsistentListTileTitle(text: 'Employee Cards'),
                    subtitle: const ConsistentListTileSubtitle(text: 'Issue cards to team members'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Business',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _createEmployeeCard();
                    },
                  ),
                if (featureService.hasEnhancement('cards', 'bulk_card_orders'))
                  ConsistentListTile(
                    leading: ConsistentListTileLeading(
                      icon: Icons.inventory_2,
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      iconColor: Colors.purple,
                    ),
                    title: const ConsistentListTileTitle(text: 'Bulk Card Order'),
                    subtitle: const ConsistentListTileSubtitle(text: 'Order multiple cards at once'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Business',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _bulkCardOrder();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _createVirtualCard() async {
    final theme = Theme.of(context);
    
    // Show creating dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Creating Virtual Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Generating secure card details...',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
    
    // Generate virtual card
    final newCard = await _cardService.generateVirtualCard(
      type: CardType.debit,
      purpose: 'online_shopping',
    );
    
    // Close dialog
    if (mounted) Navigator.pop(context);
    
    if (newCard != null) {
      // Switch to virtual cards tab
      _tabController.animateTo(1);
      
      // Show success message
          content: const Text('Virtual card created successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _navigateToCardDetails(newCard),
          ),
        ),
      );
    } else {
      // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to create virtual card)),

          );
    }
  }
  
  void _requestPhysicalCard() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Physical Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new physical card will be mailed to your registered address.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delivery Time: 7-10 business days',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Standard shipping is free',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
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
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Card request submitted! Check your email for tracking info.)),

          );
              },
              child: const Text('Request Card'),
            ),
          ],
        );
      },
    );
  }

  void _createEmployeeCard() {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Employee card creation coming soon!)),

          );
  }

  void _bulkCardOrder() {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Bulk card order feature coming soon!)),

          );
  }
}