import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../models/profile_model.dart';
import 'profile_service.dart';

class CardService extends ChangeNotifier {
  static final CardService _instance = CardService._internal();
  factory CardService() => _instance;
  CardService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  
  List<BankCard> _cards = [];
  bool _isLoading = false;
  
  List<BankCard> get cards => _cards;
  bool get isLoading => _isLoading;
  
  // Get cards for current profile
  List<BankCard> get currentProfileCards {
    final currentProfile = _profileService.currentProfile;
    if (currentProfile == null) return [];
    return _cards.where((card) => card.profileId == currentProfile.id).toList();
  }
  
  // Get active cards only
  List<BankCard> get activeCards {
    return currentProfileCards.where((card) => card.status == CardStatus.active).toList();
  }
  
  // Get virtual cards
  List<BankCard> get virtualCards {
    return currentProfileCards.where((card) => card.isVirtual).toList();
  }
  
  // Get physical cards
  List<BankCard> get physicalCards {
    return currentProfileCards.where((card) => !card.isVirtual).toList();
  }

  // Initialize and load cards
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await loadCards();
    } catch (e) {
      debugPrint('Error initializing cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all user cards
  Future<void> loadCards() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // For demo, create mock cards
      _cards = _createMockCards();
      
      // In production, this would fetch from Supabase:
      // final response = await _supabase
      //     .from('bank_cards')
      //     .select()
      //     .eq('user_id', user.id)
      //     .order('created_at');
      // 
      // _cards = (response as List)
      //     .map((json) => BankCard.fromJson(json))
      //     .toList();
    } catch (e) {
      debugPrint('Error loading cards: $e');
      // Fallback to mock data
      _cards = _createMockCards();
    }
  }

  // Create mock cards for demo
  List<BankCard> _createMockCards() {
    final profiles = _profileService.userProfiles;
    final cards = <BankCard>[];
    
    for (final profile in profiles) {
      if (profile.type == ProfileType.personal) {
        // Personal debit card
        cards.add(BankCard(
          id: 'card_debit_001',
          profileId: profile.id,
          accountId: 'acc_checking_001',
          type: CardType.debit,
          status: CardStatus.active,
          network: CardNetwork.visa,
          cardNumber: '**** **** **** 4242',
          cardholderName: 'JOHN DOE',
          expirationDate: '12/25',
          isVirtual: false,
          isPrimary: true,
          controls: CardControls.defaultControls(),
          limits: CardLimits.defaultLimits(CardType.debit),
          createdAt: DateTime.now().subtract(const Duration(days: 730)),
          lastUsedAt: DateTime.now().subtract(const Duration(hours: 2)),
          metadata: {
            'design': 'gradient_blue',
            'chip': true,
            'contactless': true,
          },
        ));
        
        // Personal credit card
        cards.add(BankCard(
          id: 'card_credit_001',
          profileId: profile.id,
          accountId: 'acc_credit_001',
          type: CardType.credit,
          status: CardStatus.active,
          network: CardNetwork.mastercard,
          cardNumber: '**** **** **** 8765',
          cardholderName: 'JOHN DOE',
          expirationDate: '06/26',
          isVirtual: false,
          controls: CardControls.defaultControls(),
          limits: CardLimits.defaultLimits(CardType.credit),
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          lastUsedAt: DateTime.now().subtract(const Duration(days: 1)),
          metadata: {
            'design': 'metal_black',
            'chip': true,
            'contactless': true,
            'rewards_program': 'cashback',
          },
        ));
        
        // Virtual card
        cards.add(BankCard(
          id: 'card_virtual_001',
          profileId: profile.id,
          accountId: 'acc_checking_001',
          type: CardType.debit,
          status: CardStatus.active,
          network: CardNetwork.visa,
          cardNumber: '**** **** **** 9999',
          cardholderName: 'JOHN DOE',
          expirationDate: '03/25',
          cvv: '123',
          isVirtual: true,
          controls: CardControls.defaultControls().copyWith(
            internationalTransactions: false,
            atmWithdrawals: false,
          ),
          limits: CardLimits.defaultLimits(CardType.debit).copyWith(
            dailySpendLimit: 500.0,
            singleTransactionLimit: 250.0,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastUsedAt: DateTime.now().subtract(const Duration(days: 5)),
          metadata: {
            'purpose': 'online_shopping',
            'auto_lock_after_use': false,
          },
        ));
      } else if (profile.type == ProfileType.business) {
        // Business debit card
        cards.add(BankCard(
          id: 'card_business_001',
          profileId: profile.id,
          accountId: 'acc_business_001',
          type: CardType.debit,
          status: CardStatus.active,
          network: CardNetwork.amex,
          cardNumber: '**** **** **** 1234',
          cardholderName: profile.businessName?.toUpperCase() ?? 'BUSINESS',
          expirationDate: '09/27',
          isVirtual: false,
          controls: CardControls.defaultControls(),
          limits: CardLimits(
            dailySpendLimit: 10000.0,
            dailyATMLimit: 2000.0,
            singleTransactionLimit: 5000.0,
            categoryLimits: {},
            dailyTransactionCount: 100,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          lastUsedAt: DateTime.now().subtract(const Duration(hours: 12)),
          metadata: {
            'design': 'metal_platinum',
            'chip': true,
            'contactless': true,
            'employee_cards': 5,
          },
        ));
      }
    }
    
    return cards;
  }

  // Lock/Unlock card
  Future<bool> toggleCardLock(String cardId) async {
    try {
      final cardIndex = _cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;
      
      final card = _cards[cardIndex];
      final newControls = card.controls.copyWith(
        isLocked: !card.controls.isLocked,
      );
      
      // In production, update in database
      // await _supabase
      //     .from('bank_cards')
      //     .update({'controls': newControls.toJson()})
      //     .eq('id', cardId);
      
      _cards[cardIndex] = card.copyWith(controls: newControls);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling card lock: $e');
      return false;
    }
  }

  // Update card controls
  Future<bool> updateCardControls(String cardId, CardControls controls) async {
    try {
      final cardIndex = _cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;
      
      // In production, update in database
      // await _supabase
      //     .from('bank_cards')
      //     .update({'controls': controls.toJson()})
      //     .eq('id', cardId);
      
      _cards[cardIndex] = _cards[cardIndex].copyWith(controls: controls);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating card controls: $e');
      return false;
    }
  }

  // Update card limits
  Future<bool> updateCardLimits(String cardId, CardLimits limits) async {
    try {
      final cardIndex = _cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;
      
      // In production, update in database
      // await _supabase
      //     .from('bank_cards')
      //     .update({'limits': limits.toJson()})
      //     .eq('id', cardId);
      
      _cards[cardIndex] = _cards[cardIndex].copyWith(limits: limits);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating card limits: $e');
      return false;
    }
  }

  // Generate new virtual card
  Future<BankCard?> generateVirtualCard({
    required CardType type,
    String? purpose,
    CardLimits? customLimits,
  }) async {
    final currentProfile = _profileService.currentProfile;
    if (currentProfile == null) return null;
    
    try {
      final virtualCard = BankCard.generateVirtualCard(
        profileId: currentProfile.id,
        accountId: type == CardType.credit ? 'acc_credit_001' : 'acc_checking_001',
        type: type,
        cardholderName: currentProfile.displayName.toUpperCase(),
      );
      
      // Apply custom limits if provided
      final cardWithLimits = customLimits != null
          ? virtualCard.copyWith(limits: customLimits)
          : virtualCard;
      
      // Add purpose to metadata if provided
      final finalCard = purpose != null
          ? cardWithLimits.copyWith(
              metadata: {...?cardWithLimits.metadata, 'purpose': purpose},
            )
          : cardWithLimits;
      
      // In production, save to database
      // final response = await _supabase
      //     .from('bank_cards')
      //     .insert(finalCard.toJson())
      //     .select()
      //     .single();
      // 
      // final savedCard = BankCard.fromJson(response);
      
      _cards.add(finalCard);
      notifyListeners();
      return finalCard;
    } catch (e) {
      debugPrint('Error generating virtual card: $e');
      return null;
    }
  }

  // Request card replacement
  Future<bool> requestCardReplacement(String cardId, String reason) async {
    try {
      final cardIndex = _cards.indexWhere((c) => c.id == cardId);
      if (cardIndex == -1) return false;
      
      // In production, create replacement request
      // await _supabase
      //     .from('card_replacement_requests')
      //     .insert({
      //       'card_id': cardId,
      //       'reason': reason,
      //       'status': 'pending',
      //       'requested_at': DateTime.now().toIso8601String(),
      //     });
      
      // Mark current card as suspended
      _cards[cardIndex] = _cards[cardIndex].copyWith(
        status: CardStatus.suspended,
        metadata: {
          ..._cards[cardIndex].metadata ?? {},
          'replacement_requested': true,
          'replacement_reason': reason,
        },
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error requesting card replacement: $e');
      return false;
    }
  }

  // Delete virtual card
  Future<bool> deleteVirtualCard(String cardId) async {
    try {
      final card = _cards.firstWhere((c) => c.id == cardId);
      if (!card.isVirtual) return false;
      
      // In production, delete from database
      // await _supabase
      //     .from('bank_cards')
      //     .delete()
      //     .eq('id', cardId);
      
      _cards.removeWhere((c) => c.id == cardId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting virtual card: $e');
      return false;
    }
  }

  // Clear all data (for logout)
  void clear() {
    _cards = [];
    _isLoading = false;
    notifyListeners();
  }
}