// Créer ce fichier pour tester sans configuration Google Sheets
// 
// Ajouter ceci au début de main.dart après les imports:
//
// import 'cloud_sync_mock.dart' if (dart.io.Platform.isAndroid) 'package:wifaq_association/main.dart';
//
// Et utiliser MockCloudSyncService à la place de CloudSyncService si vous voulez tester offline

class MockCloudSyncService {
  MockCloudSyncService._();

  static final MockCloudSyncService instance = MockCloudSyncService._();

  // In-memory storage for testing
  final Map<String, List<Map<String, dynamic>>> _mockData = {
    'registrations': [],
    'executive_members': [
      {
        'id': '1',
        'name': 'عبد العزيز عاشوري',
        'role': 'الرئيس',
        'order_index': 1,
        'photo_url': '',
        'is_deleted': false,
      },
      {
        'id': '2',
        'name': 'مليكة الرابحي',
        'role': 'النائبة الأولى',
        'order_index': 2,
        'photo_url': '',
        'is_deleted': false,
      },
    ],
    'achievements': [
      {
        'id': '1',
        'year': '2025',
        'description': 'قافلة تضامنية',
        'status': 'done',
        'order_index': 1,
        'is_deleted': false,
      },
    ],
    'objectives': [
      {
        'id': 'objective_1',
        'text': 'ترسيخ ثقافة التضامن',
        'order_index': 1,
        'is_deleted': false,
      },
    ],
    'manifestations': [],
  };

  bool get isConfigured => true;

  Future<List<String>> fetchObjectives() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rows = _mockData['objectives'] ?? [];
    return rows
        .where((e) => !e['is_deleted'])
        .map((e) => e['text'].toString())
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchExecutiveMembers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockData['executive_members'] ?? []);
  }

  Future<int> insertExecutiveMember(dynamic row) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final data = {
      'id': '${_mockData['executive_members']!.length + 1}',
      'name': row.name,
      'role': row.role,
      'order_index': row.orderIndex,
      'photo_url': row.photoPath,
      'is_deleted': false,
    };
    _mockData['executive_members']!.add(data);
    return int.parse(data['id']);
  }

  Future<int> updateExecutiveMember(dynamic row) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockData['executive_members']!
        .indexWhere((e) => e['id'].toString() == row.id.toString());
    if (index >= 0) {
      _mockData['executive_members']![index] = {
        'id': row.id.toString(),
        'name': row.name,
        'role': row.role,
        'order_index': row.orderIndex,
        'photo_url': row.photoPath,
        'is_deleted': false,
      };
    }
    return 1;
  }

  Future<int> deleteExecutiveMember(int? id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockData['executive_members']!
        .indexWhere((e) => e['id'].toString() == id.toString());
    if (index >= 0) {
      _mockData['executive_members']!.removeAt(index);
    }
    return 1;
  }

  // Stub all other methods
  Future<void> flushSync() async {}
  void clearCache() {}
  Map<String, dynamic> getSyncStatus() => {'queuedOperations': 0, 'isSyncing': false};
  Future<List<Map<String, dynamic>>> fetchAchievements({String? status}) async => [];
  Future<int> insertAchievement(dynamic item) async => 1;
  Future<int> updateAchievement(dynamic item) async => 1;
  Future<int> deleteAchievement(int? id) async => 1;
  Future<void> addAchievementPhotos(int achievementId, List<String> paths) async {}
  Future<int> deleteAchievementPhoto({required int achievementId, required int photoId}) async => 1;
  Future<void> moveExecutiveMember(int memberId, {required bool up}) async {}
  Future<void> moveAchievement(int achievementId, {required String status, required bool up}) async {}
  Future<List<Map<String, dynamic>>> fetchRegistrations() async => [];
  Future<int> insertRegistration(dynamic registration) async => 1;
  Future<int> updateRegistration(dynamic registration) async => 1;
  Future<int> deleteRegistration(int? id) async => 1;
  Future<void> saveObjectives(List<String> objectives) async {}
  Future<List<Map<String, dynamic>>> fetchManifestations() async => [];
  Future<int> insertManifestation(dynamic manifestation) async => 1;
}

// MODE D'EMPLOI:
//
// Pour utiliser le MockCloudSyncService au lieu de CloudSyncService:
//
// 1. Ouvrir lib/main.dart
// 2. Chercher avec Ctrl+F: "CloudSyncService.instance"
// 3. Remplacer par: "MockCloudSyncService.instance"
//    (NE FAIS PAS ÇA EN PROD, seulement pour le test!)
//
// Ou créer un switch dynamique:
//    final cloudSync = kDebugMode && kAppsScriptApiKey.isEmpty 
//        ? MockCloudSyncService.instance 
//        : CloudSyncService.instance;
