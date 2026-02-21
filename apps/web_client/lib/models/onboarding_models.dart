// Onboarding data models
class ProfileData {
  final String fullName;
  final String? phoneNumber;
  final String? gender; // 'male' or 'female'
  final String? profilePictureUrl;

  ProfileData({
    required this.fullName,
    this.phoneNumber,
    this.gender,
    this.profilePictureUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }
}

class CompanyData {
  final String businessName;
  final String businessType;
  final String address;
  final String country;
  final String city;
  final String? officeAddress;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;

  CompanyData({
    required this.businessName,
    required this.businessType,
    required this.address,
    required this.country,
    required this.city,
    this.officeAddress,
    this.logoUrl,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessType': businessType,
      'address': address,
      'country': country,
      'city': city,
      if (officeAddress != null) 'officeAddress': officeAddress,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class OnboardingStatus {
  final bool isComplete;
  final DateTime? completedAt;
  final String? tenantId;
  final String? role;
  final bool hasProfile;
  final bool hasPasscode;

  OnboardingStatus({
    required this.isComplete,
    this.completedAt,
    this.tenantId,
    this.role,
    this.hasProfile = false,
    this.hasPasscode = false,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      isComplete: json['isComplete'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      tenantId: json['tenantId'],
      role: json['role'],
      hasProfile: json['hasProfile'] ?? false,
      hasPasscode: json['hasPasscode'] ?? false,
    );
  }
}

// Business type enum
enum BusinessType {
  pharmacy('pharmacy', 'Pharmacy'),
  supermarket('supermarket', 'Supermarket'),
  pharmacySupermarket('pharmacy_supermarket', 'Pharmacy/Supermarket'),
  restaurant('restaurant', 'Restaurant'),
  retail('retail', 'Retail'),
  kiosk('kiosk', 'Kiosk'),
  neighbourhoodStore('neighbourhood_store', 'Neighbourhood Store');

  final String value;
  final String displayName;

  const BusinessType(this.value, this.displayName);

  static BusinessType fromValue(String value) {
    return BusinessType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BusinessType.retail,
    );
  }
}
