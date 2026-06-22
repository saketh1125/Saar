import 'package:flutter_test/flutter_test.dart';
import 'package:kashi_nav/data/models/models.dart';
import 'package:kashi_nav/data/repositories/repositories.dart';
import 'package:kashi_nav/data/seed/varanasi_pois.dart';

void main() {
  group('MockPoiRepository', () {
    late MockPoiRepository repo;

    setUp(() {
      repo = MockPoiRepository([...kSeedPois, ...kMainRoadNodes]);
    });

    test('all() returns seed POIs', () async {
      final pois = await repo.all();
      expect(pois, isNotEmpty);
      expect(pois.length, greaterThanOrEqualTo(32));
    });

    test('byCategory() filters correctly', () async {
      final ghats = await repo.byCategory(PoiCategory.ghat);
      expect(ghats, isNotEmpty);
      for (final ghat in ghats) {
        expect(ghat.category, PoiCategory.ghat);
      }
    });

    test('byId() returns matching POI', () async {
      final first = (await repo.all()).first;
      final found = await repo.byId(first.id);
      expect(found, isNotNull);
      expect(found!.id, first.id);
    });

    test('byId() returns null for unknown id', () async {
      final found = await repo.byId('nonexistent_id');
      expect(found, isNull);
    });

    test('nearestMainRoads() returns main road nodes', () async {
      final roads = await repo.nearestMainRoads(25.3176, 83.0130);
      expect(roads, isNotEmpty);
    });
  });

  group('MockLiveSituationRepository', () {
    late MockLiveSituationRepository repo;

    setUp(() {
      repo = MockLiveSituationRepository();
    });

    test('getLiveSituation() returns response with required fields', () async {
      final result = await repo.getLiveSituation(
        query: 'test query',
        lat: 25.3176,
        lng: 83.0130,
      );
      expect(result.text, isNotEmpty);
      expect(result.confidence, anyOf(equals('high'), equals('medium')));
      expect(result.sources, isNotEmpty);
      expect(result.toolCalls, isA<List<ToolCall>>());
    });
  });

  group('MockItineraryRepository', () {
    late MockItineraryRepository repo;

    setUp(() {
      repo = MockItineraryRepository();
    });

    test('generate() returns itinerary with 3 steps', () async {
      final itinerary = await repo.generate(lat: 25.3176, lng: 83.0130);
      expect(itinerary.steps, hasLength(3));
      expect(itinerary.date, isNotEmpty);
    });

    test('itinerary steps cover morning, afternoon, evening', () async {
      final itinerary = await repo.generate(lat: 25.3176, lng: 83.0130);
      final slots = itinerary.steps.map((s) => s.timeSlot).toList();
      expect(slots, containsAll(['morning', 'afternoon', 'evening']));
    });
  });

  group('MockPanchangRepository', () {
    late MockPanchangRepository repo;

    setUp(() {
      repo = MockPanchangRepository();
    });

    test('forDate() returns panchang data', () async {
      final panchang = await repo.forDate(DateTime(2026, 6, 16));
      expect(panchang.tithi, isNotEmpty);
      expect(panchang.nakshatra, isNotEmpty);
      expect(panchang.rituals, isNotEmpty);
    });
  });

  group('MockVoiceIntentRepository', () {
    late MockVoiceIntentRepository repo;

    setUp(() {
      repo = MockVoiceIntentRepository();
    });

    test('parse() returns alarm tool call for alarm text', () async {
      final intent = await repo.parse('Set an alarm for 4:30 AM');
      expect(intent.toolCalls, isNotEmpty);
      expect(intent.toolCalls.any((tc) => tc.name == 'set_alarm'), isTrue);
    });

    test('parse() returns navigation tool calls for temple text', () async {
      final intent = await repo.parse('Take me to Vishwanath temple');
      expect(intent.toolCalls, isNotEmpty);
      expect(intent.toolCalls.any((tc) => tc.name == 'show_checklist'), isTrue);
      expect(intent.toolCalls.any((tc) => tc.name == 'start_navigation'), isTrue);
    });

    test('parse() returns empty tool calls for unknown text', () async {
      final intent = await repo.parse('Hello world');
      expect(intent.toolCalls, isEmpty);
      expect(intent.ttsResponse, contains('Hello world'));
    });
  });

  group('MockCrowdDensityRepository', () {
    late MockCrowdDensityRepository repo;

    setUp(() {
      repo = MockCrowdDensityRepository();
    });

    test('forPlace() returns valid crowd density', () async {
      final density = await repo.forPlace('vpd_ghat_dashashwamedh');
      expect(density.placeId, 'vpd_ghat_dashashwamedh');
      expect(density.indexScore, greaterThanOrEqualTo(0));
      expect(density.indexScore, lessThanOrEqualTo(100));
      expect(density.crowdStatus, anyOf(equals('peaceful'), equals('active'), equals('very_crowded')));
    });
  });

  group('MockFairPriceRepository', () {
    late MockFairPriceRepository repo;

    setUp(() {
      repo = MockFairPriceRepository();
    });

    test('directory() returns rates and advisories', () async {
      final dir = await repo.directory('en_US');
      expect(dir.rates, isNotEmpty);
      expect(dir.advisories, isNotEmpty);
      expect(dir.lastUpdated, isA<DateTime>());
    });
  });

  group('MockJournalProcessingRepository', () {
    late MockJournalProcessingRepository repo;

    setUp(() {
      repo = MockJournalProcessingRepository();
    });

    test('process() returns reflection data', () async {
      final result = await repo.process('Test journal entry');
      expect(result.score, isA<double>());
      expect(result.label, isNotEmpty);
      expect(result.reflection, isNotEmpty);
      expect(result.tags, isA<List<String>>());
    });
  });
}
