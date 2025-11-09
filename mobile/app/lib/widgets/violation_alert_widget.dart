import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/no_cap_transaction_monitor.dart';
import '../services/no_cap_ai_service.dart';
import '../services/budget_commitment_service.dart';

class ViolationAlertSystem extends StatefulWidget {
  final String userId;
  final Widget child;

  const ViolationAlertSystem({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<ViolationAlertSystem> createState() => _ViolationAlertSystemState();
}

class _ViolationAlertSystemState extends State<ViolationAlertSystem>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  // Services
  final _transactionMonitor = NoCapTransactionMonitor();
  final _aiService = NoCapAIService();
  final _commitmentService = BudgetCommitmentService();

  // Stream subscriptions
  StreamSubscription<TransactionViolationAlert>? _violationSubscription;
  StreamSubscription<BudgetViolation>? _budgetViolationSubscription;

  // Alert queue and state
  final List<ViolationAlert> _alertQueue = [];
  ViolationAlert? _currentAlert;
  bool _isShowingAlert = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupViolationListeners();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    _violationSubscription?.cancel();
    _budgetViolationSubscription?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    // Shake animation for alerts
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    // Pulse animation for critical violations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _setupViolationListeners() {
    // Listen to transaction violations
    _violationSubscription = _transactionMonitor.violationAlertStream.listen(
      (alert) => _handleTransactionViolation(alert),
      onError: (error) => debugPrint('Violation stream error: $error'),
    );

    // Listen to budget violations from AI service
    _budgetViolationSubscription = _aiService.violationStream.listen(
      (violation) => _handleBudgetViolation(violation),
      onError: (error) => debugPrint('Budget violation stream error: $error'),
    );
  }

  void _handleTransactionViolation(TransactionViolationAlert alert) {
    if (alert.userId != widget.userId) return;

    final violationAlert = ViolationAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.transactionViolation,
      severity: _mapViolationTypeToSeverity(alert.violationType),
      title: 'No Cap Violation!',
      message: alert.violationReason,
      aiMessage: alert.aiMessage,
      penaltyPoints: alert.penaltyPoints,
      merchantName: alert.merchantName,
      amount: alert.amount,
      timestamp: alert.timestamp,
      commitmentId: alert.commitmentId,
      transactionId: alert.transactionId,
    );

