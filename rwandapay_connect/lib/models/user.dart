class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role; // "sender" | "receiver" | "admin"
  final String country;
  final String phone;
  final String accountNumber;
  final String idType;
  final String idNumber;
  final String verificationStatus;
  final String? address;
  final String? momoProvider;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.country,
    required this.phone,
    required this.accountNumber,
    required this.idType,
    required this.idNumber,
    this.verificationStatus = 'verified',
    this.address,
    this.momoProvider,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
