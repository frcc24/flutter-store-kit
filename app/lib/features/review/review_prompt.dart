import 'package:in_app_review/in_app_review.dart';

import '../../core/storage/local_store.dart';

class ReviewState {
  const ReviewState({
    this.refusals = 0,
    this.accepted = false,
    this.lastPromptedGames = 0,
  });

  factory ReviewState.fromJson(Map<String, dynamic> json) => ReviewState(
    refusals: json['refusals'] as int? ?? 0,
    accepted: json['accepted'] as bool? ?? false,
    lastPromptedGames: json['lastPromptedGames'] as int? ?? 0,
  );

  final int refusals;
  final bool accepted;
  final int lastPromptedGames;

  ReviewState copyWith({
    int? refusals,
    bool? accepted,
    int? lastPromptedGames,
  }) => ReviewState(
    refusals: refusals ?? this.refusals,
    accepted: accepted ?? this.accepted,
    lastPromptedGames: lastPromptedGames ?? this.lastPromptedGames,
  );

  Map<String, dynamic> toJson() => {
    'refusals': refusals,
    'accepted': accepted,
    'lastPromptedGames': lastPromptedGames,
  };
}

/// When to ask, and the platform review flow itself. Asked after the third
/// completed game, then every fifth; never again after a yes or three nos.
/// The store decides whether its own sheet actually appears (Google caps it),
/// which is why the in-app dialog comes first: it is the one we control.
class ReviewPrompt {
  ReviewPrompt(this._store, {this._review});

  static const firstAt = 3;
  static const every = 5;
  static const maxRefusals = 3;

  final LocalStore _store;
  final InAppReview? _review;

  Future<bool> shouldPrompt(int completedGames) async {
    final state = _store.loadReviewState();
    if (state.accepted || state.refusals >= maxRefusals) return false;
    if (completedGames < firstAt || (completedGames - firstAt) % every != 0) {
      return false;
    }
    if (state.lastPromptedGames == completedGames) return false;
    await _store.saveReviewState(
      state.copyWith(lastPromptedGames: completedGames),
    );
    return true;
  }

  Future<void> accept() async {
    await _store.saveReviewState(
      _store.loadReviewState().copyWith(accepted: true),
    );
    try {
      final review = _review ?? InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (_) {
      // The platform sheet is best effort; the player already said yes.
    }
  }

  Future<void> decline() async {
    final state = _store.loadReviewState();
    await _store.saveReviewState(state.copyWith(refusals: state.refusals + 1));
  }
}
