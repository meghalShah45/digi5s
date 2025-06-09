import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/audit/models/audit_sheet.dart';
import '../features/audit/models/audit_submission.dart';
import '../services/audit_sheet_service.dart';

final auditSheetServiceProvider = Provider<AuditSheetService>((ref) {
  return AuditSheetService();
});

class CreateAuditSheetParams {
  final AuditSheet auditSheet;
  final String zoneId;

  CreateAuditSheetParams({required this.auditSheet, required this.zoneId});
}

final createAuditSheetProvider = FutureProvider.family<AuditSheet, CreateAuditSheetParams>((ref, params) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.createAuditSheet(params.auditSheet, params.zoneId);
}); 

final auditSheetsProvider = FutureProvider.family<List<AuditSheet>, String>((ref, orgId) async {
  try {
    print('AuditSheetsProvider: Fetching sheets for orgId: $orgId');
    final service = ref.watch(auditSheetServiceProvider);
    final sheets = await service.getAuditSheets(orgId);
    print('AuditSheetsProvider: Successfully fetched ${sheets.length} sheets');
    return sheets;
  } catch (e, stackTrace) {
    print('AuditSheetsProvider: Error fetching sheets: $e');
    print('AuditSheetsProvider: Stack trace: $stackTrace');
    rethrow;
  }
});

final deleteAuditSheetProvider = FutureProvider.family<void, String>((ref, id) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.deleteAuditSheet(id);
});

final updateAuditSheetProvider = FutureProvider.family<AuditSheet, AuditSheet>((ref, auditSheet) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.updateAuditSheet(auditSheet);
});

final auditSheetSubmissionsProvider = FutureProvider.family<List<AuditSubmission>, String>((ref, auditSheetId) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.getAuditSheetSubmissions(auditSheetId);
}); 