import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donor.dart';
import 'donor_repository.dart';

/// Donors stored in Firestore (collection `donors`, one document per donor),
/// so the same list shows on every device. Access is limited to the admin
/// accounts by `firestore.rules`. The first time the collection is empty the
/// original list (assets/data/initial_donors.csv) is loaded into it.
class FirestoreDonorRepository extends LocalDonorRepository {
  static const String collection = 'donors';
  final FirebaseFirestore _db;
  List<Donor> _cache = [];
  final Map<String, Map<String, dynamic>> _remote = {};

  FirestoreDonorRepository._(super.prefs, this._db);

  bool _loaded = false;

  static Future<FirestoreDonorRepository> createFirestore() async {
    final prefs = await SharedPreferences.getInstance();
    return FirestoreDonorRepository._(prefs, FirebaseFirestore.instance);
  }

  /// Loads the list once after sign-in. Nothing is read or written before an
  /// admin is signed in, and nothing is seeded if the read itself failed.
  Future<void> _ensureLoaded() async {
    if (_loaded || FirebaseAuth.instance.currentUser == null) return;
    try {
      final snap = await _db.collection(collection).get();
      _remote.clear();
      final donors = <Donor>[];
      for (final d in snap.docs) {
        final data = d.data();
        _remote[d.id] = data;
        donors.add(Donor.fromJson(data));
      }
      donors.sort((a, b) => a.id.compareTo(b.id));
      _cache = donors;
      _loaded = true;
    } catch (_) {
      return;
    }
    if (_cache.isEmpty) {
      await resetToInitialData();
    }
  }

  @override
  Future<List<Donor>> getAllDonors() async {
    await _ensureLoaded();
    return List<Donor>.of(_cache);
  }

  @override
  Future<void> saveAll(List<Donor> donors) async {
    await _ensureLoaded();
    if (!_loaded) {
      throw StateError('Donor list is not available. Sign in with an admin account.');
    }
    final next = {for (final d in donors) d.id: d.toJson()};
    final commits = <Future<void>>[];
    var batch = _db.batch();
    var count = 0;

    void add(void Function(WriteBatch b) fn) {
      fn(batch);
      count++;
      if (count >= 400) {
        commits.add(batch.commit());
        batch = _db.batch();
        count = 0;
      }
    }

    next.forEach((id, json) {
      if (_remote[id].toString() != json.toString()) {
        add((b) => b.set(_db.collection(collection).doc(id), json));
      }
    });
    for (final id in _remote.keys) {
      if (!next.containsKey(id)) {
        add((b) => b.delete(_db.collection(collection).doc(id)));
      }
    }
    if (count > 0) commits.add(batch.commit());
    await Future.wait(commits);

    _remote
      ..clear()
      ..addAll(next);
    _cache = List<Donor>.of(donors);
  }
}
