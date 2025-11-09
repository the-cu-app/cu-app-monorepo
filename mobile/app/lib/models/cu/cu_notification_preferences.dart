class CUNotificationPreferences {
  final String financialInstitutionId;
  final String memberId;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool transactionAlerts;
  final bool balanceAlerts;
  final bool paymentReminders;
  final bool securityAlerts;
  final bool marketingEmails;
  final bool newsletterSubscriptions;
  final bool productUpdates;
  final String? emailAddress;
  final String? phoneNumber;
  final String? preferredLanguage;
  final String? timeZone;
  final Map<String, bool> customPreferences;
  final Map<String, dynamic> alertThresholds;
  final Map<String, dynamic> quietHours;
  final Map<String, dynamic> frequencySettings;
  final Map<String, dynamic> channelPreferences;
  final Map<String, dynamic> categoryPreferences;
  final Map<String, dynamic> urgencySettings;
  final Map<String, dynamic> deliveryMethods;
  final Map<String, dynamic> optInHistory;
  final Map<String, dynamic> complianceSettings;
  final Map<String, dynamic> auditTrail;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUNotificationPreferences({
    required this.financialInstitutionId,
    required this.memberId,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.pushNotifications,
    required this.transactionAlerts,
    required this.balanceAlerts,
    required this.paymentReminders,
    required this.securityAlerts,
    required this.marketingEmails,
    required this.newsletterSubscriptions,
    required this.productUpdates,
    this.emailAddress,
    this.phoneNumber,
    this.preferredLanguage,
    this.timeZone,
    this.customPreferences = const {},
    this.alertThresholds = const {},
    this.quietHours = const {},
    this.frequencySettings = const {},
    this.channelPreferences = const {},
    this.categoryPreferences = const {},
    this.urgencySettings = const {},
    this.deliveryMethods = const {},
    this.optInHistory = const {},
    this.complianceSettings = const {},
    this.auditTrail = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return CUNotificationPreferences(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      emailNotifications: json['emailNotifications'] as bool,
      smsNotifications: json['smsNotifications'] as bool,
      pushNotifications: json['pushNotifications'] as bool,
      transactionAlerts: json['transactionAlerts'] as bool,
      balanceAlerts: json['balanceAlerts'] as bool,
      paymentReminders: json['paymentReminders'] as bool,
      securityAlerts: json['securityAlerts'] as bool,
      marketingEmails: json['marketingEmails'] as bool,
      newsletterSubscriptions: json['newsletterSubscriptions'] as bool,
      productUpdates: json['productUpdates'] as bool,
      emailAddress: json['emailAddress'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      timeZone: json['timeZone'] as String?,
      customPreferences: Map<String, bool>.from(
        json['customPreferences'] ?? {},
      ),
      alertThresholds: Map<String, dynamic>.from(json['alertThresholds'] ?? {}),
      quietHours: Map<String, dynamic>.from(json['quietHours'] ?? {}),
      frequencySettings: Map<String, dynamic>.from(
        json['frequencySettings'] ?? {},
      ),
      channelPreferences: Map<String, dynamic>.from(
        json['channelPreferences'] ?? {},
      ),
      categoryPreferences: Map<String, dynamic>.from(
        json['categoryPreferences'] ?? {},
      ),
      urgencySettings: Map<String, dynamic>.from(json['urgencySettings'] ?? {}),
      deliveryMethods: Map<String, dynamic>.from(json['deliveryMethods'] ?? {}),
      optInHistory: Map<String, dynamic>.from(json['optInHistory'] ?? {}),
      complianceSettings: Map<String, dynamic>.from(
        json['complianceSettings'] ?? {},
      ),
      auditTrail: Map<String, dynamic>.from(json['auditTrail'] ?? {}),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'memberId': memberId,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'pushNotifications': pushNotifications,
      'transactionAlerts': transactionAlerts,
      'balanceAlerts': balanceAlerts,
      'paymentReminders': paymentReminders,
      'securityAlerts': securityAlerts,
      'marketingEmails': marketingEmails,
      'newsletterSubscriptions': newsletterSubscriptions,
      'productUpdates': productUpdates,
      'emailAddress': emailAddress,
      'phoneNumber': phoneNumber,
      'preferredLanguage': preferredLanguage,
      'timeZone': timeZone,
      'customPreferences': customPreferences,
      'alertThresholds': alertThresholds,
      'quietHours': quietHours,
      'frequencySettings': frequencySettings,
      'channelPreferences': channelPreferences,
      'categoryPreferences': categoryPreferences,
      'urgencySettings': urgencySettings,
      'deliveryMethods': deliveryMethods,
      'optInHistory': optInHistory,
      'complianceSettings': complianceSettings,
      'auditTrail': auditTrail,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
