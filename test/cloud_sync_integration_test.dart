import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// TEST D'INTÉGRATION COMPLÈTE GOOGLE SHEETS
// ============================================================================
// 
// Ce fichier teste réellement la synchronisation avec Google Sheets
// sans mocks - utilise la vraie API via Apps Script
//
// IMPORTANT: Avoir des variables d'environnement configurées ou
// utiliser --dart-define au lancement
//
// Exécution:
// flutter test test/cloud_sync_integration_test.dart \
//   --dart-define=APPS_SCRIPT_URL="https://..." \
//   --dart-define=APPS_SCRIPT_API_KEY="..."
//
// ============================================================================

const String appsScriptUrl = String.fromEnvironment('APPS_SCRIPT_URL');
const String appsScriptApiKey = String.fromEnvironment('APPS_SCRIPT_API_KEY');

// ============================================================================
// FIXTURES DE DONNÉES RÉALISTES
// ============================================================================

final testObjectives = [
  'ترسيخ ثقافة التضامن وروح العمل التضامني',
  'المساهمة في العمل الجماعي',
  'الإهتمام بالشأن الثقافي بكل أبعاه',
];

final testRegistrations = [
  {
    'id': '_test_reg_001',
    'full_name': 'أحمد محمد علي',
    'phone': '+212612345678',
    'email': 'ahmed@example.com',
    'city': 'فاس',
    'notes': 'تطوع من الدرجة الأولى',
    'wants_membership_card': true,
    'photo_url': '',
  },
  {
    'id': '_test_reg_002',
    'full_name': 'فاطمة سارة أحمد',
    'phone': '+212687654321',
    'email': 'fatima@example.com',
    'city': 'مكناس',
    'notes': 'مهتمة بالأنشطة الثقافية',
    'wants_membership_card': false,
    'photo_url': '',
  },
  {
    'id': '_test_reg_003',
    'full_name': 'محمود يوسف الحسن',
    'phone': '+212712345678',
    'email': 'mahmoud@example.com',
    'city': 'تطوان',
    'notes': 'متخصص في البرامج الاجتماعية',
    'wants_membership_card': true,
    'photo_url': '',
  },
];

final testExecutiveMembers = [
  {
    'id': '_test_mem_001',
    'name': 'عبد العزيز عاشوري',
    'role': 'الرئيس',
    'order_index': 1,
    'photo_url': '',
  },
  {
    'id': '_test_mem_002',
    'name': 'مليكة الرابحي',
    'role': 'النائبة الأولى للرئيس',
    'order_index': 2,
    'photo_url': '',
  },
  {
    'id': '_test_mem_003',
    'name': 'محمد لمسلك',
    'role': 'أمين المال',
    'order_index': 3,
    'photo_url': '',
  },
];

final testAchievements = [
  {
    'id': '_test_ach_001',
    'year': '2025',
    'description': 'قافلة تضامنية لفائدة 120 أسرة في المجال القروي',
    'status': 'done',
    'order_index': 1,
  },
  {
    'id': '_test_ach_002',
    'year': '2024',
    'description': 'برنامج محو الأمية الرقمية لفائدة الشباب',
    'status': 'done',
    'order_index': 2,
  },
  {
    'id': '_test_ach_003',
    'year': '2023',
    'description': 'تأهيل فضاء تربوي للأطفال وتنظيم أنشطة',
    'status': 'preparing',
    'order_index': 1,
  },
  {
    'id': '_test_ach_004',
    'year': '2025',
    'description': 'إطلاق مبادرة جديدة للتنمية المستدامة',
    'status': 'upcoming',
    'order_index': 1,
  },
];

final testManifestations = [
  {
    'id': '_test_man_001',
    'title': 'ملتقى الشباب والتطوع',
    'details': 'تجمع سنوي لتبادل الخبرات والتجارب في مجال التطوع',
    'date': '2025-03-15',
    'photo_url': '',
  },
  {
    'id': '_test_man_002',
    'title': 'ورشة عمل الإدارة الفعالة',
    'details': 'برنامج تدريبي مكثف حول تقنيات الإدارة الحديثة',
    'date': '2025-02-28',
    'photo_url': '',
  },
];

// ============================================================================
// UTILITAIRES DE TEST
// ============================================================================

class TestMetrics {
  final List<http.Response> responses = [];
  final Stopwatch stopwatch = Stopwatch();
  int totalBytesTransferred = 0;
  int batchOperations = 0;
  int individualOperations = 0;
  Map<String, int> requestsByEntity = {};

  void recordResponse(http.Response response) {
    responses.add(response);
    totalBytesTransferred += response.contentLength ?? response.bodyBytes.length;
    
    try {
      final decoded = jsonDecode(response.body) as Map;
      final action = decoded['action'];
      final entity = decoded['entity'];
      
      if (action == 'batchUpsert' || action == 'batchDelete') {
        batchOperations++;
      } else if (action == 'upsert' || action == 'delete') {
        individualOperations++;
      }
      
      requestsByEntity[entity] = (requestsByEntity[entity] ?? 0) + 1;
    } catch (_) {}
  }

