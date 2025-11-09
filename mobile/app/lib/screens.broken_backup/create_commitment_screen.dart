import 'package:flutter/material.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:flutter/services.dart';
import 'package:cu_design_system_omni/cu_design_system_omni.dart';
import 'package:intl/intl.dart';
import '../services/budget_commitment_service.dart';
import '../services/no_cap_ai_service.dart';
import '../services/point_system_service.dart';

class CreateCommitmentScreen extends StatefulWidget {
  const CreateCommitmentScreen({super.key});

  @override
  State<CreateCommitmentScreen> createState() => _CreateCommitmentScreenState();
}

class _CreateCommitmentScreenState extends State<CreateCommitmentScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _targetController = TextEditingController();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();

  // Services
  final _commitmentService = BudgetCommitmentService();
  final _aiService = NoCapAIService();
  final _pointService = PointSystemService();

  // Form state
  CommitmentType _selectedType = CommitmentType.merchant;
  CommitmentDifficulty _selectedDifficulty = CommitmentDifficulty.medium;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _selectedPersonality = 'motivational';
  bool _requireBiometric = true;
  bool _isCreating = false;
  bool _showAIInsights = false;

  // AI suggestions
  List<String> _aiSuggestions = [];
  String? _aiRiskAssessment;
  Map<String, dynamic>? _spendingAnalysis;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = _animationController;

    _animationController.forward();
    _loadAIInsights();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _targetController.dispose();
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAIInsights() async {
    try {
      // Get AI suggestions based on user spending patterns
      final insights =
          await _aiService.generateCommitmentSuggestions('current_user');
      setState(() {
        _aiSuggestions = insights.take(5).toList();
        _showAIInsights = true;
      });
    } catch (e) {
      debugPrint('Failed to load AI insights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Commitment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Geist',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildCommitmentTypeSection(),
                const SizedBox(height: 20),
                _buildTargetSection(),
                const SizedBox(height: 20),
                _buildLimitSection(),
                const SizedBox(height: 20),
                _buildDateSection(),
                const SizedBox(height: 20),
                _buildDifficultySection(),
                const SizedBox(height: 20),
                _buildPersonalitySection(),
                const SizedBox(height: 20),
                _buildSecuritySection(),
                if (_showAIInsights) ...[
                  const SizedBox(height: 20),
                  _buildAIInsightsSection(),
                ],
                const SizedBox(height: 30),
                _buildCreateButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withValues(alpha: 0.1),
              Colors.blue.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Cap, Can\'t Take It Back',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a locked commitment that enforces your financial discipline',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once locked, this commitment cannot be easily broken. Choose wisely!',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commitment Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...CommitmentType.values.map((type) {
              final info = _getTypeInfo(type);
              return RadioListTile<CommitmentType>(
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _targetController.clear();
                  });
                  _onTypeChanged();
                },
                title: Row(
                  children: [
                    Icon(info['icon'] as IconData,
                        size: 20, color: info['color'] as Color),
                    const SizedBox(width: 8),
                    Text(info['title'] as String),
                  ],
                ),
                subtitle: Text(info['description'] as String),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTargetLabel(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetController,
              decoration: InputDecoration(
                hintText: _getTargetHint(),
                prefixIcon:
                    Icon(_getTypeInfo(_selectedType)['icon'] as IconData),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.psychology),
                  onPressed: _showAISuggestions,
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a ${_getTargetLabel().toLowerCase()}';
                }
                return null;
              },
              onChanged: (_) => _analyzeTarget(),
            ),
            const SizedBox(height: 8),
            Text(
              _getTargetDescription(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLimitLabel(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitController,
              decoration: InputDecoration(
                hintText: _getLimitHint(),
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
                suffixText: 'USD',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (_) => _analyzeLimit(),
            ),
            const SizedBox(height: 8),
            Text(
              _getLimitDescription(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            DateFormat('MMM d, y').format(_startDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            DateFormat('MMM d, y').format(_endDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_endDate.difference(_startDate).inDays} days commitment',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...CommitmentDifficulty.values.map((difficulty) {
              final info = _getDifficultyInfo(difficulty);
              return RadioListTile<CommitmentDifficulty>(
                value: difficulty,
                groupValue: _selectedDifficulty,
                onChanged: (value) {
                  setState(() => _selectedDifficulty = value!);
                },
                title: Row(
                  children: [
                    Icon(info['icon'] as IconData,
                        size: 20, color: info['color'] as Color),
                    const SizedBox(width: 8),
                    Text(info['title'] as String),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (info['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${info['points']} pts',
                        style: TextStyle(
                          color: info['color'] as Color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(info['description'] as String),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI Coach Personality',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPersonality,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'motivational',
                    child: Text('🔥 Motivational Coach')),
                DropdownMenuItem(
                    value: 'strict', child: Text('⚡ Strict Trainer')),
                DropdownMenuItem(
                    value: 'supportive', child: Text('💖 Supportive Friend')),
                DropdownMenuItem(
                    value: 'analytical', child: Text('📊 Data-Driven Analyst')),
                DropdownMenuItem(
                    value: 'humorous', child: Text('😄 Humorous Mentor')),
              ],
              onChanged: (value) {
                setState(() => _selectedPersonality = value!);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _getPersonalityDescription(_selectedPersonality),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Security Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Require Biometric Authentication'),
              subtitle: const Text(
                  'Use fingerprint/face ID to modify or delete this commitment'),
              value: _requireBiometric,
              onChanged: (value) {
                setState(() => _requireBiometric = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_aiSuggestions.isNotEmpty) ...[
              Text(
                'Suggestions based on your spending patterns:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              ..._aiSuggestions.map(
                (suggestion) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(suggestion)),
                    ],
                  ),
                ),
              ),
            ],
            if (_aiRiskAssessment != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Risk Assessment: $_aiRiskAssessment',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isCreating ? null : _createCommitment,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Creating Commitment...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 8),
                  Text(
                    'Lock It In - No Cap!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Helper methods
  Map<String, dynamic> _getTypeInfo(CommitmentType type) {
    switch (type) {
      case CommitmentType.merchant:
        return {
          'title': 'Merchant Restriction',
          'description': 'Block spending at specific merchants',
          'icon': Icons.store,
          'color': Colors.red,
        };
      case CommitmentType.category:
        return {
          'title': 'Category Limit',
          'description': 'Limit spending in specific categories',
          'icon': Icons.category,
          'color': Colors.orange,
        };
      case CommitmentType.amountLimit:
        return {
          'title': 'Amount Limit',
          'description': 'Set maximum spending amount',
          'icon': Icons.attach_money,
          'color': Colors.green,
        };
      case CommitmentType.savingsGoal:
        return {
          'title': 'Savings Goal',
          'description': 'Commit to saving a specific amount',
          'icon': Icons.savings,
          'color': Colors.blue,
        };
    }
  }

  Map<String, dynamic> _getDifficultyInfo(CommitmentDifficulty difficulty) {
    switch (difficulty) {
      case CommitmentDifficulty.easy:
        return {
          'title': 'Easy',
          'description': 'Flexible enforcement, warnings first',
          'icon': Icons.sentiment_satisfied,
          'color': Colors.green,
          'points': 100,
        };
      case CommitmentDifficulty.medium:
        return {
          'title': 'Medium',
          'description': 'Balanced approach with penalties',
          'icon': Icons.balance,
          'color': Colors.orange,
          'points': 250,
        };
      case CommitmentDifficulty.hard:
        return {
          'title': 'Hard',
          'description': 'Strict enforcement, immediate penalties',
          'icon': Icons.gavel,
          'color': Colors.red,
          'points': 500,
        };
      case CommitmentDifficulty.extreme:
        return {
          'title': 'Extreme',
          'description': 'Nuclear option - severe penalties',
          'icon': Icons.warning,
          'color': Colors.purple,
          'points': 1000,
        };
      case CommitmentDifficulty.casual:
        return {
          'title': 'Casual',
          'description': 'Relaxed approach with gentle reminders',
          'icon': Icons.sentiment_neutral,
          'color': Colors.blue,
          'points': 50,
        };
      case CommitmentDifficulty.moderate:
        return {
          'title': 'Moderate',
          'description': 'Steady enforcement with fair penalties',
          'icon': Icons.trending_up,
          'color': Colors.amber,
          'points': 200,
        };
      case CommitmentDifficulty.hardcore:
        return {
          'title': 'Hardcore',
          'description': 'Intense enforcement with heavy penalties',
          'icon': Icons.flash_on,
          'color': Colors.deepPurple,
          'points': 750,
        };
    }
  }

  String _getPersonalityDescription(String personality) {
    switch (personality) {
      case 'motivational':
        return 'Energetic and encouraging, celebrates victories and motivates through challenges';
      case 'strict':
        return 'No-nonsense approach, direct feedback and tough love when needed';
      case 'supportive':
        return 'Understanding and compassionate, focuses on emotional support';
      case 'analytical':
        return 'Data-driven insights, focuses on numbers and trends';
      case 'humorous':
        return 'Uses humor to make financial discipline more enjoyable';
      default:
        return '';
    }
  }

  String _getTargetLabel() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return 'Merchant Name';
      case CommitmentType.category:
        return 'Spending Category';
      case CommitmentType.amountLimit:
        return 'Budget Name';
      case CommitmentType.savingsGoal:
        return 'Goal Name';
    }
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return 'e.g., Starbucks, Amazon, Target';
      case CommitmentType.category:
        return 'e.g., Dining, Entertainment, Shopping';
      case CommitmentType.amountLimit:
        return 'e.g., Weekly Groceries, Monthly Entertainment';
      case CommitmentType.savingsGoal:
        return 'e.g., Emergency Fund, Vacation Savings';
    }
  }

  String _getTargetDescription() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return 'Specify the merchant where spending will be restricted';
      case CommitmentType.category:
        return 'Choose a spending category to limit';
      case CommitmentType.amountLimit:
        return 'Give your budget a descriptive name';
      case CommitmentType.savingsGoal:
        return 'Name your savings goal for motivation';
    }
  }

  String _getLimitLabel() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return 'Monthly Spending Limit';
      case CommitmentType.category:
        return 'Category Spending Limit';
      case CommitmentType.amountLimit:
        return 'Maximum Amount';
      case CommitmentType.savingsGoal:
        return 'Savings Target';
    }
  }

  String _getLimitHint() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return '0.00';
      case CommitmentType.category:
        return '500.00';
      case CommitmentType.amountLimit:
        return '1000.00';
      case CommitmentType.savingsGoal:
        return '5000.00';
    }
  }

  String _getLimitDescription() {
    switch (_selectedType) {
      case CommitmentType.merchant:
        return 'Set to \$0 for complete restriction, or set a monthly limit';
      case CommitmentType.category:
        return 'Maximum amount you can spend in this category';
      case CommitmentType.amountLimit:
        return 'The spending limit you\'re committing to';
      case CommitmentType.savingsGoal:
        return 'Target amount you want to save';
    }
  }

  void _onTypeChanged() {
    // Clear AI analysis when type changes
    setState(() {
      _aiRiskAssessment = null;
      _spendingAnalysis = null;
    });
  }

  void _analyzeTarget() {
    // Trigger AI analysis of the target
    // This could provide suggestions or warnings
  }

  void _analyzeLimit() {
    // Analyze the spending limit
    // Could provide insights about whether it's realistic
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _showAISuggestions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🤖 AI Suggestions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_aiSuggestions.isNotEmpty)
              ..._aiSuggestions.map(
                (suggestion) => ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(suggestion),
                  onTap: () {
                    _targetController.text = suggestion;
                    Navigator.pop(context);
                  },
                ),
              )
            else
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Analyzing your spending patterns...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How No Cap Works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔒 Lock Mechanism:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Once created, commitments are locked and difficult to break.'),
              SizedBox(height: 12),
              Text('🎯 AI Monitoring:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Our AI watches your transactions 24/7 for violations.'),
              SizedBox(height: 12),
              Text('⚡ Instant Penalties:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Violations trigger immediate point deductions and alerts.'),
              SizedBox(height: 12),
              Text('🏆 Rewards System:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Staying on track earns points and unlocks achievements.'),
              SizedBox(height: 12),
              Text('🔐 Security:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Biometric authentication required for changes.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCommitment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final limit = double.parse(_limitController.text);

      final result = await _commitmentService.createCommitment(
        type: _selectedType,
        target: _targetController.text,
        spendingLimit: limit,
        timePeriod: 'monthly', // Default to monthly
        difficulty: _selectedDifficulty,
        requireBiometric: _requireBiometric,
        userNote: _notesController.text,
      );

      if (result.success) {
        // Award points for creating commitment
        await _pointService.awardPoints(
          userId: 'current_user',
          action: PointAction.commitmentSuccess,
          points: _getDifficultyInfo(_selectedDifficulty)['points'] as int,
          metadata: {
            'commitment_type': _selectedType.name,
            'difficulty': _selectedDifficulty.name,
            'target': _targetController.text,
            'limit': limit,
          },
        );

        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Commitment Locked!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 Your commitment is now locked in!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(result.message ?? 'Commitment created successfully'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${_getDifficultyInfo(_selectedDifficulty)['points']} Points Earned!',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: const Text('View Dashboard'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
              content:
                  Text(result.message ?? 'Commitment created successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text(Failed to create commitment: $e)),

          );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
