enum UserRank {
  bronze,
  silver,
  gold,
  platinum,
}

class RankingUtils {
  // Thresholds for each rank (in points)
  // 1 point = 100 MMK spent
  static const int bronzeThreshold = 0;
  static const int silverThreshold = 1000;    // 100,000 MMK spent
  static const int goldThreshold = 5000;      // 500,000 MMK spent
  static const int platinumThreshold = 20000; // 2,000,000 MMK spent

  /// Get the current rank based on total points
  static UserRank getRank(int points) {
    if (points >= platinumThreshold) {
      return UserRank.platinum;
    } else if (points >= goldThreshold) {
      return UserRank.gold;
    } else if (points >= silverThreshold) {
      return UserRank.silver;
    } else {
      return UserRank.bronze;
    }
  }

  /// Get the display name of the rank
  static String getRankName(UserRank rank) {
    switch (rank) {
      case UserRank.bronze:
        return 'Bronze';
      case UserRank.silver:
        return 'Silver';
      case UserRank.gold:
        return 'Gold';
      case UserRank.platinum:
        return 'Platinum';
    }
  }

  /// Get points needed for the next rank
  static int pointsToNextRank(int currentPoints) {
    if (currentPoints < silverThreshold) {
      return silverThreshold - currentPoints;
    } else if (currentPoints < goldThreshold) {
      return goldThreshold - currentPoints;
    } else if (currentPoints < platinumThreshold) {
      return platinumThreshold - currentPoints;
    } else {
      return 0; // Max rank reached
    }
  }

  /// Get progress percentage to the next rank (0.0 to 1.0)
  static double getProgressToNextRank(int points) {
    if (points < silverThreshold) {
      return points / silverThreshold;
    } else if (points < goldThreshold) {
      final pointsInTier = points - silverThreshold;
      final tierSize = goldThreshold - silverThreshold;
      return pointsInTier / tierSize;
    } else if (points < platinumThreshold) {
      final pointsInTier = points - goldThreshold;
      final tierSize = platinumThreshold - goldThreshold;
      return pointsInTier / tierSize;
    } else {
      return 1.0; // Max rank reached
    }
  }
}