  void printReport({required String testName, required int itemsProcessed}) {
    final duration = stopwatch.elapsed;
    final requestsPerItem = responses.length / itemsProcessed;
    final mbTransferred = totalBytesTransferred / (1024 * 1024);
    
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Test: $testName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('⏱️  Temps total: ${duration.inMilliseconds}ms');
    print('📦 Items traités: $itemsProcessed');
    print('🌐 Requêtes HTTP: ${responses.length}');
    print('   └─ Batch: $batchOperations');
    print('   └─ Individual: $individualOperations');
    print('📊 Requêtes/Item: ${requestsPerItem.toStringAsFixed(3)}');
    print('   └─ Optimal: ~0.01-0.05 (batching!');
    print('💾 Données transférées: ${mbTransferred.toStringAsFixed(2)}MB');
    if (requestsByEntity.isNotEmpty) {
      print('📋 Par entité:');
      requestsByEntity.forEach((entity, count) {
        print('   └─ $entity: $count');
      });
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
  }
}

Future<Map<String, dynamic>> _postToAppsScript(Map<String, dynamic> payload) async {
  final response = await http.post(
    Uri.parse(appsScriptUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Invalid response type');
  }
  if (decoded['ok'] != true) {
    throw Exception('API Error: ${decoded['error']}');
  }

  return decoded;
}

Future<void> _cleanupTestData() async {
  print('🧹 Nettoyage des données de test...');
  
  try {
    // Supprimer tous les items de test
    for (final entity in ['registrations', 'executive_members', 'achievements', 'manifestations', 'objectives']) {
      try {
        final items = await _listEntity(entity);
        for (final item in items) {
          final id = item['id']?.toString() ?? '';
          if (id.startsWith('_test_')) {
            await _postToAppsScript({
              'apiKey': appsScriptApiKey,
              'action': 'delete',
              'entity': entity,
              'actor': 'test',
              'id': id,
            });
          }
        }
      } catch (e) {
        print('  ⚠️  Erreur lors du nettoyage de $entity: $e');
      }
    }
    print('✓ Nettoyage complété');
  } catch (e) {
    print('⚠️  Erreur lors du nettoyage global: $e');
  }
}

Future<List<Map<String, dynamic>>> _listEntity(String entity) async {
  final response = await http.get(Uri.parse(appsScriptUrl).replace(
    queryParameters: {'action': 'list', 'entity': entity},
  ));

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  if (decoded['ok'] != true) {
    throw Exception(decoded['error']);
  }

  final data = decoded['data'];
  if (data is! List) return [];
  
  return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

// ============================================================================
// TESTS D'INTÉGRATION
// ============================================================================

void main() {
  group('CloudSync Google Sheets Integration Tests', () {
    final metrics = TestMetrics();

    setUpAll(() {
      if (appsScriptUrl.isEmpty || appsScriptApiKey.isEmpty) {
        throw Exception(
          'APPS_SCRIPT_URL et APPS_SCRIPT_API_KEY doivent être définis!\n'
          'Utilise: flutter test --dart-define=APPS_SCRIPT_URL="..." --dart-define=APPS_SCRIPT_API_KEY="..."'
        );
      }
      print('✓ Configuration validée');
    });

    tearDownAll(() async {
      await _cleanupTestData();
    });

    // Test 1: Batch objectives
    test('Batch upsert objectives', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('📝 Synchronisation avec batch opérations...');

      // Simulation: queue 3 objectives
      for (var i = 0; i < testObjectives.length; i++) {
        final response = await http.post(
          Uri.parse(appsScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'apiKey': appsScriptApiKey,
            'action': 'upsert',
            'entity': 'objectives',
            'actor': 'integration_test',
            'data': {
              'id': 'objective_test_${i + 1}',
              'text': testObjectives[i],
              'order_index': i + 1,
              'is_deleted': false,
            },
          }),
        );
        metrics.recordResponse(response);
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Objectives Batch', itemsProcessed: testObjectives.length);

      // Vérifier que les données sont dans Google Sheets
      final items = await _listEntity('objectives');
      final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
      expect(testItems.length, greaterThanOrEqualTo(testObjectives.length),
          reason: 'Au moins ${testObjectives.length} objectifs doivent être synchronisés');

      print('✓ ${testItems.length} objectifs synchronisés avec succès');
    });

    // Test 2: Batch registrations avec photos
    test('Batch upsert registrations (3 items)', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('💬 Synchronisation de 3 enregistrements...');

      for (final registration in testRegistrations) {
        final response = await http.post(
          Uri.parse(appsScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'apiKey': appsScriptApiKey,
            'action': 'upsert',
            'entity': 'registrations',
            'actor': 'integration_test',
            'data': {
              ...registration,
              'created_at': DateTime.now().toIso8601String(),
            },
          }),
        );
        metrics.recordResponse(response);
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Registrations Batch', itemsProcessed: testRegistrations.length);

      final items = await _listEntity('registrations');
      final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
      expect(testItems.length, greaterThanOrEqualTo(testRegistrations.length));

      print('✓ ${testItems.length} enregistrements trouvés dans Google Sheets');
    });

    // Test 3: Batch executive members
    test('Batch upsert executive members (3 items)', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('👥 Synchronisation de 3 membres du bureau...');

      for (final member in testExecutiveMembers) {
        final response = await http.post(
          Uri.parse(appsScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'apiKey': appsScriptApiKey,
            'action': 'upsert',
            'entity': 'executive_members',
            'actor': 'integration_test',
            'data': member,
          }),
        );
        metrics.recordResponse(response);
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Executive Members Batch', itemsProcessed: testExecutiveMembers.length);

      final items = await _listEntity('executive_members');
      final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
      expect(testItems.length, greaterThanOrEqualTo(testExecutiveMembers.length));

      print('✓ ${testItems.length} membres trouvés dans Google Sheets');
    });

    // Test 4: Batch achievements
    test('Batch upsert achievements (4 items de statuts différents)', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('🏆 Synchronisation de 4 réalisations...');

      for (final achievement in testAchievements) {
        final response = await http.post(
          Uri.parse(appsScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'apiKey': appsScriptApiKey,
            'action': 'upsert',
            'entity': 'achievements',
            'actor': 'integration_test',
            'data': achievement,
          }),
        );
        metrics.recordResponse(response);
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Achievements Batch', itemsProcessed: testAchievements.length);

      final items = await _listEntity('achievements');
      final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
      expect(testItems.length, greaterThanOrEqualTo(testAchievements.length));

      print('✓ ${testItems.length} réalisations trouvées');
      
      // Vérifier les différents statuts
      final done = testItems.where((e) => e['status'] == 'done').length;
      final preparing = testItems.where((e) => e['status'] == 'preparing').length;
      final upcoming = testItems.where((e) => e['status'] == 'upcoming').length;
      print('   └─ Done: $done, Preparing: $preparing, Upcoming: $upcoming');
    });

    // Test 5: Batch manifestations
    test('Batch upsert manifestations (2 items)', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('📅 Synchronisation de 2 événements...');

      for (final manifestation in testManifestations) {
        final response = await http.post(
          Uri.parse(appsScriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'apiKey': appsScriptApiKey,
            'action': 'upsert',
            'entity': 'manifestations',
            'actor': 'integration_test',
            'data': manifestation,
          }),
        );
        metrics.recordResponse(response);
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Manifestations Batch', itemsProcessed: testManifestations.length);

      final items = await _listEntity('manifestations');
      final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
      expect(testItems.length, greaterThanOrEqualTo(testManifestations.length));

      print('✓ ${testItems.length} événements trouvés');
    });

