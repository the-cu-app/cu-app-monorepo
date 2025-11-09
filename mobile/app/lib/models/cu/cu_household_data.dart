class CUHouseholdData {
  final String financialInstitutionId;
  final String householdId;
  final List<CUHouseholdMember> members;
  final CUAddress primaryAddress;
  final List<CUAddress> additionalAddresses;
  final String householdType;
  final DateTime verificationDate;
  final bool isVerified;
  final Map<String, dynamic> householdInfo;
  final List<String> verificationMethods;
  final Map<String, dynamic> verificationData;
  final List<String> householdDocuments;
  final String householdStatus;
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;

  const CUHouseholdData({
    required this.financialInstitutionId,
    required this.householdId,
    required this.members,
    required this.primaryAddress,
    required this.additionalAddresses,
    required this.householdType,
    required this.verificationDate,
    required this.isVerified,
    required this.householdInfo,
    required this.verificationMethods,
    required this.verificationData,
    required this.householdDocuments,
    required this.householdStatus,
    this.lastUpdated,
    required this.metadata,
  });

  factory CUHouseholdData.fromJson(Map<String, dynamic> json) {
    return CUHouseholdData(
      financialInstitutionId: json['financialInstitutionId'] as String,
      householdId: json['householdId'] as String,
      members: (json['members'] as List)
          .map((member) => CUHouseholdMember.fromJson(member))
          .toList(),
      primaryAddress: CUAddress.fromJson(
        json['primaryAddress'] as Map<String, dynamic>,
      ),
      additionalAddresses: (json['additionalAddresses'] as List)
          .map((address) => CUAddress.fromJson(address))
          .toList(),
      householdType: json['householdType'] as String,
      verificationDate: DateTime.parse(json['verificationDate'] as String),
      isVerified: json['isVerified'] as bool,
      householdInfo: Map<String, dynamic>.from(json['householdInfo'] as Map),
      verificationMethods: List<String>.from(
        json['verificationMethods'] as List,
      ),
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] as Map,
      ),
      householdDocuments: List<String>.from(json['householdDocuments'] as List),
      householdStatus: json['householdStatus'] as String,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialInstitutionId': financialInstitutionId,
      'householdId': householdId,
      'members': members.map((member) => member.toJson()).toList(),
      'primaryAddress': primaryAddress.toJson(),
      'additionalAddresses':
          additionalAddresses.map((address) => address.toJson()).toList(),
      'householdType': householdType,
      'verificationDate': verificationDate.toIso8601String(),
      'isVerified': isVerified,
      'householdInfo': householdInfo,
      'verificationMethods': verificationMethods,
      'verificationData': verificationData,
      'householdDocuments': householdDocuments,
      'householdStatus': householdStatus,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'metadata': metadata,
    };
  }

  CUHouseholdData copyWith({
    String? financialInstitutionId,
    String? householdId,
    List<CUHouseholdMember>? members,
    CUAddress? primaryAddress,
    List<CUAddress>? additionalAddresses,
    String? householdType,
    DateTime? verificationDate,
    bool? isVerified,
    Map<String, dynamic>? householdInfo,
    List<String>? verificationMethods,
    Map<String, dynamic>? verificationData,
    List<String>? householdDocuments,
    String? householdStatus,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return CUHouseholdData(
      financialInstitutionId:
          financialInstitutionId ?? this.financialInstitutionId,
      householdId: householdId ?? this.householdId,
      members: members ?? this.members,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      additionalAddresses: additionalAddresses ?? this.additionalAddresses,
      householdType: householdType ?? this.householdType,
      verificationDate: verificationDate ?? this.verificationDate,
      isVerified: isVerified ?? this.isVerified,
      householdInfo: householdInfo ?? this.householdInfo,
      verificationMethods: verificationMethods ?? this.verificationMethods,
      verificationData: verificationData ?? this.verificationData,
      householdDocuments: householdDocuments ?? this.householdDocuments,
      householdStatus: householdStatus ?? this.householdStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasMultipleMembers => members.length > 1;
  bool get hasAdditionalAddresses => additionalAddresses.isNotEmpty;
  bool get isRecentlyVerified =>
      DateTime.now().difference(verificationDate).inDays < 30;
  bool get isVerificationExpired =>
      DateTime.now().difference(verificationDate).inDays > 365;

  String get householdTypeDisplayName {
    switch (householdType.toLowerCase()) {
      case 'single':
        return 'Single Person';
      case 'couple':
        return 'Couple';
      case 'family':
        return 'Family';
      case 'extended_family':
        return 'Extended Family';
      case 'roommates':
        return 'Roommates';
      case 'other':
        return 'Other';
      default:
        return householdType;
    }
  }

  String get householdStatusDisplayName {
    switch (householdStatus.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      case 'suspended':
        return 'Suspended';
      case 'closed':
        return 'Closed';
      default:
        return householdStatus;
    }
  }

  List<CUHouseholdMember> get activeMembers =>
      members.where((member) => member.isActive).toList();
  List<CUHouseholdMember> get inactiveMembers =>
      members.where((member) => !member.isActive).toList();

  Map<String, dynamic> get householdSummary => {
        'householdId': householdId,
        'householdType': householdType,
        'householdStatus': householdStatus,
        'totalMembers': members.length,
        'activeMembers': activeMembers.length,
        'inactiveMembers': inactiveMembers.length,
        'isVerified': isVerified,
        'verificationDate': verificationDate.toIso8601String(),
        'isRecentlyVerified': isRecentlyVerified,
        'isVerificationExpired': isVerificationExpired,
        'hasAdditionalAddresses': hasAdditionalAddresses,
        'verificationMethods': verificationMethods,
        'householdDocuments': householdDocuments,
      };
}

class CUHouseholdMember {
  final String memberId;
  final String firstName;
  final String lastName;
  final String relationship;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final String ssn;
  final bool isActive;
  final DateTime addedDate;
  final Map<String, dynamic> memberInfo;
  final List<String> verificationMethods;
  final Map<String, dynamic> verificationData;
  final String memberStatus;
  final Map<String, dynamic> metadata;

  const CUHouseholdMember({
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.ssn,
    required this.isActive,
    required this.addedDate,
    required this.memberInfo,
    required this.verificationMethods,
    required this.verificationData,
    required this.memberStatus,
    required this.metadata,
  });

  factory CUHouseholdMember.fromJson(Map<String, dynamic> json) {
    return CUHouseholdMember(
      memberId: json['memberId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      relationship: json['relationship'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      ssn: json['ssn'] as String,
      isActive: json['isActive'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
      memberInfo: Map<String, dynamic>.from(json['memberInfo'] as Map),
      verificationMethods: List<String>.from(
        json['verificationMethods'] as List,
      ),
      verificationData: Map<String, dynamic>.from(
        json['verificationData'] as Map,
      ),
      memberStatus: json['memberStatus'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'firstName': firstName,
      'lastName': lastName,
      'relationship': relationship,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'ssn': ssn,
      'isActive': isActive,
      'addedDate': addedDate.toIso8601String(),
      'memberInfo': memberInfo,
      'verificationMethods': verificationMethods,
      'verificationData': verificationData,
      'memberStatus': memberStatus,
      'metadata': metadata,
    };
  }

  String get fullName => '$firstName $lastName';
  int get age => DateTime.now().year - dateOfBirth.year;

  String get relationshipDisplayName {
    switch (relationship.toLowerCase()) {
      case 'spouse':
        return 'Spouse';
      case 'child':
        return 'Child';
      case 'parent':
        return 'Parent';
      case 'sibling':
        return 'Sibling';
      case 'roommate':
        return 'Roommate';
      case 'other':
        return 'Other';
      default:
        return relationship;
    }
  }

  String get memberStatusDisplayName {
    switch (memberStatus.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      case 'suspended':
        return 'Suspended';
      case 'closed':
        return 'Closed';
      default:
        return memberStatus;
    }
  }
}

class CUAddress {
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String addressType;
  final bool isPrimary;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic> addressInfo;
  final Map<String, dynamic> metadata;

  const CUAddress({
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.addressType,
    required this.isPrimary,
    this.startDate,
    this.endDate,
    required this.addressInfo,
    required this.metadata,
  });

  factory CUAddress.fromJson(Map<String, dynamic> json) {
    return CUAddress(
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      addressType: json['addressType'] as String,
      isPrimary: json['isPrimary'] as bool,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      addressInfo: Map<String, dynamic>.from(json['addressInfo'] as Map),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'addressType': addressType,
      'isPrimary': isPrimary,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'addressInfo': addressInfo,
      'metadata': metadata,
    };
  }

  String get fullAddress {
    final address = addressLine1;
    final line2 = addressLine2?.isNotEmpty == true ? ', $addressLine2' : '';
    return '$address$line2, $city, $state $zipCode, $country';
  }

  String get addressTypeDisplayName {
    switch (addressType.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'mailing':
        return 'Mailing';
      case 'billing':
        return 'Billing';
      case 'other':
        return 'Other';
      default:
        return addressType;
    }
  }

  bool get isCurrent => endDate == null || DateTime.now().isBefore(endDate!);
  bool get isHistorical => endDate != null && DateTime.now().isAfter(endDate!);
}
