import 'package:cloud_firestore/cloud_firestore.dart';

/// Model AI Match berdasarkan skema tabel AI_MATCHES pada ERD CampusLost.
class AiMatchModel {
  final String matchId;
  final String lostItemId;
  final String foundItemId;
  final double similarityScorePercent;
  final DateTime? detectedAt;

  // Breakdown skor (Kategori, Warna, Lokasi, Waktu) — total = 100
  final int categoryScore;
  final int colorScore;
  final int locationScore;
  final int timeScore;

  /// Status verifikasi admin: 'pending' | 'verified' | 'rejected'
  final String status;
  final DateTime? verifiedAt;
  final String? verifiedBy;

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
    this.status = 'pending',
    this.verifiedAt,
    this.verifiedBy,
  });

  factory AiMatchModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    int asInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      return fallback;
    }

    double asDouble(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      return fallback;
    }

    return AiMatchModel(
      matchId: id ?? map['matchId']?.toString() ?? map['match_id']?.toString() ?? '',
      lostItemId:
          map['lostItemId']?.toString() ?? map['lost_item_id']?.toString() ?? '',
      foundItemId:
          map['foundItemId']?.toString() ?? map['found_item_id']?.toString() ?? '',
      similarityScorePercent: asDouble(
        map['similarityScorePercent'] ?? map['similarity_score_percent'],
        0.0,
      ),
      detectedAt:
          parseDate(map['detectedAt'] ?? map['detected_at'] ?? map['createdAt']),
      categoryScore: asInt(map['categoryScore'] ?? map['category_score'], 30),
      colorScore: asInt(map['colorScore'] ?? map['color_score'], 20),
      locationScore: asInt(map['locationScore'] ?? map['location_score'], 30),
      timeScore: asInt(map['timeScore'] ?? map['time_score'], 7),
      status: map['status']?.toString() ?? 'pending',
      verifiedAt: parseDate(map['verifiedAt'] ?? map['verified_at']),
      verifiedBy: map['verifiedBy']?.toString() ?? map['verified_by']?.toString(),
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
      'detected_at': detectedAt != null ? Timestamp.fromDate(detectedAt!) : null,
      'category_score': categoryScore,
      'color_score': colorScore,
      'location_score': locationScore,
      'time_score': timeScore,
      'status': status,
      if (verifiedAt != null) 'verified_at': Timestamp.fromDate(verifiedAt!),
      if (verifiedBy != null) 'verified_by': verifiedBy,
    };
  }

  AiMatchModel copyWith({
    String? status,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return AiMatchModel(
      matchId: matchId,
      lostItemId: lostItemId,
      foundItemId: foundItemId,
      similarityScorePercent: similarityScorePercent,
      detectedAt: detectedAt,
      categoryScore: categoryScore,
      colorScore: colorScore,
      locationScore: locationScore,
      timeScore: timeScore,
      status: status ?? this.status,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}