import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

enum AppearanceMode { soft, sharp }

class SettingsService {
  // Singleton
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // State
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    try {
      await CoreNotificationService().init(); // Initialize Notifications
    } catch (e) {
      debugPrint("SettingsService: Notification Init Failed: $e");
    }
  }

  void _loadSettings() {
    if (_prefs == null) return;
    
    appearanceMode.value = AppearanceMode.values[_prefs!.getInt('appearanceMode') ?? 0];
    insightTone.value = _prefs!.getString('insightTone') ?? 'Supportive';
    insightsEnabled.value = _prefs!.getBool('insightsEnabled') ?? true;
    monthlyLimit.value = _prefs!.getDouble('monthlyLimit') ?? 4000.0;
    dailyLimit.value = _prefs!.getDouble('dailyLimit') ?? 1000.0; 
    currency.value = _prefs!.getString('currency') ?? '₹';
    lastInsightIndex.value = _prefs!.getInt('lastInsightIndex') ?? 0;
    lastInsightMessage.value = _prefs!.getString('lastInsightMessage');
    lastInsightType.value = _prefs!.getString('lastInsightType');
    
    userName.value = _prefs!.getString('userName') ?? "Traveler";
    profileImagePath.value = _prefs!.getString('profileImagePath');
    
    // Load History
    final historyList = _prefs!.getStringList('dailyInsightHistory') ?? [];
    dailyInsightHistory.value = historyList;
    lastInsightDate.value = _prefs!.getString('lastInsightDate');
    
    // Onboarding Persistence
    hasSeenIntentOnboarding.value = _prefs!.getBool('hasSeenIntentOnboarding') ?? false;
    hasSeenForgeOnboarding.value = _prefs!.getBool('hasSeenForgeOnboarding') ?? false;
    hasSeenVaultOnboarding.value = _prefs!.getBool('hasSeenVaultOnboarding') ?? false;
    hasSeenAnalyticsOnboarding.value = _prefs!.getBool('hasSeenAnalyticsOnboarding') ?? false;
    hasSeenHomeOnboarding.value = _prefs!.getBool('hasSeenHomeOnboarding') ?? false;
    hasSeenQuietSpaceOnboarding.value = _prefs!.getBool('hasSeenQuietSpaceOnboarding') ?? false;
    hasSeenSystemHubOnboarding.value = _prefs!.getBool('hasSeenSystemHubOnboarding') ?? false;
    hasSeenFavorsOnboarding.value = _prefs!.getBool('hasSeenFavorsOnboarding') ?? false; // Added
    hasSeenWelcome.value = _prefs!.getBool('hasSeenWelcome') ?? false;

    // System Hub Persistence
    biometricEnabled.value = _prefs!.getBool('biometricEnabled') ?? false;
    velocityAlertsEnabled.value = _prefs!.getBool('velocityAlertsEnabled') ?? true;
    exportFormat.value = _prefs!.getString('exportFormat') ?? 'PDF';
    hapticStrength.value = _prefs!.getDouble('hapticStrength') ?? 0.5;
    privacyMode.value = _prefs!.getBool('privacyMode') ?? false;
    
    final timeStr = _prefs!.getString('dailyReminderTime');
    if (timeStr != null) {
      final parts = timeStr.split(':');
      dailyReminderTime.value = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  // State
  final ValueNotifier<AppearanceMode> appearanceMode = ValueNotifier(AppearanceMode.soft);
  final ValueNotifier<String> insightTone = ValueNotifier('Supportive');
  final ValueNotifier<bool> insightsEnabled = ValueNotifier(true);
  final ValueNotifier<double> monthlyLimit = ValueNotifier(4000.0);
  final ValueNotifier<double> dailyLimit = ValueNotifier(1000.0);
  final ValueNotifier<String> currency = ValueNotifier('₹');
  final ValueNotifier<int> lastInsightIndex = ValueNotifier(0);
  final ValueNotifier<String?> lastInsightMessage = ValueNotifier(null);
  final ValueNotifier<String?> lastInsightType = ValueNotifier(null);
  
  final ValueNotifier<List<String>> dailyInsightHistory = ValueNotifier([]);
  final ValueNotifier<String?> lastInsightDate = ValueNotifier(null);

  final ValueNotifier<String> userName = ValueNotifier("Traveler");
  final ValueNotifier<String?> profileImagePath = ValueNotifier(null);
  
  // Onboarding Flags
  final ValueNotifier<bool> hasSeenIntentOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenForgeOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenVaultOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenAnalyticsOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenHomeOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenQuietSpaceOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenSystemHubOnboarding = ValueNotifier(false);
  final ValueNotifier<bool> hasSeenFavorsOnboarding = ValueNotifier(false); // Added
  final ValueNotifier<bool> hasSeenWelcome = ValueNotifier(false);
  
  // System Hub
  final ValueNotifier<bool> biometricEnabled = ValueNotifier(false);
  final ValueNotifier<TimeOfDay> dailyReminderTime = ValueNotifier(const TimeOfDay(hour: 21, minute: 0));
  final ValueNotifier<bool> velocityAlertsEnabled = ValueNotifier(true);
  final ValueNotifier<String> exportFormat = ValueNotifier('PDF'); // Always PDF
  final ValueNotifier<double> hapticStrength = ValueNotifier(0.5);
  final ValueNotifier<bool> privacyMode = ValueNotifier(false);

  // Actions
  void setUserName(String name) {
    userName.value = name;
    _prefs?.setString('userName', name);
  }

  void setProfileImage(String? path) {
    profileImagePath.value = path;
    if (path != null) {
      _prefs?.setString('profileImagePath', path);
    } else {
      _prefs?.remove('profileImagePath');
    }
  }

  void setHasSeenIntentOnboarding(bool value) {
    hasSeenIntentOnboarding.value = value;
    _prefs?.setBool('hasSeenIntentOnboarding', value);
  }

  void setHasSeenForgeOnboarding(bool value) {
    hasSeenForgeOnboarding.value = value;
    _prefs?.setBool('hasSeenForgeOnboarding', value);
  }

  void setHasSeenVaultOnboarding(bool value) {
    hasSeenVaultOnboarding.value = value;
    _prefs?.setBool('hasSeenVaultOnboarding', value);
  }

  void setHasSeenAnalyticsOnboarding(bool value) {
    hasSeenAnalyticsOnboarding.value = value;
    _prefs?.setBool('hasSeenAnalyticsOnboarding', value);
  }

  void setHasSeenHomeOnboarding(bool value) {
    hasSeenHomeOnboarding.value = value;
    _prefs?.setBool('hasSeenHomeOnboarding', value);
  }

  void setHasSeenQuietSpaceOnboarding(bool value) {
    hasSeenQuietSpaceOnboarding.value = value;
    _prefs?.setBool('hasSeenQuietSpaceOnboarding', value);
  }

  void setHasSeenSystemHubOnboarding(bool value) {
    hasSeenSystemHubOnboarding.value = value;
    _prefs?.setBool('hasSeenSystemHubOnboarding', value);
  }

  void setHasSeenFavorsOnboarding(bool value) { // Added
    hasSeenFavorsOnboarding.value = value;
    _prefs?.setBool('hasSeenFavorsOnboarding', value);
  }

  void setHasSeenWelcome(bool value) {
    hasSeenWelcome.value = value;
    _prefs?.setBool('hasSeenWelcome', value);
  }

  // --- Insight & History Actions ---

  void setLastInsightIndex(int index) {
    lastInsightIndex.value = index;
    _prefs?.setInt('lastInsightIndex', index);
  }

  void clearHistory() {
    dailyInsightHistory.value = [];
    _prefs?.setStringList('dailyInsightHistory', []);
  }

  void setLastInsightDate(String dateStr) {
    lastInsightDate.value = dateStr;
    _prefs?.setString('lastInsightDate', dateStr);
  }

  void addToHistory(String message) {
    final currentList = List<String>.from(dailyInsightHistory.value);
    currentList.add(message);
    dailyInsightHistory.value = currentList;
    _prefs?.setStringList('dailyInsightHistory', currentList);
  }

  void setLastInsightMessage(String? message) {
    lastInsightMessage.value = message;
    if (message != null) {
      _prefs?.setString('lastInsightMessage', message);
    } else {
      _prefs?.remove('lastInsightMessage');
    }
  }

  void setLastInsightType(String? type) {
    lastInsightType.value = type;
    if (type != null) {
      _prefs?.setString('lastInsightType', type);
    } else {
      _prefs?.remove('lastInsightType');
    }
  }

  // --- Preference Actions ---

  void setTone(String tone) {
    insightTone.value = tone;
    _prefs?.setString('insightTone', tone);
  }

  void toggleInsights(bool enabled) {
    insightsEnabled.value = enabled;
    _prefs?.setBool('insightsEnabled', enabled);
  }

  void setCurrency(String symbol) {
    currency.value = symbol;
    _prefs?.setString('currency', symbol);
  }

  void setLimit(double amount) {
    // Context-aware: Using for Monthly Limit primarily, or generic limit setting
    // But based on usage in ProfileScreen, it seems to map to monthly limit usually.
    // However, MonthlyIntentScreen calls explicit setMonthlyLimit. 
    // ProfileScreen calls setLimit. Let's assume Profile updates Monthly Limit by default.
    setMonthlyLimit(amount); 
  }
  
  void setMonthlyLimit(double amount) {
    monthlyLimit.value = amount;
    _prefs?.setDouble('monthlyLimit', amount);
  }

  void setDailyLimit(double amount) {
    dailyLimit.value = amount;
    _prefs?.setDouble('dailyLimit', amount);
  }

  void setAppearance(AppearanceMode mode) {
    appearanceMode.value = mode;
    _prefs?.setInt('appearanceMode', mode.index);
  }

  // --- System Hub Actions ---

  void setBiometric(bool enabled) {
    biometricEnabled.value = enabled;
    _prefs?.setBool('biometricEnabled', enabled);
  }

  void setDailyReminderTime(TimeOfDay time) {
    dailyReminderTime.value = time;
    _prefs?.setString('dailyReminderTime', '${time.hour}:${time.minute}');
  }

  void setPrivacyMode(bool enabled) {
    privacyMode.value = enabled;
    _prefs?.setBool('privacyMode', enabled);
  }

  void setVelocityAlerts(bool enabled) {
    velocityAlertsEnabled.value = enabled;
    _prefs?.setBool('velocityAlertsEnabled', enabled);
  }

  void setHapticStrength(double strength) {
    hapticStrength.value = strength;
    _prefs?.setDouble('hapticStrength', strength);
  }
}
