import 'package:cloud_firestore/cloud_firestore.dart';

/// Model AI Match berdasarkan skema tabel AI_MATCHES pada ERD CampusLost
class AiMatchModel {
  final String matchId; // match_id INT Auto-Increment
  final String lostItemId; // FK lost_item_id INT
  final String foundItemId; // FK found_item_id INT
  final double similarityScorePercent; // similarity_score_percent DECIMAL(5, 2) (e.g., 87.0)
  final DateTime? detectedAt; // detected_at TIMESTAMP CURRENT_TIMESTAMP

  // Breakdown skor kecocokan (seperti di Banner Smart Match: Kategori, Warna, Lokasi, Waktu)
  final int categoryScore;
  final int colorScore;
  final int locationScore;
  final int timeScore;

  const AiMatchModel({
    required this.matchId,
    required this.lostItemId,
    required this.foundItemId,
    required this.similarityScorePercent,
    this.detectedAt,
    this.categoryScore = 30,
    this.colorScore = 20,
    this.locationScore = 30,
    this.timeScore = 7,
  });

  factory AiMatchModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return AiMatchModel(
      matchId: id ?? map['matchId']?.toString() ?? map['match_id']?.toString() ?? '',
      lostItemId: map['lostItemId']?.toString() ?? map['lost_item_id']?.toString() ?? '',
      foundItemId: map['foundItemId']?.toString() ?? map['found_item_id']?.toString() ?? '',
      similarityScorePercent:
          (map['similarityScorePercent'] ?? map['similarity_score_percent'] as num?)?.toDouble() ?? 0.0,
      detectedAt: parseDate(map['detectedAt'] ?? map['detected_at'] ?? map['createdAt']),
      categoryScore: (map['categoryScore'] ?? map['category_score'] as num?)?.toInt() ?? 30,
      colorScore: (map['colorScore'] ?? map['color_score'] as num?)?.toInt() ?? 20,
      locationScore: (map['locationScore'] ?? map['location_score'] as num?)?.toInt() ?? 30,
      timeScore: (map['timeScore'] ?? map['time_score'] as num?)?.toInt() ?? 7,
    );
  }

  factory AiMatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AiMatchModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'lost_item_id': lostItemId,
      'found_item_id': foundItemId,
      'similarity_score_percent': similarityScorePercent,
      'detected_at': detectedAt,
      'category_score': categoryScore,
      'color_score': colorScore,
      'location_score': locationScore,
      'time_score': timeScore,
    };
  }
}
