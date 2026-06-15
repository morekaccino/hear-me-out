import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class SettingsState {
  final String instrument;
  final String instrumentRange;
  final bool hapticsEnabled;
  final bool darkMode;
  final int dailySessionCount;
  final bool isPro;

  const SettingsState({
    this.instrument = 'guitar',
    this.instrumentRange = 'E2-E5',
    this.hapticsEnabled = true,
    this.darkMode = true,
    this.dailySessionCount = 0,
    this.isPro = false,
  });

  SettingsState copyWith({
    String? instrument,
    String? instrumentRange,
    bool? hapticsEnabled,
    bool? darkMode,
    int? dailySessionCount,
    bool? isPro,
  }) {
    return SettingsState(
      instrument: instrument ?? this.instrument,
      instrumentRange: instrumentRange ?? this.instrumentRange,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      darkMode: darkMode ?? this.darkMode,
      dailySessionCount: dailySessionCount ?? this.dailySessionCount,
      isPro: isPro ?? this.isPro,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setInstrument(String instrument) {
    state = state.copyWith(instrument: instrument);
  }

  void setInstrumentRange(String range) {
    state = state.copyWith(instrumentRange: range);
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsEnabled: !state.hapticsEnabled);
  }

  void incrementDailySession() {
    state = state.copyWith(dailySessionCount: state.dailySessionCount + 1);
  }

  void resetDailySessions() {
    state = state.copyWith(dailySessionCount: 0);
  }

  void setPro(bool isPro) {
    state = state.copyWith(isPro: isPro);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final canPracticeTodayProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.isPro) return true;
  return settings.dailySessionCount < 3;
});
