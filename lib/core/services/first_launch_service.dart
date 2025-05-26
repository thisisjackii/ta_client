// lib/core/services/first_launch_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  static const String _budgetingIntroSeenKey = 'budgeting_intro_seen';
  static const String _evaluationIntroSeenKey = 'evaluation_intro_seen';

  Future<bool> isBudgetingIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_budgetingIntroSeenKey) ?? false;
  }

  Future<void> setBudgetingIntroSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_budgetingIntroSeenKey, seen);
  }

  Future<bool> isEvaluationIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_evaluationIntroSeenKey) ?? false;
  }

  Future<void> setEvaluationIntroSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_evaluationIntroSeenKey, seen);
  }

  // Method to clear flags (e.g., for testing or if user resets app data)
  Future<void> clearAllIntroFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_budgetingIntroSeenKey);
    await prefs.remove(_evaluationIntroSeenKey);
  }
}
