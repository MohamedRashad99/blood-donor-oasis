import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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

  Future<void>? _loading;

  /// Loads the list once after sign-in. Nothing is read or written before an
  /// admin is signed in, and nothing is seeded if the read itself failed.
  Future<void> _ensureLoaded() {
    if (_loaded || FirebaseAuth.instance.currentUser == null) {
      return Future.value();
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    Map<String, Map<String, dynamic>>? docs;
    try {
      docs = await _fetchRest().timeout(const Duration(seconds: 12));
    } catch (_) {
      docs = null;
    }
    if (docs == null) {
      try {
        final snap = await _db.collection(collection).get();
        docs = {for (final d in snap.docs) d.id: d.data()};
      } catch (_) {
        return;
      }
    }
    _remote
      ..clear()
      ..addAll(docs);
    final donors = docs.values.map(Donor.fromJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    _cache = donors;
    _loaded = true;
    if (_cache.isEmpty) {
      await resetToInitialData();
    }
  }

  /// One plain HTTPS read of the collection with the admin's token. Much
  /// faster to start than the Firestore streaming connection.
  Future<Map<String, Map<String, dynamic>>> _fetchRest() async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final projectId = _db.app.options.projectId;
    final out = <String, Map<String, dynamic>>{};
    String? pageToken;
    do {
      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/$collection',
        {'pageSize': '300', if (pageToken != null) 'pageToken': pageToken},
      );
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode != 200) {
        throw StateError('Firestore REST ${res.statusCode}');
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      for (final d in (body['documents'] as List<dynamic>? ?? const [])) {
        final doc = d as Map<String, dynamic>;
        final id = (doc['name'] as String).split('/').last;
        final fields = (doc['fields'] as Map<String, dynamic>?) ?? const {};
        out[id] = {for (final e in fields.entries) e.key: _decode(e.value as Map<String, dynamic>)};
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return out;
  }

  static dynamic _decode(Map<String, dynamic> v) {
    if (v.containsKey('stringValue')) return v['stringValue'];
    if (v.containsKey('integerValue')) return int.parse(v['integerValue'] as String);
    if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
    if (v.containsKey('booleanValue')) return v['booleanValue'];
    if (v.containsKey('timestampValue')) return v['timestampValue'];
    return null;
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
