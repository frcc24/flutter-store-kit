import 'package:in_app_review/in_app_review.dart';

import '../../core/storage/local_store.dart';

class ReviewState {
  const ReviewState({this.asks = 0, this.lastAskedGames = 0});

  factory ReviewState.fromJson(Map<String, dynamic> json) => ReviewState(
    asks: json['asks'] as int? ?? 0,
    lastAskedGames: json['lastAskedGames'] as int? ?? 0,
  );

  final int asks;
  final int lastAskedGames;

  ReviewState copyWith({int? asks, int? lastAskedGames}) => ReviewState(
    asks: asks ?? this.asks,
    lastAskedGames: lastAskedGames ?? this.lastAskedGames,
  );

  Map<String, dynamic> toJson() => {
    'asks': asks,
    'lastAskedGames': lastAskedGames,
  };
}

/// When to show the Play review card. The app picks the moment and nothing
/// else: the in-app review policy forbids asking the player any question
/// before or while the card is shown — including "are you enjoying it?" — and
/// forbids a button that triggers it, because Google's quota may already be
/// spent and the button would do nothing.
/// https://developer.android.com/guide/playcore/in-app-review (read 2026-09-07)
///
/// The moment chosen here is a completed game, never a loss and never a
/// mistake: the third one, then every fifth, at most three times ever.
class ReviewPrompt {
  ReviewPrompt(this._store, {this._review});

  static const firstAt = 3;
  static const every = 5;
  static const maxAsks = 3;

  final LocalStore _store;
  final InAppReview? _review;

  /// True when [maybeAsk] would show the card. Pure: the screen uses it to
  /// decide between the review card and the interstitial without spending an
  /// ask on a game where it will not show one.
  bool willAsk(int completedGames) {
    final state = _store.loadReviewState();
    if (state.asks >= maxAsks) return false;
    if (completedGames < firstAt || (completedGames - firstAt) % every != 0) {
      return false;
    }
    return state.lastAskedGames != completedGames;
  }

  Future<void> maybeAsk(int completedGames) async {
    if (!willAsk(completedGames)) return;
    final state = _store.loadReviewState();
    await _store.saveReviewState(
      state.copyWith(asks: state.asks + 1, lastAskedGames: completedGames),
    );
    try {
      final review = _review ?? InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (_) {
      // Best effort: whether the card appears is Google's call, not ours.
    }
  }
}
