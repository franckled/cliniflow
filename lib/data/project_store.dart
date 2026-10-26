import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'project.dart';

/// Dépôt local des projets. Tout reste sur l'appareil : aucune donnée n'est
/// transmise à un serveur.
class ProjectStore extends ChangeNotifier {
  ProjectStore._(this._prefs, this._projects);

  static const _key = 'cliniflow.projects.v1';

  final SharedPreferencesWithCache _prefs;
  final List<Project> _projects;

  static Future<ProjectStore> open() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_key},
      ),
    );
    return ProjectStore._(prefs, _decode(prefs.getString(_key)));
  }

  static List<Project> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<Object?>;
      return [
        for (final e in list)
          Project.fromJson(e! as Map<String, Object?>),
      ];
    } on Object catch (e) {
      debugPrint('Lecture des projets impossible : $e');
      return [];
    }
  }

  /// Projets, du plus récemment modifié au plus ancien.
  List<Project> get projects =>
      [..._projects]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Project? byId(String id) {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<Project> create({
    required String title,
    String acronym = '',
    String sponsor = '',
  }) async {
    final now = DateTime.now();
    final p = Project(
      id: '${now.microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}',
      title: title.trim(),
      acronym: acronym.trim(),
      sponsor: sponsor.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _projects.add(p);
    await _save();
    return p;
  }

  Future<void> update(Project p) async {
    final i = _projects.indexWhere((x) => x.id == p.id);
    if (i < 0) return;
    _projects[i] = p;
    await _save();
  }

  Future<void> delete(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode([for (final p in _projects) p.toJson()]),
    );
  }
}
