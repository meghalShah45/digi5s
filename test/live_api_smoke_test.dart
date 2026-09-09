// Live smoke test against the real backend. Skipped unless credentials are
// supplied:
//   flutter test test/live_api_smoke_test.dart \
//     --dart-define=LIVE_EMAIL=... --dart-define=LIVE_PASSWORD=...
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seicho_app/core/api/api_client.dart';
import 'package:seicho_app/core/auth/session.dart';
import 'package:seicho_app/features/dashboard/dashboard_repository.dart';
import 'package:seicho_app/features/flash_news/flash_news.dart';
import 'package:seicho_app/features/organisations/organisation_service.dart';
import 'package:seicho_app/features/red_tags/services/red_tag_service.dart';
import 'package:seicho_app/features/training_material/services/training_material_service.dart';
import 'package:seicho_app/features/zone_member/services/task_service.dart';
import 'package:seicho_app/services/member_service.dart';

const _email = String.fromEnvironment('LIVE_EMAIL');
const _password = String.fromEnvironment('LIVE_PASSWORD');

/// In-memory stand-in for secure storage (no platform channel in tests).
class MemorySessionStore extends SessionStore {
  UserSession? _s;
  @override
  Future<UserSession?> read() async => _s;
  @override
  Future<String?> readToken() async => _s?.token;
  @override
  Future<void> write(UserSession s) async => _s = s;
  @override
  Future<void> clear() async => _s = null;
}

void main() {
  final enabled = _email.isNotEmpty && _password.isNotEmpty;

  late MemorySessionStore store;
  late ApiClient api;

  setUp(() {
    store = MemorySessionStore();
    api = ApiClient(sessionStore: store);
  });

  test('ping', () async {
    final res = await api.get('/ping');
    expect(res.raw['message'], 'pong');
  });

  test('login + dashboard reads', () async {
    final res = await api.post('/users/login', body: {'email': _email, 'password': _password, 'rememberMe': true});
    final session = UserSession.fromLoginData(res.map);
    expect(session.token, isNotEmpty);
    expect(session.role, isNotEmpty);
    await store.write(session);
    // ignore: avoid_print
    print('logged in as ${session.email} role=${session.role} (raw ${session.roleRaw}) orgId=${session.orgId}');

    // Pick an organisation to read dashboard data for.
    var orgId = session.orgId;
    if (orgId == null || orgId.isEmpty) {
      final orgs = await api.get('/organisations');
      expect(orgs.list, isNotEmpty);
      orgId = orgs.list.first['id'].toString();
      // ignore: avoid_print
      print('super admin: using org ${orgs.list.first['name']} ($orgId) of ${orgs.list.length}');
    }

    final repo = DashboardRepository(api);
    final counts = await repo.counts(orgId: orgId);
    // ignore: avoid_print
    print('counts: tasks=${counts.tasksTotal} (pending ${counts.tasksPending}, approval ${counts.tasksPendingApproval}, '
        'done ${counts.tasksCompleted}) redTags=${counts.redTagsTotal} (open ${counts.redTagsPending})');

    final sub = await repo.subscription(orgId);
    // ignore: avoid_print
    print('subscription: exists=${sub.exists} active=${sub.isActive} ends=${sub.endDate} daysLeft=${sub.daysLeft} free=${sub.isFree}');

    final news = await FlashNewsService(api).forOrg(orgId);
    // ignore: avoid_print
    print('flash news: ${news.length} total, ${news.where((n) => n.isActive).length} active');

    // Authenticated route: logout must accept the Bearer token.
    final logout = await api.post('/auth/logout');
    expect(logout.ok, isTrue);
  }, skip: enabled ? false : 'set LIVE_EMAIL / LIVE_PASSWORD');


  test('feature services', () async {
    final res = await api.post('/users/login', body: {'email': _email, 'password': _password, 'rememberMe': true});
    final session = UserSession.fromLoginData(res.map);
    await store.write(session);
    var orgId = session.orgId ?? '';
    final orgSvc = OrganisationService(api);
    if (session.isSuperAdmin) {
      final orgs = await orgSvc.list();
      final subs = await orgSvc.subscriptionsByOrg();
      final counts = await orgSvc.superAdminCounts();
      final pending = await orgSvc.pendingPaidSubscriptions();
      // ignore: avoid_print
      print('super admin: ${orgs.length} orgs, ${subs.length} subscription rows, counts=$counts, pending=${pending.length}');
      expect(orgs, isNotEmpty);
      orgId = orgs.firstWhere((o) => o.name == 'Test Org Name', orElse: () => orgs.first).id;
      final one = await orgSvc.get(orgId);
      expect(one?.id, orgId);
    }
    final redTags = await RedTagService(api).getRedTags(orgId);
    final tasks = await TaskService(api, store).getTasksForOrg(orgId);
    final training = await TrainingMaterialService(api).getTrainingMaterialsForOrg(orgId);
    final members = await MemberService(api).getOrgMembers(orgId);
    final roles = await MemberService(api).getRoles();
    // ignore: avoid_print
    print('org $orgId: redTags=${redTags.length} tasks=${tasks.length} training=${training.length} members=${members.length} roles=${roles.length}');
    expect(roles, isNotEmpty);
    if (!session.isSuperAdmin) {
      final mine = await TaskService(api, store).getTasksByUserId();
      // ignore: avoid_print
      print('my tasks: ${mine.length}');
    }
  }, skip: enabled ? false : 'set LIVE_EMAIL / LIVE_PASSWORD');

  test('provider wiring compiles', () {
    final container = ProviderContainer(overrides: [sessionStoreProvider.overrideWithValue(store)]);
    expect(container.read(apiClientProvider), isA<ApiClient>());
    container.dispose();
  });
}
