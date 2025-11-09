class CUUserProfile {
  final String financialInstitutionId;
  final String memberId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String dateOfBirth;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String? middleName;
  final String? suffix;
  final String? preferredName;
  final String? gender;
  final String? maritalStatus;
  final String? occupation;
  final String? employer;
  final String? annualIncome;
  final String? ssn;
  final String? driversLicense;
  final String? passportNumber;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> demographics;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> emergencyContacts;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CUUserProfile({
    required this.financialInstitutionId,
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.middleName,
    this.suffix,
    this.preferredName,
    this.gender,
    this.maritalStatus,
    this.occupation,
    this.employer,
    this.annualIncome,
    this.ssn,
    this.driversLicense,
    this.passportNumber,
    this.preferences = const {},
    this.demographics = const {},
    this.contactInfo = const {},
    this.emergencyContacts = const {},
    this.customFields = const {},
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CUUserProfile.fromJson(Map<String, dynamic> json) {
    return CUUserProfile(
      financialInstitutionId: json['financialInstitutionId'] as String,
      memberId: json['memberId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      middleName: json['middleName'] as String?,
      suffix: json['suffix'] as String?,
      preferredName: json['preferredName'] as String?,
      gender: json['gender'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      occupation: json['occupation'] as String?,
      employer: json['employer'] as String?,
      annualIncome: json['annualIncome'] as String?,
      ssn: json['ssn'] as String?,
      driversLicense: json['driversLicense'] as String?,
      passportNumber: json['passportNumber'] as String?,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      demographics: Map<String, dynamic>.from(json['demographics'] ?? {}),
      contactInfo: Map<String, dynamic>.from(json['contactInfo'] ?? {}),
      emergencyContacts: Map<String, dynamic>.from(
        json['emergencyContacts'] ?? {},
      ),
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
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
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'middleName': middleName,
      'suffix': suffix,
      'preferredName': preferredName,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'occupation': occupation,
      'employer': employer,
      'annualIncome': annualIncome,
      'ssn': ssn,
      'driversLicense': driversLicense,
      'passportNumber': passportNumber,
      'preferences': preferences,
      'demographics': demographics,
      'contactInfo': contactInfo,
      'emergencyContacts': emergencyContacts,
      'customFields': customFields,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