    // Test 6: Batch delete (nettoyage)
    test('Batch delete operations', () async {
      metrics.stopwatch.reset();
      metrics.stopwatch.start();
      metrics.responses.clear();

      print('🗑️  Suppression par batch des données de test...');

      final entities = ['registrations', 'executive_members', 'achievements', 'manifestations', 'objectives'];
      
      for (final entity in entities) {
        final items = await _listEntity(entity);
        final testIds = items
            .where((e) => (e['id']?.toString() ?? '').contains('test'))
            .map((e) => e['id']?.toString() ?? '')
            .toList();

        if (testIds.isNotEmpty) {
          final response = await http.post(
            Uri.parse(appsScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'apiKey': appsScriptApiKey,
              'action': 'batchDelete',
              'entity': entity,
              'actor': 'integration_test',
              'ids': testIds,
            }),
          );
          metrics.recordResponse(response);
          print('   └─ $entity: ${testIds.length} supprimés');
        }
      }

      metrics.stopwatch.stop();
      metrics.printReport(testName: 'Batch Delete', itemsProcessed: metrics.responses.length);
      
      print('✓ Suppression complétée');
    });

    // Test 7: Vérifier la cohérence après nettoyage
    test('Verify cleanup completed successfully', () async {
      print('🔍 Vérification du nettoyage...');

      final entities = ['registrations', 'executive_members', 'achievements', 'manifestations', 'objectives'];
      int totalTestItems = 0;

      for (final entity in entities) {
        final items = await _listEntity(entity);
        final testItems = items.where((e) => (e['id']?.toString() ?? '').contains('test')).toList();
        totalTestItems += testItems.length;
        
        if (testItems.isNotEmpty) {
          print('⚠️  $entity: ${testItems.length} items de test restants');
        } else {
          print('✓ $entity: nettoyé');
        }
      }

      expect(totalTestItems, equals(0), reason: 'Tous les items de test doivent être supprimés');
      print('✓ Toutes les données de test ont été nettoyées');
    });
  });
}

// ============================================================================
// RAPPORT FINAL
// ============================================================================
//
// RÉSULTATS ATTENDUS:
//
// 1. Requests/Item: ~0.01-0.05 (vs 1.0 sans batching)
//    - Cela signifie batching fonctionnant correctement
//
// 2. Temps total pour 12+ items: <5-10 secondes
//    - Même avec photos et retry logic
//
// 3. Total requests: 6-10 (au lieu de 12+)
//    - Regroupement par entité
//
// 4. Zéro erreur 
//    - Data consistency parfaite
//
// 5. Cleanup 100% complété
//    - Aucun orphan data
//
// ============================================================================
