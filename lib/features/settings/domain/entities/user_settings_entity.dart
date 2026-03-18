class UserSettingsEntity {
  const UserSettingsEntity({
    required this.username,
    required this.dateFormat,
    required this.currency,
  });

  final String username;
  final String dateFormat;
  final String currency;

  UserSettingsEntity copyWith({
    String? username,
    String? dateFormat,
    String? currency,
  }) => UserSettingsEntity(
    username: username ?? this.username,
    dateFormat: dateFormat ?? this.dateFormat,
    currency: currency ?? this.currency,
  );

  @override
  bool operator ==(Object other) =>
      other is UserSettingsEntity &&
      other.username == username &&
      other.dateFormat == dateFormat &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(username, dateFormat, currency);

  @override
  String toString() =>
      'UserSettingsEntity(username: $username, dateFormat: $dateFormat, currency: $currency)';
}
