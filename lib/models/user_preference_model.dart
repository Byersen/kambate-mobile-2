class UserPreferenceModel {
  final String id;
  final String userId;
  final bool onboardingCompleted;
  final List<String> selectedSports;
  final bool notificationsEnabled;

  const UserPreferenceModel({
    required this.id,
    required this.userId,
    this.onboardingCompleted = false,
    this.selectedSports = const [],
    this.notificationsEnabled = true,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserPreferenceModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      onboardingCompleted: json['onboarding_completed'] == true ||
          json['onboardingCompleted'] == true,
      selectedSports: json['selected_sports'] is List
          ? (json['selected_sports'] as List).map((e) => e.toString()).toList()
          : (json['selectedSports'] is List
              ? (json['selectedSports'] as List).map((e) => e.toString()).toList()
              : const []),
      notificationsEnabled: json['notifications_enabled'] ??
          json['notificationsEnabled'] ??
          true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'onboarding_completed': onboardingCompleted,
      'selected_sports': selectedSports,
      'notifications_enabled': notificationsEnabled,
    };
  }
}