    _queueAlert(violationAlert);
  }

  void _handleBudgetViolation(BudgetViolation violation) {
    final violationAlert = ViolationAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: AlertType.budgetViolation,
      severity: _mapSeverityStringToEnum(violation.aiAnalysis),
      title: 'Budget Alert!',
      message: violation.message,
      aiMessage: violation.aiAnalysis ?? 'Stay focused on your goals!',
      penaltyPoints: violation.penaltyPoints,
      timestamp: violation.violationDate,
      commitmentId: violation.commitmentId,
    );

    _queueAlert(violationAlert);
  }

  void _queueAlert(ViolationAlert alert) {
    setState(() {
      _alertQueue.add(alert);
    });

    // Trigger haptic feedback based on severity
    _triggerHapticFeedback(alert.severity);

    // Show alert if not currently showing one
    if (!_isShowingAlert) {
      _showNextAlert();
    }
  }

  void _showNextAlert() {
    if (_alertQueue.isEmpty || _isShowingAlert) return;

    setState(() {
      _currentAlert = _alertQueue.removeAt(0);
      _isShowingAlert = true;
    });

    _triggerAlertAnimations(_currentAlert!.severity);
    _showAlertDialog(_currentAlert!);
  }

  void _triggerHapticFeedback(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        HapticFeedback.lightImpact();
        break;
      case AlertSeverity.medium:
        HapticFeedback.mediumImpact();
        break;
      case AlertSeverity.high:
        HapticFeedback.heavyImpact();
        break;
      case AlertSeverity.critical:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), () {
          HapticFeedback.heavyImpact();
        });
        break;
    }
  }

  void _triggerAlertAnimations(AlertSeverity severity) {
    if (severity == AlertSeverity.critical) {
      _pulseController.repeat(reverse: true);
    }
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  void _showAlertDialog(ViolationAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildAlertDialog(alert),
    ).then((_) {
      setState(() {
        _isShowingAlert = false;
        _currentAlert = null;
      });
      _pulseController.stop();
      _pulseController.reset();

      // Show next alert if any
      if (_alertQueue.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _showNextAlert();
        });
      }
    });
  }

  Widget _buildAlertDialog(ViolationAlert alert) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * 0.1, 0),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: alert.severity == AlertSeverity.critical
                    ? _pulseAnimation.value
                    : 1.0,
                child: AlertDialog(
                  backgroundColor: _getAlertBackgroundColor(alert.severity),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _getAlertBorderColor(alert.severity),
                      width: 2,
                    ),
                  ),
                  title: _buildAlertHeader(alert),
                  content: _buildAlertContent(alert),
                  actions: _buildAlertActions(alert),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlertHeader(ViolationAlert alert) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getAlertIconColor(alert.severity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAlertIcon(alert.severity),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAlertIconColor(alert.severity),
                  fontSize: 18,
                ),
              ),
              Text(
                _getSeverityLabel(alert.severity),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      _getAlertIconColor(alert.severity).withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertContent(ViolationAlert alert) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main violation message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              alert.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          if (alert.merchantName != null && alert.amount != null) ...[
            const SizedBox(height: 12),
            _buildTransactionDetails(alert),
          ],

          if (alert.penaltyPoints > 0) ...[
            const SizedBox(height: 12),
            _buildPenaltyCard(alert.penaltyPoints),
          ],

          const SizedBox(height: 12),
          _buildAIMessage(alert.aiMessage),

          if (alert.severity == AlertSeverity.critical) ...[
            const SizedBox(height: 12),
            _buildCriticalWarning(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(ViolationAlert alert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.merchantName!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${alert.amount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltyCard(int penaltyPoints) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.remove_circle, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            '-$penaltyPoints Points',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          const Text(
            'Penalty Applied',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMessage(String aiMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your AI Coach Says:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aiMessage,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.priority_high, color: Colors.purple, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITICAL VIOLATION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'This is a serious breach of your commitment. Multiple violations may result in commitment termination.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAlertActions(ViolationAlert alert) {
    return [
      if (alert.severity == AlertSeverity.critical) ...[
        TextButton(
          onPressed: () => _handleEmergencyOverride(alert),
          child: const Text(
            'Emergency Override',
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ],
      TextButton(
        onPressed: () => _handleViewCommitment(alert),
        child: const Text('View Commitment'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(
          backgroundColor: _getAlertIconColor(alert.severity),
        ),
        child: const Text('Understood'),
      ),
    ];
  }

  // Helper methods
  AlertSeverity _mapViolationTypeToSeverity(ViolationType type) {
    switch (type) {
      case ViolationType.minor:
        return AlertSeverity.low;
      case ViolationType.moderate:
        return AlertSeverity.medium;
      case ViolationType.major:
        return AlertSeverity.high;
      case ViolationType.severe:
        return AlertSeverity.critical;
    }
  }

  AlertSeverity _mapSeverityStringToEnum(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AlertSeverity.low;
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.medium;
    }
  }

  Color _getAlertBackgroundColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.yellow.withValues(alpha: 0.05);
      case AlertSeverity.medium:
        return Colors.orange.withValues(alpha: 0.05);
      case AlertSeverity.high:
        return Colors.red.withValues(alpha: 0.05);
      case AlertSeverity.critical:
        return Colors.purple.withValues(alpha: 0.05);
    }
  }

  Color _getAlertBorderColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.yellow;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  Color _getAlertIconColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.yellow[700]!;
      case AlertSeverity.medium:
        return Colors.orange[700]!;
      case AlertSeverity.high:
        return Colors.red[700]!;
      case AlertSeverity.critical:
        return Colors.purple[700]!;
    }
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info;
      case AlertSeverity.medium:
        return Icons.warning;
      case AlertSeverity.high:
        return Icons.error;
      case AlertSeverity.critical:
        return Icons.crisis_alert;
    }
  }

  String _getSeverityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'LOW SEVERITY';
      case AlertSeverity.medium:
        return 'MEDIUM SEVERITY';
      case AlertSeverity.high:
        return 'HIGH SEVERITY';
      case AlertSeverity.critical:
        return 'CRITICAL SEVERITY';
    }
  }

  void _handleEmergencyOverride(ViolationAlert alert) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Override'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency overrides should only be used in genuine emergencies.',
            ),
            SizedBox(height: 12),
            Text(
              'This action will be logged and may affect your commitment rating.',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
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
              _processEmergencyOverride(alert);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _handleViewCommitment(ViolationAlert alert) {
    Navigator.pop(context);
    // Navigate to commitment details
    if (alert.commitmentId != null) {
      Navigator.pushNamed(
        context,
        '/commitment-details',
        arguments: alert.commitmentId,
      );
    }
  }

  void _processEmergencyOverride(ViolationAlert alert) {
    // Log emergency override
    debugPrint('Emergency override processed for alert: ${alert.id}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency override logged. Stay strong! 💪'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Data models
enum AlertType {
  transactionViolation,
  budgetViolation,
  commitmentExpiring,
  achievementUnlocked,
  streakMilestone,
}

enum AlertSeverity { low, medium, high, critical }

class ViolationAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String aiMessage;
  final int penaltyPoints;
  final String? merchantName;
  final double? amount;
  final DateTime timestamp;
  final String? commitmentId;
  final String? transactionId;

  ViolationAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.aiMessage,
    required this.penaltyPoints,
    this.merchantName,
    this.amount,
    required this.timestamp,
    this.commitmentId,
    this.transactionId,
  });
}

// Convenience widget for wrapping entire app
class NoCapAlertWrapper extends StatelessWidget {
  final String userId;
  final Widget child;

  const NoCapAlertWrapper({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ViolationAlertSystem(
      userId: userId,
      child: child,
    );
  }
}
