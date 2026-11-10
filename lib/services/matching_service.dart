import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_match_model.dart';

class MatchingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Set<String> _tokens(String s) {
    const stop = {
      'yang', 'dan', 'di', 'ke', 'dari', 'ini', 'itu', 'saya', 'aku',
      'ada', 'untuk', 'dengan', 'atau', 'the', 'a', 'an', 'of', 'in',
      'on', 'at', 'is', 'are', 'was', 'were', 'my', 'i',
    };
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2 && !stop.contains(t))
        .toSet();
  }

  double _tokenSim(String a, String b) {
    final ta = _tokens(a);
    final tb = _tokens(b);
    if (ta.isEmpty || tb.isEmpty) return 0;
    final inter = ta.intersection(tb).length;
    final union = ta.union(tb).length;
    return union == 0 ? 0 : inter / union;
  }

  /// Hitung 4 komponen skor (dalam persen, total 0..87 sesuai bobot).
  AiMatchModel _computeMatch({
    required String matchId,
    required Map<String, dynamic> lost,
    required String lostId,
    required Map<String, dynamic> found,
    required String foundId,
  }) {
    // Kategori — exact match, bobot 30
    final catA = (lost['category'] ?? '').toString().toLowerCase().trim();
    final catB = (found['category'] ?? '').toString().toLowerCase().trim();
    final categoryScore = (catA.isNotEmpty && catA == catB) ? 30 : 0;

    // Warna — bobot 20
    final colorA = (lost['color'] ?? '').toString().toLowerCase().trim();
    final colorB = (found['color'] ?? '').toString().toLowerCase().trim();
    final colorScore = (colorA.isNotEmpty && colorA == colorB) ? 20 : 0;

    // Lokasi — token similarity * 30
    final locSim = _tokenSim(
      (lost['location'] ?? lost['locationName'] ?? '').toString(),
      (found['location'] ?? found['locationName'] ?? '').toString(),
    );
    final locationScore = (locSim * 30).round();

    // Waktu — 7 jika selisih ≤ 3 hari, menurun linear sampai 0 di 14 hari
    int timeScore = 0;
    DateTime? tLost = _toDate(lost['date'] ?? lost['createdAt'] ?? lost['detectedAt']);
    DateTime? tFound = _toDate(found['date'] ?? found['createdAt'] ?? found['detectedAt']);
    if (tLost != null && tFound != null) {
      final diffDays = tLost.difference(tFound).inDays.abs();
      if (diffDays <= 3) {
        timeScore = 7;
      } else if (diffDays <= 14) {
        timeScore = (7 * (14 - diffDays) / 11).round();
      }
    }

    final total = categoryScore + colorScore + locationScore + timeScore;

    return AiMatchModel(
      matchId: matchId,
      lostItemId: lostId,
      foundItemId: foundId,
      similarityScorePercent: total.toDouble(),
      detectedAt: DateTime.now(),
      categoryScore: categoryScore,
      colorScore: colorScore,
      locationScore: locationScore,
      timeScore: timeScore,
    );
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  /// Jalankan pencocokan untuk SATU lost report.
  Future<List<AiMatchModel>> generateForLostReport(
    String lostId, {
    double threshold = 45,
  }) async {
    final lostDoc = await _db.collection('lost_reports').doc(lostId).get();
    if (!lostDoc.exists) return [];
    final lost = lostDoc.data()!;

    final foundSnap = await _db
        .collection('found_items')
        .where('status', whereIn: ['active', 'available', 'open'])
        .get();

    final results = <AiMatchModel>[];
    final batch = _db.batch();

    for (final doc in foundSnap.docs) {
      final ref = _db.collection('ai_matches').doc();
      final match = _computeMatch(
        matchId: ref.id,
        lost: lost,
        lostId: lostId,
        found: doc.data(),
        foundId: doc.id,
      );
      if (match.similarityScorePercent < threshold) continue;
      batch.set(ref, match.toMap());
      results.add(match);
    }

    await batch.commit();
    results.sort(
      (a, b) => b.similarityScorePercent.compareTo(a.similarityScorePercent),
    );
    return results;
  }

  /// Jalankan untuk SEMUA lost report aktif (dipanggil dari UI Admin).
  Future<int> generateAll({double threshold = 45}) async {
    final lostSnap = await _db
        .collection('lost_reports')
        .where('status', whereIn: ['active', 'open', 'pending'])
        .get();

    var count = 0;
    for (final doc in lostSnap.docs) {
      final res = await generateForLostReport(doc.id, threshold: threshold);
      count += res.length;
    }
    return count;
  }

  /// Stream daftar match untuk admin.
  Stream<List<AiMatchModel>> watchMatches({String status = 'pending'}) {
    return _db
        .collection('ai_matches')
        .where('status', isEqualTo: status)
        .orderBy('similarity_score_percent', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AiMatchModel.fromFirestore(d))
            .toList());
  }

  /// Admin memverifikasi match → tandai kedua item verified + match verified.
  Future<void> verifyMatch(AiMatchModel match, {required String adminUid}) async {
    final batch = _db.batch();
    final now = DateTime.now();

    batch.update(_db.collection('ai_matches').doc(match.matchId), {
      'status': 'verified',
      'verified_at': Timestamp.fromDate(now),
      'verified_by': adminUid,
    });

    batch.update(_db.collection('lost_reports').doc(match.lostItemId), {
      'status': 'verified',
      'matched_with': match.foundItemId,
      'verified_at': Timestamp.fromDate(now),
    });

    batch.update(_db.collection('found_items').doc(match.foundItemId), {
      'status': 'verified',
      'matched_with': match.lostItemId,
      'verified_at': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Admin menolak match.
  Future<void> rejectMatch(AiMatchModel match, {required String adminUid}) async {
    await _db.collection('ai_matches').doc(match.matchId).update({
      'status': 'rejected',
      'verified_at': Timestamp.fromDate(DateTime.now()),
      'verified_by': adminUid,
    });
  }
}