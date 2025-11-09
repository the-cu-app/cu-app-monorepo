import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/check_deposit_model.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/banking_service.dart';

class CheckDepositService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _uuid = Uuid();
  static final _profileService = ProfileService();
  static final _bankingService = BankingService();

  // Mock Plaid Check Deposit API endpoint
  static const String _plaidCheckDepositUrl = 
      'https://vsduehkavltenthprjwe.supabase.co/functions/v1/plaid-check-deposit';

  // Create a new check deposit
  Future<CheckDeposit> createCheckDeposit({
    required String accountId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final profile = _profileService.currentProfile;
    if (profile == null) throw Exception('No active profile found');

    final id = _uuid.v4();
    final deposit = CheckDeposit(
      id: id,
      userId: user.id,
      profileId: profile.id,
      accountId: accountId,
      amount: 0.0,
      status: CheckDepositStatus.draft,
      createdAt: DateTime.now(),
    );

    // Store in local storage for now
    await _saveDepositToLocal(deposit);
    
    return deposit;
  }

  // Get deposit limits for the current profile
  Future<CheckDepositLimits> getDepositLimits() async {
    final profile = _profileService.currentProfile;
    if (profile == null) throw Exception('No active profile found');

    // Get limits from profile
    final transactionLimit = profile.limits.mobileDepositLimit;
    
    // Calculate daily and monthly limits based on profile type
    final dailyLimit = transactionLimit * 2; // 2x transaction limit per day
    final monthlyLimit = transactionLimit * 20; // 20x transaction limit per month
    
    // Get usage data (mock for now)
    final usedDailyAmount = await _getUsedAmount(TimeFrame.daily);
    final usedMonthlyAmount = await _getUsedAmount(TimeFrame.monthly);
    final usedDailyCount = await _getUsedCount(TimeFrame.daily);
    final usedMonthlyCount = await _getUsedCount(TimeFrame.monthly);

    return CheckDepositLimits(
      dailyLimit: dailyLimit,
      transactionLimit: transactionLimit,
      monthlyLimit: monthlyLimit,
      dailyCount: 5, // 5 deposits per day
      monthlyCount: 50, // 50 deposits per month
      usedDailyAmount: usedDailyAmount,
      usedMonthlyAmount: usedMonthlyAmount,
      usedDailyCount: usedDailyCount,
      usedMonthlyCount: usedMonthlyCount,
    );
  }

  // Validate check amount
  Future<String?> validateAmount(double amount) async {
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    final limits = await getDepositLimits();
    return limits.getDepositError(amount);
  }

  // Save check image
  Future<File> saveCheckImage(File image, String depositId, CheckSide side) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${depositId}_${side.name}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${directory.path}/check_deposits/$fileName';
    
    // Create directory if it doesn't exist
    final checkDir = Directory('${directory.path}/check_deposits');
    if (!await checkDir.exists()) {
      await checkDir.create(recursive: true);
    }
    
    final savedImage = await image.copy(path);
    return savedImage;
  }

  // Update check deposit with images
  Future<CheckDeposit> updateDepositImages({
    required CheckDeposit deposit,
    File? frontImage,
    File? backImage,
  }) async {
    CheckDeposit updatedDeposit = deposit;

    if (frontImage != null) {
      final savedFront = await saveCheckImage(frontImage, deposit.id, CheckSide.front);
      updatedDeposit = updatedDeposit.copyWith(
        frontImage: savedFront,
        frontImagePath: savedFront.path,
      );
    }

    if (backImage != null) {
      final savedBack = await saveCheckImage(backImage, deposit.id, CheckSide.back);
      updatedDeposit = updatedDeposit.copyWith(
        backImage: savedBack,
        backImagePath: savedBack.path,
      );
    }

    await _saveDepositToLocal(updatedDeposit);
    return updatedDeposit;
  }

  // Update deposit amount and check number
  Future<CheckDeposit> updateDepositDetails({
    required CheckDeposit deposit,
    required double amount,
    String? checkNumber,
  }) async {
    final updatedDeposit = deposit.copyWith(
      amount: amount,
      checkNumber: checkNumber,
      status: CheckDepositStatus.reviewPending,
    );

    await _saveDepositToLocal(updatedDeposit);
    return updatedDeposit;
  }

  // Submit check deposit
  Future<CheckDeposit> submitDeposit(CheckDeposit deposit) async {
    // Validate deposit
    if (deposit.frontImage == null || deposit.backImage == null) {
      throw Exception('Both front and back images are required');
    }
    if (deposit.amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    // Update status to processing
    var processingDeposit = deposit.copyWith(
      status: CheckDepositStatus.processing,
    );
    await _saveDepositToLocal(processingDeposit);

    try {
      // Mock API call - simulate processing time
      await Future.delayed(Duration(seconds: 3));

      // Generate reference number
      final referenceNumber = 'CHK${DateTime.now().millisecondsSinceEpoch}';
      
      // Mock OCR and verification
      final isValid = await _mockVerifyCheck(deposit);
      
      if (isValid) {
        // Update account balance (mock)
        await _mockUpdateAccountBalance(deposit.accountId, deposit.amount);
        
        // Mark as completed
        final completedDeposit = processingDeposit.copyWith(
          status: CheckDepositStatus.completed,
          completedAt: DateTime.now(),
          referenceNumber: referenceNumber,
          endorsementVerified: true,
        );
        
        await _saveDepositToLocal(completedDeposit);
        
        // Add to transaction history
        await _addToTransactionHistory(completedDeposit);
        
        return completedDeposit;
      } else {
        // Mark as failed
        final failedDeposit = processingDeposit.copyWith(
          status: CheckDepositStatus.failed,
          completedAt: DateTime.now(),
          failureReason: 'Check verification failed. Please ensure the check images are clear and properly endorsed.',
        );
        
        await _saveDepositToLocal(failedDeposit);
        return failedDeposit;
      }
    } catch (e) {
      // Handle error
      final failedDeposit = processingDeposit.copyWith(
        status: CheckDepositStatus.failed,
        completedAt: DateTime.now(),
        failureReason: e.toString(),
      );
      
      await _saveDepositToLocal(failedDeposit);
      return failedDeposit;
    }
  }

  // Get deposit history
  Future<List<CheckDeposit>> getDepositHistory() async {
    // For now, return mock data
    final deposits = <CheckDeposit>[];
    
    // Add some mock history
    deposits.add(
      CheckDeposit(
        id: _uuid.v4(),
        userId: _supabase.auth.currentUser?.id ?? '',
        profileId: 'mock-profile-id',
        accountId: 'demo_checking_001',
        amount: 1250.00,
        checkNumber: '1234',
        status: CheckDepositStatus.completed,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        completedAt: DateTime.now().subtract(Duration(days: 7)),
        referenceNumber: 'CHK1234567890',
        endorsementVerified: true,
      ),
    );
    
    deposits.add(
      CheckDeposit(
        id: _uuid.v4(),
        userId: _supabase.auth.currentUser?.id ?? '',
        profileId: 'mock-profile-id',
        accountId: 'demo_checking_001',
        amount: 450.50,
        checkNumber: '5678',
        status: CheckDepositStatus.completed,
        createdAt: DateTime.now().subtract(Duration(days: 14)),
        completedAt: DateTime.now().subtract(Duration(days: 14)),
        referenceNumber: 'CHK0987654321',
        endorsementVerified: true,
      ),
    );
    
    return deposits;
  }

  // Mock methods for demo
  Future<bool> _mockVerifyCheck(CheckDeposit deposit) async {
    // Simulate check verification with 90% success rate
    return Random().nextDouble() > 0.1;
  }

  Future<void> _mockUpdateAccountBalance(String accountId, double amount) async {
    // In a real implementation, this would update the account balance
    print('Updated account $accountId balance by \$${amount.toStringAsFixed(2)}');
  }

  Future<void> _addToTransactionHistory(CheckDeposit deposit) async {
    // In a real implementation, this would add a transaction record
    print('Added check deposit to transaction history: ${deposit.referenceNumber}');
  }

  Future<double> _getUsedAmount(TimeFrame timeFrame) async {
    // Mock implementation - return random used amount
    switch (timeFrame) {
      case TimeFrame.daily:
        return Random().nextDouble() * 1000; // Random amount up to $1000
      case TimeFrame.monthly:
        return Random().nextDouble() * 5000; // Random amount up to $5000
    }
  }

  Future<int> _getUsedCount(TimeFrame timeFrame) async {
    // Mock implementation - return random count
    switch (timeFrame) {
      case TimeFrame.daily:
        return Random().nextInt(3); // 0-2 deposits today
      case TimeFrame.monthly:
        return Random().nextInt(20); // 0-19 deposits this month
    }
  }

  // Local storage helpers
  Future<void> _saveDepositToLocal(CheckDeposit deposit) async {
    // In a real implementation, this would save to local database or Supabase
    print('Saving deposit ${deposit.id} with status ${deposit.status}');
  }

  // Validate check image quality
  Future<bool> validateImageQuality(File image) async {
    // Mock implementation - check file size and existence
    final exists = await image.exists();
    if (!exists) return false;
    
    final size = await image.length();
    // Ensure image is between 100KB and 10MB
    return size > 100 * 1024 && size < 10 * 1024 * 1024;
  }

  // Mock OCR for check amount
  Future<double?> extractAmountFromCheck(File frontImage) async {
    // Simulate OCR processing time
    await Future.delayed(Duration(seconds: 2));
    
    // Return a random amount for demo
    final amounts = [125.50, 450.00, 1000.00, 2500.00, 750.25];
    return amounts[Random().nextInt(amounts.length)];
  }

  // Check if endorsement is present
  Future<bool> verifyEndorsement(File backImage) async {
    // Simulate verification time
    await Future.delayed(Duration(seconds: 1));
    
    // Mock verification - 80% success rate
    return Random().nextDouble() > 0.2;
  }
}

enum TimeFrame {
  daily,
  monthly,
}