import 'package:flutter/foundation.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// Who a try-on or purchase is being sized for.
enum Wearer {
  /// The signed-in account holder — use their saved Bodygram/manual sizes.
  self,

  /// Someone else (a friend, a gift) — use sizes entered just for this session.
  someoneElse,
}

/// Tracks *whose body* the size checks should judge against — the "session".
///
/// The whole point: a size-fit warning is only meaningful for the person who
/// will actually wear the item. By default that's the account holder (whose
/// measurements are on file), but a user often shops for someone else, so they
/// can switch the session to a guest and enter that person's sizes. Both the
/// try-on size banner + NanoBanana render adjustment AND the checkout banner
/// read the wearer from here, so they always agree.
///
/// A singleton [ChangeNotifier] so any screen can react when the wearer flips.
/// Guest sizes are intentionally in-memory only — they belong to a shopping
/// session, not the account — and reset to [Wearer.self] on [reset].
class FittingSession extends ChangeNotifier {
  FittingSession._();
  static final FittingSession instance = FittingSession._();

  final DatabaseService _db = DatabaseService();

  Wearer _wearer = Wearer.self;
  Wearer get wearer => _wearer;
  bool get isSelf => _wearer == Wearer.self;

  /// Display name for the guest, if given ("Mom", "May"). Null → generic.
  String? _guestName;
  String? get guestName => _guestName;

  /// Sizes entered for the guest this session (someoneElse mode only).
  BodyMeasurements? _guestMeasurements;
  BodyMeasurements? get guestMeasurements => _guestMeasurements;

  /// Short label for messages: "you" for self, else the guest's name or "them".
  String get wearerLabel =>
      isSelf ? 'you' : (_guestName?.trim().isNotEmpty == true ? _guestName!.trim() : 'them');

  /// Switch the session back to the account holder.
  void useSelf() {
    _wearer = Wearer.self;
    notifyListeners();
  }

  /// Switch the session to a guest with the sizes entered for them.
  void useSomeoneElse({String? name, required BodyMeasurements measurements}) {
    _wearer = Wearer.someoneElse;
    _guestName = name;
    _guestMeasurements = measurements;
    notifyListeners();
  }

  /// The measurements to size against right now: the guest's when shopping for
  /// someone else, otherwise the account holder's (loaded from Firestore).
  /// Returns null when the active wearer has no sizes on file yet — callers
  /// treat that as "can't judge fit" and simply skip the check.
  Future<BodyMeasurements?> currentMeasurements() async {
    if (_wearer == Wearer.someoneElse) return _guestMeasurements;
    return _db.getBodyMeasurements();
  }

  /// Clear any guest and return to self — call when a shopping flow ends.
  void reset() {
    _wearer = Wearer.self;
    _guestName = null;
    _guestMeasurements = null;
    notifyListeners();
  }
}
